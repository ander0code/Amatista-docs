# PLAN DE IMPLEMENTACION -- Requerimientos Sr. Tito (v4)

> **Fecha:** 2026-03-02 (actualizado 2026-03-02 v4 -- decisiones finales incorporadas)
> **Regla:** Cada cambio es aditivo. No se rompe nada existente. Migraciones con defaults seguros.
> **Estado:** Listo para comenzar implementacion. Preguntas pendientes resueltas.

---

## CAMBIOS RESPECTO A v3 (decisiones incorporadas)

| Decision | Cambio en el plan |
|----------|------------------|
| D1: Ambas formas de recepcion | Multi-lote soportado tanto en recepcion de OC como en entrada manual |
| D2: requiere_lote ya en True | No hay data migration para ese campo |
| D3: Nota libre para arreglista | + campo `notas_arreglista` en `DetalleVenta` (Fase 2) |
| D4: Multi-lote es frecuente | Prioridad alta -- implementar en Fase 1, no postergable |
| D5: Base con productos reales + flujo receta en formulario | Campo `descuenta_insumos` (default=False). Legacy sigue vendiendose. Nuevos con receta arrancan en True. Validacion en `crear_venta_pos()` solo si `descuenta_insumos=True` |
| D6: Precio personalizacion = recarga fija + costo estimado como referencia | + campo `recargo_personalizacion` en `DetalleVenta`. Funcion `calcular_costo_estimado_ajuste()` para referencia del vendedor |
| D7: Unificar Compras → Inventario | `registrar_recepcion()` llama a `registrar_entrada()`. Se hace en Fase 1 |

---

## FASE 1 -- FUNDACION: Tipo de Registro + Ciclo de Vida + Semaforo de Frescura + Multi-lote + Unificacion

**Objetivo:** Que el Sr. Tito vea el estado real de sus insumos (flores) en la camara, con semaforo por color y ordenados FIFO. Yolanda puede registrar multi-lote en cada recepcion (frecuente). El stock queda correctamente vinculado a lotes con fecha.

### 1.1 Choices nuevos en `core/choices.py`

```python
# ═══════════════════════════════════════════
# TIPO DE REGISTRO (que es este item)
# ═══════════════════════════════════════════
TIPO_REG_INSUMO_ORGANICO    = "insumo_organico"      # Rosa, girasol, follaje -- perecible
TIPO_REG_INSUMO_NO_ORGANICO = "insumo_no_organico"   # Cinta, base, adorno -- no perecible
TIPO_REG_PRODUCTO_FINAL     = "producto_final"        # Arreglo floral vendible

TIPO_REGISTRO_CHOICES = [
    (TIPO_REG_INSUMO_ORGANICO,    "Insumo organico (flor / perecible)"),
    (TIPO_REG_INSUMO_NO_ORGANICO, "Insumo no organico (cinta, base, etc.)"),
    (TIPO_REG_PRODUCTO_FINAL,     "Producto final (arreglo para venta)"),
]

# ═══════════════════════════════════════════
# NOTA: NO existe TIPO_VENTA_PRODUCTO_CHOICES.
# La personalizacion NO es un tipo de producto.
# ═══════════════════════════════════════════
# ESTADOS DE FRESCURA (insumos organicos -- por dias exactos)
# ═══════════════════════════════════════════
FRESCURA_OPTIMO     = "optimo"
FRESCURA_PRECAUCION = "precaucion"
FRESCURA_FUNEBRE    = "funebre"
FRESCURA_DESCARTE   = "descarte"

ESTADO_FRESCURA_CHOICES = [
    (FRESCURA_OPTIMO,     "Optimo (dias 1-3)"),
    (FRESCURA_PRECAUCION, "Precaucion (dia 4)"),
    (FRESCURA_FUNEBRE,    "Funebre (dias 5-7, solo funebres)"),
    (FRESCURA_DESCARTE,   "Descarte (dia 8+, botar)"),
]
```

### 1.2 Migraciones (Base de Datos)

**Tabla `productos` -- agregar 4 columnas (es_perecible y dias_vida_util ELIMINADOS):**

```sql
-- Migracion 1a: tipo de insumo vs producto final
ALTER TABLE productos ADD COLUMN tipo_registro VARCHAR(20) DEFAULT 'producto_final' NOT NULL;
-- Default 'producto_final' -- todos los registros existentes siguen funcionando igual
-- tipo_registro='insumo_organico' implica perecible directamente. No se necesita es_perecible.
-- Los umbrales del semaforo son FIJOS (1-3, 4, 5-7, 8+). No se necesita dias_vida_util.

-- Migracion 1b: migracion gradual de descuento de insumos
ALTER TABLE productos ADD COLUMN descuenta_insumos BOOLEAN DEFAULT FALSE NOT NULL;
-- False = producto legacy: se vende y produce igual que hoy (sin descuento de insumos)
-- True  = producto nuevo o activado: requiere receta activa; al producir descuenta stock via FIFO
-- El admin activa esto manualmente cuando le define la receta a un producto legacy

-- Migracion 1c: unidad de compra vs unidad de uso
ALTER TABLE productos ADD COLUMN unidad_compra VARCHAR(50) DEFAULT '' NOT NULL;
ALTER TABLE productos ADD COLUMN factor_conversion INTEGER DEFAULT 1 NOT NULL;
-- factor_conversion=1 por defecto (sin conversion -- stock sube 1 por 1)
```

**Tabla `lotes` -- agregar 2 columnas:**

```sql
-- Migracion 2: frescura del lote
ALTER TABLE lotes ADD COLUMN fecha_entrada DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE lotes ADD COLUMN estado_frescura VARCHAR(20) DEFAULT 'optimo' NOT NULL;
-- Todos los lotes existentes quedan como 'optimo' y fecha_entrada = hoy (default seguro)
```

### 1.3 Backend -- Cambios

**Archivos a MODIFICAR:**

| Archivo | Que se hace |
|---------|-------------|
| `core/choices.py` | Agregar `TIPO_REGISTRO_CHOICES`, `ESTADO_FRESCURA_CHOICES` (ver 1.1) |
| `apps/inventario/models.py` | Agregar 6 campos a `Producto`, 2 campos a `Lote`, property `dias_en_camara` en `Lote` |
| `apps/inventario/services.py` | Agregar `actualizar_estados_frescura()` y `obtener_estado_camara()` |
| `apps/inventario/tasks.py` | Agregar task `actualizar_frescura_diaria` (corre cada noche a las 00:00) |
| `apps/inventario/serializers.py` | Agregar campos nuevos a serializers existentes de `Producto` y `Lote` |
| `apps/inventario/views.py` | Agregar endpoint `EstadoCamaraView` (GET `/inventario/camara/`) |
| `apps/inventario/urls.py` | Registrar ruta `camara/` |
| `apps/compras/services.py` | **D7:** `registrar_recepcion()` llama a `registrar_entrada()` para crear lotes correctamente. Soporte de multi-lote por item |
| `apps/inventario/services.py` | Asegurar que `registrar_entrada()` setea `fecha_entrada` y `estado_frescura` al crear el lote |

**Logica de `actualizar_estados_frescura()` (dias exactos, no relativos):**

```python
def actualizar_estados_frescura():
    """
    Recorre lotes activos de insumos perecibles y actualiza estado_frescura
    segun dias exactos transcurridos desde fecha_entrada.

    Regla del negocio (fija):
      Dias 1-3 → optimo     (verde)
      Dia 4    → precaucion (amarillo)
      Dias 5-7 → funebre    (rojo -- solo usar para arreglos funebres)
      Dia 8+   → descarte   (negro -- botar)

    Los umbrales son FIJOS (no dependen de ningun campo configurable):
      Dias 1-3 → optimo, Dia 4 → precaucion, Dias 5-7 → funebre, Dia 8+ → descarte
    ELIMINADO: dias_vida_util (no necesario). ELIMINADO: es_perecible (usar tipo_registro directamente).
    """
    hoy = date.today()
    lotes = Lote.objects.filter(
        is_active=True,
        producto__tipo_registro=TIPO_REG_INSUMO_ORGANICO,
        cantidad_actual__gt=0,
    ).select_related("producto")

    for lote in lotes:
        dias = (hoy - lote.fecha_entrada).days

        if dias <= 3:
            nuevo_estado = FRESCURA_OPTIMO
        elif dias == 4:
            nuevo_estado = FRESCURA_PRECAUCION
        elif dias <= 7:
            nuevo_estado = FRESCURA_FUNEBRE
        else:
            nuevo_estado = FRESCURA_DESCARTE

        if lote.estado_frescura != nuevo_estado:
            lote.estado_frescura = nuevo_estado
            lote.save(update_fields=["estado_frescura", "updated_at"])
```

**Property `dias_en_camara` en `Lote`:**

```python
@property
def dias_en_camara(self) -> int:
    """Dias transcurridos desde que el lote entro a la camara."""
    return (date.today() - self.fecha_entrada).days
```

**Logica de `obtener_estado_camara(almacen_id=None)`:**

```python
def obtener_estado_camara(almacen_id=None):
    """
    Retorna todos los lotes de insumos perecibles ordenados FIFO
    (el mas viejo primero = lo que hay que usar antes).
    """
    qs = Lote.objects.filter(
        is_active=True,
        producto__tipo_registro=TIPO_REG_INSUMO_ORGANICO,
        cantidad_actual__gt=0,
    ).select_related("producto", "almacen")

    if almacen_id:
        qs = qs.filter(almacen_id=almacen_id)

    return qs.order_by("fecha_entrada")  # FIFO: mas viejo primero
```

**Unificacion `registrar_recepcion()` → `registrar_entrada()` (D7):**

```python
# En apps/compras/services.py -- registrar_recepcion()
# Por cada item en la recepcion:
#   Si el item tiene multiples lotes (multi-lote D4):
#     Por cada sub-lote: llamar registrar_entrada() con fecha_entrada especifica
#   Si el item es un solo lote:
#     Llamar registrar_entrada() con fecha_entrada = date.today()
#   El factor_conversion se aplica: cantidad_stock = cantidad_recibida * factor_conversion

# registrar_entrada() ya existe en apps/inventario/services.py
# Solo necesita asegurarse de:
#   1. Setear Lote.fecha_entrada = fecha_entrada (parametro nuevo)
#   2. Setear Lote.estado_frescura = 'optimo' al crear el lote
#   3. Vincular DetalleRecepcion.lote al lote creado

# Payload de la API de recepcion (multi-lote por item):
# {
#   "recepcion_id": "...",
#   "items": [
#     {
#       "detalle_oc_id": "...",
#       "producto_id": "...",
#       "lotes": [
#         { "cantidad": 6, "fecha_entrada": "2026-02-28" },  <- lote 1 (mas viejo)
#         { "cantidad": 6, "fecha_entrada": "2026-03-01" }   <- lote 2 (mas nuevo)
#       ]
#     }
#   ]
# }
```

### 1.4 Frontend -- Cambios

**Archivos a MODIFICAR:**

| Archivo | Que se cambia |
|---------|---------------|
| `ProductoForm.tsx` (530 lineas) | + select `tipo_registro` (3 opciones), + inputs `unidad_compra` + `factor_conversion` (visibles si tipo=insumo_organico o insumo_no_organico), + toggle `descuenta_insumos` (visible solo si tipo=producto_final, auto-activado al guardar con receta) |
| `ProductoFormModal.tsx` (466 lineas) | + select `tipo_registro` (version simplificada) |
| `ProductList.tsx` (439 lineas) | + filtro por `tipo_registro`, + badge "Organico" con color verde para insumos perecibles |
| `StockOverview.tsx` (371 lineas) | + columna "Frescura" en tabla de lotes con badge color (verde/amarillo/rojo/negro), ordenar FIFO (fecha_entrada ASC) |
| `DashboardInventario.tsx` (268 lineas) | Descomentar `RotacionABC` (ya existe, estaba comentado), + widget "Estado Camara" con contadores por estado |
| UI de recepcion de compras | + soporte multi-lote por item: al registrar recepcion, cada item puede dividirse en sub-lotes con fechas distintas (frecuente -- D4) |

**Archivos a CREAR:**

| Archivo | Que hace |
|---------|----------|
| `src/app/(admin)/(app)/(inventario)/camara/components/EstadoCamara.tsx` | Vista "Control de Camara": tabla de lotes de insumos organicos con semaforo (verde/amarillo/rojo/negro), ordenados FIFO (mas viejo arriba), contadores por estado en header, filtro por almacen |

**Ruta nueva en FE:** `/inventario/camara` -- "Control de Camara"

### 1.5 Tests

```python
# tests/test_frescura_services.py

def test_lote_optimo_con_1_dia():
    # fecha_entrada = hoy - 1 dia -> estado_frescura = 'optimo'

def test_lote_optimo_con_3_dias():
    # fecha_entrada = hoy - 3 dias -> estado_frescura = 'optimo'

def test_lote_precaucion_con_4_dias():
    # fecha_entrada = hoy - 4 dias -> estado_frescura = 'precaucion'

def test_lote_funebre_con_5_dias():
    # fecha_entrada = hoy - 5 dias -> estado_frescura = 'funebre'

def test_lote_funebre_con_7_dias():
    # fecha_entrada = hoy - 7 dias -> estado_frescura = 'funebre'

def test_lote_descarte_con_8_dias():
    # fecha_entrada = hoy - 8 dias -> estado_frescura = 'descarte'

def test_no_afecta_insumos_no_organicos():
    # Producto con tipo_registro='insumo_no_organico' -> no se actualiza estado_frescura

def test_no_afecta_productos_finales():
    # Producto con tipo_registro='producto_final' -> no se actualiza

def test_estado_camara_retorna_ordenado_fifo():
    # Crear 3 lotes con fechas distintas -> retorna ordenado por fecha_entrada ASC

def test_estado_camara_filtra_por_almacen():
    # Lotes de 2 almacenes -> con filtro solo retorna los del almacen pedido

# tests/test_recepcion_con_lotes.py

def test_registrar_recepcion_crea_lote_con_fecha_entrada():
    # registrar_recepcion() -> DetalleRecepcion.lote no es NULL
    # Lote.fecha_entrada = date.today()
    # Lote.estado_frescura = 'optimo'

def test_registrar_recepcion_multi_lote_mismo_producto():
    # item con 2 sub-lotes de fechas distintas -> crea 2 lotes en inventario
    # Stock total = suma de ambos sub-lotes

def test_registrar_recepcion_sin_oc_entrada_manual_tambien_crea_lote():
    # entrada manual (sin OC) -> mismo comportamiento, crea lote con fecha_entrada

def test_factor_conversion_multiplica_stock():
    # insumo con factor_conversion=100 (caja de 100 tallos)
    # recepcion de 1 unidad -> stock sube en 100
```

---

## FASE 2 -- BOM: Receta del Producto + Descuento de Insumos al Producir

**Objetivo:** Cada producto final tiene su receta de insumos. La receta se define directamente desde el formulario del producto (crear o editar). Un producto sin receta puede existir pero NO puede venderse. Al producir (marcar "listo" en Kanban), el sistema descuenta automaticamente los insumos del stock via FIFO.

### 2.1 Migraciones

**Tablas NUEVAS (no tocan nada existente):**

```sql
-- Migracion 3: receta_producto
CREATE TABLE receta_producto (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id UUID REFERENCES productos(id) ON DELETE RESTRICT,
    nombre VARCHAR(100) NOT NULL,          -- "Estandar", "Version grande", etc.
    es_default BOOLEAN DEFAULT TRUE,       -- La receta que se usa al armar por defecto
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_receta_producto_id ON receta_producto(producto_id);

-- Migracion 4: detalle_receta
CREATE TABLE detalle_receta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receta_id UUID REFERENCES receta_producto(id) ON DELETE CASCADE,
    insumo_id UUID REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad_requerida DECIMAL(12,2) NOT NULL, -- Por 1 unidad de producto final
    es_sustituible BOOLEAN DEFAULT FALSE,       -- Si se puede cambiar al personalizar
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_detalle_receta_receta ON detalle_receta(receta_id);

-- Migracion 5: ajuste_personalizacion
-- Variacion de receta para un pedido especifico. NO toca la receta default del producto.
-- Ejemplo: Ramo Primavera tiene 5 rosas rojas. Cliente quiere 3 rojas + 2 blancas.
-- -> 2 filas aqui. La receta default del producto NO cambia.
CREATE TABLE ajuste_personalizacion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    detalle_venta_id UUID REFERENCES detalle_ventas(id) ON DELETE CASCADE,
    insumo_id UUID REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad_ajuste DECIMAL(12,2) NOT NULL, -- Cantidad a usar en este pedido
    es_nuevo BOOLEAN DEFAULT FALSE,          -- True = insumo que no estaba en la receta default
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ajuste_detalle_venta ON ajuste_personalizacion(detalle_venta_id);

-- Migracion 6: detalle_venta_insumo (trazabilidad inmutable al producir)
-- Se genera al marcar 'listo'. Refleja receta default + ajustes aplicados.
CREATE TABLE detalle_venta_insumo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    detalle_venta_id UUID REFERENCES detalle_ventas(id) ON DELETE CASCADE,
    insumo_id UUID REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad DECIMAL(12,2) NOT NULL,
    lote_id UUID REFERENCES lotes(id) ON DELETE SET NULL,  -- De que lote se tomo (FIFO)
    created_at TIMESTAMPTZ DEFAULT NOW()
    -- Sin updated_at -- es inmutable (registro de lo que ocurrio)
);
CREATE INDEX idx_dvi_detalle_venta ON detalle_venta_insumo(detalle_venta_id);
```

**Tabla `detalle_ventas` -- agregar 2 columnas:**

```sql
-- Migracion 7: nota y recargo en DetalleVenta
ALTER TABLE detalle_ventas ADD COLUMN notas_arreglista TEXT DEFAULT '' NOT NULL;
-- Texto libre para instrucciones especificas al arreglista (D3)
-- Ejemplo: "usar moño azul marino exactamente"

ALTER TABLE detalle_ventas ADD COLUMN recargo_personalizacion DECIMAL(12,4) DEFAULT 0 NOT NULL;
-- Cargo extra cuando hay personalizacion (D6)
-- Es un monto fijo que el vendedor define, NO el costo exacto de los insumos
-- Total DetalleVenta = (precio_unitario * cantidad) + recargo_personalizacion
```

### 2.2 Backend -- Cambios

**Archivos a MODIFICAR (agregar modelos y logica):**

| Archivo | Que se agrega |
|---------|---------------|
| `apps/inventario/models.py` | Modelos `RecetaProducto` y `DetalleReceta` |
| `apps/ventas/models.py` | Modelos `AjustePersonalizacion` y `DetalleVentaInsumo`, + campos `notas_arreglista` y `recargo_personalizacion` en `DetalleVenta` |
| `apps/inventario/services.py` | Funciones: `crear_receta()`, `obtener_receta_default()`, `calcular_costo_receta()`, `verificar_disponibilidad_insumos()`, `calcular_costo_estimado_ajuste()` |
| `apps/inventario/serializers.py` | `RecetaProductoSerializer`, `DetalleRecetaSerializer`, `RecetaCreateSerializer` |
| `apps/inventario/views.py` | `RecetaViewSet` (CRUD completo) |
| `apps/inventario/urls.py` | Registrar `recetas/` en el router |
| `apps/ventas/services.py` | Funcion `completar_produccion_item()` + **validacion en `crear_venta_pos()`** (bloquear producto_final sin receta) |

**Validacion nueva en `crear_venta_pos()` (D5 -- solo aplica a productos con descuenta_insumos=True):**

```python
# En apps/ventas/services.py -- crear_venta_pos()
# Por cada item del pedido:
#   if item.producto.descuenta_insumos:
#       receta = obtener_receta_default(item.producto)
#       if not receta:
#           raise ValidationError(
#               f"'{item.producto.nombre}' tiene descuento de insumos activado "
#               "pero no tiene receta definida. Define la receta desde la ficha "
#               "del producto o desactiva 'descuenta_insumos'."
#           )
# Si descuenta_insumos=False (legacy): pasa sin validacion. Comportamiento actual sin cambios.
```

**Logica critica -- `completar_produccion_item()`:**

```python
def completar_produccion_item(*, detalle_venta_id, usuario=None):
    """
    Se llama cuando el arreglista marca un item como 'listo' en el Kanban.

    Flujo:
    1. Toma la receta DEFAULT del producto.
    2. Si el DetalleVenta tiene AjustePersonalizacion, los aplica ENCIMA de la receta:
       - Si el ajuste modifica un insumo existente: usa la cantidad del ajuste.
       - Si el ajuste agrega un insumo nuevo: lo incluye.
    3. Descuenta del stock via FIFO cada insumo resultante.
    4. Registra trazabilidad en DetalleVentaInsumo (inmutable).
    5. Si `descuenta_insumos=False` (legacy): marca como listo sin descontar. Sin cambios para productos legacy.

    INVARIANTE: La RecetaProducto del producto NUNCA se modifica. Los ajustes
    viven solo en el DetalleVenta y se aplican en memoria en el momento de producir.
    """
    detalle = DetalleVenta.objects.get(id=detalle_venta_id)
    receta = None
    if detalle.producto.descuenta_insumos:
        receta = obtener_receta_default(detalle.producto)

    if receta:
        almacen = obtener_almacen_principal()

        # Construir mapa de insumos a descontar: receta default
        insumos_a_descontar = {
            item.insumo_id: item.cantidad_requerida * detalle.cantidad
            for item in receta.detalles.filter(insumo__is_active=True)
        }

        # Aplicar ajustes de personalizacion si existen (sin tocar la receta)
        ajustes = AjustePersonalizacion.objects.filter(detalle_venta=detalle)
        for ajuste in ajustes:
            insumos_a_descontar[ajuste.insumo_id] = ajuste.cantidad_ajuste * detalle.cantidad

        # Descontar cada insumo resultante via FIFO
        for insumo_id, cantidad_total in insumos_a_descontar.items():
            if cantidad_total <= 0:
                continue
            movimiento = registrar_salida(
                producto_id=insumo_id,
                almacen_id=almacen.id,
                cantidad=cantidad_total,
                referencia_tipo="venta",
                referencia_id=detalle.venta_id,
                motivo=f"Produccion item #{detalle_venta_id}",
                usuario=usuario,
            )
            # Registro inmutable de trazabilidad
            DetalleVentaInsumo.objects.create(
                detalle_venta=detalle,
                insumo_id=insumo_id,
                cantidad=cantidad_total,
                lote=movimiento.lote if movimiento else None,
            )

    detalle.estado_produccion = PRODUCCION_LISTO
    detalle.produccion_completada_en = now()
    detalle.save(update_fields=["estado_produccion", "produccion_completada_en"])
```

**Funcion `calcular_costo_estimado_ajuste()` (D6 -- referencia para el vendedor):**

```python
def calcular_costo_estimado_ajuste(receta, ajustes):
    """
    Calcula el costo estimado de los cambios en la personalizacion,
    en base al precio_compra de los insumos involucrados.

    Este valor es SOLO referencia para el vendedor -- no es el recargo
    que se cobrara. El vendedor decide cuanto cobrar (recargo_personalizacion).

    Retorna: { "costo_estimado": Decimal, "detalle": [...] }
    """
    # Compara la receta default con los ajustes
    # Para insumos que se agregan o aumentan: calcula el costo extra
    # Para insumos que se quitan o reducen: calcula el ahorro
    # Retorna el costo neto estimado
```

### 2.3 Frontend -- Cambios

**Archivos a MODIFICAR:**

| Archivo | Que se cambia |
|---------|---------------|
| `ProductoForm.tsx` | + seccion "Receta / Composicion" (SOLO visible si tipo_registro=producto_final): componente `RecetaEditor` embebido. Si el producto ya tiene receta, la carga. Guardado opcional al crear (no bloquea). |
| `pedido-pos/index.tsx` | + boton "Personalizar" por item. Al activar: panel lateral con receta default del producto, campos para ajustar cantidades o agregar insumos, campo "costo estimado del ajuste" (calculado por backend, solo referencia), campo "recargo adicional" (el vendedor ingresa cuanto cobra), campo "nota para el arreglista" (texto libre). Se guarda como `AjustePersonalizacion` + `recargo_personalizacion` + `notas_arreglista`. |
| Kanban Produccion (distribucion FE) | Al hacer click en "Listo", llamar `POST /ventas/detalle-ventas/{id}/completar/`. El backend aplica receta default + ajustes automaticamente. |

**Archivos a CREAR:**

| Archivo | Que hace |
|---------|----------|
| `src/app/(admin)/(app)/(inventario)/product-create/components/RecetaEditor.tsx` | Editor de receta DEFAULT del producto: tabla con buscador de insumos (filtrado por tipo insumo), campo cantidad decimal, boton agregar/quitar fila. Si hay receta existente la carga. Guardado independiente del resto del formulario del producto. Esta receta es permanente -- no se edita por pedido. |

### 2.4 Tests

```python
# tests/test_receta_services.py

def test_crear_receta_con_insumos():
def test_calcular_costo_receta_suma_insumos():
def test_obtener_receta_default():

def test_completar_produccion_descuenta_receta_default():
def test_completar_produccion_sin_receta_no_descuenta():  # comportamiento legacy OK
def test_completar_produccion_crea_detalle_venta_insumo():

def test_completar_produccion_con_ajustes_aplica_variacion():
    # receta default: 5 rosas rojas
    # ajuste: { rosa_roja: 3, rosa_blanca: 2 }
    # debe descontar: 3 rosas rojas + 2 rosas blancas (NO 5 rojas)

def test_ajuste_no_modifica_receta_default_del_producto():
    # despues de completar_produccion con ajustes,
    # receta.detalles sigue teniendo 5 rosas rojas

def test_verificar_disponibilidad_insumos_suficientes():
def test_verificar_disponibilidad_insumos_insuficientes():

def test_notas_arreglista_se_guardan_en_detalle_venta():
def test_recargo_personalizacion_suma_al_total():
def test_costo_estimado_ajuste_calcula_precio_compra():

# tests/test_venta_validaciones.py

def test_crear_venta_pos_bloquea_producto_final_sin_receta():
    # producto_final sin RecetaProducto -> ValidationError con mensaje claro

def test_crear_venta_pos_permite_producto_final_con_receta():
    # producto_final con RecetaProducto activa -> OK

def test_crear_venta_pos_permite_insumo_sin_receta():
    # insumo (tipo_registro != producto_final) -> no necesita receta, OK
```

---

## FASE 3 -- ALERTAS + COMPRAS INTELIGENTES

**Objetivo:** Yolanda puede ver exactamente que comprar antes de ir al mayorista, con OC pre-llenada.

### 3.1 Backend -- Cambios

**No se necesitan nuevas migraciones.** Todo es logica nueva sobre datos existentes.

**Archivos a MODIFICAR:**

| Archivo | Que se agrega |
|---------|---------------|
| `apps/inventario/services.py` | Funcion `generar_lista_compras()` que combina: insumos bajo stock minimo + insumos en estado funebre/descarte + rotacion ABC + cantidades sugeridas |
| `apps/inventario/serializers.py` | `ListaComprasItemSerializer` con campos: insumo, razon (stock_bajo/mermado/alta_rotacion), stock_actual, stock_minimo, cantidad_sugerida, estado_frescura, fecha_entrada_ultimo_lote |
| `apps/inventario/views.py` | `ListaComprasView` (GET `/inventario/lista-compras/`) con parametros de filtro |
| `apps/inventario/tasks.py` | Task `alerta_compras_nocturna` (corre a las 20:00 antes que Yolanda llame al mayorista) |

**Sub-filtros disponibles en `ListaComprasView`:**

| Parametro URL | Descripcion |
|---------------|-------------|
| `?tipo=perecibles_fuera_uso` | Solo insumos organicos en estado funebre o descarte |
| `?tipo=stock_bajo` | Solo insumos bajo stock minimo |
| `?tipo=alta_rotacion` | Solo insumos con clasificacion A (mas vendidos) |
| `?tipo=baja_rotacion` | Solo insumos con clasificacion C (estancados) |
| `?tipo=todos` (default) | Todos los insumos con al menos una razon de compra |

**Generacion de OC pre-llenada:**
El endpoint `POST /inventario/lista-compras/generar-oc/` recibe los items seleccionados y crea un borrador de `OrdenCompra` en `apps/compras/` con esos insumos y cantidades sugeridas. El modulo de OC ya existe -- solo se pre-llena.

### 3.2 Frontend -- Cambios

**Archivos a MODIFICAR:**

| Archivo | Que se cambia |
|---------|---------------|
| `DashboardInventario.tsx` | Descomentar `RotacionABC`, + widget "Estado Camara" con resumen (N optimo / N precaucion / N funebre / N descarte), link a `/inventario/camara` |

**Archivos a CREAR:**

| Archivo | Que hace |
|---------|----------|
| `src/app/(admin)/(app)/(inventario)/compras-inteligentes/components/ListaCompras.tsx` | Vista unificada con: tabs de sub-filtro, tabla de insumos, checkbox por fila para seleccionar, boton "Generar OC" que pre-llena el modulo de compras existente |

**Ruta nueva en FE:** `/inventario/compras-inteligentes`

**Nota de integracion:** El boton "Generar OC" NO crea una pagina nueva -- redirige al modulo de compras existente (`/compras/ordenes/nueva`) con los items como parametros. No se duplica logica.

### 3.3 Tests

```python
def test_generar_lista_compras_incluye_stock_bajo():
def test_generar_lista_compras_incluye_mermados():
def test_generar_lista_compras_filtra_solo_insumos():
def test_generar_lista_compras_no_incluye_productos_finales():
def test_filtro_perecibles_fuera_uso():
def test_generar_oc_prellenada_desde_lista():
```

---

## FASE 4 -- PRECIOS DIFERENCIADOS

**Objetivo:** Precio corporativo seteado por producto, descuentos por cantidad automaticos, costo estimado de ajuste como referencia para el vendedor.

### 4.1 Migraciones

```sql
-- Migracion 8: precio_corporativo en productos (nullable -- NULL = usar precio_venta normal)
ALTER TABLE productos ADD COLUMN precio_corporativo DECIMAL(12,4) NULL;

-- Migracion 9: regla_descuento (tabla nueva)
CREATE TABLE regla_descuento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    cantidad_minima INTEGER NOT NULL,          -- Desde X unidades
    descuento_porcentaje DECIMAL(5,2) NOT NULL,
    aplica_a_segmento VARCHAR(20) NULL,        -- NULL=todos, 'corporativo', 'natural'
    aplica_a_producto_id UUID REFERENCES productos(id) ON DELETE CASCADE NULL,
    -- NULL = aplica a todos los productos finales
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.2 Backend

**Archivos a MODIFICAR:**

| Archivo | Que se agrega |
|---------|---------------|
| `apps/inventario/models.py` | + campo `precio_corporativo` a `Producto`. + modelo `ReglaDescuento`. |
| `apps/inventario/serializers.py` | + campo `precio_corporativo` en serializers de `Producto`. + `ReglaDescuentoSerializer`. |
| `apps/inventario/views.py` | + `ReglaDescuentoViewSet` (CRUD). |
| `apps/ventas/services.py` | + funcion `resolver_precio(producto, cliente, cantidad)` |

**Logica de `resolver_precio()` (D6 incorporado):**

```python
def resolver_precio(producto, cliente=None, cantidad=1):
    """
    Retorna el precio correcto segun el cliente y la cantidad.

    Prioridad:
    1. Si cliente es corporativo Y producto tiene precio_corporativo: usar precio_corporativo
    2. Si hay regla de descuento por cantidad que aplica: precio_venta - descuento%
    3. En cualquier otro caso: precio_venta normal

    NOTA: el recargo_personalizacion es un campo separado en DetalleVenta
    que el vendedor define manualmente. No lo calcula esta funcion.
    Esta funcion solo resuelve el precio_unitario base.
    """
    precio_base = producto.precio_venta

    # 1. Precio corporativo
    if (cliente
        and cliente.segmento == SEG_CORPORATIVO
        and cliente.tipo_documento == TIPO_DOC_RUC
        and producto.precio_corporativo is not None):
        precio_base = producto.precio_corporativo

    # 2. Descuento por cantidad
    regla = ReglaDescuento.objects.filter(
        is_active=True,
        cantidad_minima__lte=cantidad,
    ).filter(
        Q(aplica_a_producto=producto) | Q(aplica_a_producto__isnull=True)
    ).filter(
        Q(aplica_a_segmento=cliente.segmento if cliente else None)
        | Q(aplica_a_segmento__isnull=True)
    ).order_by("-cantidad_minima").first()

    if regla:
        descuento = precio_base * (regla.descuento_porcentaje / 100)
        return precio_base - descuento

    return precio_base
```

### 4.3 Frontend

**Archivos a MODIFICAR:**

| Archivo | Que se cambia |
|---------|---------------|
| `ProductoForm.tsx` | + input `precio_corporativo` (opcional, visible solo si tipo_registro=producto_final) |
| `pedido-pos/index.tsx` | Al seleccionar cliente corporativo, aplicar `precio_corporativo` automaticamente. Badge "Precio Corp." visible en el item. |
| `CotizacionModal.tsx` | Al seleccionar cliente corporativo, cargar precios corporativos. |

### 4.4 Tests

```python
# tests/test_precios_services.py

def test_resolver_precio_cliente_natural():
def test_resolver_precio_cliente_corporativo_con_precio_seteado():
def test_resolver_precio_corporativo_sin_precio_seteado_usa_normal():
def test_descuento_por_cantidad_aplica():
def test_descuento_por_cantidad_no_aplica_bajo_minimo():
def test_costo_estimado_ajuste_referencia_vendedor():
```

---

## FASE 5 -- COTIZACIONES MEJORADAS + FLUJO CORPORATIVO

**Objetivo:** PDF profesional, envio por email, check de gerencia.

### 5.1 Migraciones

```sql
-- Migracion 10: aprobacion de cotizacion
ALTER TABLE cotizaciones ADD COLUMN aprobada_por_id UUID REFERENCES perfil_usuarios(id) ON DELETE SET NULL NULL;
ALTER TABLE cotizaciones ADD COLUMN aprobada_en TIMESTAMPTZ NULL;
-- NULL para todas las cotizaciones existentes -- no afecta nada
```

### 5.2 Backend

**No se necesitan modelos nuevos.** Se reutiliza infraestructura existente.

| Archivo | Que se agrega |
|---------|---------------|
| `apps/ventas/services.py` | + `generar_cotizacion_pdf()` (clonar y adaptar patron de `generar_resumen_venta_pdf()`) |
| `apps/ventas/services.py` | + `enviar_cotizacion_email(cotizacion_id, email_destino)` |
| `apps/ventas/services.py` | + `aprobar_cotizacion(cotizacion_id, usuario)` (setea aprobada_por y aprobada_en) |
| `apps/ventas/views.py` | + actions en `CotizacionViewSet`: `descargar_pdf` (GET), `enviar_email` (POST), `aprobar` (POST, solo gerente/admin) |
| `apps/ventas/models.py` | + campos `aprobada_por` y `aprobada_en` en `Cotizacion` |

### 5.3 Frontend

| Archivo | Que se cambia |
|---------|---------------|
| `cotizacion-detalle/index.tsx` | + boton "Descargar PDF", + boton "Enviar por Email" (modal con email pre-llenado), + boton "Aprobar" (solo gerente/admin) |
| `cotizaciones/index.tsx` | + columna "Aprobada" con icono check/pending |

---

## FASE 6 -- CAMPANAS DE TEMPORADA

**Objetivo:** Descuentos automaticos por campana en POS y cotizaciones.

### 6.1 Migraciones

```sql
-- Migracion 11: campana
CREATE TABLE campana (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,              -- "Dia de la Madre 2026"
    descripcion TEXT DEFAULT '',
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    descuento_porcentaje DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migracion 12: campana_producto (M2M -- que productos participan)
CREATE TABLE campana_producto (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campana_id UUID REFERENCES campana(id) ON DELETE CASCADE,
    producto_id UUID REFERENCES productos(id) ON DELETE CASCADE,
    UNIQUE(campana_id, producto_id)
);
```

### 6.2 Backend

| Archivo | Que se agrega |
|---------|---------------|
| `apps/ventas/models.py` | Modelos `Campana` y `CampanaProducto` (M2M) |
| `apps/ventas/services.py` | + `obtener_campanas_activas()`, + `aplicar_descuento_campana(producto)` |
| `apps/ventas/services.py` | Integrar `aplicar_descuento_campana()` en `crear_venta_pos()` y `crear_cotizacion()` |
| `apps/ventas/views.py` | + `CampanaViewSet` (CRUD) |
| `apps/ventas/serializers.py` | + `CampanaSerializer`, `CampanaCreateSerializer` |
| `apps/ventas/urls.py` | Registrar `campanas/` |

### 6.3 Frontend

| Archivo | Que se cambia |
|---------|---------------|
| `pedido-pos/index.tsx` | + badge "Campana -X%" en productos que estan en campana activa hoy |
| `ProductList.tsx` | + badge "En campana" en productos participantes |

**Archivos a CREAR:**

| Archivo | Que hace |
|---------|----------|
| `src/app/(admin)/(app)/(ventas)/campanas/components/CampanasList.tsx` | CRUD campanas: nombre, descripcion, fechas inicio/fin, descuento %, multi-select de productos finales que participan, toggle activa/inactiva |

**Ruta nueva en FE:** `/ventas/campanas`

---

## RESUMEN DE MIGRACIONES (v4 -- final)

| # | Migracion | Fase | Tabla | Tipo | Riesgo |
|---|-----------|------|-------|------|--------|
| 1a | `tipo_registro` en productos | F1 | existente | ADD COLUMN | Nulo (default 'producto_final') |
| 1b | `descuenta_insumos` en productos | F1 | existente | ADD COLUMN | Nulo (default False) |
| 1c | `unidad_compra` + `factor_conversion` en productos | F1 | existente | ADD COLUMN | Nulo (defaults ''/1) |
| 2 | `fecha_entrada` + `estado_frescura` en lotes | F1 | existente | ADD COLUMN | Nulo (defaults hoy/'optimo') |
| 3 | Tabla `receta_producto` | F2 | nueva | CREATE TABLE | Nulo |
| 4 | Tabla `detalle_receta` | F2 | nueva | CREATE TABLE | Nulo |
| 5 | Tabla `ajuste_personalizacion` | F2 | nueva | CREATE TABLE | Nulo |
| 6 | Tabla `detalle_venta_insumo` | F2 | nueva | CREATE TABLE | Nulo |
| 7 | `notas_arreglista` + `recargo_personalizacion` en detalle_ventas | F2 | existente | ADD COLUMN | Nulo (defaults ''/0) |
| 8 | `precio_corporativo` en productos | F4 | existente | ADD COLUMN | Nulo (nullable) |
| 9 | Tabla `regla_descuento` | F4 | nueva | CREATE TABLE | Nulo |
| 10 | `aprobada_por` + `aprobada_en` en cotizaciones | F5 | existente | ADD COLUMN | Nulo (nullable) |
| 11 | Tabla `campana` | F6 | nueva | CREATE TABLE | Nulo |
| 12 | Tabla `campana_producto` | F6 | nueva | CREATE TABLE | Nulo |

**Ninguna migracion modifica datos existentes ni elimina columnas.**
**Los productos reales existentes en la DB no se ven afectados.**

---

## RESUMEN DE ARCHIVOS

### Archivos NUEVOS a crear

| Archivo | Fase | Tipo |
|---------|------|------|
| `tests/test_frescura_services.py` | F1 | Test BE |
| `tests/test_recepcion_con_lotes.py` | F1 | Test BE |
| `tests/test_receta_services.py` | F2 | Test BE |
| `tests/test_venta_validaciones.py` | F2 | Test BE |
| `tests/test_precios_services.py` | F4 | Test BE |
| `tests/test_campana_services.py` | F6 | Test BE |
| FE: `EstadoCamara.tsx` | F1 | Vista FE |
| FE: `RecetaEditor.tsx` | F2 | Componente FE |
| FE: `ListaCompras.tsx` | F3 | Vista FE |
| FE: `CampanasList.tsx` | F6 | Vista FE |

**Total: 6 tests BE nuevos + 4 archivos FE nuevos = 10 archivos nuevos**

### Archivos EXISTENTES a modificar

| Archivo | Fases que lo tocan |
|---------|-------------------|
| `core/choices.py` | F1 |
| `apps/inventario/models.py` | F1, F2, F4 |
| `apps/inventario/services.py` | F1, F2, F3 |
| `apps/inventario/serializers.py` | F1, F2, F3 |
| `apps/inventario/views.py` | F1, F2, F3, F4 |
| `apps/inventario/urls.py` | F1, F2 |
| `apps/inventario/tasks.py` | F1, F3 |
| `apps/compras/services.py` | F1 (unificacion D7 + multi-lote D4) |
| `apps/ventas/models.py` | F2, F5, F6 |
| `apps/ventas/services.py` | F2, F4, F5, F6 |
| `apps/ventas/views.py` | F5, F6 |
| `apps/ventas/serializers.py` | F6 |
| `apps/ventas/urls.py` | F6 |
| FE: `ProductoForm.tsx` | F1, F2, F4 |
| FE: `ProductoFormModal.tsx` | F1 |
| FE: `ProductList.tsx` | F1, F6 |
| FE: `StockOverview.tsx` | F1 |
| FE: `DashboardInventario.tsx` | F1, F3 |
| FE: `pedido-pos/index.tsx` | F2, F4, F6 |
| FE: UI de recepcion de compras | F1 (multi-lote) |
| FE: `CotizacionModal.tsx` | F4 |
| FE: `cotizacion-detalle/index.tsx` | F5 |
| FE: `cotizaciones/index.tsx` | F5 |

**Total: 13 archivos BE + 10 archivos FE = 23 archivos a modificar**
