# AMATISTA ERP — REGLAS DE BACKEND

> Aplica unicamente a Amatista-be/.
> Para el template base (Jsoluciones-be/) ver Jsoluciones-docs/rules/BACKEND.md.

---

## 1. PATRON POR APP (OBLIGATORIO)

```
apps/{modulo}/
  models.py        -> Modelos con mixins, db_table, indices, constraints
  serializers.py   -> SOLO validacion y transformacion (NUNCA logica de negocio)
  services.py      -> TODA la logica de negocio (@transaction.atomic)
  views.py         -> Solo orquesta: request -> service -> response
  urls.py          -> Router DRF + paths custom
  admin.py         -> Registro en Django admin
  tasks.py         -> Tareas Celery (si aplica)
```

---

## 2. REGLAS ESTRICTAS

### Logica de negocio
```
BACK-01: Toda logica de negocio va en services.py. NUNCA en views ni serializers.
BACK-02: Views solo orquestan: recibir request -> llamar service -> retornar response.
BACK-03: Serializers solo validan y transforman. NO logica, NO queries complejas.
BACK-04: Services son funciones puras (no clases). Keyword-only arguments.
BACK-05: Signals solo para side-effects (logs, notificaciones). NUNCA logica principal.
```

### Transacciones y concurrencia
```
BACK-06: Toda operacion que modifique >1 tabla DEBE usar @transaction.atomic.
BACK-07: Descontar stock, correlativos de comprobante -> select_for_update().
BACK-08: Acciones post-TX (Celery tasks, emails) -> transaction.on_commit().
```

### Reglas especificas de Amatista (floreria)
```
BACK-F01: Al descontar insumos de la receta, SIEMPRE usar FIFO (lotes ordenados por fecha_entrada ASC).
BACK-F02: completar_produccion_item() es la unica funcion que descuenta insumos organicos.
          No descontar insumos desde crear_venta_pos() — el descuento ocurre al marcar "listo".
BACK-F03: La RecetaProducto del producto NUNCA se modifica al producir.
          Los AjustePersonalizacion viven en el DetalleVenta y se aplican en memoria al producir.
BACK-F04: Los endpoints publicos del e-commerce (sin JWT) van en urls_publicas.py separado.
          NUNCA mezclar endpoints publicos con los endpoints autenticados del ERP.
BACK-F05: La disponibilidad e-commerce se calcula desde los INSUMOS (via receta),
          no desde el stock del producto final. Ver ROADMAP.md seccion E-commerce.
```

### Queries y performance
```
BACK-10: NUNCA queries N+1. Siempre select_related y prefetch_related.
BACK-11: Calculos de agregacion SIEMPRE en la DB (aggregate/annotate). NUNCA en Python.
BACK-12: Paginacion obligatoria en TODOS los listados.
BACK-13: Filtros con django-filter en cada listado.
```

### Seguridad
```
BACK-16: Toda vista DEBE tener permisos (IsAuthenticated minimo).
BACK-17: Endpoints publicos de e-commerce: AllowAny + rate limiting estricto.
BACK-18: NUNCA exponer datos de costos (precio_compra, margen) en endpoints publicos.
```

### Documentacion
```
BACK-20: Todo ViewSet debe tener @extend_schema(tags=["..."]) a nivel de clase.
BACK-21: Al terminar cambios en endpoints -> regenerar OpenAPI schema.
BACK-22: python manage.py spectacular --color --file ../Amatista-fe/openapi-schema.yaml
```

### Generales
```
BACK-23: Logs con logging de Python. NUNCA print().
BACK-24: Campos monetarios -> DecimalField(max_digits=12, decimal_places=2).
         Precio unitario -> DecimalField(max_digits=12, decimal_places=4).
         NUNCA FloatField para dinero.
BACK-25: Constantes en core/choices.py. NUNCA hardcodear valores de negocio en codigo.
BACK-26: Nomenclatura: espanol para modelos/campos de negocio, ingles para metodos tecnicos.
```

---

## 3. EXCEPCIONES CUSTOM (core/exceptions.py)

```python
ReglaDeNegocioError       # 400 — Validacion de logica generica
StockInsuficienteError    # 400 — Venta/produccion sin stock de insumos
InsumoSinRecetaError      # 400 — Producto con descuenta_insumos=True sin receta activa
NubefactError             # 502 — Fallo comunicacion Nubefact
ComprobanteRechazadoError # 400 — SUNAT rechazo el comprobante
VentaNoAnulableError      # 400 — Comprobante ya aceptado por SUNAT
LimiteCreditoExcedidoError # 400 — Cliente excedio limite de credito
PermisoInsuficienteError  # 403 — Sin permiso RBAC
```

---

## 4. ENDPOINTS CLAVE DE AMATISTA

### Inventario (floreria) — YA IMPLEMENTADOS
```
GET  /api/v1/inventario/camara/                              <- Estado insumos organicos FIFO
GET  /api/v1/inventario/lista-compras/                       <- Lista de que comprar al mayorista
POST /api/v1/inventario/lista-compras/generar-oc/            <- Pre-llena OC
CRUD /api/v1/inventario/recetas/                             <- Recetas de productos finales
POST /api/v1/inventario/detalle-ventas/{id}/completar/       <- Marca listo, descuenta insumos FIFO
CRUD /api/v1/inventario/reglas-descuento/                    <- Descuentos por cantidad
```

### Ventas (floreria) — YA IMPLEMENTADOS
```
CRUD /api/v1/ventas/campanas/                                <- Campanas de temporada
```

### E-commerce (publico, sin JWT) — PENDIENTES
```
GET  /api/publico/productos/             <- Catalogo sin auth (pendiente)
GET  /api/publico/productos/{slug}/      <- Detalle de producto (pendiente)
GET  /api/publico/categorias/            <- Categorias sin auth (pendiente)
GET  /api/publico/disponibilidad/{id}/   <- Disponibilidad (pendiente)
CRUD /api/publico/carrito/               <- Carrito web (pendiente)
POST /api/publico/checkout/              <- Confirmar pedido + pago (pendiente)
POST /api/publico/auth/registro/         <- Registro cliente (pendiente)
POST /api/publico/auth/login/            <- Login cliente (pendiente)
```

---

## 5. FLUJO CRITICO — completar_produccion_item()

```python
# YA EXISTE en apps/inventario/services.py:1353
def completar_produccion_item(*, detalle_venta_id, usuario=None):
    """
    Se llama al marcar "listo" en el Kanban.
    1. Toma RecetaProducto.default del producto
    2. Aplica AjustePersonalizacion del DetalleVenta encima de la receta
    3. Descuenta cada insumo via FIFO (registrar_salida con lotes ordenados por fecha_entrada)
    4. Registra DetalleVentaInsumo (inmutable — trazabilidad de que se uso)
    5. Si descuenta_insumos=False (default): marca listo sin descontar nada
    """
```

ESTADO: Backend implementado. La llamada desde el frontend esta SUSPENDIDA (comentada en Kanban FE).
INVARIANTE: La RecetaProducto NUNCA se modifica al producir. Los ajustes son efimeros.

### Modelo de negocio: Produccion bajo pedido

`crear_venta_pos()` NO descuenta stock (linea 523: "Stock no gestionado — negocio produce bajo pedido").
El descuento de insumos solo ocurre en `completar_produccion_item()` al marcar "listo" en Kanban.

---

## 6. CHECKLIST ANTES DE CADA CAMBIO

- [ ] La logica de negocio esta en services.py?
- [ ] Los views solo orquestan?
- [ ] Se usa @transaction.atomic en operaciones multi-tabla?
- [ ] Se usa select_for_update donde hay concurrencia (stock, correlativos)?
- [ ] Se usa select_related/prefetch_related en queries con relaciones?
- [ ] Hay @extend_schema(tags=[...]) en el ViewSet?
- [ ] Hay permisos en todos los endpoints?
- [ ] Se usa logging en vez de print?
- [ ] Campos monetarios son DecimalField?
- [ ] Hay paginacion en listados?
- [ ] Si cambie endpoints, regenere el OpenAPI schema?
- [ ] Si cambie modelos, cree la migracion Y la mostre al usuario antes de aplicar?
