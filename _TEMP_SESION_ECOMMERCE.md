# Sesion E-commerce — Estado Actual y Pendientes

> Archivo temporal para continuar la sesion. Borrar cuando se complete todo.

## COMPLETADO en esta sesion

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
POST /api/v1/shop/pedidos/              → crear pedido web (no probado con POST real)
GET  /api/v1/shop/pedidos/seguimiento/<codigo>/ → tracking publico
```

### Frontend (JS-FE-Shop/) — Cimientos listos, componentes pendientes

#### Archivos modificados
| Archivo | Cambio |
|---|---|
| `src/types/product.ts` | Product ahora tiene: id(string/UUID), slug, nombre, descripcion, precio_venta(string), category, category_slug, image, destacado, orden_display. ProductDetail extiende con descripcion_larga, images[]. PaginatedResponse<T> generico. |
| `src/types/category.ts` | ShopCategory ahora tiene: id(string/UUID), nombre, slug, descripcion, product_count. Tipos legacy (PopularCategory, ShopColor, etc.) conservados. |
| `src/types/index.ts` | Barrel exports actualizado con nuevos tipos |
| `src/lib/api/client.ts` | Base URL cambiada a /api/v1/shop |
| `src/lib/api/products.ts` | Todas las funciones ahora llaman al API real (getProducts, getProductBySlug, getFeaturedProducts, searchProducts, getCategories, etc.) |
| `src/app/layout.tsx` | CartProvider wrapping children |

#### Archivos nuevos
| Archivo | Descripcion |
|---|---|
| `src/types/order.ts` | CreateOrderRequest, OrderResponse, OrderTracking |
| `src/lib/api/orders.ts` | createOrder(), trackOrder() |
| `src/context/CartContext.tsx` | CartProvider + useCart hook. Reducer con ADD/REMOVE/UPDATE/CLEAR. Persistencia en localStorage. |

---

## PENDIENTE — lo que falta para que funcione visualmente

### 1. Mapeo de campos en componentes (CRITICO)

Los componentes del template usan campos en INGLES que ya no existen:
```
product.name       → product.nombre
product.price      → parseFloat(product.precio_venta)
product.image      → product.image  (este SI coincide)
product.category   → product.category  (este SI coincide)
product.badge      → product.destacado ? "Destacado" : undefined
product.rating     → NO EXISTE en API (quitar o hardcodear)
product.ratingCount → NO EXISTE en API
product.soldCount  → NO EXISTE en API
product.totalStock → NO EXISTE en API
product.unit       → NO EXISTE en API
product.originalPrice → NO EXISTE en API
product.badgeColor → NO EXISTE en API
```

Componentes que necesitan actualizarse (usan `product.name`, `product.price`, etc.):
- `src/components/ui/ProductCard.tsx` — usado en home pages
- `src/components/pages/ShopSection.tsx` — la pagina /shop (importa data estatica directamente, no usa API)
- `src/components/pages/ProductDetailsOne.tsx` — pagina /product-details
- `src/components/pages/ProductDetailsTwo.tsx` — pagina /product-details-two
- `src/components/pages/CartSection.tsx` — pagina /cart (data hardcodeada)
- `src/components/pages/WishlistSection.tsx` — pagina /wishlist (data hardcodeada)
- `src/components/pages/CheckoutSection.tsx` — pagina /checkout (no funcional)
- `src/components/home-one/*.tsx` — ~8 componentes de homepage que renderizan productos
- `src/components/home-two/*.tsx` — ~5 componentes
- `src/components/home-three/*.tsx` — ~5 componentes

**Opcion A (rapida)**: Crear un helper `mapProduct()` que convierte la respuesta del API al formato que esperan los componentes legacy:
```ts
function mapProduct(p: Product): LegacyProduct {
  return { id: p.id, name: p.nombre, price: parseFloat(p.precio_venta), image: p.image || "/placeholder.png", category: p.category, ... }
}
```
Y usarlo en cada componente al recibir datos del API.

**Opcion B (mejor a largo plazo)**: Actualizar cada componente para usar los campos reales del API directamente.

### 2. Ruta dinamica /product/[slug] (CRITICO)

Actualmente `/product-details` es una pagina estatica. Necesita:
- Crear `src/app/product/[slug]/page.tsx`
- Que llame a `getProductBySlug(slug)` en el server component
- Renderice ProductDetailsOne/Two con datos reales
- Actualizar todos los links que van a `/product-details` para ir a `/product/${slug}`

### 3. ShopSection conectada al API (CRITICO)

`src/components/pages/ShopSection.tsx` importa datos directamente de `@/lib/data/products` y `@/lib/data/categories`. Necesita:
- Recibir productos y categorias como props (desde el server component)
- O convertirse en un client component que llame al API
- Implementar paginacion real (la API pagina a 20)
- Conectar filtros de categoria al query param `?category=slug`

### 4. CartSection funcional (IMPORTANTE)

`src/components/pages/CartSection.tsx` tiene items hardcodeados. Necesita:
- Usar `useCart()` hook del CartContext
- Renderizar items reales del carrito
- Botones +/- que llamen `updateCantidad()`
- Boton eliminar que llame `removeItem()`
- Subtotal/total calculado desde el context

### 5. CheckoutSection funcional (IMPORTANTE)

`src/components/pages/CheckoutSection.tsx` no tiene logica. Necesita:
- Formulario con campos de PedidoWeb (nombre, telefono, direccion, etc.)
- Mostrar items del carrito desde useCart()
- Submit que llame a `createOrder()` del API
- Pantalla de confirmacion con numero de pedido y codigo de seguimiento
- Limpiar carrito despues de pedido exitoso

### 6. Headers: badge del carrito dinamico (MENOR)

Ambos headers (HeaderOne, HeaderTwo) tienen `<span>2</span>` hardcodeado como badge del carrito. Necesitan:
- Usar `useCart().itemCount` para mostrar la cantidad real
- Estos son server components, asi que necesitarian un client component wrapper para el badge

### 7. Botones "Agregar al Carrito" funcionales (IMPORTANTE)

Todos los botones "Agregar al Carrito" son `<Link href="/cart">`. Necesitan:
- Llamar `addItem(product)` del CartContext
- Mostrar feedback (toast o similar) de "Agregado al carrito"
- No navegar a /cart automaticamente

### 8. Pagina de seguimiento de pedido (OPCIONAL)

Crear una pagina `/seguimiento` donde el cliente ingresa su codigo y ve el estado del pedido.
- Formulario simple con un input
- Llama a `trackOrder(codigo)` del API
- Muestra el estado

---

## Archivos de datos estaticos que se pueden BORRAR cuando los componentes esten conectados

Estos archivos ya no se necesitan una vez que todo consuma el API:
- `src/lib/data/products.ts` — 697 lineas de productos fake
- `src/lib/data/productDetails.ts` — 62 lineas de detalles fake
- `src/lib/data/categories.ts` — 140 lineas (parcialmente, los shopCategories se reemplazan)

NO borrar hasta que todos los componentes esten migrados.

---

## Orden recomendado para la proxima sesion

1. **Crear helper `mapProduct()`** para no tener que cambiar todos los componentes de golpe
2. **ShopSection** — conectar al API con paginacion
3. **Ruta /product/[slug]** — pagina dinamica
4. **CartSection** — conectar al CartContext
5. **Botones "Agregar al Carrito"** — funcionales con CartContext
6. **CheckoutSection** — formulario + POST pedido
7. **Headers** — badge dinamico del carrito
8. **Limpieza** — quitar data estatica, quitar componentes/paginas no usados
