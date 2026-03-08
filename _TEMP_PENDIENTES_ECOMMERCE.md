# Amatista E-commerce — Pendientes y Decisiones

> Documento temporal de trabajo. Actualizar conforme se avance.
> Basado en análisis real del código de los 3 proyectos — sin especulación.
> Última actualización: Sesión 7.

---

## ESTADO POR FASE

### FASE 1 — Amatista-eco (fixes inmediatos) ✅ COMPLETADO

| Item | Estado | Archivo |
|------|--------|---------|
| `site.ts` con datos reales | ✅ | `src/config/site.ts` |
| Quitar "Compra en Movimiento" footer | ✅ | `FooterOne.tsx` |
| Eliminar imágenes genéricas BestSells | ✅ | `BestSellsOne.tsx` |
| Eliminar imagen hot-deals | ✅ | `HotDealsOne.tsx` |
| Eliminar imagen newsletter | ✅ | `NewsletterOne.tsx` |
| Metadata SEO de `page.tsx` | ✅ | Título, description, keywords, OpenGraph |
| Textos reales en `ShippingOne.tsx` | ✅ | Delivery, frescura, pago, asesoría |

### FASE 2 — Amatista-be: nueva app `ecommerce/` ✅ COMPLETADO

| Item | Estado | Archivo |
|------|--------|---------|
| `apps/ecommerce/` completa | ✅ | models, admin, serializers, views, urls |
| Endpoints públicos `/shop/banners/` + `/shop/config/` | ✅ | AllowAny + throttle |
| Endpoints admin `/ecommerce/banners/` + `/ecommerce/config/` | ✅ | IsAuthenticated + EsAdmin |
| `migrations/0001_initial.py` | ✅ | **PENDIENTE APLICAR** |
| `campana_activa` en `ShopProductoDetailSerializer` | ✅ | Detail endpoint |
| `campana_activa` en `ShopProductoListSerializer` | ✅ | Con Subquery annotation (sin N+1) |
| Filtro `?campana_activa=true` en `ShopProductoListView` | ✅ | |

### FASE 3 — Amatista-eco: conectar al backend ✅ COMPLETADO

| Item | Estado | Archivo |
|------|--------|---------|
| Tipos `Banner`, `ShopConfig`, `CampanaActiva` | ✅ | `src/types/` |
| `campana_activa` en tipo `Product` | ✅ | `src/types/product.ts` |
| `getBanners()`, `getShopConfig()`, `campana_activa` filter | ✅ | `src/lib/api/products.ts` |
| `BannerOne.tsx` dinámico | ✅ | Consume `/shop/banners/` con fallback |
| `FooterOne.tsx` dinámico (server component) | ✅ | Redes sociales desde `/shop/config/` |
| `WhatsAppButton` dinámico (server hydration) | ✅ | Número desde `/shop/config/` via layout.tsx |
| `HotDealsOne.tsx` con `campana_activa` | ✅ | Fallback a todos si no hay campaña |
| `FlashSalesOne.tsx` con `campana_activa` | ✅ | Título real de campaña en cada slide |
| `ProductCard` con badge de descuento y precio tachado | ✅ | Muestra `-15%` y precio original |
| `BestSellsOne.tsx` con badge + precio tachado | ✅ | Sesión 5 |
| `shop/page.tsx` — theme y metadata corregidos | ✅ | Eliminado `ThemeProvider orange`; metadata SEO completa |

### FASE 4 — Amatista-fe: módulo ERP ✅ COMPLETADO

| Item | Estado | Archivo |
|------|--------|---------|
| Sección "E-commerce" en sidebar | ✅ | `menu.ts` — admin only |
| CRUD banners (crear/editar/activar/eliminar) | ✅ | `BannerList.tsx` con modales |
| CRUD promo cards | ✅ | `PromoCardList.tsx` |
| Ruta `/ecommerce/promo-cards` registrada | ✅ | `Routes.tsx` — bug fix sesión 6 |
| CRUD campañas tienda | ✅ | `CampanasTiendaList.tsx` + `form/index.tsx` |
| Rutas campañas `/ecommerce/campanas` + `/nueva` + `/:id/editar` | ✅ | `Routes.tsx` |
| Formulario config tienda (PATCH) + sección delivery | ✅ | `ConfiguracionTienda.tsx` |
| Uploader de imagen en categorías | ✅ | `CategoriaFormModal.tsx` — ya existía |
| Botón "Ver en tienda" en todas las páginas E-commerce | ✅ | 4 `index.tsx` de ecommerce — sesión 6 |
| Singleton guard `ConfigPublicaEcommerce.save()` | ✅ | `models.py` — ya existía |

### FASE 5 — Sistema de precios por campaña (sesión 7) ✅ COMPLETADO

| Item | Estado | Archivo |
|------|--------|---------|
| `CampanaTienda` — nuevos campos `tipo_precio`, `porcentaje`, `fecha_inicio_precio` | ✅ | `apps/ecommerce/models.py` |
| Migración `0005_campana_tipo_precio_fecha_inicio_precio` | ✅ | Aplicada |
| `CampanaTiendaAdminSerializer` — validación mutual exclusión | ✅ | `apps/ecommerce/serializers_admin.py` |
| Campo `campana_tienda_activa` en endpoint público de lista | ✅ | `apps/inventario/serializers_publicos.py` + 3 Subquery annotations en `views_publicas.py` |
| Campo `campana_tienda_activa` en endpoint público de detalle | ✅ | `apps/inventario/serializers_publicos.py` (query directa a `CampanaTienda`) |
| `CampanasTiendaList.tsx` — columna "Ajuste Precio" con tipo_precio/porcentaje | ✅ | ERP frontend |
| `form/index.tsx` — selector tipo_precio + porcentaje + fecha_inicio_precio | ✅ | ERP frontend |
| `ProductCard.tsx` — badge "Precio de temporada" para aumento | ✅ | Amatista-eco |
| `CampanaTiendaActiva` type en `src/types/product.ts` | ✅ | Amatista-eco |

---

## ACCIÓN REQUERIDA INMEDIATA

```
⚠️  APLICAR MIGRACIÓN (no se ha aplicado todavía)

cd Amatista-be
python manage.py migrate ecommerce

Esto crea 2 tablas:
  - banners_home
  - config_publica_ecommerce

SIN esta migración, todos los endpoints de ecommerce retornan 500.
```

---

## ENDPOINTS COMPLETOS

### Públicos (AllowAny)

| Método | URL | Descripción |
|--------|-----|-------------|
| GET | `/api/v1/shop/banners/` | Banners activos y vigentes |
| GET | `/api/v1/shop/config/` | Config pública (singleton): WA, IG, FB, TK |
| GET | `/api/v1/shop/productos/` | Lista; soporta `?campana_activa=true` |
| GET | `/api/v1/shop/productos/<slug>/` | Detalle — `campana_activa` incluida |
| GET | `/api/v1/shop/categorias/` | Categorías activas |
| POST | `/api/v1/shop/pedidos/` | Crear pedido |
| GET | `/api/v1/publico/pedidos/seguimiento/<codigo>/` | Tracking |

### Autenticados ERP (IsAuthenticated + EsAdmin)

| Método | URL | Descripción |
|--------|-----|-------------|
| GET/POST | `/api/v1/ecommerce/banners/` | Listar todos / Crear |
| GET/PATCH/DELETE | `/api/v1/ecommerce/banners/<id>/` | Detalle / Editar / Eliminar |
| GET/PATCH | `/api/v1/ecommerce/config/` | Leer / Editar config singleton |

---

## PENDIENTES SESIÓN SIGUIENTE

### Estado de migraciones (sesión 7)
- Todas aplicadas: `0001` → `0005` ✅
- `python manage.py check` → 0 issues ✅

### Decisiones arquitectónicas tomadas (sesión 7)
- **Option B**: `campana_activa` (de `ventas.Campana`) y `campana_tienda_activa` (de `ecommerce.CampanaTienda`) son **dos campos separados** en el endpoint público. `ventas.Campana` NO se modificó. Separación limpia de responsabilidades.
- La ordenación de múltiples `CampanaTienda` activas prioriza `tipo='aumento'` sobre `'descuento'` (orden alfabético inverso `"-campana__tipo_precio"`).

### Pendiente real (no alucinar — verificado en código)
1. **Drag & drop ordering** para Banners y PromoCards — actualmente orden manual con número. Usar `@dnd-kit/sortable` (ya en el proyecto). Requiere endpoint batch `POST /api/v1/ecommerce/banners/reordenar/` y `POST /api/v1/ecommerce/promo-cards/reordenar/`.
2. **`VITE_SHOP_URL`** — agregar al `.env` de Amatista-fe para que el botón "Ver tienda" use la URL de producción. Actualmente fallback a `http://localhost:3000`.
3. **Precio calculado en la tienda** — cuando `campana_tienda_activa.tipo_precio == 'aumento'`, el frontend eco muestra el badge pero NO recalcula el precio (el precio del backend ya refleja el ajuste, o no — verificar si el backend aplica el porcentaje al calcular `precio_venta` o si es solo informativo).
4. **Endpoints CRUD de `CampanaTiendaProducto`** — el formulario del ERP envía `producto_ids` pero no está claro si el serializer admin lo gestiona. Verificar `serializers_admin.py` para el M2M con `CampanaTiendaProducto`.

---

## NOTAS TÉCNICAS

### campana_activa en el listado de productos
- El queryset de `ShopProductoListView` anota cada producto con `_campana_nombre` y `_campana_descuento` via `Subquery` desde `CampanaProducto` (modelo `ventas.Campana`). Zero N+1.
- El serializer lee esas anotaciones en `get_campana_activa()`.
- El tipo `Product` en el frontend incluye `campana_activa: CampanaActiva | null`.

### campana_tienda_activa (nueva, sesión 7)
- Campo SEPARADO de `campana_activa`. Usa `ecommerce.CampanaTienda` + `CampanaTiendaProducto`.
- Listado: 3 Subquery annotations en `views_publicas.py`: `_ct_nombre`, `_ct_tipo_precio`, `_ct_porcentaje`.
- Detalle: query directa a `CampanaTienda` en `get_campana_tienda_activa()` del `ShopProductoDetailSerializer`.
- Filtra por `precio activo hoy`: `fecha_inicio_precio <= hoy` O (`fecha_inicio_precio IS NULL AND fecha_inicio <= hoy`), y siempre `fecha_fin >= hoy`.
- Tipo `CampanaTiendaActiva` en `src/types/product.ts` (Amatista-eco).
- `ProductCard.tsx` muestra badge naranja "Precio de temporada" cuando `tipo_precio == 'aumento'`, badge rojo `-X%` cuando `tipo_precio == 'descuento'` (si no hay ya `campana_activa`).

### ProductCard — badge y precio tachado
- Si `campana_activa` no es null: muestra badge `-X%` en rojo sobre la imagen, nombre de campaña debajo, precio original tachado.
- Si solo `destacado=true`: muestra badge "Destacado" en púrpura.
- El precio original se calcula: `precio_venta / (1 - descuento/100)`.

### WhatsAppButton — dinámica server-side
- `layout.tsx` es `async`, llama a `getShopConfig()` en SSR.
- Pasa `phoneNumber` como prop a `WhatsAppButton` (client component).
- Si el backend no responde, usa `siteConfig.contact.whatsapp` como fallback.
- Si `phoneNumber` está vacío, el botón no se renderiza.

### FlashSalesOne — con campañas reales
- Primero pide `?campana_activa=true`; si hay resultados, usa los nombres de campaña como título de cada slide y calcula el % de descuento para el subtítulo.
- Si no hay campañas, muestra los 6 productos más recientes con títulos genéricos.

### Metadata SEO
- `layout.tsx`: título "Amatista — Detalles que Enamoran | Florería en Lima", description de `siteConfig`.
- `page.tsx`: título más largo con keywords, description con flores específicas, OpenGraph configurado.
