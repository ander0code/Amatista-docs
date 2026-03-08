# Sesión 3 — Ecommerce Amatista — Resumen y pendientes

> Archivo temporal de handoff. Borrar cuando todo esté en producción.
> Basado en código real implementado. Sin especulación.

---

## ¿Qué se hizo en esta sesión?

Flujo completo de **contenido dinámico gestionado desde el ERP**:
promo cards, configuración de delivery y conexión de esos datos al ecommerce.

---

## Archivos creados / modificados

### `Amatista-be/` — (ya estaba hecho al inicio de sesión, migración aplicada)

```
apps/ecommerce/
  models.py
    — PromoCard (UUID PK, etiqueta, titulo, subtitulo, imagen_url,
                 texto_boton, link_destino, orden, activo)
    — ConfigPublicaEcommerce ampliada con:
        texto_delivery   (default: "Delivery el mismo día en Lima")
        horario_delivery (default: "de 9:00 AM a 8:00 PM")
        minimo_delivery  (DecimalField, null=True)

  serializers_admin.py    — PromoCardAdminSerializer
  serializers_publicos.py — PromoCardSerializer + Config actualizado
  views_admin.py          — PromoCardListCreateView, PromoCardDetailView,
                            PromoCardUploadImagenView
  views_publicas.py       — ShopPromoCardListView + Config defaults
  urls_admin.py           — /ecommerce/promo-cards/ + /<uuid>/ + /<uuid>/imagen/
  urls_publicas.py        — /shop/promo-cards/
  migrations/0004_promo_cards_delivery_config.py  ← APLICADA ✅
```

**Endpoints resultantes:**
| Método | URL | Acceso |
|--------|-----|--------|
| GET | `/api/v1/shop/promo-cards/` | público |
| GET | `/api/v1/shop/config/` | público (incluye campos delivery) |
| GET/POST | `/api/v1/ecommerce/promo-cards/` | admin |
| GET/PATCH/DELETE | `/api/v1/ecommerce/promo-cards/<uuid>/` | admin |
| POST | `/api/v1/ecommerce/promo-cards/<uuid>/imagen/` | admin, multipart |

---

### `Amatista-fe/` — módulo ERP

**Creados:**
```
src/app/(admin)/(app)/(ecommerce)/promo-cards/
  components/PromoCardList.tsx   ← CRUD completo (igual patrón que BannerList.tsx)
  index.tsx                      ← página wrapper
```

**Modificados:**
```
src/components/layouts/SideNav/menu.ts
  — nuevo ítem: EcommercePromoCards → /ecommerce/promo-cards (ícono LuLayoutGrid)
  — posición: entre "Config. Visual / Fotos" y "Campañas Tienda"

src/app/(admin)/(app)/(ecommerce)/configuracion/components/ConfiguracionTienda.tsx
  — interfaz ShopConfig ampliada con: texto_delivery, horario_delivery, minimo_delivery
  — nueva sección "Configuración de Delivery" (3 campos editables)
  — se guarda con el mismo PATCH a /api/v1/ecommerce/config/
```

---

### `Template_original/marketpro/` — ecommerce Next.js

**Creado:**
```
src/lib/api/ecommerce.js
  — getPromoCards()   → GET /api/v1/shop/promo-cards/  (fallback [])
  — getShopConfig()   → GET /api/v1/shop/config/       (fallback null)
```

**Modificados:**
```
src/app/page.jsx
  — import getPromoCards, getShopConfig
  — Promise.all ahora tiene 8 llamadas (era 6)
  — <PromotionalOne promoCards={promoCards} />
  — <DeliveryOne config={shopConfig} />

src/components/PromotionalOne.jsx
  — ya NO tiene array hardcodeado
  — recibe prop promoCards[]
  — si promoCards.length === 0 → return null (sección invisible)
  — muestra hasta 4 cards con imagen del back + gradiente de fallback por índice

src/components/DeliveryOne.jsx
  — recibe prop config
  — usa config.texto_delivery, config.horario_delivery, config.minimo_delivery
  — si config es null → defaults hardcodeados (back caído no rompe la franja)
```

**Build:** ✅ 22 páginas, 0 errores, 0 warnings TypeScript.

---

## Comportamiento esperado

### PromoCards (sección home tienda)
- Sin cards en BD → la sección `<PromotionalOne>` no aparece en el home
- Con 1-4 cards activas → aparecen en la grilla 4 columnas
- Con imagen subida → se muestra la imagen (semitransparente como fondo)
- Sin imagen → gradiente de fallback (rosa/púrpura/naranja por índice)

### Delivery (franja home tienda)
- Con config en BD → muestra el texto y horario configurados desde el ERP
- Sin config (primer arranque o back caído) → texto por defecto "Delivery el mismo día en Lima — de 9:00 AM a 8:00 PM"
- Con `minimo_delivery` → aparece línea "En pedidos desde S/ {monto}"
- Sin `minimo_delivery` → esa línea no aparece

---

## Patrón de upload de imagen en ERP

El uploader de `PromoCardList.tsx` sigue exactamente el patrón de `BannerList.tsx`:
1. Usuario hace clic → abre `<input type="file">`
2. Preview local inmediato con `URL.createObjectURL`
3. POST multipart a `/<id>/imagen/` con campo `archivo`
4. Si éxito → actualiza preview con URL de R2
5. Si error → revierte preview y muestra toast

---

## Qué falta / próximos pasos sugeridos

### ERP (`Amatista-fe`)

**A. Imágenes de categorías desde el ERP**
El endpoint ya existe en el backend:
```
POST /api/v1/inventario/categorias/<uuid>/imagen/
```
Pero la página de Categorías (`/inventario/categorias`) todavía no tiene uploader de imagen.
Agregar el mismo componente `ImageUploader` dentro de la fila o modal de edición de categoría.

**B. Router — verificar que `/ecommerce/promo-cards` está declarado**
El ERP usa Vite + react-router. Revisar si las rutas de ecommerce están declaradas en un router
central o si el file-system routing de la carpeta `(ecommerce)` se registra automáticamente.
Si no está declarado, agregar la ruta en el archivo de rutas correspondiente.

**C. Vista previa del home desde el ERP**
Botón "Ver en tienda" en el header de la sección E-commerce que abra `http://localhost:3000`
en nueva pestaña. Mejora UX sin costo técnico.

**D. Orden drag & drop para Promo Cards y Banners**
Actualmente el orden se edita manualmente con un campo numérico.
Implementar drag & drop con `@dnd-kit/sortable` (ya usado en el proyecto) para reordenar
visualmente y hacer PATCH del campo `orden` en batch.

### Backend (`Amatista-be`)

**E. Validar unicidad del singleton ConfigPublicaEcommerce**
Si se llama POST dos veces al config se crean dos registros. Agregar `Meta.constraints` o
sobreescribir `save()` para que solo exista uno.

**F. Endpoint de reordenamiento batch para PromoCards**
`POST /api/v1/ecommerce/promo-cards/reordenar/`
Body: `[{ "id": "uuid", "orden": 0 }, ...]`
Permite actualizar el orden de todas las cards en una sola llamada (útil si se implementa DnD).

**G. Campo `color_fondo` en PromoCard (opcional)**
Actualmente el ecommerce usa gradientes hardcodeados como fallback.
Si se agrega `color_fondo` (CharField, default vacío) al modelo, el admin puede personalizar
el color de cada card desde el ERP.

### Ecommerce (`marketpro`)

**H. Imágenes de categorías dinámicas**
`FeatureOne.jsx` ya recibe `categories` del back, pero si la categoría no tiene `imagen_url`
muestra un placeholder. Una vez que el ERP permita subir imágenes de categoría (punto A),
`FeatureOne.jsx` ya las mostraría automáticamente sin cambios adicionales.

**I. Footer dinámico**
`FooterOne.jsx` tiene datos hardcodeados (WhatsApp, redes sociales).
Ya existe `GET /api/v1/shop/config/` con esos campos.
Pasar `shopConfig` como prop a `<FooterOne>` y consumirlo.

---

## Estructura de referencias rápidas

```
Patrón CRUD en ERP:
  BannerList.tsx → PromoCardList.tsx (ya existe, úsalo como referencia)

Patrón API pública en marketpro:
  src/lib/api/banners.js → src/lib/api/ecommerce.js (ya existe)

Endpoints públicos base:
  http://localhost:8000/api/v1/shop/

Endpoints admin base:
  http://localhost:8000/api/v1/ecommerce/

ERP dev server:
  http://localhost:5173/

Ecommerce dev server:
  http://localhost:3000/
```
