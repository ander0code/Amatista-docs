# AMATISTA ERP — VISION GENERAL

> ERP especializado para floreria/arreglos florales. Cliente: Sr. Tito (Amatista).
> Single-tenant. Una sola instalacion. Sin multi-tenancy.
> Fork del template JSoluciones con modulos especificos de floreria agregados.

---

## Que es Amatista ERP

Sistema ERP completo para una floreria peruana. Maneja el ciclo completo del negocio:
ventas en POS y campo, pedidos con delivery, inventario de flores con control de frescura (FIFO),
facturacion electronica SUNAT, compras a mayoristas, finanzas, y comunicacion por WhatsApp.

Lo que lo diferencia del template base JSoluciones:
- **Control de camara** — semaforo de frescura para flores (organico/perecible): optimo, precaucion, funebre, descarte
- **BOM / Recetas** — cada arreglo floral tiene una receta de insumos (flores + cintas + bases)
- **Kanban de produccion** — estado por item: pendiente → en_produccion → listo
- **Personalizacion de pedidos** — ajustes sobre la receta default + notas al arreglista + recargo
- **Precios diferenciados** — precio corporativo (clientes RUC) + descuentos por cantidad
- **Campanias de temporada** — descuentos automaticos Dia de la Madre, San Valentin, etc.
- **Stock FIFO estricto** — al marcar "listo" en Kanban, los insumos se descuentan por FIFO automaticamente

---

## Stack Tecnologico

### Backend

| Capa | Tecnologia | Version |
|------|-----------|---------|
| Framework | Django | 4.2 |
| API REST | Django REST Framework | 3.14+ |
| Auth | simplejwt | 5.3+ (access 60min, refresh 7d, rotacion + blacklist) |
| DB | PostgreSQL | 16 (UUIDs, JSONB, indices compuestos) |
| Schema/Docs | drf-spectacular | 0.29+ (genera OpenAPI para Orval) |
| Tareas async | Celery + Redis | 5.3+ |
| WebSockets | Django Channels + Daphne | 4.0+ |
| Storage | Cloudflare R2 (boto3) | 3 buckets privados, presigned URLs |
| Cache | Redis (LocMem en dev) | - |
| Facturacion SUNAT | Nubefact OSE via HTTP | - |

### Frontend

| Tecnologia | Version | Proposito |
|-----------|---------|-----------|
| React | 19 | Framework UI |
| TypeScript | 5.8 | Tipado estatico |
| Vite | 7 | Build tool + dev server con proxy |
| Tailwind CSS | 4 | Estilos (via @tailwindcss/vite) |
| Preline | 3.2 | Interacciones JS (dropdowns, modales, tabs) |
| TanStack React Query | 5 | Data fetching, cache, mutations |
| Orval | 8 | Genera hooks y tipos desde OpenAPI |
| react-hot-toast | - | Notificaciones toast |
| react-apexcharts | - | Graficos en dashboard |
| react-hook-form | - | Formularios complejos |
| pnpm | - | Package manager |

### Infraestructura

- Redis: 3 usos (broker Celery DB0, channel layer WS DB1, cache general DB2)
- Celery: 4 colas (critical, default, notifications, reports)
- Docker Compose para desarrollo local
- Uvicorn ASGI en produccion

---

## Repositorios

| Repo | Descripcion | Path local |
|------|-------------|------------|
| `Amatista-be` | Django Backend (API REST + WebSockets + Celery) | `../Amatista-be/` |
| `Amatista-fe` | React Frontend (Vite + TanStack Query + Orval) | `../Amatista-fe/` |
| `Amatista-docs` | Documentacion (este repo) | `../Amatista-docs/` |

> Jsoluciones-be/ y Jsoluciones-fe/ son el TEMPLATE BASE del que este proyecto es fork. No modificar.

---

## Arquitectura del Backend

```
config/
  settings/base.py, development.py, production.py, testing.py
  urls.py, celery.py, asgi.py

core/
  mixins.py          -> TimestampMixin, SoftDeleteMixin, AuditMixin
  choices.py         -> TODAS las constantes (choices, roles, estados, tipos registro, frescura)
  pagination.py      -> StandardPagination (20/page), LargeDatasetPagination (cursor)
  permissions.py     -> TienePermiso, EsAdmin, EsSupervisorOAdmin, SoloSusDatos
  exceptions.py      -> Excepciones custom con error_code
  exception_handler.py -> Handler global formato estandar
  consumers.py       -> WebSocket consumers
  routing.py         -> Rutas WebSocket
  utils/
    validators.py    -> validar_ruc, validar_dni
    r2_storage.py    -> R2StorageService
    nubefact.py      -> Cliente HTTP Nubefact
  tasks/
    r2_tasks.py      -> Upload async, cache presigned URLs

apps/
  empresa/       -> Configuracion empresa (singleton, 1 fila)
  usuarios/      -> Usuario, Rol, Permiso, PerfilUsuario, LogActividad
  clientes/      -> Cliente (RUC/DNI, segmento, limite credito)
  proveedores/   -> Proveedor (RUC, condiciones pago)
  inventario/    -> Producto (con tipo_registro + frescura), Almacen, Stock, Lote, MovimientoStock,
                    RecetaProducto, DetalleReceta
  ventas/        -> Cotizacion, OrdenVenta, Venta, DetalleVenta (con notas_arreglista + estado_produccion),
                    AjustePersonalizacion, DetalleVentaInsumo, Campana, ReglaDescuento, Caja
  facturacion/   -> Comprobante, NotaCreditoDebito, SerieComprobante, LogEnvio
  media/         -> MediaArchivo (polimorfico, R2 buckets)
  compras/       -> OrdenCompra, FacturaProveedor, Recepcion, DetalleRecepcion
  finanzas/      -> CuentaCobrar/Pagar, Cobro, Pago
  distribucion/  -> Transportista, Pedido (con estado_produccion), SeguimientoPedido
  whatsapp/      -> ConfiguracionWA, Plantilla, Mensaje, LogWA
  reportes/      -> Sin modelos propios (queries cross-app)
```

### Patron obligatorio por app

```
apps/{modulo}/
  models.py        -> Modelos con mixins, db_table, indices, constraints
  serializers.py   -> Solo validacion y transformacion (NUNCA logica de negocio)
  services.py      -> TODA la logica de negocio (@transaction.atomic)
  views.py         -> Solo orquesta: request -> service -> response
  urls.py          -> Router DRF + paths custom
  admin.py         -> Registro en Django admin
  tasks.py         -> Tareas Celery (si aplica)
```

---

## Arquitectura del Frontend

```
src/
  api/
    fetcher.ts              -> Custom fetch con JWT (mutex refresh, maneja 401)
    generated/              -> AUTO-GENERADO por Orval (NO editar)
    models/                 -> AUTO-GENERADO por Orval (NO editar)

  app/
    (admin)/                -> Paginas autenticadas
      layout.tsx            -> Layout con sidebar + topbar + footer
      (dashboards)/index/   -> Dashboard principal
      (app)/
        (ventas)/           -> POS, lista ventas, detalle venta, cotizaciones, campanas
        (inventario)/       -> Productos, stock, camara, compras-inteligentes, recetas
        (hr)/               -> Cotizaciones, cobros
        (invoice)/          -> Facturacion
        (users)/            -> Clientes, proveedores, usuarios
        (whatsapp)/         -> Configuracion, plantillas, mensajes
        (finanzas)/         -> CxC, CxP
        (distribucion)/     -> Pedidos con Kanban, transportistas
        (compras)/          -> Ordenes de compra, recepciones (con multi-lote)
        (configuracion)/    -> Roles, permisos, empresa, audit log
    (auth)/                 -> Login, Logout

  components/
    common/                 -> Badge, ConfirmModal, DataTable, EmptyState, ErrorBoundary,
                               RowDropdown, PhoneInput, DistritoSelect
    layouts/                -> Sidebar, topbar, footer, customizer

  context/
    AuthContext.tsx          -> Estado de autenticacion + RBAC
    WebSocketManager.tsx     -> WebSockets globales (notificaciones + dashboard KPIs)

  lib/
    tokenRefresh.ts          -> Mutex-based token refresh (evita race condition 401)
    routerNavigate.ts        -> Singleton navigate() para uso fuera de componentes
    createReconnectingWS.ts  -> WebSocket con exponential backoff
    dateUtils.ts             -> localDateStr() — fecha en zona horaria Lima, no UTC

  helpers/
    formatters.ts           -> formatMoney, formatDate, formatDateTime, formatDocNumber
```

---

## Roles del Sistema (8 roles)

| Rol | Codigo | Acceso |
|-----|--------|--------|
| Administrador | admin | TODOS los modulos |
| Gerente | gerente | Dashboard, Ventas, Inventario, Compras, Finanzas, Reportes |
| Supervisor | supervisor | Ventas, Inventario, Clientes, Compras |
| Vendedor | vendedor | Ventas, Clientes, Inventario (consulta) |
| Cajero | cajero | POS, Ventas (crear) |
| Almacenero | almacenero | Inventario, Compras (recepcion) |
| Contador | contador | Finanzas, Facturacion (consulta), Reportes |
| Repartidor | repartidor | Distribucion (solo sus pedidos) |

---

## Design System de Amatista

| Token CSS | Color | Hex | Uso |
|-----------|-------|-----|-----|
| `--color-primary` | Purpura Amatista | `#8E338A` | CTAs, links activos, badges primarios |
| `--color-primary-hover` | Purpura Oscuro | `#72287E` | Hover del boton principal |
| `--color-accent-orange` | Naranja Atardecer | `#F28E2B` | Top del degradado, alertas |
| `--color-accent-pink` | Rosa Vibrante | `#D81B60` | Centro del degradado, botones secundarios |
| `--color-brand-surface` | Rosa Nude | `#FFF5F7` | Fondo general de pagina |
| `--color-brand-dark` | Negro Suave | `#1A1A2E` | Titulos H1/H2 |
| `--color-brand-body` | Gris Pizarra | `#555555` | Texto cuerpo, labels |
| `--color-brand-border` | Gris Suave | `#E0E0E0` | Bordes de inputs, cards |

**Degradado de marca:** `linear-gradient(180deg, #F28E2B 0%, #D81B60 50%, #8E338A 100%)`

Tipografia: **Playfair Display** (titulos) + **Montserrat** (cuerpo y UI).

---

## Formato de Respuesta API

```json
// Exito — listado paginado
{
  "count": 150,
  "next": "/api/v1/ventas/?page=2",
  "previous": null,
  "results": [...]
}

// Exito — detalle / accion
{
  "id": "uuid",
  "numero": "V001-0001",
  ...
}

// Error (400/403/404/500)
{
  "success": false,
  "data": null,
  "message": "Stock insuficiente para Rosa Roja.",
  "errors": [],
  "error_code": "stock_insuficiente"
}
```
