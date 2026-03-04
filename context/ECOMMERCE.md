# AMATISTA — E-commerce: Auditoria, Gaps y Plan de Integracion

> Documento de referencia para el desarrollo del e-commerce de Amatista.
> Frontend: `JS-FE-Shop/` (Next.js 16). Backend: `Amatista-be/` (Django/DRF).
> Este documento sirve como punto de partida para saber exactamente que hay,
> que falta y en que orden construirlo.

---

## 1. Arquitectura General

```
Cliente (navegador)
       |
JS-FE-Shop (Next.js 16, React 19, TypeScript, Tailwind CSS 4)
  NEXT_PUBLIC_API_URL=https://api.amatista.com/api
       |  consume API publica (AllowAny + rate-limit)
       v
Amatista BE (Django 5 / DRF)
  ├── /api/publico/  ← endpoints sin JWT para el e-commerce
  ├── apps/inventario/  ← catalogo, stock, disponibilidad
  ├── apps/ventas/      ← Venta [tipo_venta='online']
  ├── apps/distribucion/ ← Pedido de delivery
  ├── apps/facturacion/  ← boleta/factura SUNAT automatica
  └── apps/clientes/     ← registro de cliente
       |
  PostgreSQL + Redis (cache, carrito TTL, Celery)
```

El e-commerce NO reemplaza el ERP. Vive al lado, consumiendo la misma API.
Los pedidos web entran al sistema como `Venta` con `tipo_venta='online'`.

---

## 2. Stack del Frontend E-commerce (JS-FE-Shop)

| Tecnologia | Version | Proposito |
|------------|---------|-----------|
| Next.js | 16.1.6 | Framework (App Router, Turbopack) |
| React | 19.2.3 | UI |
| TypeScript | 5.9.3 | Tipado (strict) |
| Tailwind CSS | 4.2.1 | Estilos via @theme inline |
| Headless UI | 2.2.9 | Tabs, Listbox (accesibles) |
| Phosphor Icons | 2.1.10 | Iconos |
| Swiper | 12.1.2 | Carruseles |
| react-fast-marquee | 1.6.5 | Texto deslizante |

**NO tiene:** State management, auth library, form library, test framework.

---

## 3. Auditoria Completa del Template

### 3.1 Catalogo y Navegacion

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 1 | Listado productos grid/list | TIENE | `src/components/pages/ShopSection.tsx` | Toggle grid/list funcional, sidebar filtros, 12 productos mock |
| 2 | Detalle producto con galeria | TIENE | `src/components/pages/ProductDetailsOne.tsx`, `ProductDetailsTwo.tsx` | Galeria thumbnails clickeable, info completa, countdown, qty selector |
| 3 | Filtro por categorias | TIENE | `ShopSection.tsx` sidebar + mega-menu en headers | 13 categorias con contadores, mega-menu con subcategorias |
| 4 | Buscador | PARCIAL | Headers (3 variantes) | UI completa (input + dropdown categoria + boton), sin logica de filtrado |
| 5 | Filtro por rango de precio | TIENE | `src/components/ui/DualRangeSlider.tsx` | Slider dual con min/max, boton "Filtrar", sin conexion a data |
| 6 | Ordenar por | PARCIAL | `ShopSection.tsx` select | 4 opciones (Popular, Reciente, Tendencia, Coincidencias), sin onChange |
| 7 | Paginacion | PARCIAL | `ShopSection.tsx` | Solo texto "Mostrando 1-20 de 85", sin controles de pagina |
| 8 | Breadcrumbs | TIENE | `src/components/ui/Breadcrumb.tsx` | Reutilizable, 3 variantes (default/green/orange), en todas las paginas |

### 3.2 Carrito

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 9 | Pagina de carrito | TIENE | `src/components/pages/CartSection.tsx` | Tabla completa, 4 items hardcoded |
| 10 | Actualizar cantidad | TIENE | `src/components/ui/QuantityControl.tsx` | Stepper +/- funcional, no recalcula totales |
| 11 | Eliminar item | PARCIAL | `CartSection.tsx` | Boton con icono XCircle, sin onClick handler |
| 12 | Totales (subtotal, envio, tax) | TIENE | `CartSection.tsx` sidebar | UI completa: subtotal, envio gratis, impuesto, total (valores hardcoded) |
| 13 | Input cupon/descuento | TIENE | `CartSection.tsx` | Input + boton "Aplicar Cupon" (sin logica) |
| 14 | Mini-cart en header | TIENE | Headers (3 variantes) | Icono carrito + badge con numero (hardcoded "2") |

### 3.3 Checkout

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 15 | Formulario billing | TIENE | `src/components/pages/Checkout.tsx` | Nombre, empresa, pais, calle, apto, ciudad, estado, zip, tel, email, notas |
| 16 | Direccion envio separada | FALTA | — | No existe checkbox "Enviar a otra direccion" ni formulario separado |
| 17 | Seleccion metodo pago | TIENE | `Checkout.tsx` | 3 radios: transferencia, cheque, contra entrega. State funcional |
| 18 | Resumen del pedido | TIENE | `Checkout.tsx` sidebar | Lista items + subtotal + total (hardcoded) |
| 19 | Pagina confirmacion/exito | FALTA | — | No existe. "Realizar Pedido" no navega ni hace nada |

### 3.4 Auth y Cuenta

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 20 | Login | TIENE | `src/components/pages/Account.tsx` | Form con email/password, toggle show/hide, "Recordarme" |
| 21 | Registro | TIENE | `Account.tsx` | Form con username, email, password, link privacidad |
| 22 | Recuperar password | PARCIAL | `Account.tsx` | Link "Olvidaste tu contrasena?" apunta a `#`, sin pagina |
| 23 | Mi cuenta / perfil | FALTA | — | No existe pagina post-login (dashboard, datos personales) |
| 24 | Historial de pedidos | FALTA | — | No existe |
| 25 | Libreta de direcciones | FALTA | — | No existe |

### 3.5 Wishlist

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 26 | Pagina wishlist | TIENE | `src/components/pages/WishlistSection.tsx` | Tabla con 4 items, stock status, boton agregar al carrito |
| 27 | Boton wishlist en productos | PARCIAL | `ProductDetailsOne.tsx`, `ProductDetailsTwo.tsx` | Heart icon solo en pagina detalle, no en ProductCard del listado |

### 3.6 Otros Esenciales

| # | Feature | Estado | Archivo / Componente | Detalle |
|---|---------|--------|----------------------|---------|
| 28 | Responsive / mobile | TIENE | Todos los componentes | Menu hamburguesa, overlay, grids responsive, breakpoints custom |
| 29 | Pagina contacto | TIENE | `src/components/pages/Contact.tsx` | Form completo + sidebar info contacto + tarjetas de accion |
| 30 | Pagina "Sobre nosotros" | FALTA | — | No existe. Links "Sobre Nosotros" apuntan a `#` o `/contact` |
| 31 | Paginas de politicas | FALTA | — | No existen (envio, devoluciones, privacidad). Links van a `/shop` |
| 32 | Pagina 404 | FALTA | — | No existe `not-found.tsx`. Next.js muestra default |
| 33 | Loading states / skeletons | PARCIAL | `src/components/ui/Preloader.tsx` | Solo preloader de 1 seg con GIF. Sin skeletons ni loading.tsx |
| 34 | Sistema de toasts/alertas | FALTA | — | No existe. Sin feedback al usuario en ninguna accion |
| 35 | Reviews/resenas | PARCIAL | ProductDetails | Muestra estrellas + conteo, sin listado de resenas ni formulario |
| 36 | Productos relacionados | FALTA | — | No existe seccion "Tambien te puede gustar" en detalle |
| 37 | Newsletter | TIENE | `NewsletterOne.tsx`, `NewsletterTwo.tsx`, `NewsletterThree.tsx` | 3 variantes, input email + boton suscribirse (sin logica) |
| 38 | Redes sociales | TIENE | Footers | Facebook, Twitter, Instagram, LinkedIn desde siteConfig |

---

## 4. Resumen por Estado

| Estado | Cantidad | Porcentaje |
|--------|:--------:|:----------:|
| TIENE (UI completa) | 20 | 53% |
| PARCIAL (UI incompleta) | 8 | 21% |
| FALTA (no existe) | 10 | 26% |
| **Total evaluado** | **38** | 100% |

---

## 5. Problemas Transversales del Template

Estos afectan multiples features y deben resolverse antes de conectar al backend:

| Problema | Impacto | Solucion |
|----------|---------|----------|
| Sin state management | Carrito, wishlist, auth, search no persisten entre paginas | Agregar Zustand o Context API |
| Sin rutas dinamicas | `/product-details` es estatica, no `/product/[slug]` | Crear ruta dinamica App Router |
| Componentes usan data estatica | Importan de `src/lib/data/`, no de `src/lib/api/` | Reconectar a la capa API existente |
| Formularios sin logica | Login, registro, checkout, contacto no hacen nada | Agregar handlers + validacion |
| Sin middleware de auth | Rutas protegidas (mi cuenta, pedidos) no existen | Crear middleware Next.js |
| Cart count hardcoded | Siempre muestra "2" en todos los headers | Leer desde store global |

---

## 6. Lo que HAY QUE CONSTRUIR en JS-FE-Shop

### 6.1 Vistas y Paginas Nuevas (no existen en el template)

| # | Pagina | Ruta sugerida | Prioridad | Complejidad |
|---|--------|---------------|-----------|-------------|
| 1 | Producto dinamico | `/product/[slug]` | Critica | Media |
| 2 | Confirmacion de pedido | `/order-confirmation` | Critica | Baja |
| 3 | Mi cuenta (dashboard) | `/account/dashboard` | Critica | Media |
| 4 | Historial de pedidos | `/account/orders` | Critica | Media |
| 5 | Detalle de pedido | `/account/orders/[id]` | Critica | Media |
| 6 | Recuperar contrasena | `/account/forgot-password` | Alta | Baja |
| 7 | Pagina 404 | `src/app/not-found.tsx` | Alta | Baja |
| 8 | Seguimiento de pedido | `/tracking/[codigo]` | Alta | Baja (ya existe endpoint BE) |
| 9 | Productos relacionados (seccion) | Componente en detalle | Alta | Baja |
| 10 | Sobre nosotros | `/about` | Baja | Baja |
| 11 | Politicas (envio, devoluciones) | `/policies/[slug]` | Baja | Baja |

### 6.2 Funcionalidad a Construir Sobre la UI Existente

| # | Feature | Prioridad | Complejidad | Que hacer |
|---|---------|-----------|-------------|-----------|
| 1 | Store global de carrito | Critica | Media | Zustand o Context. Persistir en localStorage. Sincronizar con BE |
| 2 | Store global de auth | Critica | Media | Token JWT de cliente. Refresh automatico |
| 3 | Conectar catalogo a API | Critica | Media | ShopSection → `GET /publico/productos/` con filtros y paginacion |
| 4 | Conectar detalle a API | Critica | Baja | ProductDetails → `GET /publico/productos/{slug}/` |
| 5 | Login/registro funcional | Critica | Media | Account → `POST /publico/auth/login/` y `/registro/` |
| 6 | Checkout funcional | Critica | Alta | Form → `POST /publico/checkout/` con validacion |
| 7 | Pasarela de pago (Culqi) | Critica | Alta | Integrar Culqi.js en checkout |
| 8 | Paginacion real | Alta | Baja | Controles de pagina en ShopSection, leer `count`/`next`/`previous` del BE |
| 9 | Buscador funcional | Alta | Baja | Debounce 300ms → `GET /publico/productos/?search=` |
| 10 | Sort funcional | Alta | Baja | Select → `GET /publico/productos/?ordering=` |
| 11 | Sistema de toasts | Alta | Baja | Agregar `react-hot-toast` o `sonner` |
| 12 | Loading skeletons | Media | Baja | Componentes skeleton para catalogo, detalle, carrito |
| 13 | Direccion envio en checkout | Media | Baja | Checkbox + form duplicado |
| 14 | Wishlist funcional | Media | Media | Store + `POST /publico/wishlist/` o localStorage |
| 15 | Boton wishlist en ProductCard | Media | Baja | Agregar heart icon al componente |

### 6.3 Adaptaciones de Branding

| # | Que | Prioridad | Detalle |
|---|-----|-----------|---------|
| 1 | Colores Amatista | Alta | Cambiar HSL vars a purpura `#8E338A`, rosa nude `#FFF5F7` |
| 2 | Logo Amatista | Alta | Reemplazar logos en `/public/assets/images/logo/` |
| 3 | Fuentes Amatista | Media | Playfair Display (titulos) + Montserrat (cuerpo) |
| 4 | siteConfig | Alta | Telefono, email, direccion, redes sociales reales del Sr. Tito |
| 5 | Quitar secciones no relevantes | Baja | Blog (si no aplica), marcas, testimonios genericos |

---

## 7. Lo que HAY QUE CONSTRUIR en Amatista-be

### 7.1 Endpoints Publicos (sin JWT)

Todos van en `apps/{modulo}/urls_publicas.py`. Permission: `AllowAny` + rate-limit estricto.
NUNCA exponer `precio_compra`, margenes, ni datos internos.

```
# --- Catalogo ---
GET  /api/publico/productos/                     Catalogo paginado con filtros
     Query params: ?search=, ?categoria=, ?precio_min=, ?precio_max=,
                   ?ordering=precio|-precio|nombre|mas_vendido,
                   ?destacado=true, ?page=
     Response: { count, next, previous, results: [ProductoPublico] }

GET  /api/publico/productos/{slug}/              Detalle de producto con imagenes
     Response: { slug, nombre, descripcion, descripcion_larga, precio_venta,
                 precio_original, descuento_porcentaje, categoria, imagenes[],
                 disponibilidad, campana_activa }

GET  /api/publico/categorias/                    Arbol de categorias activas
     Response: [{ id, nombre, slug, hijos: [...] }]

GET  /api/publico/disponibilidad/{producto_id}/  Disponibilidad calculada desde receta
     Response: { producto_id, disponible: bool, cantidad_maxima: int,
                 mensaje: "Disponible" | "Agotado" | "Ultimas N unidades" }
     Logica: floor(min(stock_insumo / cantidad_requerida)) para cada insumo de la receta

# --- Carrito (session-based o token anonimo) ---
GET    /api/publico/carrito/                     Ver carrito actual
POST   /api/publico/carrito/                     Agregar item (producto_id, cantidad)
PATCH  /api/publico/carrito/{item_id}/           Actualizar cantidad
DELETE /api/publico/carrito/{item_id}/           Remover item
       Reserva en Redis con TTL de 15 minutos por item

# --- Auth de clientes (separado del auth staff) ---
POST /api/publico/auth/registro/                 Crear cuenta (email, password, nombre, telefono)
POST /api/publico/auth/login/                    Obtener JWT (access + refresh)
POST /api/publico/auth/refresh/                  Refrescar token
POST /api/publico/auth/forgot-password/          Enviar email de recuperacion
POST /api/publico/auth/reset-password/           Resetear con token

# --- Checkout ---
POST /api/publico/checkout/                      Confirmar pedido
     Body: { carrito_token, datos_facturacion, datos_envio, metodo_pago,
             token_culqi (si pago online), tipo_comprobante: boleta|factura,
             dedicatoria?, notas? }
     Logica: validar disponibilidad → crear Venta [tipo_venta='online']
             → crear Pedido si delivery → emitir comprobante → cobrar Culqi
             → vaciar carrito Redis

# --- Cuenta del cliente (requiere JWT de cliente) ---
GET  /api/publico/mis-pedidos/                   Historial de pedidos del cliente
GET  /api/publico/mis-pedidos/{id}/              Detalle de un pedido
GET  /api/publico/mi-perfil/                     Datos del cliente
PATCH /api/publico/mi-perfil/                    Actualizar datos
```

### 7.2 Modelos Nuevos

```python
# CarritoWeb — tabla temporal o solo Redis
# Opcion A (solo Redis): hash con TTL, sin modelo Django
# Opcion B (DB + Redis): modelo para persistencia + Redis para TTL/lock

# Si se elige Opcion B:
class CarritoWeb(TimestampMixin):
    token = models.UUIDField(unique=True, default=uuid4)  # ID anonimo
    cliente = models.ForeignKey('clientes.Cliente', null=True, on_delete=SET_NULL)
    class Meta:
        db_table = 'carritos_web'

class ItemCarritoWeb(TimestampMixin):
    carrito = models.ForeignKey(CarritoWeb, on_delete=CASCADE, related_name='items')
    producto = models.ForeignKey('inventario.Producto', on_delete=PROTECT)
    cantidad = models.PositiveIntegerField(default=1)
    class Meta:
        db_table = 'items_carrito_web'
        unique_together = ('carrito', 'producto')
```

### 7.3 Campos Nuevos en Producto (migracion)

```python
# Agregar a apps/inventario/models.py — Producto
slug              = models.SlugField(unique=True, blank=True)
descripcion_larga = models.TextField(blank=True, default="")
destacado         = models.BooleanField(default=False)
orden_display     = models.PositiveIntegerField(default=0)
```

### 7.4 Disponibilidad: Funciones que YA Existen

```python
# YA EXISTE en apps/inventario/services.py:1174
def verificar_disponibilidad_insumos(*, producto_id, cantidad=1):
    """
    Verifica si hay stock suficiente de insumos para producir N unidades.
    Usa la receta default del producto.
    Retorna: { disponible: bool, faltantes: [...] }
    """

# YA EXISTE en apps/inventario/services.py:1229
def calcular_costo_receta(*, receta_id):
    """Calcula costo total de la receta basado en precio_compra de insumos."""

# YA EXISTE en apps/inventario/services.py:1156
def obtener_receta_default(*, producto_id):
    """Obtiene la receta default activa de un producto."""
```

Para el e-commerce, se necesita un wrapper publico que:
- Si `descuenta_insumos=False` → retorna "Disponible" (el negocio produce bajo pedido)
- Si `descuenta_insumos=True` → llama a `verificar_disponibilidad_insumos()` que ya existe
- NUNCA expone `precio_compra` ni costos internos

---

## 8. Modelo de Negocio y E-commerce

### Produccion bajo pedido (estado actual)

El negocio de Amatista opera por **produccion bajo pedido**:
- `crear_venta_pos()` NO descuenta stock del producto final (linea 523: "Stock no gestionado")
- Los arreglos se arman al momento cuando llega el pedido
- El descuento de insumos (flores) ocurre solo al marcar "listo" en Kanban via `completar_produccion_item()`
- Esto es consistente con una floreria: los ramos no estan pre-armados en un estante

### Implicacion para el e-commerce

Un e-commerce clasico muestra stock: "quedan 5 unidades". Pero Amatista no maneja stock de producto final.

**Opcion A — Catalogo por encargo (recomendada para empezar):**
- Mostrar productos como "Disponible" / "No disponible" (sin cantidad)
- El cliente encarga, se genera un pedido, el equipo lo arma y entrega
- Similar a una pasteleria online o una floreria web real
- **Compatible con el modelo actual sin cambios en el backend**

**Opcion B — Disponibilidad calculada desde insumos (futuro):**
- Usar `verificar_disponibilidad_insumos()` (ya existe en `inventario/services.py:1174`)
- Calcular cuantos arreglos se pueden armar segun stock de insumos en camara
- Requiere: recetas cargadas por producto + `descuenta_insumos=True`
- Mas complejo pero mas preciso

### NO hay bloqueo tecnico

Las Fases 1-6 del ERP **ya estan implementadas** en el backend:
- BOM/Recetas existen (modelos, services, views, migraciones)
- `verificar_disponibilidad_insumos()` existe y funciona
- Se puede empezar el e-commerce inmediatamente

---

## 9. Plan de Ejecucion Paso a Paso

> Cada paso detalla: que se hace, en que repo, si cambia la DB, y que decisiones requieren aprobacion.

### PASO 1 — Campos e-commerce en Producto (Amatista-be)

| Accion | Detalle |
|--------|---------|
| Agregar 4 campos a `Producto` | `slug` (SlugField unique), `descripcion_larga` (TextField), `destacado` (BooleanField), `orden_display` (PositiveIntegerField) |
| Script de datos | Generar slugs automaticos para productos existentes (slugify del nombre) |
| **DB cambia:** | SI — 4 columnas nuevas en `productos` |
| **Requiere aprobacion:** | SI |
| **Toca JS-FE-Shop:** | NO |

### PASO 2 — Endpoints publicos de catalogo (Amatista-be)

| Accion | Detalle |
|--------|---------|
| `apps/inventario/urls_publicas.py` | Rutas publicas separadas |
| `ProductoPublicoSerializer` | Solo campos publicos. NUNCA `precio_compra` |
| `CategoriaPublicaSerializer` | Arbol de categorias activas |
| Views `AllowAny` + rate-limit | `ProductoPublicoListView`, `ProductoPublicoDetailView`, `CategoriaPublicaListView` |
| `calcular_disponibilidad()` | Funcion en services.py — usa receta (Paso 2) + stock insumos |
| Registrar en `config/urls.py` | Bajo prefijo `/api/publico/` |
| **DB cambia:** | NO — solo codigo nuevo |
| **Toca JS-FE-Shop:** | NO (pero ya se puede conectar despues) |

### PASO 3 — Preparar JS-FE-Shop (paralelo con Pasos 1-2)

**No depende del backend. Se puede hacer en cualquier momento.**

| Accion | Detalle |
|--------|---------|
| Ruta `/product/[slug]/page.tsx` | Pagina dinamica de detalle de producto |
| Instalar Zustand | Store para carrito (localStorage), auth (token), wishlist |
| `not-found.tsx` | Pagina 404 personalizada |
| `/order-confirmation/page.tsx` | Pagina de confirmacion post-checkout |
| `/account/dashboard/page.tsx` | Mi cuenta / perfil |
| `/account/orders/page.tsx` | Historial de pedidos |
| `/account/orders/[id]/page.tsx` | Detalle de un pedido |
| Instalar `sonner` | Sistema de toasts/notificaciones |
| Componentes `Skeleton.tsx` | Loading states para catalogo, detalle, carrito |
| Branding Amatista | Colores (`#8E338A`), logo, fuentes (Playfair + Montserrat), siteConfig |
| **DB cambia:** | NO |
| **Toca Amatista-be:** | NO |

### PASO 4 — Auth de clientes (Amatista-be)

| Accion | Detalle |
|--------|---------|
| **Decision requerida:** | Los clientes usan el modelo `Cliente` existente + campo `password` nuevo? O se crea un `User` separado? |
| Endpoints auth | `POST /publico/auth/registro/`, `/login/`, `/refresh/`, `/forgot-password/` |
| JWT separado | Tokens de cliente NO pueden acceder a endpoints del ERP |
| **DB cambia:** | POSIBLEMENTE — depende de decision sobre modelo auth |
| **Requiere aprobacion:** | SI — decision de arquitectura |

### PASO 5 — Conectar JS-FE-Shop a API real

| Accion | Detalle |
|--------|---------|
| Modificar `src/lib/api/products.ts` | Descomentar/reescribir para usar `apiClient` real |
| Modificar `src/lib/api/categories.ts` | Idem |
| Conectar ShopSection | Filtros, paginacion, sort → query params del BE |
| Conectar ProductDetails | `/product/[slug]` → `GET /publico/productos/{slug}/` |
| Conectar login/registro | Account → `/publico/auth/login/` y `/registro/` |
| `NEXT_PUBLIC_API_URL` | Configurar en `.env.local` |
| `next.config.ts` | Agregar dominio de imagenes R2 |
| **DB cambia:** | NO |

### PASO 6 — Carrito web (Amatista-be + JS-FE-Shop)

| Accion | Detalle |
|--------|---------|
| **Decision requerida:** | Carrito solo en Redis (efimero) o DB + Redis (persistente)? |
| Endpoints CRUD carrito | GET, POST, PATCH, DELETE en `/publico/carrito/` |
| Reserva TTL | 15 minutos por item en Redis |
| Conectar store Zustand → API | Sincronizar carrito local con backend |
| **DB cambia:** | SI si DB+Redis (2 tablas: `carritos_web`, `items_carrito_web`). NO si solo Redis |

### PASO 7 — Checkout + Culqi (Amatista-be + JS-FE-Shop)

| Accion | Detalle |
|--------|---------|
| **Prerequisito:** | Credenciales Culqi del Sr. Tito |
| Endpoint `POST /publico/checkout/` | `@transaction.atomic`: validar stock → Venta → Pedido → comprobante → Culqi |
| Instalar SDK Culqi BE | `pip install culqi-python` |
| Integrar Culqi.js en FE | Formulario tarjeta tokenizado |
| Metodos de pago | Online (Culqi), Yape/Plin (QR), contra entrega |
| **DB cambia:** | NO — usa tablas existentes (`ventas`, `pedidos`, `comprobantes`, `formas_pago`) |

### PASO 8 — Pulido y vistas secundarias

| Accion | Repo | Detalle |
|--------|------|---------|
| Paginacion, sort, search | JS-FE-Shop | Controles de pagina, select ordering, debounce search |
| Productos relacionados | JS-FE-Shop | Seccion "Tambien te puede gustar" por categoria |
| Historial de pedidos | Ambos | Endpoint `GET /publico/mis-pedidos/` + vista |
| Seguimiento de pedido | JS-FE-Shop | Reutilizar `GET /publico/seguimiento/{codigo}/` existente |
| Wishlist funcional | Ambos | Store + API o solo localStorage |
| Paginas estaticas | JS-FE-Shop | Sobre nosotros, politicas |
| Panel ERP pedidos web | Amatista-fe | Filtro `tipo_venta='online'` en lista de ventas |
| SEO | JS-FE-Shop | sitemap.ts, robots.ts, structured data (JSON-LD) |

---

## 9.1 Resumen de Impacto en Base de Datos

| Paso | Cambio | Tablas afectadas |
|------|--------|------------------|
| 1 | 4 columnas nuevas | `productos` (`slug`, `descripcion_larga`, `destacado`, `orden_display`) |
| 4 | Posible 1 columna | `clientes` (password_hash) — depende de decision |
| 6 | Posible 2 tablas nuevas | `carritos_web`, `items_carrito_web` — depende de decision |
| **Total** | **~5 columnas nuevas + 0-2 tablas nuevas** | |

**Nota:** Las Fases 1-6 (BOM, Camara, Campanas, etc.) YA tienen sus migraciones aplicadas.
No hay que crear tablas de recetas ni campos de frescura — ya existen.

Cada migracion se muestra al usuario antes de aplicar (regla DB-01 de `DATABASE.md`).

## 9.2 Decisiones que Requieren Aprobacion

| # | Decision | Opciones | Impacto |
|---|----------|----------|---------|
| 1 | Modelo de disponibilidad | A) Catalogo por encargo ("Disponible/No disponible"). B) Disponibilidad calculada desde insumos via receta | A es simple y compatible. B requiere recetas cargadas |
| 2 | Auth de clientes web | A) Agregar `password_hash` a modelo `Cliente` existente. B) Crear modelo `ClienteUsuario` separado | A es mas simple pero mezcla datos. B es mas limpio |
| 3 | Persistencia del carrito | A) Solo Redis (efimero). B) DB + Redis (persistente) | A es simple. B requiere 2 tablas |
| 4 | Pasarela de pago | Culqi (Peru). Requiere credenciales del Sr. Tito | Sin credenciales no se puede integrar |

---

## 10. Reglas para el Desarrollo del E-commerce

### Backend (aplican sobre las reglas de `rules/BACKEND.md`)

```
ECOM-BE-01: Endpoints publicos van en urls_publicas.py por app. NUNCA mezclar con ERP.
ECOM-BE-02: Permission AllowAny + throttle estricto (20 req/min anon, 60 req/min auth).
ECOM-BE-03: NUNCA exponer precio_compra, margen, ni datos internos en respuestas publicas.
ECOM-BE-04: Disponibilidad se calcula desde INSUMOS (via receta). NUNCA desde stock directo.
            Solo contar lotes con estado_frescura IN ('optimo', 'precaucion').
ECOM-BE-05: Carrito web usa Redis con TTL de 15 minutos. Al expirar, liberar reserva.
ECOM-BE-06: Checkout es @transaction.atomic: validar stock → crear Venta → crear Pedido
            → emitir comprobante → cobrar Culqi. Si algo falla, rollback completo.
ECOM-BE-07: Auth de clientes es SEPARADA del auth de staff. Tokens distintos.
            Un cliente NO puede acceder a endpoints del ERP.
```

### Frontend (aplican sobre las reglas de `rules/FRONTEND.md`)

```
ECOM-FE-01: State management: Zustand para carrito y wishlist. Auth en Context.
ECOM-FE-02: NUNCA fetch() a mano. Usar la capa API de src/lib/api/ con el apiClient.
ECOM-FE-03: Toda pagina que consume datos: loading skeleton → datos → error.
ECOM-FE-04: Busquedas con debounce 300ms minimo.
ECOM-FE-05: Precios siempre formateados con 2 decimales y simbolo S/. (PEN).
ECOM-FE-06: Imagenes de producto via next/image con dominio configurado en next.config.ts.
ECOM-FE-07: Paginas de cuenta (/account/*) protegidas con middleware de auth.
ECOM-FE-08: NUNCA mostrar UUIDs al usuario. Usar slug para productos, codigo para pedidos.
```

---

## 11. Estructura de Archivos Esperada en JS-FE-Shop (post-integracion)

```
src/
  app/
    layout.tsx
    page.tsx                          ← Home
    not-found.tsx                     ← 404 (NUEVO)
    shop/page.tsx                     ← Catalogo
    product/[slug]/page.tsx           ← Detalle dinamico (NUEVO)
    cart/page.tsx                     ← Carrito
    checkout/page.tsx                 ← Checkout
    order-confirmation/page.tsx       ← Confirmacion (NUEVO)
    wishlist/page.tsx                 ← Wishlist
    account/
      page.tsx                        ← Login/Registro (existe)
      dashboard/page.tsx              ← Mi cuenta (NUEVO)
      orders/page.tsx                 ← Historial pedidos (NUEVO)
      orders/[id]/page.tsx            ← Detalle pedido (NUEVO)
      forgot-password/page.tsx        ← Recuperar password (NUEVO)
    tracking/[codigo]/page.tsx        ← Seguimiento pedido (NUEVO)
    contact/page.tsx                  ← Contacto (existe)
    about/page.tsx                    ← Sobre nosotros (NUEVO)
    policies/[slug]/page.tsx          ← Politicas (NUEVO)
  
  stores/                             ← NUEVO
    cart.ts                           ← Zustand store carrito
    auth.ts                           ← Zustand store auth
    wishlist.ts                       ← Zustand store wishlist
  
  lib/
    api/
      client.ts                       ← Base HTTP client (existe, apunta a BE)
      products.ts                     ← Conectar a API real (modificar)
      categories.ts                   ← Conectar a API real (modificar)
      cart.ts                         ← Endpoints carrito (NUEVO)
      auth.ts                         ← Endpoints auth cliente (NUEVO)
      checkout.ts                     ← Endpoint checkout (NUEVO)
      orders.ts                       ← Endpoints mis-pedidos (NUEVO)
  
  components/
    ui/
      Skeleton.tsx                    ← Loading skeleton (NUEVO)
      Toast.tsx                       ← Sistema toasts (NUEVO)
    pages/
      OrderConfirmation.tsx           ← Pagina confirmacion (NUEVO)
      AccountDashboard.tsx            ← Mi cuenta (NUEVO)
      OrderHistory.tsx                ← Historial pedidos (NUEVO)
      OrderDetail.tsx                 ← Detalle pedido (NUEVO)
      RelatedProducts.tsx             ← Productos relacionados (NUEVO)
```
