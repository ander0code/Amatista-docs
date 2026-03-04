# AMATISTA ERP — MODULOS DEL SISTEMA

> Estado real de los modulos (Mar 2026).
> Verificado contra el codigo fuente de Amatista-be/ y Amatista-fe/.
> **Modelo de negocio:** Produccion bajo pedido. `crear_venta_pos()` NO descuenta stock.
> El descuento de insumos ocurre al marcar "listo" en Kanban via `completar_produccion_item()`.

---

## Estado por Modulo

| Modulo | Backend | Frontend | Promedio |
|--------|:-------:|:--------:|:-------:|
| 1. Ventas / POS | ~90% | ~75% | ~83% |
| 2. Inventario + Control Camara | ~90% | ~80% | ~85% |
| 3. BOM / Recetas + Produccion | ~90% | ~70% | ~80% |
| 4. Facturacion Electronica | ~87% | ~85% | ~86% |
| 5. Distribucion y Seguimiento | ~85% | ~80% | ~83% |
| 6. Compras y Proveedores | ~85% | ~80% | ~83% |
| 7. Gestion Financiera | ~88% | ~85% | ~87% |
| 8. WhatsApp | ~45% | ~65% | ~55% |
| 9. Dashboard y Reportes | ~90% | ~95% | ~93% |
| 10. Usuarios y Roles | ~95% | ~95% | ~95% |
| 11. E-commerce (Tienda Web) | 0% | UI only | ~5% |

---

## MODULO 1 — Ventas / POS

### Backend Implementado
- Venta POS con multiples metodos de pago (efectivo, tarjeta, transferencia, yape_plin, credito, mixto)
- `crear_venta_pos()` con `@transaction.atomic` — **NO descuenta stock** (linea 523: "Stock no gestionado — negocio produce bajo pedido")
- Si `descuenta_insumos=True`, valida que el producto tenga receta activa (pero no descuenta nada al vender)
- Apertura y cierre de caja con arqueo
- CRUD clientes con validacion RUC/DNI
- Cotizaciones: CRUD, duplicar, convertir a OV, aprobar (`aprobar_cotizacion()` existe)
- Ordenes de venta con conversion a venta
- Anulacion de venta con reversion
- Emision automatica de comprobante post-venta (via Celery `transaction.on_commit`)
- Validacion limite de credito vs CxC pendientes
- `tipo_venta`: directa | online | campo (campo en DB, `online` reservado para e-commerce)
- Kanban de produccion por item: `DetalleVenta.estado_produccion` (pendiente/armando/listo)
- Campos `notas_arreglista` y `recargo_personalizacion` en DetalleVenta (existen en DB)
- `resolver_precio()` con soporte para `precio_corporativo` y `ReglaDescuento`
- Campanas: `obtener_campanas_activas()`, `aplicar_descuento_campana()`, `crear_campana()`, `actualizar_campana()`
- Generacion PDF de venta y cotizacion (`generar_resumen_venta_pdf()`, `generar_cotizacion_pdf()`)
- Envio cotizacion por email (`enviar_cotizacion_email()`)
- Sincronizacion ventas offline (`sincronizar_ventas_offline()`)

### Frontend Implementado
- POS completo: panel productos + carrito
- Busqueda por nombre/SKU + scanner codigo de barras
- Modal apertura/cierre caja con arqueo
- Metodos de pago diferenciados, pago mixto, vuelto automatico
- Cotizaciones: wizard 4 pasos, badges estado, duplicar/convertir
- Ordenes de venta
- Kanban de produccion (distribucion) con columnas pendiente/armando/listo

### Pendiente
- Panel "Personalizar" por item en POS (campos existen en BE, UI del panel no construida)
- Badge "Precio Corp." en POS cuando aplica precio diferenciado
- Badge "Campana -X%" en productos con descuento activo
- Sin Service Worker ni IndexedDB para modo offline real

---

## MODULO 2 — Inventario + Control de Camara

### Backend Implementado
- Stock en tiempo real por producto y almacen
- Entradas, salidas (FIFO), transferencias, ajustes manuales
- Transferencias: flujo 3 pasos (crear → aprobar → confirmar recepcion)
- Trazabilidad por lote
- Alertas stock minimo (task Celery `verificar_stock_minimo`)
- Rotacion ABC (`calcular_rotacion_abc()`)
- Dashboard inventario (`dashboard_inventario()`)
- **Campos Fase 1 YA en DB:** `tipo_registro`, `descuenta_insumos`, `unidad_compra`, `factor_conversion` en Producto (migracion `0006`)
- **Campos Fase 1 YA en DB:** `fecha_entrada`, `estado_frescura` en Lote (migracion `0006`)
- `actualizar_estados_frescura()` — task diaria 00:00 (existe en `tasks.py`)
- `obtener_estado_camara()` — endpoint `GET /inventario/camara/` (existe en views)
- `registrar_salida()` con FIFO automatico por `fecha_vencimiento, created_at`
- `seleccionar_lotes_fifo()` — sugiere lotes FIFO para un producto
- `alertar_lotes_por_vencer` — task diaria 7:00
- Series y ubicaciones de almacen
- `generar_lista_compras()` y `generar_oc_desde_lista_compras()` (Fase 3 implementada en BE)
- Task `alerta_compras_nocturna` a las 20:00

### Frontend Implementado
- Vista stock con semaforo verde/amarillo/rojo + filtros
- Formularios entrada, salida, transferencia, ajuste
- Trazabilidad por lote
- Dashboard inventario con KPIs
- CRUD productos con campos `tipo_registro`, `descuenta_insumos`, etc.
- Vista "Control de Camara" (`/inventario/camara`) con tabla FIFO y semaforo de frescura
- Widget "Estado Camara" en DashboardInventario (link a `/inventario/camara`)

### Pendiente
- Verificar si UI multi-lote en recepcion de compras esta completa
- Verificar si columna "Frescura" con badge color aparece en tabla de lotes general

---

## MODULO 3 — BOM / Recetas + Produccion

> Modulo especifico de floreria. **Backend completamente implementado.**
> Frontend mayormente implementado pero con la llamada a descuento de insumos SUSPENDIDA.

### Backend Implementado
- **Tablas YA en DB** (migracion `0007` + `0011`):
  - `receta_producto` — FK a Producto, `es_default`, `is_active`
  - `detalle_receta` — FK a receta + FK a insumo, `cantidad_requerida`, `es_sustituible`
  - `ajuste_personalizacion` — FK a DetalleVenta, ajustes por item
  - `detalle_venta_insumo` — inmutable, trazabilidad de produccion
- `RecetaViewSet` completo: CRUD + `verificar_disponibilidad` + `calcular_costo_ajuste`
- `crear_receta()` en services — crea receta con detalles
- `obtener_receta_default()` — obtiene receta default de un producto
- `verificar_disponibilidad_insumos()` — verifica si hay stock para producir
- `calcular_costo_receta()` — calcula costo total de la receta
- `calcular_costo_estimado_ajuste()` — referencia de costo con personalizacion
- `completar_produccion_item()` — **EXISTE y FUNCIONA**: al marcar "listo", descuenta insumos via FIFO, crea DetalleVentaInsumo inmutable
- Validacion en `crear_venta_pos()`: si `descuenta_insumos=True` y no hay receta activa → error
- Endpoint `POST /inventario/detalle-ventas/{detalle_id}/completar/` registrado en URLs

### Frontend Implementado
- `RecetaEditor.tsx` — editor de receta embebido en ficha del producto (existe, funcional)
- Kanban de produccion con columnas pendiente/armando/listo
- Boton "Marcar como listo" en Kanban (existe con dialogo de confirmacion)
- Tipos/modelos de API generados por Orval (recetaCreate, detalleReceta, completarProduccion, etc.)

### Pendiente / Parcial
- **Llamada a `completarProduccion` en FE esta COMENTADA/SUSPENDIDA** — El Kanban mueve el estado via endpoint de distribucion `avanzar`, pero NO llama al endpoint de inventario `completar` que descuenta insumos. El codigo esta comentado en el frontend.
- Panel "Personalizar" en POS por item (campos existen en BE, UI no construida)

---

## MODULO 4 — Facturacion Electronica

### Backend Implementado
- Integracion real con Nubefact OSE via HTTP POST
- Correlativo atomico con `select_for_update()`
- Facturas (01), boletas (03), notas de credito (07), debito (08)
- XML firmado y CDR guardados en Cloudflare R2
- Log inmutable de cada intento de envio
- Max reintentos, modo contingencia
- Reenvio manual individual y masivo
- Prevencion doble-emision: `unique_together` (serie, numero)
- Task `reenviar_comprobantes_pendientes` (cada 5 min)
- Task `enviar_resumen_diario_boletas` (23:50)
- DEMO VERIFICADO: comprobante aceptado por Nubefact OSE

### Frontend Implementado
- Formulario emision manual
- Badges estado SUNAT en tiempo real via WebSocket
- Lista con filtros
- Detalle con PDF, XML, CDR descargables
- Reenvio manual
- Banner ContingenciaBanner

---

## MODULO 5 — Distribucion y Seguimiento

### Backend Implementado
- Pedidos: maquina de estados PENDIENTE → CONFIRMADO → DESPACHADO → EN_RUTA → ENTREGADO / CANCELADO / NO_ENTREGADO / REPROGRAMADO
- Asignacion transportista con validacion `limite_pedidos_diario`
- Codigo seguimiento UUID corto (8 chars)
- Endpoint publico sin auth: `GET /publico/seguimiento/{codigo}/`
- Registro evidencias: foto, firma, OTP via MediaArchivo
- Consumer WebSocket GPSConsumer: coordenadas en tiempo real
- `estado_produccion` por pedido: pendiente → armando → listo (Kanban)

### Frontend Implementado
- Lista pedidos con estados y filtros
- Detalle pedido con timeline de eventos
- Kanban de produccion (tarjetas por estado)
- Modal asignacion transportista
- Modal evidencia entrega
- Seguimiento publico (URL sin login)

### Pendiente
- Mapa visual con iconos de transportistas
- Vista movil dedicada para conductor

---

## MODULO 6 — Compras y Proveedores

### Backend Implementado
- Ordenes de compra: Borrador → Pendiente → Aprobada → Enviada → Cerrada
- Aprobacion con validacion monto limite
- Recepcion total o parcial
- Facturas proveedor
- `generar_lista_compras()` genera lista inteligente (stock bajo + merma + ABC)
- `generar_oc_desde_lista_compras()` pre-llena OC

### Frontend Implementado
- Lista OC con estados y filtros
- Formulario creacion OC
- Recepcion con accordeon por item

### Pendiente
- Verificar si UI multi-lote por item en recepcion esta completa

---

## MODULO 7 — Gestion Financiera

### Backend Implementado
- CxC automatica al vender al credito
- CxP automatica al registrar factura proveedor
- Pagos parciales o totales
- Asientos contables basicos

### Frontend Implementado
- Lista CxC y CxP con semaforo de vencimiento
- Modal cobro/pago con soporte parcial

### Pendiente
- Conciliacion bancaria (no implementada en Amatista — a diferencia del template JSoluciones)
- Libros contables completos (parcial)

---

## MODULO 8 — Comunicacion WhatsApp

### Backend Implementado
- Modelo ConfiguracionWA (singleton)
- CRUD Plantillas
- Mensajes (read-only)
- Webhook endpoint (sin auth, para Meta)

### Backend STUB (no funcional)
- `POST /whatsapp/enviar/` — STUB, no envia real a Meta
- Validacion firma HMAC del webhook

### Frontend Implementado
- Pagina configuracion
- Lista plantillas con badges estado
- Lista mensajes con filtros

### Dependencia para activar WhatsApp
- Credenciales Meta: `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_APP_SECRET`

---

## MODULO 9 — Dashboard y Reportes

### Backend Implementado
- KPIs pre-calculados periodicamente (Celery Beat)
- Emision via WebSocket
- Filtros de acceso por rol

### Frontend Implementado
- Dashboard con KPIs por rol
- Semaforos con umbrales configurables
- Actualizacion automatica via WebSocket

---

## MODULO 10 — Usuarios y Roles

### Backend Implementado
- Auth: email + password (bcrypt)
- JWT: access 60min, refresh 7d, rotacion + blacklist Redis
- 2FA con TOTP
- Rate limiting en login
- Audit log
- Permisos RBAC: 8 roles

### Frontend Implementado
- Login con 2FA
- Tabla usuarios con busqueda y filtros
- Matriz permisos: tabla cruzada filas=modulos, columnas=acciones
- Audit log con filtros

---

## MODULO 11 — E-commerce (Tienda Web)

> Documento completo: **`context/ECOMMERCE.md`** — auditoria, gaps, endpoints, plan de integracion.
> Frontend: `JS-FE-Shop/` (Next.js 16, React 19, TypeScript, Tailwind CSS 4).
> Backend: endpoints publicos en Amatista-be (por crear).

### Auditoria del template (38 features evaluadas)

| Estado | Cantidad |
|--------|:--------:|
| TIENE (UI completa) | 20 (53%) |
| PARCIAL (UI incompleta) | 8 (21%) |
| FALTA (no existe) | 10 (26%) |

### Backend — 0% (no existen endpoints publicos)

- Sin endpoint publico de catalogo (todos requieren JWT)
- Sin registro/login de clientes (auth es solo para staff)
- Sin modelo de carrito (`CarritoWeb` no existe)
- Sin pasarela de pago (Culqi no integrado)
- Campos e-commerce (`slug`, `descripcion_larga`, `destacado`, `orden_display`) NO existen en Producto

### Nota sobre modelo de negocio y e-commerce

El negocio opera por **produccion bajo pedido**: `crear_venta_pos()` no descuenta stock.
Para e-commerce hay dos opciones:
- **Opcion A (catalogo simple):** Mostrar productos como "Disponible/No disponible" sin cantidad. Compatible con el modelo actual.
- **Opcion B (disponibilidad calculada):** Usar `verificar_disponibilidad_insumos()` (ya existe en BE) para calcular cuantos arreglos se pueden armar. Requiere recetas cargadas y `descuenta_insumos=True`.

---

## Notas Importantes

- **El negocio funciona por produccion bajo pedido.** `crear_venta_pos()` NO descuenta stock (linea 523 de `ventas/services.py`).
- **Fases 1-6 del ROADMAP original YA estan implementadas en el codigo** (modelos, migraciones, services, views, tasks). Ver `ROADMAP.md` para detalles.
- **La llamada FE a `completarProduccion` esta SUSPENDIDA** — el Kanban mueve estados pero no descuenta insumos. El backend esta listo; falta habilitar la llamada en el frontend.
- **WhatsApp (~55%)** sigue siendo stub — el envio real depende de credenciales Meta.
- **E-commerce** — frontend recibido (`JS-FE-Shop/`), backend por construir endpoints publicos.
- **Los errores LSP en `Amatista-be/`** son pre-existentes (Django Channels, lxml, typing de DRF). No son regresiones. NO tocar sin autorizacion.
