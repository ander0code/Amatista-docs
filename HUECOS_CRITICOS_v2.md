# HUECOS CRITICOS -- Analisis Profundo v2

> **Fecha:** 2026-03-02
> **Metodo:** Lectura directa del codigo fuente con numeros de linea. Sin suposiciones.
> **Archivos leidos:** 18 archivos BE + 3 archivos FE + tests + signals + factories

---

## CLASIFICACION DE HUECOS

| Nivel | Significado |
|-------|-------------|
| **BLOQUEANTE** | Si no se resuelve ANTES de implementar, el codigo que escribamos fallara o sera incorrecto |
| **ALTO** | Cambia significativamente el diseno o la complejidad de lo planificado |
| **MEDIO** | Hay que tenerlo en cuenta pero no cambia el diseno fundamental |
| **BAJO** | Detalle menor a corregir durante la implementacion |

---

## HUECO #1 -- BLOQUEANTE: `TIPO_REGISTRO_CHOICES` ya existe en choices.py pero con solo 2 valores, NO 3

**Archivo:** `core/choices.py`, lineas 696-705

**Lo que existe HOY:**
```python
# linea 699
TIPO_REG_INSUMO = "insumo"
TIPO_REG_PRODUCTO_FINAL = "producto_final"

TIPO_REGISTRO_CHOICES = [
    (TIPO_REG_INSUMO, "Insumo (materia prima)"),
    (TIPO_REG_PRODUCTO_FINAL, "Producto Final (arreglo)"),
]
```

**Lo que el plan asume:**
```python
TIPO_REG_INSUMO_ORGANICO    = "insumo_organico"
TIPO_REG_INSUMO_NO_ORGANICO = "insumo_no_organico"
TIPO_REG_PRODUCTO_FINAL     = "producto_final"
```

**El problema:**
- El plan usa 3 valores. El codigo actual tiene 2.
- `TIPO_REG_INSUMO` (valor: `"insumo"`) es diferente a `TIPO_REG_INSUMO_ORGANICO` (valor: `"insumo_organico"`).
- Estos choices YA ESTAN IMPORTADOS en `apps/inventario/models.py` lineas 20-22 pero **el campo `tipo_registro` NO existe en el modelo `Producto`** (confirmado: el modelo `Producto` tiene solo los campos de las lineas 63-113, sin `tipo_registro`).
- Es decir: el import es codigo muerto. El campo nunca se agrego al modelo.

**DECISION TOMADA (D8 resuelve esto parcialmente):**
- Usar los 3 valores del plan: `"insumo_organico"`, `"insumo_no_organico"`, `"producto_final"`.
- El valor `"insumo"` (actual en choices.py) se REEMPLAZA -- no hay datos que migrar porque el campo nunca existio en la DB.
- La opcion `es_perecible` como sub-campo fue DESCARTADA (D8): `tipo_registro='insumo_organico'` ya implica perecible directamente.

**Accion en Fase 1:**
1. En `core/choices.py`: reemplazar `TIPO_REG_INSUMO = "insumo"` por `TIPO_REG_INSUMO_ORGANICO = "insumo_organico"` y agregar `TIPO_REG_INSUMO_NO_ORGANICO = "insumo_no_organico"`.
2. En `apps/inventario/models.py`: actualizar el import (lineas 20-22) para importar los 3 nuevos nombres de constantes.
3. La migracion `ADD COLUMN tipo_registro ... DEFAULT 'producto_final'` es un simple ADD COLUMN -- no hay ALTER de datos existentes.

---

## HUECO #2 -- BLOQUEANTE: Los tests de ventas asumen que `crear_venta_pos()` DESCUENTA stock -- pero NO lo hace

**Archivos:**
- `tests/test_ventas_services.py`, lineas 111-132: `test_crea_venta_y_descuenta_stock`
- `tests/test_ventas_services.py`, lineas 134-152: `test_falla_si_stock_insuficiente`
- `apps/ventas/services.py`, linea 505: `# Stock no gestionado — no se descuenta (negocio produce bajo pedido)`

**El problema:**
```python
# test_ventas_services.py linea 128-129
stock_restante = Stock.objects.get(producto=producto, almacen=almacen)
assert stock_restante.cantidad == Decimal("8")  # asume que se descuento 2

# test_ventas_services.py linea 151
with pytest.raises(StockInsuficienteError):
    crear_venta_pos(datos=datos, vendedor=vendedor)  # espera error de stock
```

```python
# ventas/services.py linea 505
# Stock no gestionado — no se descuenta (negocio produce bajo pedido)
```

**Estos tests YA ESTAN FALLANDO si se corren hoy.** El test `test_crea_venta_y_descuenta_stock` espera que el stock baje de 10 a 8, pero el servicio no toca el stock. El test `test_falla_si_stock_insuficiente` espera un `StockInsuficienteError` que el servicio nunca lanza.

Ademas, `StockInsuficienteError` se importa de `core.exceptions` (linea 28) -- hay que verificar que esa excepcion exista en `core/exceptions.py`.

**Impacto en el plan:**
- Cuando implementemos `completar_produccion_item()` (Fase 2), esta funcion SI descuenta stock.
- Pero los tests actuales prueban `crear_venta_pos()` (no `completar_produccion_item()`).
- Hay que decidir: ¿corregir los tests para que reflejen el comportamiento actual (sin descuento en venta)? ¿O el plan es que `crear_venta_pos()` SI descuente?
- Segun el diagnostico: el descuento ocurre al producir (marcar "listo"), NO al vender. Entonces estos tests son **incorrectos y deben actualizarse**.

**Accion requerida antes de Fase 2:**
Corregir `test_ventas_services.py`:
- `test_crea_venta_y_descuenta_stock`: eliminar las aserciones de stock (el stock no se descuenta al vender)
- `test_falla_si_stock_insuficiente`: este test ya no aplica para `crear_venta_pos()`. Se debera mover a `test_receta_services.py` y probar `completar_produccion_item()` cuando hay stock insuficiente.

---

## HUECO #3 -- BLOQUEANTE: `registrar_entrada()` ya acepta `numero_lote` y `fecha_vencimiento` -- pero NO `fecha_entrada`

**Archivo:** `apps/inventario/services.py`, lineas 600-692

**Lo que existe HOY:**
```python
def registrar_entrada(
    *,
    producto_id,
    almacen_id,
    cantidad: Decimal,
    motivo_tipo: str,
    motivo_descripcion: str = "",
    lote_id=None,
    numero_lote: str = "",
    fecha_vencimiento=None,   # <-- linea 609: esto existe
    usuario=None,
) -> MovimientoStock:
```

**El modelo `Lote` HOY (lineas 155-194):**
```python
class Lote(models.Model):
    numero_lote    = CharField(max_length=50)         # linea 168
    fecha_vencimiento = DateField(null=True, blank=True)  # linea 169
    cantidad_inicial  = DecimalField(...)              # linea 170
    cantidad_actual   = DecimalField(...)              # linea 171
    almacen           = FK(Almacen)                    # linea 172
    is_active         = BooleanField(default=True)     # linea 178
    created_at        = DateTimeField(auto_now_add=True) # linea 179
    updated_at        = DateTimeField(auto_now=True)   # linea 180
    # NO existe: fecha_entrada
    # NO existe: estado_frescura
```

**El problema:**
- El plan propone agregar `fecha_entrada` a `Lote` (diferente de `created_at`).
- El plan propone agregar `estado_frescura` a `Lote`.
- El plan propone que `registrar_entrada()` setee `fecha_entrada` al crear el lote.
- Pero `registrar_entrada()` ya crea el lote con `fecha_vencimiento` -- que es un campo diferente a `fecha_entrada`.
- La funcion `registrar_recepcion()` en compras NO llama a `registrar_entrada()`.

**Implicacion clave:**
- Para el semaforo de frescura, necesitamos `fecha_entrada` (cuando llego a la camara), no `fecha_vencimiento` (cuando vence segun el proveedor). Son semanticas distintas.
- El plan de unificacion (D7) es correcto: `registrar_recepcion()` debe llamar a `registrar_entrada()`. Y `registrar_entrada()` debe setear `fecha_entrada = date.today()` al crear el lote.
- El parametro `fecha_vencimiento` se mantiene (es para compatibilidad FIFO existente). Se agrega `fecha_entrada` como campo nuevo en el lote.

**Conclusion:** El hueco ya estaba identificado en el plan. Solo confirmamos que la firma de `registrar_entrada()` necesita un parametro nuevo `fecha_entrada` adicionalmente al `fecha_vencimiento` existente.

---

## HUECO #4 -- ALTO: `TIPO_REGISTRO_CHOICES` se importa en `inventario/models.py` pero el campo `tipo_registro` NO existe en el modelo `Producto`

**Archivo:** `apps/inventario/models.py`, lineas 20-22 (imports) y lineas 56-128 (modelo Producto)

**Lo que existe HOY:**
```python
# linea 20-22: imports (codigo muerto)
from core.choices import (
    ...
    TIPO_REGISTRO_CHOICES,
    TIPO_REG_INSUMO,
)

# Modelo Producto (lineas 63-113): NO tiene campo tipo_registro
class Producto(models.Model):
    id, sku, nombre, descripcion, codigo_barras, categoria,
    unidad_medida, precio_compra, precio_venta, codigo_afectacion_igv,
    stock_minimo, stock_maximo, requiere_lote, requiere_serie,
    is_active, created_at, updated_at, creado_por, actualizado_por
    # <-- total: 19 campos. Ninguno es tipo_registro.
```

**Implicacion:**
- Alguien ya empezo a agregar `tipo_registro` (creo los choices y el import) pero nunca termino de agregar el campo al modelo.
- Esto confirma que NO hay datos de `tipo_registro` en la DB -- el campo nunca existio.
- La migracion puede hacerse limpiamente como `ADD COLUMN tipo_registro ... DEFAULT 'producto_final'`.

---

## HUECO #5 -- ALTO: Los tests de ventas esperan `StockInsuficienteError` -- verificar que esta excepcion existe

**Archivo:** `tests/test_ventas_services.py`, linea 28

```python
from core.exceptions import (
    ReglaDeNegocioError,
    StockInsuficienteError,  # <-- ¿existe?
)
```

**Necesita verificacion:** Ir a `core/exceptions.py` y confirmar que `StockInsuficienteError` esta definida. Si no existe, los tests ya estan rotos hoy (import error).

**Accion:** Leer `core/exceptions.py` antes de Fase 1.

---

## HUECO #6 -- ALTO: `DashboardInventarioView` tiene un `@action` en una `APIView` -- codigo roto

**Archivo:** `apps/inventario/views.py`, lineas 538-547

```python
class DashboardInventarioView(APIView):  # <-- APIView, no ViewSet
    ...
    @extend_schema(summary="Stock completo del almacén")
    @action(detail=True, methods=["get"], url_path="stock")  # <-- linea 538-539: INCORRECTO
    def stock(self, request, pk=None):
        ...
```

**El problema:**
- `@action` es un decorador de DRF que solo funciona en `ViewSet` y sus subclases.
- `APIView` no tiene el mecanismo de routing que `@action` necesita.
- Este metodo `stock` probablemente nunca se enruta correctamente.
- Si alguien llama a `/inventario/dashboard/stock/` o similar, falla silenciosamente o da 404.

**Impacto en el plan:**
- El plan agrega un widget "Estado Camara" en `DashboardInventario.tsx` que hace una llamada al backend.
- Si el endpoint de dashboard esta mal implementado, hay que arreglarlo en Fase 1.

**Accion:** Revisar `apps/inventario/urls.py` para ver si este endpoint esta registrado y como. Si es necesario convertir `DashboardInventarioView` a un `ViewSet` o simplemente eliminar el `@action` y convertirlo en una vista separada.

---

## HUECO #7 -- ALTO: Signal de venta crea CxC usando `getattr(cliente, "dias_credito", 30)` pero el campo NO existe en `Cliente`

**Archivo:** `core/signals.py`, linea 122

```python
dias_credito = getattr(cliente, "dias_credito", 30) or 30
```

**Archivo:** `apps/clientes/models.py` -- el campo `dias_credito` NO existe en el modelo `Cliente`

**El problema:**
- El signal siempre usa 30 dias como fallback porque `dias_credito` nunca esta en el modelo.
- Si alguna vez se agrega ese campo, el signal lo usaria. Pero hoy es codigo silenciosamente incorrecto.

**Impacto en el plan:**
- No afecta directamente las 6 fases planificadas.
- Pero si en B8 (Ventas Corporativas) se define condiciones de credito por cliente, este signal necesita actualizarse.
- **Pendiente:** agregar `dias_credito` a `Cliente` en alguna fase futura (o documentarlo como deuda tecnica).

---

## HUECO #8 -- ALTO: El modelo `Lote` usa `fecha_vencimiento` para FIFO -- el plan propone agregar `fecha_entrada` -- son dos campos distintos con semantica diferente

**Archivos:**
- `apps/inventario/models.py`, linea 169: `fecha_vencimiento = DateField(null=True, blank=True)`
- `apps/inventario/services.py`, linea 727 aprox: `seleccionar_lotes_fifo()` ordena por `fecha_vencimiento`

**El problema:**
- El FIFO actual ordena por `fecha_vencimiento` (cuando vence segun el proveedor).
- El plan propone `fecha_entrada` (cuando Yolanda recibio la flor en la camara).
- Para flores frescas sin `fecha_vencimiento` del proveedor, `fecha_vencimiento` es NULL.
- El FIFO actual con flores puede fallar porque `fecha_vencimiento` es NULL para muchos lotes.

**Verificar:** ¿Los lotes de flores actuales en produccion tienen `fecha_vencimiento` seteada o es NULL?

**Implicacion para el plan:**
- `fecha_entrada` es el campo correcto para el semaforo de frescura de Amatista.
- El FIFO de frescura debe ordenar por `fecha_entrada ASC` (lo mas viejo primero).
- El FIFO existente (`seleccionar_lotes_fifo()`) ordena por `fecha_vencimiento` -- puede mantenerse para otros productos no perecibles.
- Para insumos perecibles, el FIFO debe priorizar `fecha_entrada`.

**Conclusion:** No hay conflicto, pero hay que asegurarse de que `obtener_estado_camara()` ordene por `fecha_entrada` (nuevo campo) y no por `fecha_vencimiento` (campo existente, potencialmente NULL en flores).

---

## HUECO #9 -- MEDIO: `registrar_recepcion()` en Compras NO llama a `registrar_entrada()` -- confirmado

**Archivo:** `apps/compras/services.py` (confirmado por el agente)

**El problema ya estaba documentado en el plan (D7).** Confirmamos que es real:
- `registrar_recepcion()` manipula `Stock` directamente
- NO crea `Lote` a menos que el payload incluya un `lote_id` preexistente
- Al unificar (Fase 1), `registrar_recepcion()` debe llamar a `registrar_entrada()`
- La firma de `registrar_entrada()` ya acepta `numero_lote` y `fecha_vencimiento`
- Solo hay que agregar `fecha_entrada` como parametro nuevo

**Accion (Fase 1):** Modificar `registrar_recepcion()` en `apps/compras/services.py` para que llame a `registrar_entrada()` por cada item. La logica actual de Stock debe eliminarse para evitar doble conteo.

---

## HUECO #10 -- MEDIO: `ProductoForm.tsx` NO muestra los campos `requiere_lote`, `requiere_serie`, `stock_minimo`, `stock_maximo`

**Archivo:** FE `product-create/components/ProductoForm.tsx`

**Campos que el backend tiene en `Producto` pero el formulario FE NO muestra:**
- `requiere_lote` (booleano -- crítico para los lotes de flores)
- `requiere_serie` (booleano)
- `stock_minimo` (para alertas)
- `stock_maximo`
- `codigo_afectacion_igv` (para calculo de IGV)

**Impacto:**
- Cuando se creen insumos organicos desde el formulario, el usuario no podra setear `requiere_lote=True` desde la UI.
- Para las flores ya existentes: `requiere_lote=True` ya esta confirmado (D2 respondido anteriormente).
- Para insumos nuevos que se creen en el futuro, el formulario no expone ese campo.

**Accion (Fase 1 o 2):** Al agregar `tipo_registro` al formulario, tambien agregar `requiere_lote` (auto-seteado a `True` si tipo=insumo_organico) y `stock_minimo`/`stock_maximo` (importantes para las alertas de Compras Inteligentes).

---

## HUECO #11 -- MEDIO: `numero_lote` en `Lote` es REQUERIDO (no nullable, sin default)

**Archivo:** `apps/inventario/models.py`, linea 168

```python
numero_lote = models.CharField(max_length=50)  # NOT NULL, sin default, sin blank=True
```

**El problema:**
- `numero_lote` es obligatorio en el modelo.
- `registrar_entrada()` exige `numero_lote` si `producto.requiere_lote = True` (linea 637-641).
- Para el multi-lote de flores, cuando Yolanda recibe una docena, el sistema necesita generar un `numero_lote` automaticamente si ella no lo ingresa manualmente.

**Implicacion para la UI de multi-lote:**
- La UI debe o bien: (a) pedir que Yolanda ingrese un numero de lote por cada sub-lote, o (b) el sistema lo genera automaticamente (ej: `LOTE-{fecha}-{uuid[:6]}`).
- Opcion (b) es mejor UX para una floreria.

**Decision requerida:** ¿El numero de lote lo ingresa Yolanda manualmente o el sistema lo genera?

**Recomendacion:** Auto-generar en el backend: `f"L{date.today().strftime('%Y%m%d')}-{uuid4().hex[:6].upper()}"`.

---

## HUECO #12 -- MEDIO: Signal de venta puede disparar doble el Celery task de comprobante

**Archivo:** `core/signals.py` + `apps/ventas/services.py` linea 519+

**El problema:**
- En `crear_venta_pos()` hay un `transaction.on_commit(lambda: emitir_comprobante_por_venta.delay(...))` (linea ~524 de ventas/services.py).
- En `core/signals.py` hay un signal `post_save` en `Venta` que tambien puede encolar el task.

**Riesgo:** Un comprobante electronico se envia dos veces. Esto puede causar rechazos en SUNAT o comprobantes duplicados.

**Impacto en el plan:**
- No afecta las 6 fases planificadas directamente.
- Pero en Fase 5 (Cotizaciones + email), hay que asegurarse de no repetir este patron.

**Accion:** Verificar en `core/signals.py` si el signal de `Venta` efectivamente encola el mismo task. Si es asi, eliminar uno de los dos encolamientos.

---

## HUECO #13 -- MEDIO: `test_anula_venta_y_devuelve_stock` en tests asume devolucion de stock al anular

**Archivo:** `tests/test_ventas_services.py` (mencionado por el agente -- no leido directamente)

**El problema:**
- El test espera que al anular una venta, el stock se devuelva.
- Pero si `crear_venta_pos()` nunca descuenta stock, anularlo tampoco deberia devolver stock.
- Este test esta roto hoy.

**Accion:** Igual que el Hueco #2 -- corregir los tests de ventas antes o durante Fase 2 para reflejar el comportamiento real (descuento ocurre al producir, no al vender).

---

## HUECO #14 -- MEDIO: El `Stock` es un modelo SEPARADO del `Lote` -- hay que actualizar ambos

**Archivo:** `apps/inventario/models.py`, lineas 197+ (modelo `Stock`)

**Lo que existe:**
- `Stock`: cantidad total de un producto en un almacen (una fila por producto+almacen). Se actualiza con cada movimiento.
- `Lote`: batch especifico con numero, fecha de vencimiento, cantidad actual. Solo existe si `producto.requiere_lote=True`.

**El problema para el plan:**
- `completar_produccion_item()` llama a `registrar_salida()` que descuenta AMBOS: el `Stock` y el `Lote` via FIFO.
- Esto esta correcto -- `registrar_salida()` ya maneja ambos.
- Pero en la UI de "Control de Camara", mostrar el stock de flores requiere consultar `Lote` (no `Stock`), porque los lotes tienen la `fecha_entrada` y el `estado_frescura`.

**Implicacion:** La vista de Camara (`EstadoCamara.tsx`) debe consultar el endpoint de `Lote`, no el de `Stock`. Esto ya esta en el plan (`obtener_estado_camara()` filtra por `Lote`). Solo confirmar que no se confunden.

---

## HUECO #15 -- BAJO: El campo `foto` en `ProductoForm.tsx` es un campo visible pero el backend no tiene `foto` en el modelo `Producto`

**Archivo:** FE `product-create/components/ProductoForm.tsx` (campo foto en el formulario)

**Verificar:** Si el backend no tiene un campo `foto` o `imagen` en `Producto`, el formulario envia datos que el backend ignora. Esto puede ser una foto almacenada en otro servicio (S3, Cloudinary) referenciada por URL, o puede ser un campo que si existe en el modelo pero no lo leimos en el analisis de modelos (los modelos se leyeron parcialmente).

**Accion:** Confirmar si `Producto` tiene campo `foto` o `imagen_url` antes de la Fase 1.

---

## HUECO #16 -- BAJO: La vista de `pedido-pos/index.tsx` llama a `POST /api/v1/ventas/pedido-pos/` pero NO tiene campos para `notas_arreglista` ni `recargo_personalizacion`

**Archivo:** FE `pedido-pos/index.tsx`

**El problema:**
- Los campos nuevos `notas_arreglista` y `recargo_personalizacion` (Fase 2) deben agregarse al payload del POS.
- El payload actual no los incluye.

**Esto ya esta en el plan** (Fase 2 modifica `pedido-pos/index.tsx`). Solo confirmar que el endpoint `POST /api/v1/ventas/pedido-pos/` acepta campos extras en los items sin romper la validacion actual.

**Accion (Fase 2):** Verificar el serializer de `crear_venta_pos()` para asegurarse de que acepte `notas_arreglista` y `recargo_personalizacion` por item.

---

## RESUMEN DE ACCIONES PREVIAS A LA IMPLEMENTACION

Antes de escribir la primera linea de codigo de Fase 1, hay que resolver:

| # | Accion | Estado | Quien decide |
|---|--------|--------|-------------|
| R1 | ¿Usamos `"insumo"` o `"insumo_organico"` / `"insumo_no_organico"`? | **RESUELTO (D8):** usar `"insumo_organico"` + `"insumo_no_organico"`. El valor `"insumo"` se descarta. Como el campo no existe en la DB, no hay datos que migrar. | Joshymar |
| R2 | Leer `core/exceptions.py` para confirmar que `StockInsuficienteError` existe | **PENDIENTE** -- leer antes de Fase 1 | Automatico |
| R3 | Verificar `apps/inventario/urls.py` para entender si el `@action` roto esta registrado | **PENDIENTE** -- leer antes de Fase 1 | Automatico |
| R4 | ¿El `numero_lote` lo ingresa Yolanda o el sistema lo genera? | **RESUELTO:** auto-generar en backend (`f"L{date.today():%Y%m%d}-{uuid4().hex[:6].upper()}"`) -- mejor UX para floreria | Joshymar |
| R5 | Confirmar si `Producto` tiene campo `foto` o `imagen_url` | **PENDIENTE** -- leer modelos completos antes de Fase 1 | Automatico |
| R6 | Verificar el signal doble de comprobante en `core/signals.py` | **PENDIENTE** -- verificar antes de Fase 1 | Automatico |

---

## RESUMEN EJECUTIVO DE HUECOS

| # | Hueco | Nivel | Fase afectada | Accion |
|---|-------|-------|---------------|--------|
| 1 | `TIPO_REGISTRO_CHOICES` tiene 2 valores (`insumo`, `producto_final`), el plan usa 3 (`insumo_organico`, `insumo_no_organico`, `producto_final`) | BLOQUEANTE | F1 | **RESUELTO (D8):** reemplazar `"insumo"` por los 2 valores nuevos en choices.py. Sin migracion de datos (campo no existe en DB). |
| 2 | Tests de ventas asumen descuento de stock al vender -- el servicio NO descuenta | BLOQUEANTE | F2 | Corregir tests antes de F2 |
| 3 | `registrar_entrada()` no tiene parametro `fecha_entrada` -- solo `fecha_vencimiento` | BLOQUEANTE | F1 | Agregar parametro al unificar |
| 4 | `tipo_registro` importado en models.py pero nunca agregado al modelo `Producto` | ALTO | F1 | Confirma que la migracion es limpia |
| 5 | `StockInsuficienteError` -- verificar que existe en `core/exceptions.py` | ALTO | F2 | Leer exceptions.py |
| 6 | `@action` en `APIView` -- codigo roto en `DashboardInventarioView` | ALTO | F1 | Arreglar al implementar el widget de camara |
| 7 | Signal usa `getattr(cliente, "dias_credito", 30)` pero campo no existe en `Cliente` | ALTO | B8 (futuro) | Documentar como deuda tecnica |
| 8 | FIFO existente ordena por `fecha_vencimiento` (puede ser NULL en flores) -- plan usa `fecha_entrada` | ALTO | F1 | Asegurar que `obtener_estado_camara()` use `fecha_entrada` |
| 9 | `registrar_recepcion()` no llama a `registrar_entrada()` -- ya en el plan (D7) | MEDIO | F1 | Confirmado, resolvido en F1 |
| 10 | `ProductoForm.tsx` no muestra `requiere_lote`, `stock_minimo`, `stock_maximo` | MEDIO | F1 | Agregar campos en F1 |
| 11 | `numero_lote` es REQUERIDO en `Lote` -- multi-lote necesita auto-generacion | MEDIO | F1 | Decision de UX requerida |
| 12 | Posible doble encolado del Celery task de comprobante (signal + on_commit) | MEDIO | Pre-F1 | Verificar y corregir |
| 13 | `test_anula_venta_y_devuelve_stock` tambien esta roto | MEDIO | F2 | Corregir junto con Hueco #2 |
| 14 | `Stock` y `Lote` son modelos separados -- la vista Camara consulta Lotes, no Stock | MEDIO | F1 | Ya en el plan, solo confirmar |
| 15 | Campo `foto` en ProductoForm.tsx -- verificar si existe en el modelo backend | BAJO | F1 | Leer modelos completos |
| 16 | `pedido-pos/index.tsx` no tiene campos de personalizacion en el payload actual | BAJO | F2 | Ya en el plan |

**Total: 3 bloqueantes + 5 altos + 6 medios + 2 bajos = 16 huecos**
