# RESUMEN DE IMPACTO -- Que se afecta, mejora y potencia (v4)

> **Fecha:** 2026-03-02 (actualizado 2026-03-02 v4 -- decisiones finales incorporadas)
>
> **Glosario:**
> - **Insumo**: materia prima (rosa, girasol, clavel, follaje, cinta, base). Tiene stock. Puede ser organico (perecible) o no organico (duradero).
> - **Producto Final**: el arreglo floral terminado que se vende al cliente. Esta compuesto de insumos.
> - **tipo_registro**: campo que dice QUE ES el item (insumo_organico / insumo_no_organico / producto_final).
> - **Receta default**: composicion permanente del producto final (5 rosas, 3 follajes, 1 envoltorio). Nunca se toca por un pedido. Se define en el formulario del producto.
> - **AjustePersonalizacion**: variacion de la receta para un pedido especifico. Vive en el DetalleVenta. La receta default del producto permanece intacta.
> - **notas_arreglista**: campo de texto libre en DetalleVenta para instrucciones especificas al arreglista.
> - **recargo_personalizacion**: cargo extra (monto fijo) en DetalleVenta cuando hay personalizacion. El vendedor lo define. NO es el costo exacto de los insumos.
> - **Lote mezclado**: cuando en una misma compra hay flores de distintas fechas, se registran como lotes separados para que el semaforo de frescura sea exacto. Ocurre varias veces por semana.
> - **NO existe tipo_venta_producto**: la personalizacion no es un tipo de producto, es informacion del pedido.

---

## 1. QUE SE AFECTA (sin romper nada)

### Base de Datos

**Columnas nuevas en tablas existentes:**

| Tabla | Columna nueva | Tipo | Default seguro | Impacto en datos actuales |
|-------|--------------|------|----------------|--------------------------|
| `productos` | `tipo_registro` | VARCHAR(20) | `'producto_final'` | Cero. Todos los registros existentes quedan como producto_final. |
| `productos` | `descuenta_insumos` | BOOLEAN | `FALSE` | Cero. Productos legacy no cambian comportamiento. Solo se activa manualmente cuando se define receta. |
| `productos` | `unidad_compra` | VARCHAR(50) | `''` | Cero. Vacio = no tiene unidad de compra especial. |
| `productos` | `factor_conversion` | INTEGER | `1` | Cero. 1 = 1 unidad de compra = 1 unidad de stock (comportamiento actual). |
| `productos` | `precio_corporativo` | DECIMAL | `NULL` | Cero. NULL = usar precio_venta normal siempre. |
| `lotes` | `fecha_entrada` | DATE | `CURRENT_DATE` | Cero. Los lotes existentes quedan con la fecha de hoy. |
| `lotes` | `estado_frescura` | VARCHAR(20) | `'optimo'` | Cero. Todos los lotes existentes quedan como optimo. |
| `detalle_ventas` | `notas_arreglista` | TEXT | `''` | Cero. Las ventas existentes quedan sin nota. |
| `detalle_ventas` | `recargo_personalizacion` | DECIMAL | `0` | Cero. Las ventas existentes quedan con recargo=0. |
| `cotizaciones` | `aprobada_por_id` | UUID FK | `NULL` | Cero. Las cotizaciones existentes quedan sin aprobador. |
| `cotizaciones` | `aprobada_en` | TIMESTAMPTZ | `NULL` | Cero. |

**ELIMINADOS del plan (D8):** `es_perecible` (redundante -- `tipo_registro='insumo_organico'` ya implica perecible) y `dias_vida_util` (umbrales del semaforo son fijos: 1-3, 4, 5-7, 8+).

**Total columnas nuevas en tablas existentes: 11 columnas en 4 tablas.**

**Tablas completamente nuevas (no tocan nada existente):**

| Tabla nueva | Que almacena | Fase |
|-------------|-------------|------|
| `receta_producto` | Composicion default de cada producto final (permanente, no se toca por pedidos) | F2 |
| `detalle_receta` | Lineas de receta: insumo + cantidad por unidad de producto | F2 |
| `ajuste_personalizacion` | Variaciones de receta para un pedido especifico (vive en DetalleVenta, no toca el producto) | F2 |
| `detalle_venta_insumo` | Trazabilidad inmutable: insumos reales descontados al producir (receta + ajustes aplicados) | F2 |
| `regla_descuento` | Reglas de descuento automatico por cantidad o segmento | F4 |
| `campana` | Campanas de descuento temporal (Dia de la Madre, San Valentin, etc.) | F6 |
| `campana_producto` | Que productos finales participan en cada campana (M2M) | F6 |

**Total DB: 11 columnas nuevas en 4 tablas existentes + 7 tablas nuevas.**
**Cero datos existentes se modifican, eliminan o pierden.**
**Los productos reales que ya existen en la DB no se ven afectados.**

---

### Backend (Django)

Todos los cambios son **aditivos**: funciones nuevas, campos nuevos con defaults, modelos nuevos.

La modificacion mas importante en logica existente:
- `completar_produccion_item()`: solo aplica si hay receta. Sin receta = comportamiento actual sin cambio.
- `crear_venta_pos()`: nueva validacion que bloquea producto_final sin receta (con mensaje claro).
- `registrar_recepcion()`: se unifica con `registrar_entrada()` para crear lotes correctamente (D7).

| Archivo | Tipo de cambio | Se rompe algo? |
|---------|---------------|----------------|
| `core/choices.py` | +2 grupos de constantes: `TIPO_REGISTRO_CHOICES`, `ESTADO_FRESCURA_CHOICES` | NO |
| `apps/inventario/models.py` | +6 campos en Producto, +2 campos en Lote, +3 modelos nuevos (RecetaProducto, DetalleReceta, ReglaDescuento) | NO (campos con default) |
| `apps/inventario/services.py` | +6 funciones nuevas (actualizar_estados_frescura, obtener_estado_camara, funciones de receta, calcular_costo_estimado_ajuste, generar_lista_compras) | NO |
| `apps/inventario/serializers.py` | +campos opcionales en serializers existentes, +serializers nuevos | NO |
| `apps/inventario/views.py` | +4 vistas nuevas (EstadoCamara, Recetas, ListaCompras, ReglaDescuento) | NO |
| `apps/inventario/urls.py` | +3 rutas nuevas | NO |
| `apps/inventario/tasks.py` | +2 tasks Celery nuevas (actualizar_frescura_diaria, alerta_compras_nocturna) | NO |
| `apps/compras/services.py` | Unificacion: `registrar_recepcion()` llama a `registrar_entrada()`. Soporte multi-lote. | MINIMO: tests de recepcion deben verificarse |
| `apps/ventas/models.py` | +2 campos en DetalleVenta (notas_arreglista, recargo_personalizacion), +4 modelos nuevos (AjustePersonalizacion, DetalleVentaInsumo, Campana, CampanaProducto), +2 campos en Cotizacion | NO |
| `apps/ventas/services.py` | +5 funciones nuevas (completar_produccion_item, resolver_precio, generar_cotizacion_pdf, enviar_cotizacion_email, aprobar_cotizacion, campanas). +validacion en crear_venta_pos() | MINIMO: nueva validacion de receta |
| `apps/ventas/views.py` | +actions en CotizacionViewSet (pdf, email, aprobar), +CampanaViewSet | NO |
| `apps/ventas/serializers.py` | +CampanaSerializer | NO |
| `apps/ventas/urls.py` | +1 ruta nueva (campanas) | NO |

**Tests existentes (18 tests de inventario):** NO se rompen.

---

### Frontend (React/TypeScript)

| Archivo | Tipo de cambio | Se rompe algo? |
|---------|---------------|----------------|
| `ProductoForm.tsx` (530 lineas) | +select `tipo_registro` (3 opciones: organico/no organico/producto final), +checkbox `requiere_lote` (auto-True si tipo=insumo_organico), +inputs `unidad_compra`+`factor_conversion` (visibles si tipo=insumo), +input `stock_minimo`/`stock_maximo`, +toggle `descuenta_insumos` (visible si tipo=producto_final), +input `precio_corporativo` (visible si tipo=producto_final), +seccion **RecetaEditor embebida** (buscador de insumos, cantidades, agregar/quitar lineas -- solo si tipo=producto_final) | NO |
| `ProductoFormModal.tsx` (466 lineas) | +select tipo_registro basico | NO |
| `ProductList.tsx` (439 lineas) | +filtro por tipo_registro, +badge "Organico", +badge "Sin receta" en producto_final sin receta | NO |
| `StockOverview.tsx` (371 lineas) | +columna "Frescura" con badge de color en tabla de lotes, ordenar FIFO | NO |
| `DashboardInventario.tsx` (268 lineas) | Descomentar RotacionABC (ya existia), +widget Estado Camara | NO |
| `pedido-pos/index.tsx` (555 lineas) | +precio corporativo automatico, +badge campana, +descuento cantidad automatico, +boton "Personalizar" por item (ajustes + nota libre + recargo), +bloqueo producto_final sin receta | NO |
| `CotizacionModal.tsx` (681 lineas) | +precio segun segmento de cliente | NO |
| `cotizacion-detalle/index.tsx` (390 lineas) | +boton PDF, +boton Email, +boton Aprobar | NO |
| `cotizaciones/index.tsx` | +columna "Aprobada" | NO |
| UI recepcion de compras | +soporte multi-lote por item (frecuente -- varias veces/semana) | NO |

---

## 2. QUE MEJORA

### Para el Sr. Tito (dueno / gerente)

| Problema actual | Solucion |
|----------------|----------|
| No sabe el estado real de sus flores en la camara | Vista "Control de Camara": tabla con semaforo verde/amarillo/rojo/negro por dias de frescura, ordenado FIFO (lo mas viejo arriba) |
| La empleada dice "esta bien" pero no hay datos | El sistema dice: "lote rosa roja -- 4 dias -- PRECAUCION" basado en la fecha de entrada real |
| Pierde insumos porque no los usa a tiempo | Alerta automatica diaria: "X lotes pasaron a funebre, usarlos para funebres o descartar" |
| No sabe el costo real de un arreglo | Cada producto final tiene su receta con costo de insumos calculado automaticamente |
| Un solo precio para todos | Precio persona natural vs corporativo se aplica automaticamente segun el cliente |
| Cotizaciones sin PDF ni correo | PDF profesional + envio por email con un click desde el sistema |
| Gerencia no puede aprobar cotizaciones formalmente | Boton "Aprobar" para que el Sr. Tito de el visto bueno antes de enviar al cliente |
| Sin campanas de descuento por temporada | Seccion campanas: define productos, fechas y descuento. Se aplica solo en POS y cotizaciones |

### Para Yolanda (compras)

| Antes | Despues |
|-------|---------|
| Va al mayorista sin saber exactamente que falta | Vista "Compras Inteligentes" con lista de insumos a reponer, ordenada por urgencia |
| Pide de mas por si acaso (genera merma) | Ve exactamente cuanto hay vs cuanto se necesita segun ventas recientes y recetas |
| No puede generar un pedido formal desde el sistema | Boton "Generar OC" crea un borrador de Orden de Compra pre-llenado con los items y cantidades |
| No sabe que flores estan a punto de mermarse | Sub-filtro "Perecibles fuera de uso" muestra exactamente que hay que reemplazar |
| Recibe informacion de noche para llamar al mayorista | Alerta nocturna automatica (task Celery) le envia la lista antes de hacer el pedido |
| Al registrar flores de distintas fechas en una compra, se perdia la informacion de frescura | Multi-lote en recepcion: puede registrar 2 lotes del mismo insumo con fechas distintas |

### Para el arreglista (produccion)

| Antes | Despues |
|-------|---------|
| Al marcar "Listo" en el Kanban no pasa nada en inventario | Al marcar "Listo", se descuentan automaticamente los insumos de la receta del stock |
| No hay trazabilidad de que insumos se usaron | Queda registro de que lote de que insumo se uso en que venta |
| No sabe si hay personalizacion en el pedido | Ve las notas del arreglista y los ajustes de insumos directamente en el Kanban |

### Para la vendedora (POS)

| Antes | Despues |
|-------|---------|
| Tiene que recordar el precio corporativo | El precio corporativo aparece automatico al seleccionar cliente corporativo |
| No sabe si hay descuento de campana vigente | Los productos en campana muestran badge con el descuento aplicado |
| Calcula descuentos manualmente | Las reglas de descuento por cantidad se aplican automaticamente |
| Al personalizar un arreglo, no tiene referencia del costo extra | El sistema muestra el costo estimado del ajuste (referencia) para que decida cuanto cobrar |
| No puede dejar instrucciones especificas para el arreglista | Campo "nota para el arreglista" disponible por cada item del pedido |

### Para Yamile (cotizaciones)

| Antes | Despues |
|-------|---------|
| Crea cotizacion en el sistema pero la manda por WhatsApp manualmente | Boton "Enviar por email" envia PDF profesional al email del cliente desde el sistema |
| No hay PDF formal de cotizacion | PDF con logo Amatista, datos del cliente, productos, precios, condiciones, fechas de validez |
| Precio corporativo se define a ojo | El sistema carga el precio corporativo automaticamente segun el segmento del cliente |

---

## 3. QUE SE POTENCIA (capacidades nuevas)

**1. Control de Camara (B1 + B2)**
- Seccion nueva: `/inventario/camara`
- Semaforo visual: verde (1-3 dias) / amarillo (4 dias) / rojo (5-7 dias) / negro (8+ dias)
- Alertas automaticas diarias via Celery (task nocturna)
- FIFO visual: lo mas viejo siempre aparece primero
- Unidad de compra: registrar "1 caja de 100 tallos" y el stock sube en 100
- **Multi-lote en recepcion**: dividir una compra en lotes con fechas distintas (soportado desde el inicio)

**2. Recetas / BOM (B3)**
- Receta definida directamente desde el formulario del producto (crear o editar)
- Si un producto no tiene receta: puede crearse y editarse, pero no puede venderse
- Al producir: descuento automatico de insumos via FIFO
- Calculo automatico del costo de cada arreglo
- Trazabilidad: que lote de rosa se uso en que venta
- Personalizacion: nota libre para el arreglista + recargo definido por el vendedor + costo estimado del ajuste como referencia

**3. Compras Inteligentes (B4)**
- Sub-filtros: perecibles fuera de uso / stock bajo / alta rotacion / baja rotacion
- Generacion de OC pre-llenada en un click (conecta con modulo de compras existente)
- Alerta nocturna automatica para que Yolanda tenga la lista antes de llamar al mayorista

**4. Precios Diferenciados (B6)**
- `precio_corporativo` por producto (opcional, nullable)
- `recargo_personalizacion` en DetalleVenta (cargo fijo por personalizar, lo define el vendedor)
- `calcular_costo_estimado_ajuste()` como referencia para el vendedor
- `ReglaDescuento` configurable sin tocar codigo
- `resolver_precio()` aplica la logica correcta automaticamente en POS y cotizaciones

**5. Cotizaciones Profesionales (B5 + B8)**
- PDF generado con ReportLab (patron ya existe en PDF de venta, se adapta)
- Envio por email (infraestructura ya existe en comprobantes electronicos, se reutiliza)
- Flujo de aprobacion gerencia: borrador → aprobada → enviada al cliente

**6. Campanas (B7)**
- Seccion nueva: `/ventas/campanas`
- CRUD de campanas con productos seleccionados y fechas
- Descuento automatico en POS y cotizaciones durante el periodo de campana
- Badge visual en productos participantes

---

## 4. NUMEROS FINALES (v4)

| Metrica | Cantidad |
|---------|----------|
| Columnas nuevas en tablas existentes | 11 (en 4 tablas: productos, lotes, detalle_ventas, cotizaciones) |
| Tablas nuevas en DB | 7 (receta_producto, detalle_receta, ajuste_personalizacion, detalle_venta_insumo, regla_descuento, campana, campana_producto) |
| Migraciones Django | 12 grupos |
| Archivos BE nuevos | 6 (archivos de test) |
| Archivos BE modificados | 13 |
| Archivos FE nuevos | 4 (EstadoCamara, RecetaEditor, ListaCompras, CampanasList) |
| Archivos FE modificados | 10 |
| Tests nuevos | ~35 |
| Tests existentes que se rompen | 0 |
| Datos existentes que se pierden | 0 |
| Endpoints BE nuevos | ~14 |
| Rutas FE nuevas | 3 (/inventario/camara, /inventario/compras-inteligentes, /ventas/campanas) |
| Fases de implementacion | 6 |

---

## 5. MAPA VISUAL DE CAMBIOS POR MODULO

```
INVENTARIO
  Modelo Producto (tabla: productos)
    + tipo_registro: insumo_organico / insumo_no_organico / producto_final   <-- NUEVO
    + descuenta_insumos (default False -- migracion gradual legacy->receta)  <-- NUEVO
    + unidad_compra (ej: 'caja')                                              <-- NUEVO
    + factor_conversion (ej: 100 tallos por caja)                            <-- NUEVO
    + precio_corporativo (nullable)                                           <-- NUEVO
    NOTA: es_perecible y dias_vida_util ELIMINADOS (D8 -- redundantes/innecesarios)
    + RecetaProducto (modelo nuevo, editado desde ProductoForm)               <-- NUEVO
      + DetalleReceta: insumo + cantidad_requerida                            <-- NUEVO
    + ReglaDescuento (modelo nuevo)                                           <-- NUEVO
    NOTA: insumos organicos ya tienen requiere_lote=True -- no hay que migrar ese campo

  Modelo Lote (tabla: lotes)
    + fecha_entrada (cuando entro a la camara)                               <-- NUEVO
    + estado_frescura: optimo/precaucion/funebre/descarte                    <-- NUEVO

  Vista "Control de Camara"  /inventario/camara                              <-- NUEVA
  Vista "Compras Inteligentes"  /inventario/compras-inteligentes             <-- NUEVA
  Task: actualizar_frescura_diaria (00:00 cada dia)                          <-- NUEVA
  Task: alerta_compras_nocturna (20:00 para Yolanda)                         <-- NUEVA

COMPRAS (modulo existente)
  registrar_recepcion() → ahora llama a registrar_entrada()                  <-- UNIFICADO
  Soporte multi-lote en UI de recepcion (frecuente -- varias veces/semana)   <-- NUEVO

VENTAS
  Modelo DetalleVenta (existente)
    + notas_arreglista (texto libre para el arreglista)                       <-- NUEVO
    + recargo_personalizacion (cargo extra por personalizar -- lo define vendedor) <-- NUEVO
    + AjustePersonalizacion (modelo nuevo): variacion de receta por pedido    <-- NUEVO
      (la receta default del Producto NO se toca)
    + DetalleVentaInsumo (modelo nuevo): trazabilidad insumos consumidos      <-- NUEVO
  
  crear_venta_pos()
    + Validacion: producto_final sin receta → rechaza con mensaje claro        <-- NUEVO

  Modelo Cotizacion (existente)
    + aprobada_por (FK usuario gerente)                                       <-- NUEVO
    + aprobada_en (timestamp)                                                 <-- NUEVO
    + Boton PDF en cotizacion-detalle                                         <-- NUEVO
    + Boton Enviar Email en cotizacion-detalle                                <-- NUEVO
    + Boton Aprobar en cotizacion-detalle (solo gerente/admin)                <-- NUEVO
    + Precio automatico segun segmento cliente                                <-- NUEVO

  POS (existente)
    + Precio corporativo automatico al seleccionar cliente empresa            <-- NUEVO
    + Badge campana en productos                                              <-- NUEVO
    + Descuento por cantidad automatico                                       <-- NUEVO
    + Boton "Personalizar" por item: ajustes + nota libre + recargo           <-- NUEVO
    + Bloqueo de producto_final sin receta con mensaje                        <-- NUEVO

  Modelo Campana (nuevo)                                                      <-- NUEVO
  Vista Campanas  /ventas/campanas                                            <-- NUEVA

PRODUCCION (Kanban existente)
  Al marcar "Listo"
    + Descuenta insumos via receta del producto (si tiene receta)            <-- NUEVO
    + Aplica AjustePersonalizacion si los hay (sin tocar la receta default)  <-- NUEVO
    + Registra DetalleVentaInsumo (trazabilidad)                             <-- NUEVO
    + Sin receta: comportamiento actual (no cambia nada)                     <-- SIN CAMBIO
```
