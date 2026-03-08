# Sesion E-commerce — Estado Actual y Pendientes

> Archivo temporal para continuar la sesion. Borrar cuando se complete todo.

## COMPLETADO en sesiones anteriores + sesion actual

### Backend (Amatista-be/) — 100% listo

#### Migraciones aplicadas
- `inventario/0010_ecommerce_slug_descripcion_destacado` — Agrega slug (Categoria + Producto), descripcion_larga, destacado, orden_display. Popula slugs existentes.
- `inventario/0011_ecommerce_slug_unique` — Hace slugs unique.
- `ventas/0015_pedido_web` — Crea tablas pedido_web y detalle_pedido_web.

#### Archivos nuevos
| Archivo | Descripcion |
|---|---|
| `apps/inventario/serializers_publicos.py` | ShopCategoriaSerializer, ShopProductoListSerializer, ShopProductoDetailSerializer, PedidoWebCreateSerializer, PedidoWebResponseSerializer, PedidoWebTrackingSerializer |
| `apps/inventario/views_publicas.py` | 5 views AllowAny con throttling (120/min browse, 10/min orders), paginacion (20/page), filtros (category, featured, search, ordering) |
| `apps/inventario/urls_publicas.py` | 5 rutas bajo prefijo /api/v1/shop/ |

#### Archivos modificados
| Archivo | Cambio |
|---|---|
| `apps/inventario/models.py` | +slug, descripcion_larga, destacado, orden_display en Producto. +slug en Categoria. +save() auto-slug en ambos. +import slugify. |
| `apps/ventas/models.py` | +PedidoWeb (22 campos), +DetallePedidoWeb (7 campos). +import secrets, choices. |
| `core/choices.py` | +ESTADO_PEDIDO_WEB_CHOICES (nuevo, confirmado, en_produccion, listo, despachado, entregado, cancelado) |
| `config/urls.py` | +path('api/v1/shop/', include('apps.inventario.urls_publicas')) |

#### Endpoints PROBADOS y funcionando
```
GET  /api/v1/shop/categorias/           → 15 categorias con product_count
GET  /api/v1/shop/productos/            → 129 productos paginados, con imagenes R2
GET  /api/v1/shop/productos/<slug>/     → detalle con images[]
POST /api/v1/shop/pedidos/              → crear pedido web
GET  /api/v1/shop/pedidos/seguimiento/<codigo>/ → tracking publico
```

### Frontend (Amatista-eco/) — FLUJO PRINCIPAL COMPLETO

#### Archivos creados/modificados en sesion actual
| Archivo | Cambio |
|---|---|
| `src/lib/mapProduct.ts` | NUEVO. Helper mapProduct() y mapProductDetail() para adaptar campos API a formato legacy |
| `src/components/ui/ProductCard.tsx` | Reescrito. Usa campos reales (nombre, precio_venta, slug). Boton "Agregar al Carrito" funcional via useCart() |
| `src/components/pages/ShopSection.tsx` | Reescrito. Conectado a getProducts() y getCategories(). Paginacion real. Filtro por categoria. Boton agregar funcional. |
| `src/app/product/[slug]/page.tsx` | NUEVO. Ruta dinamica server component. Llama getProductBySlug(slug), renderiza detalle completo. |
| `src/app/product/[slug]/AddToCartButton.tsx` | NUEVO. Client component para boton de carrito en pagina de detalle. |
| `src/components/pages/CartSection.tsx` | Reescrito. Usa useCart(). Items reales del carrito. Botones +/- funcionan. Boton eliminar funciona. Totales dinamicos. |
| `src/components/pages/Checkout.tsx` | Reescrito. Formulario completo con campos de PedidoWeb. Submit conectado a createOrder(). Pantalla de confirmacion con numero y codigo de seguimiento. Limpia carrito al confirmar. |
| `src/components/home-one/BestSellsOne.tsx` | Reescrito. Usa getProducts() API. Botones de carrito funcionales. |
| `src/components/home-one/NewArrivalOne.tsx` | Reescrito. Usa getProducts() API. Botones de carrito funcionales. |
| `src/components/home-one/HotDealsOne.tsx` | Reescrito. Usa getProducts() API. ProductCard ya funcional. |
| `src/components/home-one/RecommendedOne.tsx` | Reescrito. Tabs: Todos y Destacados desde API real. |
| `src/components/layout/HeaderOne.tsx` | Badge del carrito dinamico via useCart().itemCount. Se oculta cuando es 0. |

#### Archivos creados en sesion anterior (cimientos)
| Archivo | Descripcion |
|---|---|
| `src/types/product.ts` | Product con id(UUID), slug, nombre, descripcion, precio_venta(string), category, category_slug, image, destacado, orden_display. |
| `src/types/category.ts` | ShopCategory con id(UUID), nombre, slug, descripcion, product_count. |
| `src/types/order.ts` | CreateOrderRequest, OrderResponse, OrderTracking |
| `src/types/index.ts` | Barrel exports |
| `src/lib/api/client.ts` | Base URL apunta a /api/v1/shop |
| `src/lib/api/products.ts` | getProducts(), getProductBySlug(), getFeaturedProducts(), getCategories(), etc. |
| `src/lib/api/orders.ts` | createOrder(), trackOrder() |
| `src/context/CartContext.tsx` | CartProvider + useCart hook. Reducer completo. Persistencia localStorage. |
| `src/app/layout.tsx` | CartProvider wrapping children |

---

## FLUJO QUE YA FUNCIONA (probarlo)

```
1. Home (/) → ver productos reales de la DB en BestSellsOne, NewArrivalOne, HotDealsOne, RecommendedOne
2. Click "Agregar al Carrito" en cualquier producto → badge del header se actualiza
3. /shop → catalogo completo con paginacion real (20/pag), filtro por categoria, ordenamiento
4. /shop → click en producto → va a /product/<slug> con datos reales
5. /cart → ver items reales, cambiar cantidades, eliminar
6. /checkout → formulario de datos, con/sin delivery, submit → pantalla de confirmacion con codigo
```

---

## PENDIENTE — lo que falta

### Critico
- [ ] **FlashSalesOne** (`src/components/home-one/FlashSalesOne.tsx`) — aun usa `flashSaleProducts` de data estatica. Conectar al API.
- [ ] **OrganicOne** — verificar si usa datos estaticos y conectar
- [ ] **HeaderTwo** (`src/components/layout/HeaderTwo.tsx`) — si existe, tambien tiene badge hardcodeado `2`

### Importante
- [ ] **Pagina de seguimiento** — crear `/seguimiento/[codigo]/page.tsx` que use `trackOrder()`
- [ ] **Paginas de cuenta del cliente** — `/account/dashboard`, `/account/orders` (requiere auth de clientes, no implementada aun)
- [ ] **`not-found.tsx`** — pagina 404 personalizada

### Menor
- [ ] **Branding Amatista** — colores del tema son verde (#22C55E = main-600). Cambiar a purpura Amatista (#8E338A). Ver DESIGN_SYSTEM.md
- [ ] **Fuentes** — layout.tsx carga Quicksand/Exo/Outfit/Dancing Script. Cambiar a Playfair Display + Montserrat
- [ ] **Limpiar data estatica** — `src/lib/data/products.ts` (697 lineas), `src/lib/data/productDetails.ts` (62 lineas)

### Requiere decision del cliente
- [ ] **Auth de clientes web** — registrarse/loguearse para ver historial de pedidos. Requiere: crear modelo ClienteUsuario o usar tabla clientes con password. Consultar al Sr. Tito.

---

## Orden recomendado para proxima sesion

1. **Branding** — cambiar `main-600` de verde a purpura Amatista en `globals.css` o `tailwind.config`
2. **FlashSalesOne** — conectar al API
3. **Pagina de seguimiento** `/seguimiento/[codigo]`
4. **`not-found.tsx`**
5. **Limpieza** de datos estaticos
