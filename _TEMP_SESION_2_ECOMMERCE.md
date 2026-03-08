# Sesión 2 — Ecommerce Amatista — Checklist de trabajo

> Archivo temporal de trabajo. Borrar cuando todo esté en producción.
> Basado en código real leído en sesión. Sin especulación.

---

## ESTADO GLOBAL

- [ ] FASE 1 — Fixes Amatista-eco (sin backend)
- [ ] FASE 2 — Backend app `ecommerce/`
- [ ] FASE 3 — Conectar eco al nuevo backend
- [ ] FASE 4 — Módulo ERP Amatista-fe

---

## FASE 1 — Amatista-eco (fixes inmediatos, no depende de backend)

### 1A — site.ts datos reales
- [ ] Reemplazar teléfonos placeholder con datos reales de Amatista
- [ ] Reemplazar email placeholder
- [ ] Reemplazar dirección
- [ ] Actualizar descripción y tagline
- [ ] Actualizar URLs redes sociales

### 1B — FooterOne.tsx
- [ ] Eliminar bloque "Compra en Movimiento" (App Store / Play Store)
- [ ] Mover botones de redes sociales al bloque de contacto
- [ ] El div que queda vacío eliminarlo limpiamente

### 1C — BestSellsOne.tsx
- [ ] Eliminar imagen `special-snacks.png` (fondo bg)
- [ ] Eliminar imagen `special-snacks-img.png` (producto supermercado)
- [ ] Reemplazar panel lateral por diseño limpio Amatista (fondo color púrpura)

### 1D — HotDealsOne.tsx
- [ ] Reemplazar `hot-deals-img.png` por SVG/emoji de flores o placeholder Amatista

### 1E — NewsletterOne.tsx
- [ ] Reemplazar `newsletter-img.png` por SVG/emoji o eliminar la imagen

---

## FASE 2 — Amatista-be: nueva app `ecommerce/`

### 2A — Modelos
- [ ] Crear `apps/ecommerce/__init__.py`
- [ ] Crear `apps/ecommerce/apps.py`
- [ ] Crear `apps/ecommerce/models.py` con:
  - `BannerHome`: imagen_url (CharField), titulo, subtitulo, texto_boton, link_destino, orden, activo, fecha_inicio (nullable), fecha_fin (nullable)
  - `ConfigPublicaEcommerce`: singleton con whatsapp, instagram_url, facebook_url, descripcion_tienda
- [ ] Todos los modelos con UUID PK + TimestampMixin si existe

### 2B — Migraciones
- [ ] Crear `apps/ecommerce/migrations/0001_initial.py`
- [ ] **INFORMAR AL USUARIO ANTES DE APLICAR**

### 2C — Serializers + Views + URLs
- [ ] Crear `apps/ecommerce/serializers_publicos.py`
- [ ] Crear `apps/ecommerce/views_publicas.py` con AllowAny + throttle
- [ ] Crear `apps/ecommerce/urls_publicas.py`
- [ ] Endpoints: GET /api/v1/shop/banners/ y GET /api/v1/shop/config/

### 2D — Registro
- [ ] Agregar `apps.ecommerce` a INSTALLED_APPS en settings.py
- [ ] Registrar rutas en config/urls.py bajo /api/v1/shop/

### 2E — Admin
- [ ] Crear `apps/ecommerce/admin.py` para gestión desde Django admin

### 2F — campana_activa en serializer
- [ ] Agregar campo `campana_activa` a `ShopProductoDetailSerializer`
- [ ] Buscar Campana vigente: fecha_inicio <= hoy <= fecha_fin AND is_active=True
- [ ] Retornar: { nombre, descuento_porcentaje } o null

---

## FASE 3 — Amatista-eco: conectar al nuevo backend

### 3A — BannerOne.tsx dinámico
- [ ] Agregar función `getBanners()` en `src/lib/api/products.ts` (o nuevo archivo)
- [ ] Reescribir BannerOne.tsx para consumir /shop/banners/ via apiClient
- [ ] Skeleton/loading mientras carga
- [ ] Fallback si no hay banners activos

### 3B — Config dinámica (opcional esta sesión)
- [ ] Agregar `getShopConfig()` en api layer
- [ ] Si la config existe en backend, actualizar footer/header dinámicamente

---

## FASE 4 — Amatista-fe: módulo ERP (ecommerce)

### 4A — Banners CRUD
- [ ] Crear `src/app/(admin)/(app)/(ecommerce)/banners/index.tsx`
- [ ] Lista de banners con tabla
- [ ] Crear/editar banner (modal o página)
- [ ] Usar hooks generados por Orval (necesita regenerar schema)

### 4B — Configuración tienda
- [ ] Crear `src/app/(admin)/(app)/(ecommerce)/configuracion/index.tsx`
- [ ] Formulario con WhatsApp, Instagram, descripción
- [ ] PATCH al singleton ConfigPublicaEcommerce

---

## Decisiones tomadas (no requieren confirmación adicional)

1. `BannerHome` usa `imagen_url` (CharField) para flexibilidad — no FK a MediaArchivo todavía
   (el upload de imágenes es un paso posterior; por ahora el operador puede pegar una URL)
2. `ConfigPublicaEcommerce` solo tiene campos que NO existen en `Configuracion`:
   whatsapp, instagram_url, facebook_url, descripcion_tienda
   Los datos fiscales y logo siguen en `Configuracion`
3. Imágenes genéricas del template se reemplazan con SVG inline o colores de marca
   (no hay assets Amatista reales disponibles todavía)

---

## Archivos a tocar por proyecto

### Amatista-eco/
- `src/config/site.ts` — datos reales
- `src/components/layout/FooterOne.tsx` — quitar app, mover social
- `src/components/home-one/BestSellsOne.tsx` — quitar imágenes genéricas
- `src/components/home-one/HotDealsOne.tsx` — quitar hot-deals-img.png
- `src/components/home-one/NewsletterOne.tsx` — quitar newsletter-img.png
- `src/components/home-one/BannerOne.tsx` — conectar al backend
- `src/lib/api/products.ts` — agregar getBanners()

### Amatista-be/ (NUEVA app)
- `apps/ecommerce/__init__.py`
- `apps/ecommerce/apps.py`
- `apps/ecommerce/models.py`
- `apps/ecommerce/admin.py`
- `apps/ecommerce/serializers_publicos.py`
- `apps/ecommerce/views_publicas.py`
- `apps/ecommerce/urls_publicas.py`
- `apps/ecommerce/migrations/0001_initial.py`
- `config/settings/base.py` — agregar a INSTALLED_APPS
- `config/urls.py` — registrar rutas
- `apps/inventario/serializers_publicos.py` — agregar campana_activa

### Amatista-fe/
- `src/app/(admin)/(app)/(ecommerce)/banners/index.tsx` (nuevo)
- `src/app/(admin)/(app)/(ecommerce)/configuracion/index.tsx` (nuevo)

---

## Notas técnicas

- `BannerHome` muestra banners donde: `activo=True` AND (fecha_fin IS NULL OR fecha_fin >= hoy)
- `ConfigPublicaEcommerce` es singleton — el view devuelve el primer objeto o 404 con defaults
- El serializer de `Campana` no expone `precio_compra` ni costos
- Los banners se ordenan por campo `orden` ASC
