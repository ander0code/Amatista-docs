# DIAGNOSTICO COMPLETO -- Requerimientos Sr. Tito (Amatista)

> **Fecha:** 2026-03-02 (actualizado 2026-03-02 v4 -- decisiones finales incorporadas)
> **Contexto:** Analisis cruzado de lo solicitado por el Sr. Tito vs. lo que existe actualmente en `Amatista-be` y `Amatista-fe`.
> **Regla:** No se alucina -- cada punto se mapea a codigo real existente o se marca como **NO EXISTE**.
> **Verificado contra:** Codigo fuente real de ambos repos (modelos, services, views, serializers, tasks, rutas FE, componentes).
> **Estado:** Todas las preguntas pendientes respondidas. Listo para implementacion.

---

## DECISIONES FINALES (respuestas del equipo -- 2026-03-02)

| # | Pregunta | Respuesta | Impacto en plan |
|---|----------|-----------|-----------------|
| D1 | ¿Como ingresa Yolanda el stock? | **Ambas formas** (con OC y entrada manual directa) | Hay que soportar multi-lote tanto en recepcion de OC como en entrada manual de inventario |
| D2 | ¿Insumos organicos ya tienen requiere_lote=True? | **Si, ya tienen requiere_lote=True** | No hay migracion de datos necesaria para ese campo. La trazabilidad de lotes ya funciona para ellos |
| D3 | ¿Nota libre para arreglista? | **Si, nota libre ademas de AjustePersonalizacion estructurado** | Agregar campo `notas_arreglista` (TextField, blank=True) en `DetalleVenta` |
| D4 | ¿Frecuencia de multi-lote en una recepcion? | **Frecuente (varias veces/semana)** | Soportar multi-lote DESDE EL INICIO en la UI de recepcion. No puede quedar pendiente |
| D5 | ¿Estado de la base de datos? | **Tiene productos reales.** Los productos legacy pueden seguir vendiendose sin receta. Los productos nuevos si o si deben tener receta al crearse. Se usa campo `descuenta_insumos` para diferenciar | Ver D5-detalle abajo |
| D6 | ¿Como se calcula el precio de personalizacion? | **Recarga fija por personalizar** (no por insumos exactos), pero el sistema debe mostrar el costo de insumos como referencia | Ver D6-detalle abajo |
| D7 | ¿Que hacemos con la logica duplicada Compras vs Inventario? | **Unificar para largo plazo limpio** -- el desarrollador decide lo tecnico | registrar_recepcion() debe llamar a registrar_entrada() para crear lotes correctamente |
| D8 | ¿`es_perecible` y `dias_vida_util` son necesarios? | **Eliminar ambos.** `tipo_registro='insumo_organico'` ya implica perecible. Los umbrales del semaforo son fijos (1-3, 4, 5-7, 8+) y no dependen de ningun campo configurable | 2 columnas menos en `productos`. El codigo filtra por `tipo_registro='insumo_organico'` directamente |

---

### D5-detalle: Estado real de la DB y flujo de receta en el formulario

**Situacion actual:**
- La DB tiene productos reales ya cargados (no es base vacia)
- Esos productos no tienen receta definida todavia (el modelo RecetaProducto no existe aun)
- El formulario de crear producto (`ProductoForm.tsx`) existe y funciona

**Lo que se pide:**
- Desde el formulario de **crear o editar** un producto, poder definir su receta (que insumos necesita y en que cantidad)
- UX: similar a "agregar tags" pero mas estructurado -- buscar insumos existentes, agregar cantidad, agregar mas lineas
- Un producto nuevo (creado despues de la Fase 2) debe tener receta si o si para poder venderse
- Los productos legacy (existentes antes de Fase 2) pueden seguir vendiendose mientras Yolanda/el admin les asigna la receta progresivamente

**Mecanismo: campo `descuenta_insumos` (BooleanField, default=False)**

```
Producto legacy (existente hoy):
  descuenta_insumos = False  (default)
  → Puede venderse normalmente
  → Al producir: marca "listo" pero NO descuenta insumos (comportamiento actual)
  → Cuando el admin le asigna una receta: puede activar descuenta_insumos=True manualmente

Producto nuevo (creado despues de Fase 2):
  descuenta_insumos = True  (lo setea la UI al crear con receta)
  → NO puede venderse si no tiene RecetaProducto activa
  → Al producir: descuenta insumos via FIFO automaticamente
```

**Por que este enfoque y no un simple bloqueo:**
- Bloquear todos los `producto_final` sin receta romperia todas las ventas actuales del negocio
- Con `descuenta_insumos` la transicion es gradual y controlada
- El admin puede ir activando producto por producto a medida que les define la receta
- Nuevo producto = no puede activar `descuenta_insumos=True` sin receta definida (validacion en el formulario y en el backend)

**Impacto tecnico:**
- La receta se edita en el mismo `ProductoForm.tsx` con un componente `RecetaEditor` embebido
- Si el producto ya existe (editar), el editor carga la receta actual (si tiene) o muestra vacio
- Validacion en `crear_venta_pos()`: si el producto tiene `descuenta_insumos=True` y NO tiene receta activa, rechazar con error claro
- Los productos legacy (descuenta_insumos=False) se venden y producen igual que hoy sin cambios

---

### D6-detalle: Precio de personalizacion

**Lo que se pide:**
- Cuando un cliente pide personalizacion (variacion de la receta default), se agrega un cargo extra
- Ese cargo NO es el costo exacto de los insumos cambiados -- es una **recarga por servicio de personalizacion**
- Pero el sistema DEBE mostrar al vendedor el costo estimado de los insumos del ajuste como referencia
- El vendedor/gerente puede configurar cual es la recarga (ej: S/. 10 fijos, o X% sobre el precio base)

**Implicacion en el modelo:**
- `AjustePersonalizacion` sigue igual (registra que insumos cambian y en que cantidad)
- Se agrega campo `recargo_personalizacion` en `DetalleVenta` (Decimal, default 0) -- la recarga que se cobra por personalizar este item
- En el POS, al activar personalizacion, el sistema muestra: "Costo estimado de ajuste: S/. X" (calculado en base a precio_compra de los insumos extra), y el vendedor ingresa el recargo que cobrara
- El total del DetalleVenta = (precio_unitario * cantidad) + recargo_personalizacion

---

## GLOSARIO CRITICO (leer antes que todo)

| Termino | Significado en este proyecto |
|---------|------------------------------|
| **Insumo** | Materia prima: rosa, girasol, clavel, follaje, cinta, base, adorno. Tiene stock. Puede ser organico (perecible) o no organico (duradero). |
| **Producto Final** | El arreglo floral terminado que se vende al cliente. Esta compuesto de insumos. |
| **tipo_registro** | Campo en el modelo `Producto` que indica si un registro es `insumo_organico`, `insumo_no_organico` o `producto_final`. Es una caracteristica permanente del item, no del pedido. `insumo_organico` implica perecible (semaforo de frescura). |
| **Receta default** | La composicion estandar de un producto final: cuantas rosas, cuanto follaje, que envoltorio. Se define desde el formulario del producto. Nunca cambia por un pedido especifico. |
| **descuenta_insumos** | Campo BooleanField en Producto (default=False). Cuando es True, el producto requiere receta activa para venderse y al producir descuenta insumos del stock. Los productos legacy quedan en False para no romper ventas actuales. Se activa manualmente cuando el admin define la receta del producto. |
| **Producto legacy** | Producto_final existente antes de Fase 2, con `descuenta_insumos=False`. Se vende y produce igual que hoy. El admin lo "activa" al asignarle una receta. |
| **Personalizacion de pedido** | Cuando un cliente quiere una variacion de la receta default para su pedido especifico. No toca la receta default. Se registra en el DetalleVenta como ajustes + recargo. |
| **AjustePersonalizacion** | Modelo nuevo que vive en el DetalleVenta. Guarda las diferencias respecto a la receta default. La receta del producto permanece intacta. |
| **notas_arreglista** | Campo de texto libre en DetalleVenta. Para instrucciones especificas que no encajan en los ajustes estructurados (ej: "usar moño azul marino especificamente"). |
| **recargo_personalizacion** | Cargo extra en DetalleVenta cuando hay personalizacion. No es el costo exacto de los insumos -- es una recarga por servicio de personalizacion que el vendedor define. |
| **Paquete / Unidad de Compra** | Los mayoristas venden por caja sellada (ej: 100 unidades). Amatista compra por caja pero usa/vende por tallo/unidad. El sistema registra el factor de conversion. |
| **Lote mezclado** | Cuando en una misma compra llegan flores de distintas fechas. Se registran como lotes separados. Ocurre varias veces por semana -- soportar desde el inicio. |
| **FIFO** | "Lo primero que entro es lo primero que sale." La flor mas vieja se usa primero. Lo nuevo va atras. |
| **Camara** | El espacio fisico donde se guardan las flores frescas. Control de camara = saber el estado de cada lote de flor. |
| **Estado Frescura** | Clasificacion de un lote de insumo organico segun cuantos dias tiene: optimo (verde), precaucion (amarillo), funebre (rojo), descarte (negro). |
| **Merma** | Insumo que ya paso sus dias de vida util y no sirve para venta normal. Solo para funebres o descarte. |

---

## 1. RESUMEN DE LO QUE PIDE EL SR. TITO

Del audio transcrito y las notas anotadas en reunion, se extraen **8 bloques funcionales**:

| #  | Bloque | Descripcion resumida |
|----|--------|---------------------|
| B1 | **Control de Camara (Stock Organico)** | Cada insumo organico (flor) tiene fecha de entrada. Ciclo de vida 5 dias. Semaforo por color (verde/amarillo/rojo). FIFO visual: lo mas viejo aparece primero. Estados: optimo → funebre → descarte. Alertas automaticas. |
| B2 | **Insumos Organicos vs No Organicos** | Clasificar insumos como organicos (perecibles, con ciclo de vida y semaforo) o no organicos (cintas, bases -- sin caducidad). Un insumo puede venderse en **paquetes** (unidad de compra) o por unidad. |
| B3 | **Producto Final = Receta de Insumos (BOM)** | Un producto final (arreglo) esta compuesto por insumos especificos con cantidades exactas. La receta se define desde el formulario del producto (crear o editar). Producto sin receta NO puede venderse. Al producir, se descuentan los insumos del stock via FIFO automaticamente. |
| B4 | **Alertas y Compras Inteligentes** | Vista unificada para Yolanda antes de ir al mayorista: que falta (stock bajo), que ya merma (funebre/descarte), alta rotacion vs estancados. Genera OC pre-llenada. Alerta nocturna. |
| B5 | **Cotizaciones Formales** | PDF profesional con logo, datos, productos, condiciones, fechas. Envio por correo. Check de aprobacion de gerencia antes de enviar. |
| B6 | **Precios Diferenciados** | 3 tipos de precio para productos finales: Persona Natural (precio estandar), Corporativo (empresa con RUC, precio seteado), Con recargo de personalizacion (recarga fija cuando el cliente pide variacion de la receta). Descuentos por cantidad configurables. |
| B7 | **Campanas / Temporadas** | Seccion para gestionar descuentos temporales por campana (Dia de la Madre, San Valentin, etc.). Se aplica a productos seleccionados durante un rango de fechas automaticamente en POS y cotizaciones. |
| B8 | **Ventas Corporativas / Pre-venta** | Flujo: registrar empresa (con RUC) → enviar catalogo/cotizacion → cerrar venta corporativa. Mini-CRM para seguimiento de prospectos. Alertas de cotizacion sin respuesta. |

---

## 2. HALLAZGO CRITICO: EL STOCK NO SE DESCUENTA AL VENDER

> **Archivo:** `apps/ventas/services.py` -- funcion `crear_venta_pos()`
> **Linea relevante:** `stock = None  # Stock no gestionado -- negocio produce bajo pedido`

Cuando se crea una venta en el POS, el sistema **NO descuenta inventario**. El negocio opera "produce bajo pedido": se vende primero, se arma despues.

- El descuento de insumos debe implementarse cuando el arreglista marca `estado_produccion = listo` en el Kanban, NO al vender.
- Si un producto no tiene receta asignada, no pasa nada (comportamiento actual se mantiene).
- Solo los `producto_final` con receta asignada descontaran insumos al producir.

**REGLA (D5 -- migracion gradual):** Solo los productos con `descuenta_insumos=True` son bloqueados si no tienen receta activa. Los productos legacy (`descuenta_insumos=False`, que es el default) se siguen vendiendo normal. El admin activa `descuenta_insumos=True` manualmente cuando asigna la receta a un producto legacy. Los productos nuevos que se creen con receta desde el inicio arrancan con `descuenta_insumos=True`.

**Lo que SI existe para produccion:**
- `DetalleVenta.estado_produccion` -- choices: `pendiente`, `armando`, `listo`
- `DetalleVenta.produccion_iniciada_en` y `produccion_completada_en` (timestamps)
- Kanban de produccion en FE: `/distribucion/produccion`

---

## 3. DIAGNOSTICO DETALLADO: QUE EXISTE vs. QUE FALTA

---

### B1 -- Control de Camara (Stock Organico con Ciclo de Vida)

**Lo que pide el Sr. Tito (textual del audio):**
- Cada insumo organico tiene una **fecha de entrada** a la camara.
- Ciclo de vida estandar: **5 dias habiles** (configurable por insumo).
- Semaforo exacto por dias:
  - **Verde (optimo)**: dias 1-3
  - **Amarillo (precaucion)**: dia 4 -- "en ambas" (puede seguir usandose pero hay que moverlo)
  - **Rojo (funebre)**: dia 5 en adelante -- ya no sirve para cliente normal. Solo para arreglos funebres (se usa 1-2 dias mas y se bota).
  - **Descarte**: pasado el uso funebre -- se bota.
- El sistema debe ordenar FIFO **visualmente**: **lo mas viejo aparece primero en la lista** (no al reves).
- Alertas automaticas: "Esto ya paso a merma", "Esto esta faltando".

**Umbrales de frescura (dias exactos, no relativos):**
- Dias 1-3: optimo (verde)
- Dia 4: precaucion (amarillo)
- Dias 5-7: funebre (rojo -- solo usar para arreglos funebres)
- Dia 8+: descarte (negro -- botar)

**Lo que EXISTE actualmente:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Lote` con `fecha_vencimiento`, `cantidad_inicial`, `cantidad_actual`, `almacen` | SI | `apps/inventario/models.py` |
| Logica FIFO por `fecha_vencimiento` en `registrar_salida()` | SI | `apps/inventario/services.py` |
| `Producto.requiere_lote` (flag booleano) -- **insumos organicos ya tienen requiere_lote=True** | SI (confirmado) | `apps/inventario/models.py` |
| Alertas de stock bajo: `productos_bajo_stock_minimo()` | SI | `apps/inventario/services.py` |
| Task Celery `alertar_lotes_por_vencer` (detecta lotes que vencen en < 7 dias) | SI | `apps/inventario/tasks.py` |
| Task Celery `verificar_stock_minimo` (notifica supervisores) | SI | `apps/inventario/tasks.py` |
| Serializer `FifoSugerenciaSerializer` (endpoint `/lotes/fifo/`) | SI | `apps/inventario/serializers.py` |
| `DashboardInventarioSerializer` con campo `lotes_por_vencer` (numero) | SI | `apps/inventario/serializers.py` |
| FE: `StockOverview.tsx` con semaforo de stock (verde/amarillo/rojo por stock_minimo) | SI (pero es semaforo de CANTIDAD, no de frescura) | FE `(inventario)/stock/` |
| FE: `DashboardInventario.tsx` con KPI "Lotes por Vencer" (solo numero) | SI | FE `(inventario)/dashboard-inventario/` |

**Lo que NO EXISTE (hay que crear):**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Campo `fecha_entrada` en `Lote` (cuando entro a la camara, diferente a `created_at`) | NO | Baja |
| Campo `estado_frescura` en `Lote` con choices: `optimo`, `precaucion`, `funebre`, `descarte` | NO | Baja |
| Property `dias_en_camara` en `Lote` (calculada: hoy - fecha_entrada) | NO | Baja |
| Funcion `actualizar_estados_frescura()` en services (recorre lotes de `tipo_registro='insumo_organico'` y actualiza estado) | NO | Media |
| Task Celery `actualizar_frescura_diaria` (corre cada noche) | NO | Baja |
| Vista FE "Control de Camara" `/inventario/camara` con semaforo visual FIFO (viejo primero) | NO | Alta |
| Alerta de insumos que pasaron a funebre/descarte | NO | Media |
| Ordenamiento FIFO **visual** en la UI (lo mas viejo arriba siempre) | PARCIAL (FIFO en codigo pero no en UI) | Baja |
| Soporte multi-lote en recepcion (UI para dividir en varios lotes -- **frecuente, prioridad alta**) | NO | Alta |
| Soporte multi-lote en entrada manual de inventario | NO | Media |

**ELIMINADO del plan:** `es_perecible` (redundante con `tipo_registro='insumo_organico'`) y `dias_vida_util` (umbrales del semaforo son fijos: 1-3, 4, 5-7, 8+).

**NOTA CRITICA (D4):** El multi-lote ocurre **varias veces por semana**. Debe implementarse desde el inicio, no postergarse.

---

### B2 -- Insumos Organicos vs No Organicos + Paquetes

**Lo que pide el Sr. Tito:**
- Al registrar un **insumo**, indicar si es **organico** (perecible: rosas, girasoles, claveles, follaje) o **no organico** (duradero: cintas, bases, adornos, papel).
- Los organicos tienen ciclo de vida con semaforo de frescura.
- Los no organicos se almacenan sin caducidad.
- Los mayoristas venden en **cajas/paquetes** (ej: 100 tallos por caja). El sistema debe manejar la **unidad de compra** (caja) vs **unidad de uso** (tallo/unidad).

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Producto` generico con 17 campos | SI | `apps/inventario/models.py` |
| Campo `requiere_lote` (booleano) -- insumos organicos ya tienen True | SI (confirmado D2) | `apps/inventario/models.py` |
| `Producto.unidad_medida` con 8 opciones SUNAT (NIU, KGM, LTR, DZN, PK, etc.) | SI | `apps/inventario/models.py` |
| Modelo `Categoria` con jerarquia (categoria_padre) | SI | `apps/inventario/models.py` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Campo `tipo_registro` en Producto: `insumo_organico`, `insumo_no_organico`, `producto_final` | NO | Baja |
| Campo `descuenta_insumos` en Producto (BooleanField, default=False -- migracion gradual legacy→nuevo) | NO | Baja |
| Campo `unidad_compra` en Producto (ej: "caja") y `factor_conversion` (ej: 100 unidades por caja) | NO | Media |
| Que al registrar una recepcion de compra con unidad_compra=caja, el stock suba por el factor (x100) | NO | Media |

**Nota arquitectonica:** No se necesita modelo nuevo. Se agrega `tipo_registro` + `descuenta_insumos` + `unidad_compra` + `factor_conversion` al modelo `Producto` existente. Todo con defaults seguros. Ningun dato existente se rompe.
**ELIMINADO:** `es_perecible` (redundante -- `tipo_registro='insumo_organico'` ya implica perecible) y `dias_vida_util` (umbrales de semaforo son fijos, no configurables).

---

### B3 -- Producto Final = Receta de Insumos (BOM) + Personalizacion de Pedido

**Lo que pide el Sr. Tito + decision D5:**
- Un **producto final** (arreglo floral) esta compuesto por insumos especificos con cantidades exactas.
- **La receta se define directamente desde el formulario de crear/editar el producto** (no desde una pantalla separada).
- Un producto puede guardarse SIN receta para flujo rapido (ej: cuando aun no se sabe la composicion exacta).
- **REGLA CRITICA:** Un `producto_final` SIN receta definida **no puede agregarse a una venta**. El sistema rechaza con mensaje claro.
- Al producir/armar el arreglo (cuando el arreglista marca "listo" en el Kanban), el sistema descuenta automaticamente cada insumo del stock via FIFO.

**Dos niveles que NO deben confundirse:**

| Nivel | Donde vive | Que hace | Se puede cambiar? |
|-------|-----------|----------|-------------------|
| **Receta default** | En el `Producto` (via `RecetaProducto`) | Define la composicion estandar: 5 rosas rojas, 3 follajes, 1 envoltorio | Solo el admin/gerente puede editarla desde el formulario del producto. Es el template del arreglo. |
| **Ajuste de personalizacion** | En el `DetalleVenta` | Para este pedido especifico, el cliente quiere 3 rojas + 2 blancas. Se registran los cambios respecto al default. | Lo define la vendedora/arreglista en el momento del pedido. |
| **Nota libre arreglista (D3)** | En el `DetalleVenta` (campo `notas_arreglista`) | Texto libre para instrucciones que no encajan en los ajustes estructurados. Ej: "usar moño azul marino exactamente". | La vendedora/arreglista lo escribe libremente. |

**Ejemplo concreto:**

```
Producto: Ramo Primavera
  Receta default (definida en el formulario del producto):
    - Rosa Roja x5
    - Follaje x3
    - Envoltorio x1

Pedido de Juan (sin personalizacion):
  DetalleVenta → Ramo Primavera x1
  Ajustes: ninguno
  Nota arreglista: (vacia)
  Al producir descuenta: Rosa Roja x5 + Follaje x3 + Envoltorio x1

Pedido de Maria (con personalizacion):
  DetalleVenta → Ramo Primavera x1
  Ajustes: { Rosa Roja: 3 (en vez de 5), Rosa Blanca: 2 (nuevo) }
  Nota arreglista: "usar cinta plateada, no dorada"
  Recargo personalizacion: S/. 10.00
  Al producir descuenta: Rosa Roja x3 + Rosa Blanca x2 + Follaje x3 + Envoltorio x1
  (La receta default del Ramo Primavera sigue siendo 5 rosas rojas -- no cambia)
```

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Producto` reutilizable | SI | `apps/inventario/models.py` |
| Modelo `DetalleVenta` vincula `Venta` → `Producto` con cantidades | SI | `apps/ventas/models.py` |
| `DetalleVenta.estado_produccion` (pendiente/armando/listo) | SI | `apps/ventas/models.py` |
| Kanban de produccion FE `/distribucion/produccion` | SI | FE distribucion |
| `registrar_salida()` con FIFO por lote | SI | `apps/inventario/services.py` |
| `ProductoForm.tsx` (530 lineas) -- donde se editara la receta | SI | FE product-create |
| **Descuento de stock al producir** | **NO** (ver Seccion 2) | `apps/ventas/services.py` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Modelo `RecetaProducto` (composicion default del producto: insumos + cantidades) | NO | **Alta** |
| Modelo `DetalleReceta` (insumo_id + cantidad_requerida por unidad de producto final) | NO | **Alta** |
| Modelo `AjustePersonalizacion` (variacion por pedido: insumo + cantidad_ajuste, vive en DetalleVenta) | NO | Media |
| Campo `notas_arreglista` en `DetalleVenta` (texto libre para el arreglista -- D3) | NO | Baja |
| Campo `recargo_personalizacion` en `DetalleVenta` (Decimal, default 0 -- D6) | NO | Baja |
| Campo `descuenta_insumos` en `Producto` (BooleanField, default=False -- migracion gradual D5) | NO | Baja |
| Componente `RecetaEditor` embebido en `ProductoForm.tsx` (D5) | NO | **Alta** |
| Validacion en `crear_venta_pos()`: bloquear si `descuenta_insumos=True` y sin receta activa (D5) | NO | Baja |
| Logica `completar_produccion_item()`: si `descuenta_insumos=True` descuenta receta + ajustes; si False no hace nada (comportamiento legacy) | NO | **Alta** |
| Modelo `DetalleVentaInsumo` (trazabilidad: insumos reales descontados, incluye ajustes) | NO | Media |
| Calculo de costo estimado de ajuste (para mostrar al vendedor como referencia -- D6) | NO | Media |

---

### B4 -- Alertas y Compras Inteligentes

**Lo que pide el Sr. Tito (con detalle):**
- Al momento de ir al mayorista, Yolanda necesita ver **todo lo que falta**.
- La lista debe combinar en una sola pantalla:
  1. **Insumos bajo stock minimo** (hay poco, hay que reponer)
  2. **Insumos mermados** (estado funebre o descarte, hay que reemplazarlos)
  3. **Alta rotacion** (se venden rapido, hay que tener mas)
  4. **Baja rotacion / estancados** (no comprar mas de estos)
  5. **Fecha de compra** del lote actual (para saber si el proveedor puede dar producto fresco)
- Desde esa vista, poder **generar una Orden de Compra pre-llenada** con los items y cantidades sugeridas.
- **Alerta nocturna** automatica para que Yolanda la tenga disponible la noche antes de ir al mayorista.

**Sub-vistas / filtros de la seccion Compras Inteligentes:**

| Sub-vista / Filtro | Descripcion |
|--------------------|-------------|
| "Perecibles fuera de uso" | Insumos organicos en estado funebre o descarte -- hay que botar/reemplazar |
| "Stock bajo" | Insumos por debajo del stock minimo definido |
| "Alta rotacion" | Insumos que se usan mucho (clasificacion A en rotacion ABC) |
| "Baja rotacion" | Insumos estancados (clasificacion C) -- no comprar mas |
| "Todos los insumos" | Vista general con fecha de compra y estado de frescura |

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| `productos_bajo_stock_minimo()` | SI | `apps/inventario/services.py` |
| Endpoint `AlertasStockView` (GET `alertas-stock/`) | SI | `apps/inventario/views.py` |
| `calcular_rotacion_abc()` con clasificacion A/B/C | SI | `apps/inventario/services.py` |
| Endpoint `RotacionABCView` (GET `rotacion-abc/`) | SI | `apps/inventario/views.py` |
| `dashboard_inventario()` con KPIs completos | SI | `apps/inventario/services.py` |
| Task Celery `alertar_lotes_por_vencer` | SI | `apps/inventario/tasks.py` |
| Task Celery `verificar_stock_minimo` | SI | `apps/inventario/tasks.py` |
| FE: `RotacionABC.tsx` (componente completo pero **OCULTO/comentado** para Amatista) | SI oculto | FE `(inventario)/dashboard-inventario/` |
| **Modulo de Compras completo** (OC, proveedores, recepciones, facturas proveedor) | SI | `apps/compras/` + FE 6 paginas |
| FE: Comparacion de proveedores | SI | `ComparacionProveedoresModal.tsx` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Vista unificada "Compras Inteligentes" que combina stock bajo + merma + rotacion | NO | Media |
| Sub-filtros por tipo: perecibles fuera de uso / stock bajo / alta rotacion / baja rotacion | NO | Media |
| Alerta de insumos **mermados** (organicos en estado funebre/descarte) | NO | Media |
| **Generacion de OC pre-llenada** desde la vista de alertas (items + cantidades sugeridas) | NO (el modulo OC existe pero no se conecta con alertas) | Media |
| Alerta nocturna automatica para Yolanda (task Celery programada) | NO | Baja |
| Activar RotacionABC en el dashboard (actualmente comentado) | NO -- solo descomentar | **Baja** |

**Nota:** La tarea no es crear compras desde cero. Es **conectar** las alertas de stock/frescura con el sistema de OC existente y crear la vista unificada.

---

### B5 -- Cotizaciones Formales

**Lo que pide el Sr. Tito:**
- Formulario completo y formal: datos cliente, productos, condiciones comerciales, notas, fechas emision y validez.
- PDF profesional con **logo Amatista**, bonito, que de confianza a una empresa.
- Envio a correo del cliente directo desde el sistema.
- **Check de aprobacion de gerencia** antes de enviarlo (el Sr. Tito da el visto bueno).
- Yamile puede crear la cotizacion, pero la gerencia la aprueba.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Cotizacion` completo (numero, fechas, cliente, vendedor, estado, totales, notas, condiciones_comerciales) | SI | `apps/ventas/models.py` |
| Modelo `DetalleCotizacion` (producto, cantidad, precio_unitario, descuento_%, subtotal, igv, total) | SI | `apps/ventas/models.py` |
| Estados: borrador, vigente, aceptada, vencida, rechazada | SI | `core/choices.py` |
| `crear_cotizacion()`, `duplicar_cotizacion()`, `convertir_cotizacion_a_orden()` | SI | `apps/ventas/services.py` |
| CRUD completo + KPIs endpoint | SI | `apps/ventas/views.py` |
| FE: Lista cotizaciones con KPIs (total, tasa conversion, montos) | SI | `(ventas)/cotizaciones/` |
| FE: Modal wizard 4 pasos (Cliente → Productos → Condiciones → Resumen) | SI (681 lineas) | `CotizacionModal.tsx` |
| FE: Detalle cotizacion con acciones (editar, duplicar, convertir a OV) | SI (390 lineas) | `(ventas)/cotizacion-detalle/` |
| PDF de resumen de venta (patron reutilizable con ReportLab + logo Amatista) | SI | `apps/ventas/services.py` → `generar_resumen_venta_pdf()` |
| Envio de email (infraestructura funciona para comprobantes electronicos) | SI | `apps/facturacion/` + `apps/reportes/` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| PDF de cotizacion profesional (clonar patron `generar_resumen_venta_pdf()`) | NO | Baja-Media |
| Envio de cotizacion por correo al cliente | NO (infraestructura SI existe, falta el endpoint) | Baja |
| **Campo `aprobada_por` en Cotizacion** (quien aprobo + timestamp) | NO | Baja |
| Boton "Aprobar" visible solo para gerente/admin | NO | Baja |
| Seleccion de tipo de precio (corporativo/natural) en la cotizacion | NO | Media |
| Alerta de cotizaciones proximas a vencer sin respuesta | NO | Baja |

---

### B6 -- Precios Diferenciados (Corporativo / Natural / Con Recargo de Personalizacion)

**Lo que pide el Sr. Tito + decision D6:**

**Tres niveles de precio para productos finales:**

| Nivel | Quien aplica | Precio | Condicion |
|-------|-------------|--------|-----------|
| **Natural** | Persona natural (DNI) | `precio_venta` estandar | Por defecto |
| **Corporativo** | Empresa con RUC, desde 5 unidades | `precio_corporativo` (seteado fijo por producto) | Solo clientes con segmento=corporativo |
| **Con recargo de personalizacion** | Cualquier cliente que pide variacion de la receta | Precio base + `recargo_personalizacion` (fijo, no por insumos exactos) | Cuando el `DetalleVenta` tiene `AjustePersonalizacion` |

> **DECISION D6:** El recargo por personalizacion es un cargo fijo que el vendedor define, NO el costo exacto de los insumos cambiados. Sin embargo, el sistema DEBE mostrar el costo estimado de los insumos del ajuste como referencia para que el vendedor pueda decidir cuanto cobrar.

**Reglas del corporativo (textual del Sr. Tito):**
- El corporativo debe estar "seteado" -- no se puede dar a cualquiera que quiera precio bajo.
- Aplica a empresas con RUC (ya existe `tipo_documento = RUC` en `Cliente`).
- Desde 5 unidades en adelante.
- Si una persona natural compra cantidad, puede recibir un **descuento por cantidad**, pero ese no es precio corporativo -- es un descuento.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| `Producto.precio_venta` (un solo precio) | SI | `apps/inventario/models.py` |
| `Producto.precio_compra` (base para calcular margen y costo estimado de ajuste) | SI | `apps/inventario/models.py` |
| `DetalleCotizacion.descuento_porcentaje` | SI | `apps/ventas/models.py` |
| `DetalleVenta.descuento_porcentaje` | SI | `apps/ventas/models.py` |
| `Cliente.segmento` con choices incluyendo `corporativo` | SI | `apps/clientes/models.py` |
| `Cliente.tipo_documento` (DNI="1" vs RUC="6") | SI | `apps/clientes/models.py` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Campo `precio_corporativo` en Producto (nullable, NULL = usar precio_venta normal) | NO | Baja |
| Funcion `resolver_precio(producto, cliente, cantidad)` que retorna el precio correcto | NO | Baja |
| Validacion: solo clientes con segmento `corporativo` + RUC acceden a precio corporativo | NO | Baja |
| Campo `recargo_personalizacion` en `DetalleVenta` (Decimal, default 0 -- D6) | NO | Baja |
| Calculo de costo estimado de ajuste (precio_compra de insumos extra/modificados -- referencia para el vendedor) | NO | Media |
| Modelo `ReglaDescuento` (cantidad_minima, descuento_%, aplica_a_segmento) | NO | Media |
| Aplicacion automatica de descuento por cantidad en POS y cotizaciones | NO | Media |

---

### B7 -- Campanas / Temporadas

**Lo que pide el Sr. Tito:**
- Seccion para gestionar **campanas de descuento temporal** (Dia de la Madre, San Valentin, Aniversarios, etc.).
- Se define: nombre, fechas (inicio/fin), descuento %, y que productos participan.
- El descuento se aplica **automaticamente** en el POS y en cotizaciones durante ese periodo.
- Badge visual en los productos que estan en campana activa.

**Lo que EXISTE:**

| Componente | Estado |
|-----------|--------|
| Seccion `/whatsapp/campanas` en FE | EXISTE pero es de **campanas de mensajeria WhatsApp**, NO de descuentos comerciales -- son cosas distintas |
| Nada en BE para campanas de descuento comercial | NO |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Modelo `Campana` (nombre, fecha_inicio, fecha_fin, descuento_porcentaje, is_active) | NO | Media |
| Relacion M2M `Campana ↔ Producto` (que productos participan) | NO | Baja |
| Funcion `obtener_campanas_activas()` y `aplicar_descuento_campana()` | NO | Media |
| Integracion en `crear_venta_pos()` y `crear_cotizacion()` | NO | Media |
| Vista FE `/ventas/campanas` (CRUD campanas) | NO | Media |
| Badge visual "En campana -X%" en productos en POS y listado | NO | Baja |

---

### B8 -- Ventas Corporativas / Pre-venta

**Lo que pide el Sr. Tito:**
- Registrar empresa como cliente corporativo (con RUC).
- Desde el sistema, enviar catalogo + cotizacion a empresas cercanas (Miraflores, San Isidro).
- Mercado objetivo: funebres, cumpleanos ejecutivos, aniversarios, Dia de la Madre, Dia del Secretario.
- Flujo: Pre-venta (llamada/email) → Cotizacion → Aprobacion gerencia → Venta.
- Mini-CRM: lista de prospectos con estado de seguimiento.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Cliente` con `segmento = corporativo` | SI | `apps/clientes/models.py` |
| Flujo completo: `Cotizacion` → `OrdenVenta` → `Venta` | SI | `apps/ventas/models.py` + `services.py` |
| `cotizacion_origen` en OrdenVenta (trazabilidad) | SI | `apps/ventas/models.py` |
| CRUD clientes con RUC/DNI | SI | `apps/clientes/` |
| FE: Cliente-detalle con tabs (Datos, Historial Ventas, Cotizaciones) | SI (491 lineas) | FE `(users)/cliente-detalle/` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Catalogo exportable (PDF o enlace) para enviar a empresas | NO | Media |
| Envio de cotizacion por email desde el sistema | NO (infraestructura SI existe) | Baja-Media |
| Lista de prospectos con estado (llamar / enviado / negociando / cerrado) | NO | Alta |
| Historial de interacciones con empresa | NO | Alta |
| Alertas de cotizaciones proximas a vencer / sin respuesta | NO | Media |

---

## 4. SEPARACION CRITICA: tipo_registro vs personalizacion vs precio

```
MODELO Producto                    MODELO DetalleVenta
───────────────────                ──────────────────────────────────
tipo_registro                      notas_arreglista (NUEVO -- texto libre)
  insumo_organico    (flor)        recargo_personalizacion (NUEVO -- decimal)
  insumo_no_organico (cinta, base)
  producto_final     (arreglo)     receta_default del producto
                                     └─ se usa siempre que no haya ajustes
RecetaProducto (NUEVO)
  └─ DetalleReceta: insumo+cantidad AjustePersonalizacion (NUEVO, vive en DetalleVenta)
                                       └─ solo existe si el cliente pidio variacion
                                       └─ guarda que insumos cambian y en que cantidad
                                       └─ NO toca la RecetaProducto del Producto

FLUJO POS cuando hay personalizacion:
  1. Vendedor activa "personalizar" en el item del pedido
  2. Sistema muestra receta default del producto
  3. Vendedor ajusta cantidades o agrega insumos nuevos
  4. Sistema calcula costo estimado del ajuste (referencia: precio_compra de insumos)
  5. Vendedor ingresa el recargo que cobrara (campo libre)
  6. Vendedor escribe nota para el arreglista (campo de texto libre)
  7. Se guarda: AjustePersonalizacion + recargo_personalizacion + notas_arreglista
```

---

## 5. HUECO TECNICO RESUELTO: Unificacion Compras → Inventario (D7)

**Situacion actual:**
- `registrar_recepcion()` en `apps/compras/services.py` manipula el stock directamente, SIN llamar a `registrar_entrada()` del inventario
- Esto significa que cuando se recibe una compra, NO se crea un `Lote` nuevo -- el campo `lote` en `DetalleRecepcion` queda NULL si no viene un `lote_id` externo
- Esto rompe el semaforo de frescura: sin `Lote.fecha_entrada`, no hay forma de saber cuantos dias tiene la flor

**Decision (D7): UNIFICAR -- registrar_recepcion() debe llamar a registrar_entrada()**

**Plan de unificacion:**
1. `registrar_recepcion()` llama a `registrar_entrada()` por cada item recibido
2. `registrar_entrada()` crea el `Lote` con `fecha_entrada = date.today()` y `estado_frescura = 'optimo'`
3. El `DetalleRecepcion.lote` queda vinculado al lote creado (ya no NULL)
4. Si la UI envia multiples lotes para un mismo producto en una recepcion (multi-lote D4), se llama a `registrar_entrada()` una vez por cada lote
5. La logica de Stock se mantiene en `registrar_entrada()` (ya existia) -- se elimina la logica duplicada de Compras

**Impacto en tests:** verificar que `registrar_recepcion()` sigue pasando sus tests actuales + nuevos tests de que el lote se crea correctamente.

---

## 6. MAPA DE PRIORIDADES Y DEPENDENCIAS

```
PRIORIDAD 1 (FUNDACIONAL -- base de todo lo demas):
====================================================
  +--------------------------------------------------+
  | B2: tipo_registro + descuenta_insumos            | <-- Campos en Producto
  |     + unidad_compra + factor_conversion          |
  +-------------------------+------------------------+
                            | depende de ^
  +-------------------------v------------------------+
  | B1: fecha_entrada + estado_frescura en Lote      | <-- Campos en Lote
  |     + Task frescura diaria + multi-lote UI       |     + Task + Vista Camara
  +-------------------------+------------------------+
                            | depende de ^
  +-------------------------v------------------------+
  | B3: RecetaProducto + DetalleReceta               | <-- Modelos nuevos
  |     + RecetaEditor en ProductoForm               |     + Logica produccion
  |     + notas_arreglista + recargo_personalizacion |     + Validacion venta
  |     + completar_produccion descuenta insumos     |
  +-------------------------+------------------------+
                            | depende de ^
  +-------------------------v------------------------+
  | B4: Vista Compras Inteligentes                   | <-- Combina B1+B2+B3
  |     + OC pre-llenada + alerta nocturna           |     + compras existente
  +--------------------------------------------------+

PRIORIDAD 2 (COMERCIAL -- para mejorar ventas):
================================================
  +--------------------------------------------------+
  | B6: precio_corporativo en Producto               | <-- Campo en Producto
  |     + ReglaDescuento + resolver_precio()         |     + Modelo nuevo
  |     + costo estimado ajuste como referencia      |
  +-------------------------+------------------------+
                            | depende de ^
  +-------------------------v------------------------+
  | B5: PDF cotizacion + email + aprobacion gerencia | <-- Patron PDF existente
  |     + precio segun segmento en cotizacion        |
  +-------------------------+------------------------+
                            | depende de ^
  +-------------------------v------------------------+
  | B8: Flujo corporativo completo                   | <-- Combina B5+B6
  |     + catalogo + mini-CRM                        |
  +--------------------------------------------------+

PRIORIDAD 3 (MARKETING):
========================
  +--------------------------------------------------+
  | B7: Campanas de descuento temporales             | <-- Independiente
  |     (Dia de la Madre, San Valentin, etc.)        |     se integra con B6 en POS
  +--------------------------------------------------+
```

---

## 7. INVENTARIO COMPLETO DE CAMBIOS EN MODELOS

### 7.1 Campos nuevos en modelos EXISTENTES

```
Modelo Producto (tabla: productos) -- SOLO agregar, NO rompe nada:
  + tipo_registro      CharField  choices(insumo_organico, insumo_no_organico, producto_final)
                                  default='producto_final'  -- todos los existentes quedan igual
  -- NOTA: tipo_registro='insumo_organico' implica perecible directamente.
  -- NO se agrega es_perecible (redundante) ni dias_vida_util (umbrales son fijos: 1-3, 4, 5-7, 8+).
  + descuenta_insumos  BooleanField  default=False
                                  -- False = producto legacy, se vende normal sin descuento de insumos
                                  -- True  = requiere receta activa para vender; al producir descuenta stock
  + precio_corporativo DecimalField  null=True, blank=True
  + unidad_compra      CharField  max_length=50, blank=True, default=''
  + factor_conversion  PositiveIntegerField  default=1

Modelo Lote (tabla: lotes) -- SOLO agregar, NO rompe nada:
  + fecha_entrada      DateField  default=date.today
  + estado_frescura    CharField  choices(optimo, precaucion, funebre, descarte)  default='optimo'

Modelo DetalleVenta (tabla: detalle_ventas) -- SOLO agregar, NO rompe nada:
  + notas_arreglista       TextField  blank=True, default=''
                           -- texto libre para el arreglista (D3)
  + recargo_personalizacion DecimalField  max_digits=12, decimal_places=4  default=0
                           -- cargo extra cuando hay personalizacion (D6)

Modelo Cotizacion (tabla: cotizaciones) -- SOLO agregar:
  + aprobada_por       FK(PerfilUsuario)  null=True, blank=True
  + aprobada_en        DateTimeField  null=True, blank=True
```

### 7.2 Modelos NUEVOS a crear

```python
# === RECETA / BOM ===

class RecetaProducto(Model):
    """Composicion de insumos de un producto final. Se define desde el formulario del producto."""
    producto       = FK(Producto, limit_choices_to={"tipo_registro": "producto_final"})
    nombre         = CharField      # "Estandar", "Version grande"
    es_default     = BooleanField   # La receta que se usa por defecto al armar
    is_active      = BooleanField
    created_at / updated_at

class DetalleReceta(Model):
    """Un insumo dentro de una receta (cuantas rosas, cuanto follaje, etc.)."""
    receta             = FK(RecetaProducto)
    insumo             = FK(Producto, limit_choices_to={"tipo_registro__in": ["insumo_organico", "insumo_no_organico"]})
    cantidad_requerida = DecimalField   # Por unidad de producto final
    es_sustituible     = BooleanField   # Si se puede cambiar al personalizar

class AjustePersonalizacion(Model):
    """
    Variacion de la receta para un pedido especifico. NO toca RecetaProducto.

    Ejemplo: Ramo Primavera tiene 5 rosas rojas por default.
    Cliente quiere 3 rojas + 2 blancas.
    Se crean 2 AjustePersonalizacion para ese DetalleVenta:
      - Rosa Roja:   cantidad_ajuste = 3  (cambia de 5 a 3)
      - Rosa Blanca: cantidad_ajuste = 2  (nuevo insumo que no estaba en la receta)
    La receta default del Ramo Primavera sigue siendo 5 rosas rojas.
    """
    detalle_venta    = FK(DetalleVenta)
    insumo           = FK(Producto)
    cantidad_ajuste  = DecimalField   # Cantidad a usar en este pedido
    es_nuevo         = BooleanField   # True = insumo que no estaba en la receta default

class DetalleVentaInsumo(Model):
    """
    Trazabilidad inmutable: que insumos reales se descontaron al producir.
    Se genera al marcar 'listo' en el Kanban.
    Refleja la receta default + los ajustes de personalizacion aplicados.
    """
    detalle_venta = FK(DetalleVenta)
    insumo        = FK(Producto)
    cantidad      = DecimalField
    lote          = FK(Lote, null=True)   # De que lote se tomo (FIFO)
    # Sin updated_at -- es inmutable (registro de lo que ocurrio)

# === PRECIOS / DESCUENTOS ===

class ReglaDescuento(Model):
    """Descuento automatico por cantidad."""
    nombre                = CharField
    cantidad_minima       = IntegerField     # Desde X unidades
    descuento_porcentaje  = DecimalField
    aplica_a_segmento     = CharField        # null=todos, 'corporativo', 'natural'
    aplica_a_producto     = FK(Producto, null=True)   # null=todos los productos finales
    is_active             = BooleanField

# === CAMPANAS ===

class Campana(Model):
    """Campana de descuento temporal por fechas."""
    nombre                = CharField   # "Dia de la Madre 2026"
    descripcion           = TextField
    fecha_inicio          = DateField
    fecha_fin             = DateField
    descuento_porcentaje  = DecimalField
    is_active             = BooleanField
    productos             = M2M(Producto, limit_choices_to={"tipo_registro": "producto_final"})
```

---

## 8. IMPACTO EN FRONTEND

| Pagina FE | Estado actual | Cambios necesarios |
|-----------|---------------|-------------------|
| `ProductoForm.tsx` (530 lineas) | Funciona | + select `tipo_registro` (3 opciones: organico/no organico/producto final), + checkbox `requiere_lote` (auto-True si tipo=insumo_organico), + inputs `unidad_compra` + `factor_conversion` (visibles si tipo=insumo), + inputs `stock_minimo`/`stock_maximo`, + toggle `descuenta_insumos` (visible si tipo=producto_final), + input `precio_corporativo` (visible si tipo=producto_final), + seccion `RecetaEditor` embebida (SOLO si tipo_registro=producto_final): tabla de insumos con buscador, cantidad, agregar/quitar lineas. Si el producto ya existe y tiene receta, la carga. Guardado opcional -- no bloquea crear el producto |
| `ProductoFormModal.tsx` (466 lineas) | Funciona | + select `tipo_registro` (version simplificada, sin RecetaEditor) |
| `ProductList.tsx` (439 lineas) | Funciona | + filtro por `tipo_registro`, + badge "Organico" para insumos perecibles, + badge "Sin receta" para producto_final sin receta definida |
| `StockOverview.tsx` (371 lineas) | Funciona | + columna "Frescura" en tabla de lotes con badge color (verde/amarillo/rojo/negro), ordenar FIFO (fecha_entrada ASC -- viejo primero) |
| `DashboardInventario.tsx` (268 lineas) | Funciona (parcialmente oculto) | Descomentar `RotacionABC`, + widget "Estado Camara" |
| `CotizacionModal.tsx` (681 lineas) | Funciona | + selector tipo precio (corporativo aplica automatico si cliente=corporativo), + boton "Descargar PDF", + boton "Enviar por Email" |
| `cotizacion-detalle/index.tsx` (390 lineas) | Funciona | + boton "Aprobar" (solo gerente/admin), + boton "Descargar PDF", + boton "Enviar por Email" |
| `cotizaciones/index.tsx` | Funciona | + columna "Aprobada" con check |
| `pedido-pos/index.tsx` (555 lineas) | Funciona | + precio corporativo automatico al seleccionar cliente corporativo, + badge campana en productos, + descuento por cantidad automatico, + bloqueo de producto_final sin receta con mensaje claro |
| `pedido-pos/index.tsx` -- personalizacion | Funciona | + boton "Personalizar" por item: abre panel lateral con receta default del producto, el vendedor ajusta cantidades o agrega insumos, el sistema muestra costo estimado del ajuste (referencia), el vendedor ingresa el recargo que cobrara, campo de texto libre "nota para el arreglista" |
| Kanban Produccion (distribucion) | Funciona | Al hacer "Listo", llamar endpoint que: (1) toma la receta default, (2) aplica ajustes si los hay, (3) descuenta los insumos resultantes del stock via FIFO |
| **`EstadoCamara.tsx`** | NO EXISTE | CREAR: tabla de insumos organicos con semaforo frescura, ordenados FIFO (viejo primero), contadores por estado, filtros por almacen |
| **`RecetaEditor.tsx`** | NO EXISTE | CREAR: editor de receta DEFAULT del producto, embebido en ProductoForm. Buscador de insumos, campo cantidad, agregar/quitar lineas. Carga receta existente si la hay |
| **`ListaCompras.tsx`** | NO EXISTE | CREAR: vista unificada con sub-filtros, boton "Generar OC" pre-llenada |
| **`CampanasList.tsx`** | NO EXISTE | CREAR: CRUD campanas con selector de productos y fechas |

---

## 9. IMPACTO EN TESTS

**Tests existentes (18 tests de inventario):** NO se rompen. Todos los cambios son aditivos.

**Tests nuevos necesarios:**

```
tests/test_frescura_services.py
  - test_lote_optimo_dias_1_a_3
  - test_lote_precaucion_dia_4
  - test_lote_funebre_dia_5_a_7
  - test_lote_descarte_dia_8_mas
  - test_no_afecta_insumos_no_perecibles
  - test_no_afecta_productos_finales
  - test_estado_camara_retorna_lotes_ordenados_fifo

tests/test_receta_services.py
  - test_crear_receta_con_insumos
  - test_calcular_costo_receta
  - test_completar_produccion_descuenta_receta_default
  - test_completar_produccion_sin_receta_no_descuenta (comportamiento legacy OK)
  - test_completar_produccion_con_ajustes_descuenta_ajustado
    # receta default: 5 rosas rojas
    # ajuste: 3 rojas + 2 blancas
    # debe descontar: 3 rojas + 2 blancas (NO 5 rojas)
    # la receta default del producto NO cambia
  - test_ajuste_no_modifica_receta_default_del_producto
  - test_verificar_disponibilidad_insumos_suficientes
  - test_verificar_disponibilidad_insumos_insuficientes
  - test_notas_arreglista_se_guardan_en_detalle_venta
  - test_recargo_personalizacion_suma_al_total
  - test_costo_estimado_ajuste_calcula_precio_compra_insumos

tests/test_venta_validaciones.py
  - test_crear_venta_pos_bloquea_producto_final_sin_receta
  - test_crear_venta_pos_permite_producto_final_con_receta
  - test_crear_venta_pos_permite_insumo_sin_receta (los insumos no necesitan receta)

tests/test_recepcion_con_lotes.py
  - test_registrar_recepcion_crea_lote_con_fecha_entrada
  - test_registrar_recepcion_multi_lote_mismo_producto
  - test_registrar_recepcion_sin_oc_tambien_crea_lote

tests/test_precios_services.py
  - test_resolver_precio_cliente_natural
  - test_resolver_precio_cliente_corporativo_con_precio_seteado
  - test_resolver_precio_corporativo_sin_precio_seteado_usa_normal
  - test_descuento_por_cantidad_aplica
  - test_descuento_por_cantidad_no_aplica_bajo_minimo
  - test_costo_estimado_ajuste_referencia_vendedor

tests/test_campana_services.py
  - test_campana_activa_aplica_descuento
  - test_campana_fuera_de_fecha_no_aplica
  - test_campana_inactiva_no_aplica
```

---

## 10. RESUMEN EJECUTIVO

| Bloque | % Que ya existe | % Que falta | Esfuerzo |
|--------|----------------|-------------|----------|
| B1 -- Control Camara | ~30% (FIFO + lotes + tasks) | ~70% (fecha_entrada, estado_frescura, vista camara, FIFO visual, **multi-lote UI**) | Medio-Alto |
| B2 -- Organico/No Organico + Paquetes | ~15% (Producto + requiere_lote) | ~85% (tipo_registro, descuenta_insumos, unidad_compra, factor_conversion) | Bajo-Medio |
| B3 -- Receta/BOM | ~10% (Kanban produccion + registrar_salida) | ~90% (RecetaProducto, DetalleReceta, **RecetaEditor en ProductoForm**, notas_arreglista, recargo_personalizacion, completar_produccion, **validacion venta**) | Alto |
| B4 -- Alertas + Compras | ~50% (alertas + rotacion + modulo compras) | ~50% (vista unificada, sub-filtros, OC pre-llenada, alerta nocturna) | Medio |
| B5 -- Cotizaciones | ~75% (CRUD + patron PDF + email infra) | ~25% (PDF cotizacion, email, aprobacion gerencia) | Medio-Bajo |
| B6 -- Precios diferenciados | ~20% (segmento corporativo, descuento %) | ~80% (precio_corporativo, recargo_personalizacion, ReglaDescuento, resolver_precio, **costo estimado ajuste**) | Medio |
| B7 -- Campanas | ~0% | ~100% (todo nuevo) | Medio |
| B8 -- Ventas Corporativas | ~45% (flujo cot→OV→venta + cliente-detalle) | ~55% (catalogo, email cot, CRM basico) | Medio |

### Orden de implementacion recomendado:

1. **Fase 1 -- Fundacion** (B2 + B1): tipo_registro + descuenta_insumos + unidad_compra + fecha_entrada + estado_frescura + vista Camara + **multi-lote en recepcion** + unificacion Compras→Inventario
2. **Fase 2 -- BOM** (B3): RecetaProducto + DetalleReceta + **RecetaEditor en ProductoForm** + notas_arreglista + recargo_personalizacion + completar_produccion descuenta insumos + **validacion venta**
3. **Fase 3 -- Alertas** (B4): Vista unificada Compras Inteligentes + OC pre-llenada + alerta nocturna
4. **Fase 4 -- Precios** (B6): precio_corporativo + ReglaDescuento + resolver_precio + **costo estimado ajuste**
5. **Fase 5 -- Cotizaciones** (B5 + B8): PDF + email + aprobacion gerencia + flujo corporativo
6. **Fase 6 -- Campanas** (B7): CRUD campanas + integracion POS

---

> **NOTA:** Este documento es diagnostico puro. No se ha implementado ni modificado ningun archivo de codigo. Cada fase debe comenzar con tests (TDD) siguiendo el patron existente (`tests/factories.py` → `tests/test_*_services.py` → `services.py` → `serializers.py` → `views.py` → FE).
> **VERSION:** v4 -- todas las preguntas pendientes resueltas -- listo para implementacion.
