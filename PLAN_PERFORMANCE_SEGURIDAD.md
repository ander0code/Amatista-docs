# Plan de Performance y Seguridad — Amatista

> Generado: 2026-02-26  
> Basado en auditoría completa de `Amatista-fe/` y `Amatista-be/`  
> Reglas de ejecución al final del documento.

---

## Índice

- [Fase 1 — Frontend: Correcciones críticas de bundle y render](#fase-1)
- [Fase 2 — Frontend: Correcciones de runtime y memory leaks](#fase-2)
- [Fase 3 — Frontend: Código muerto, bugs, y limpieza](#fase-3)
- [Fase 4 — Backend: N+1 queries en Ventas (el más grave)](#fase-4)
- [Fase 5 — Backend: N+1 queries en Inventario y otros serializers](#fase-5)
- [Fase 6 — Backend: Bulk operations en Finanzas](#fase-6)
- [Fase 7 — Backend: Cache de permisos y queries de singleton](#fase-7)
- [Fase 8 — Backend: Seguridad en production.py](#fase-8)
- [Fase 9 — SEO y meta tags](#fase-9)
- [Estado de ejecución](#estado)
- [Reglas de ejecución](#reglas)

---

## Fase 1 — Frontend: Correcciones críticas de bundle y render {#fase-1}

> **Mundo:** FE únicamente  
> **Archivos:** `vite.config.ts`, `src/App.tsx`, `src/routes/index.tsx`  
> **Riesgo:** Alto — son archivos transversales. Un error aquí rompe toda la app.  
> **Regla aplicable:** Regla 10 — leer completo, UN cambio, verificar que la app levanta, luego el siguiente.

### Paso 1.1 — `vite.config.ts`: Añadir `manualChunks` para code splitting

**Problema:** Sin `manualChunks`, Leaflet (~150KB), FullCalendar (~300KB), ApexCharts (~400KB), html5-qrcode (~250KB) van todos en el bundle inicial. Usuarios que nunca usan el mapa o el calendario pagan ese costo igualmente.

**Archivo:** `Amatista-fe/vite.config.ts`

**Cambio a aplicar:**
```ts
// Añadir dentro de defineConfig():
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'vendor-react':    ['react', 'react-dom', 'react-router'],
        'vendor-query':    ['@tanstack/react-query'],
        'vendor-charts':   ['react-apexcharts', 'apexcharts'],
        'vendor-maps':     ['leaflet', 'react-leaflet'],
        'vendor-calendar': ['@fullcalendar/react', '@fullcalendar/core',
                            '@fullcalendar/daygrid', '@fullcalendar/timegrid',
                            '@fullcalendar/interaction', '@fullcalendar/list'],
        'vendor-qr':       ['html5-qrcode'],
        'vendor-ui':       ['swiper', 'flatpickr', 'simplebar-react'],
      },
    },
  },
},
```

**Verificación:** Correr `pnpm build` y revisar que el output muestra chunks separados. La app debe levantar con `pnpm preview` sin errores.

**Estado:** ⬜ Pendiente

---

### Paso 1.2 — `App.tsx`: `ReactQueryDevtools` solo en DEV

**Problema:** `<ReactQueryDevtools>` se incluye en el bundle de producción. Aunque la librería intenta auto-desactivarse en prod, la dependencia sigue en el bundle.

**Archivo:** `Amatista-fe/src/App.tsx`

**Cambio a aplicar:**
```tsx
// Línea actual (~40):
<ReactQueryDevtools initialIsOpen={false} />

// Cambiar por:
{import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
```

**Verificación:** La app levanta. En producción (`pnpm build && pnpm preview`) el panel de devtools no aparece.

**Estado:** ⬜ Pendiente

---

### Paso 1.3 — `routes/index.tsx`: Envolver rutas en `<Suspense>`

**Problema:** Todas las rutas usan `React.lazy()` pero ninguna tiene `<Suspense>`. Si el chunk no ha cargado, React lanza un error sin fallback visual — pantalla en blanco o crash.

**Archivo:** `Amatista-fe/src/routes/index.tsx`

**Cambio a aplicar:**
```tsx
// Añadir import al inicio:
import { Suspense } from 'react';

// Envolver cada route.element en el map de layoutsRoutes:
element={
  <ProtectedRoute requiredPermission={route.requiredPermission} requiredRole={route.requiredRole}>
    <Suspense fallback={<FullPageSpinner />}>
      <PageWrapper>{route.element}</PageWrapper>
    </Suspense>
  </ProtectedRoute>
}

// Y para singlePageRoutes:
element={
  <Suspense fallback={<FullPageSpinner />}>
    {route.element}
  </Suspense>
}
```

> Nota: Verificar que ya existe un componente `FullPageSpinner` o usar el spinner que ya está en `ProtectedRoute`. Si no existe, crearlo antes.

**Verificación:** Navegar a una ruta lazy, confirmar que se ve el spinner en lugar de pantalla en blanco mientras carga.

**Estado:** ⬜ Pendiente

---

### Paso 1.4 — `main.tsx`: Añadir `gcTime` al QueryClient

**Problema:** Sin `gcTime` explícito, el cache de TanStack Query expira a los 5 minutos. En un ERP donde los usuarios cambian de pestaña frecuentemente, cada regreso fuerza un refetch completo.

**Archivo:** `Amatista-fe/src/main.tsx`

**Cambio a aplicar:**
```ts
// Cambiar:
defaultOptions: {
  queries: {
    staleTime: 5 * 60 * 1000,
    retry: 1,
  },
},

// Por:
defaultOptions: {
  queries: {
    staleTime: 5 * 60 * 1000,
    gcTime:    10 * 60 * 1000,  // mantener cache 10 min sin suscriptores
    retry: 1,
  },
},
```

**Verificación:** La app levanta. En DevTools de React Query se ve `gcTime: 600000`.

**Estado:** ⬜ Pendiente

---

## Fase 2 — Frontend: Correcciones de runtime y memory leaks {#fase-2}

> **Mundo:** FE únicamente  
> **Archivos:** `ProvidersWrapper.tsx`, `index.html`, `assets/css/style.css`  
> **Riesgo:** Medio — `ProvidersWrapper` afecta componentes Preline UI. Verificar visualmente después.  
> **Regla aplicable:** Regla 11 — antes de eliminar el MutationObserver, verificar qué depende de él.

### Paso 2.1 — `ProvidersWrapper.tsx`: Eliminar MutationObserver

**Problema:** Un `MutationObserver` sobre `document.body` con `subtree: true` llama a `HSStaticMethods.autoInit()` en **cada cambio del DOM** — cada keystroke en un input, cada spinner, cada toggle de clase. En un ERP activo esto se ejecuta miles de veces por sesión. `autoInit()` re-inicializa todos los componentes Preline UI — es caro.

El segundo `useEffect` que ya existe (corre en cambio de ruta) es suficiente para Preline.

**Archivo:** `Amatista-fe/src/components/ProvidersWrapper.tsx`

**Cambio a aplicar:**
```tsx
// Eliminar completamente este useEffect:
useEffect(() => {
  const observer = new MutationObserver(() => {
    if (window.HSStaticMethods) {
      window.HSStaticMethods.autoInit();
    }
  });
  observer.observe(document.body, { childList: true, subtree: true });
  return () => observer.disconnect();
}, []);
// El useEffect de cambio de ruta se mantiene intacto.
```

**Verificación post-cambio:** Navegar por al menos 5 páginas distintas con dropdowns, modales y tooltips de Preline. Confirmar que siguen funcionando correctamente. Si algún componente Preline deja de inicializarse, la solución alternativa es llamar `autoInit()` con un debounce de 300ms en el effect de ruta.

**Estado:** ⬜ Pendiente

---

### Paso 2.2 — `index.html` + `style.css`: Google Fonts sin bloqueo de render

**Problema:** Los `@import url('https://fonts.googleapis.com/...')` en `style.css` son render-blocking: el browser no puede continuar parseando el CSS hasta que la fuente responda. Añade un RTT completo al critical path.

**Archivo A:** `Amatista-fe/index.html`  
**Archivo B:** `Amatista-fe/src/assets/css/style.css`

**Cambio en `index.html`** — añadir antes del `</head>`:
```html
<!-- Preconexión a Google Fonts (elimina el RTT de DNS+TCP+TLS) -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<!-- Cargar fonts de forma no bloqueante -->
<link rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Montserrat:wght@400;500;600&display=swap">
```

**Cambio en `style.css`** — eliminar las líneas `@import` de Google Fonts (las que ya movimos a `index.html`).

> Importante: Verificar cuántos `@import` de Google Fonts hay en `style.css` antes de editar — puede haber más de uno (Playfair + Tourney + Montserrat).

**Verificación:** La app carga, las fuentes se ven igual. En Network tab del browser, las fonts aparecen como `preconnect`-optimizadas.

**Estado:** ⬜ Pendiente

---

### Paso 2.3 — `index.html`: Meta tags esenciales

**Problema:** `lang="en"` en una app en español, sin `robots: noindex` (ERP privado), sin `theme-color`, sin descripción.

**Archivo:** `Amatista-fe/index.html`

**Cambios a aplicar:**
```html
<!-- Cambiar: -->
<html lang="en">
<!-- Por: -->
<html lang="es">

<!-- Añadir dentro de <head>: -->
<meta name="description" content="Amatista — Sistema de gestión para boutique floral">
<meta name="theme-color" content="#8E338A">
<meta name="robots" content="noindex, nofollow">
```

**Verificación:** El HTML renderizado en el browser muestra `lang="es"`. En móvil, la barra del navegador es púrpura.

**Estado:** ⬜ Pendiente

---

### Paso 2.4 — Dashboard queries: añadir `enabled` por permisos

**Problema:** El dashboard dispara 10 requests HTTP al montar, independientemente de si el usuario tiene permisos. Las permission checks solo afectan el render, no el fetch.

**Archivo:** `Amatista-fe/src/app/(admin)/(dashboards)/index/index.tsx`

**Cambio a aplicar — ejemplo para cada query:**
```tsx
// Antes:
const { data: kpis } = useReportesDashboardRetrieve();

// Después:
const { data: kpis } = useReportesDashboardRetrieve({
  query: { enabled: hasPermission('ver_ventas') }
});
```
> Aplicar el `enabled` correcto a cada uno de los 10 hooks según el permiso que ya controla su render.

**Verificación:** Un usuario sin `ver_ventas` no genera requests al dashboard de ventas. Verificar en Network tab.

**Estado:** ⬜ Pendiente

---

### Paso 2.5 — `useLayoutContext.tsx`: Corregir clave de localStorage

**Problema:** La clave `'__TAILWICK_NEXT_CONFIG__'` es un remanente del template original. Si un usuario tuvo instalado el template base, tendrá data stale bajo esa clave causando estados de layout incorrectos.

**Archivo:** `Amatista-fe/src/context/useLayoutContext.tsx`

**Cambio:**
```tsx
// Cambiar:
useLocalStorage<LayoutStateType>('__TAILWICK_NEXT_CONFIG__', INIT_STATE)
// Por:
useLocalStorage<LayoutStateType>('__AMATISTA_LAYOUT__', INIT_STATE)
```

**Verificación:** Abrir la app en un browser limpio. El layout carga con los valores por defecto. En Application > LocalStorage se ve la nueva clave.

**Estado:** ⬜ Pendiente

---

## Fase 3 — Frontend: Código muerto, bugs, y limpieza {#fase-3}

> **Mundo:** FE únicamente  
> **Archivos:** varios  
> **Riesgo:** Bajo — son eliminations y fixes puntuales.

### Paso 3.1 — Eliminar `layout.tsx` duplicado

**Problema:** `src/app/(admin)/layout.tsx` es byte-por-byte idéntico a `src/components/PageWrapper.tsx`. El router usa `PageWrapper`, `layout.tsx` nunca se importa.

**Acción:** Leer ambos archivos, confirmar que son idénticos, eliminar `layout.tsx`.

**Estado:** ⬜ Pendiente

---

### Paso 3.2 — Eliminar `authService.ts` (código muerto)

**Problema:** `src/services/authService.ts` nunca es importado por nada. `AuthContext` usa fetch directo y hooks Orval.

**Acción:** Confirmar con grep que nada lo importa, luego eliminarlo.

**Estado:** ⬜ Pendiente

---

### Paso 3.3 — Fix link roto en `WelcomeUser.tsx`

**Problema:** Enlace a `/ventas/pos` pero la ruta real en `Routes.tsx` es `/ventas/pedido-pos`.

**Archivo:** `src/app/(admin)/(dashboards)/index/components/WelcomeUser.tsx` línea ~64

**Cambio:**
```tsx
// De:
<Link to="/ventas/pos">
// A:
<Link to="/ventas/pedido-pos">
```

**Estado:** ⬜ Pendiente

---

### Paso 3.4 — Fix "Buy Now" en Customizer

**Problema:** `buyLink = ''` en `helpers/constants.ts` hace que el botón "Buy Now" sea un `<a href="">` — recarga la página completa al hacer clic.

**Acciones:**
1. Si el botón no tiene uso real en este proyecto: eliminarlo del template del Customizer.
2. Si se quiere conservar: asignarle una URL válida o `href="#"` con `e.preventDefault()`.

**Estado:** ⬜ Pendiente

---

### Paso 3.5 — Fix `key={index}` en DataTable y Dashboard

**Problema:** `key={index}` en tablas causa reconciliación incorrecta de React al reordenar o eliminar filas.

**Archivos:**
- `src/components/common/DataTable.tsx` línea ~55
- `src/app/(admin)/(dashboards)/index/index.tsx` línea ~965

**Cambio:**
```tsx
// De:
{data.map((item, index) => <tr key={index}>
// A:
{data.map((item) => <tr key={(item as { id: string | number }).id}>
```

**Estado:** ⬜ Pendiente

---

### Paso 3.6 — `ContingenciaBanner` + `DemoBanner`: deduplicar refetchInterval

**Problema:** Ambos componentes suscriben independientemente a `useFacturacionContingenciaRetrieve` con `refetchInterval: 60_000`. TanStack Query deduplica la request, pero mantiene dos timers — el endpoint se consulta el doble de frecuente (~cada 30s efectivos).

**Archivo:** `src/components/layouts/topbar/index.tsx` (o donde se montan ambos)

**Acción:** Elevar el hook al componente padre Topbar, pasar el resultado como prop a ambos banners.

**Estado:** ⬜ Pendiente

---

### Paso 3.7 — `AddNew.tsx`: limpiar setTimeout

**Problema:** `setTimeout(() => navigate(...), 1800)` sin cleanup. Si el componente se desmonta antes de 1800ms, el navigate se dispara sobre un componente muerto.

**Archivo:** `src/app/(admin)/(app)/(invoice)/add-new/components/AddNew.tsx` línea ~141

**Cambio:**
```tsx
// Dentro del onSuccess:
const timer = setTimeout(() => navigate('/facturacion'), 1800);
// Asegurarse de retornar cleanup si el componente usa useEffect,
// o mover la lógica a useEffect con dep en el flag de éxito:
useEffect(() => {
  if (!successMsg) return;
  const timer = setTimeout(() => navigate('/facturacion'), 1800);
  return () => clearTimeout(timer);
}, [successMsg, navigate]);
```

**Estado:** ⬜ Pendiente

---

## Fase 4 — Backend: N+1 queries en Ventas {#fase-4}

> **Mundo:** BE únicamente  
> **Archivos:** `apps/ventas/views.py`, `apps/ventas/serializers.py`  
> **Riesgo:** Alto — afecta los endpoints más usados del sistema.  
> **Regla aplicable:** Regla 12 — verificar con Django shell contando queries antes y después.

### Paso 4.1 — `VentaViewSet.get_queryset()`: añadir prefetch de pedidos

**Problema:** `VentaListSerializer.get_pedido_info` y `VentaDetailSerializer.get_pedido_id/get_pedido_detalle` hacen `obj.pedidos.filter(is_active=True).first()` — una query por cada Venta. Con 50 ventas paginadas = 50-150 queries extras.

**Archivo:** `apps/ventas/views.py` — método `get_queryset()` de `VentaViewSet`

**Cambio a aplicar:**
```python
# Añadir al queryset existente:
from django.db.models import Prefetch
from apps.distribucion.models import Pedido  # ajustar import según la app real

.prefetch_related(
    Prefetch(
        'pedidos',
        queryset=Pedido.objects.filter(is_active=True)
                               .select_related('transportista'),
        to_attr='pedidos_activos'
    )
)
```

**Y en el serializer**, cambiar los métodos para usar el atributo prefetcheado:
```python
def get_pedido_info(self, obj):
    pedidos = getattr(obj, 'pedidos_activos', None)
    if not pedidos:
        return None
    pedido = pedidos[0]
    # ... resto de la lógica
```

**Verificación con Django shell:**
```python
from django.test.utils import CaptureQueriesContext
from django.db import connection
from apps.ventas.models import Venta

with CaptureQueriesContext(connection) as ctx:
    ventas = list(Venta.objects.all()[:20])  # simular list view
    # serializar...
print(f"Queries: {len(ctx.captured_queries)}")
# Antes: ~60-80 queries para 20 ventas
# Después: ~3-5 queries para 20 ventas
```

**Estado:** ⬜ Pendiente

---

### Paso 4.2 — `VentaViewSet.get_queryset()`: prefetch de imágenes de productos

**Problema:** `DetalleVentaSerializer.get_producto_imagen_url` hace queries a `MediaArchivo` por cada línea de detalle. Una venta con 10 ítems genera 10-20 queries extras.

**Archivo:** `apps/ventas/views.py`

**Cambio a aplicar:**
```python
# Añadir al prefetch_related existente:
from apps.media.models import MediaArchivo

Prefetch(
    'detalles__producto__imagenes',
    queryset=MediaArchivo.objects.filter(es_principal=True),
    to_attr='imagenes_principales'
)
```

**Y en el serializer:**
```python
def get_producto_imagen_url(self, obj):
    imagenes = getattr(obj.producto, 'imagenes_principales', [])
    if imagenes:
        return imagenes[0].url  # o el campo correcto
    return None
```

**Verificación:** Igual que 4.1 — medir queries antes y después con `CaptureQueriesContext`.

**Estado:** ⬜ Pendiente

---

## Fase 5 — Backend: N+1 en Inventario y otros serializers {#fase-5}

> **Mundo:** BE únicamente  
> **Archivos:** `apps/inventario/serializers.py`, `apps/inventario/views.py`  
> **Riesgo:** Medio

### Paso 5.1 — Anotar `subcategorias_count` en `CategoriaViewSet`

**Problema:** `CategoriaSerializer.get_subcategorias_count` hace `obj.subcategorias.filter(is_active=True).count()` — una query por categoría.

**Archivo:** `apps/inventario/views.py` — `CategoriaViewSet.get_queryset()`

**Cambio:**
```python
from django.db.models import Count, Q

def get_queryset(self):
    return Categoria.objects.annotate(
        subcategorias_count=Count(
            'subcategorias',
            filter=Q(subcategorias__is_active=True)
        )
    )
```

**En el serializer:**
```python
def get_subcategorias_count(self, obj):
    return getattr(obj, 'subcategorias_count', 0)
```

**Estado:** ⬜ Pendiente

---

### Paso 5.2 — Anotar `total_items` en `SolicitudTransferenciaViewSet`

**Problema:** `SolicitudTransferenciaListSerializer.get_total_items` hace `obj.detalles.count()` por ítem.

**Cambio:**
```python
def get_queryset(self):
    return SolicitudTransferencia.objects.annotate(
        total_items=Count('detalles')
    )
```

**En el serializer:**
```python
def get_total_items(self, obj):
    return getattr(obj, 'total_items', 0)
```

**Estado:** ⬜ Pendiente

---

### Paso 5.3 — `ProductoListSerializer`: prefetch imagen principal

**Problema:** `get_imagen_url` en `ProductoListSerializer` tiene un fallback que hace una query a `MediaArchivo` cuando falta el atributo `_imagen_principal_r2_key`.

**Acción:** Revisar `ProductoViewSet.get_queryset()` y añadir `Prefetch` de `MediaArchivo` con `es_principal=True`, igual que en Paso 4.2. Luego eliminar el fallback que hace la query individual.

**Estado:** ⬜ Pendiente

---

## Fase 6 — Backend: Bulk operations en Finanzas {#fase-6}

> **Mundo:** BE únicamente  
> **Archivos:** `apps/finanzas/views.py`  
> **Riesgo:** Medio — operaciones de escritura, requieren `transaction.atomic()`

### Paso 6.1 — `auto_matching`: reemplazar loop de `save()` por `bulk_update`

**Problema:** Loop de `mov.save(update_fields=["conciliado"])` — un UPDATE por movimiento.

**Archivo:** `apps/finanzas/views.py` — acción `auto_matching` (~líneas 1043-1113)

**Cambio:**
```python
# Antes:
for mov in movimientos:
    mov.conciliado = True
    mov.save(update_fields=["conciliado"])

# Después:
ids_a_actualizar = [mov.id for mov in movimientos if criterio_match(mov)]
MovimientoBancario.objects.filter(id__in=ids_a_actualizar).update(
    conciliado=True,
    updated_at=timezone.now()  # si el modelo tiene este campo
)
```

**Verificación:** Ejecutar la acción con datos reales, confirmar que los movimientos quedan conciliados. Verificar en DB.

**Estado:** ⬜ Pendiente

---

### Paso 6.2 — `importar_extracto`: `bulk_create` + `transaction.atomic()`

**Problema:** `MovimientoBancario.objects.create(...)` en loop por cada fila del CSV. Sin transacción — si falla en la fila 50, las primeras 49 quedan commitadas.

**Archivo:** `apps/finanzas/views.py` — acción `importar_extracto` (~líneas 842-998)

**Cambio:**
```python
from django.db import transaction

# Antes:
for row in rows:
    MovimientoBancario.objects.create(**parse_row(row))

# Después:
with transaction.atomic():
    objetos = [MovimientoBancario(**parse_row(row)) for row in rows]
    MovimientoBancario.objects.bulk_create(objetos, batch_size=500)
```

**Verificación:** Importar un CSV de prueba. Confirmar que todos los registros se crean o ninguno (rollback si hay error).

**Estado:** ⬜ Pendiente

---

### Paso 6.3 — `CotizacionKPIsView`: 6 queries → 1 aggregate

**Problema:** 6 llamadas separadas a `.count()` y `.aggregate()` para una sola vista de KPIs.

**Archivo:** `apps/ventas/views.py` — `CotizacionKPIsView` (~líneas 877-895)

**Cambio:**
```python
from django.db.models import Count, Q

resultado = Cotizacion.objects.aggregate(
    total=Count('id'),
    aceptadas=Count('id', filter=Q(estado='aceptada')),
    rechazadas=Count('id', filter=Q(estado='rechazada')),
    vencidas=Count('id', filter=Q(estado='vencida')),
    pendientes=Count('id', filter=Q(estado__in=['pendiente', 'borrador'])),
)
```

**Verificación:** El endpoint retorna los mismos valores que antes. Comparar con los valores en la DB directamente.

**Estado:** ⬜ Pendiente

---

## Fase 7 — Backend: Cache de permisos y queries singleton {#fase-7}

> **Mundo:** BE únicamente  
> **Archivos:** `apps/usuarios/models.py`, `apps/empresa/views.py`, `core/permissions.py`  
> **Riesgo:** Medio — la cache de permisos requiere invalidación correcta al cambiar roles.

### Paso 7.1 — `tiene_permiso()`: cachear permisos por usuario

**Problema:** `RolPermiso.objects.filter(rol=self.rol, permiso__codigo=codigo_permiso).exists()` en cada request autenticado. Con 200 req/min por usuario = 200 DB hits/min solo para permisos.

**Archivo:** `apps/usuarios/models.py` — método `tiene_permiso()` de `PerfilUsuario`

**Cambio:**
```python
from django.core.cache import cache

def tiene_permiso(self, codigo_permiso: str) -> bool:
    cache_key = f'permisos_rol_{self.rol_id}'
    permisos = cache.get(cache_key)
    if permisos is None:
        permisos = set(
            RolPermiso.objects.filter(rol_id=self.rol_id)
                              .values_list('permiso__codigo', flat=True)
        )
        cache.set(cache_key, permisos, timeout=300)  # 5 minutos
    return codigo_permiso in permisos
```

> Usar `rol_id` (no `self.rol`) para evitar query adicional al objeto Rol.

**Invalidación necesaria:** Añadir `cache.delete(f'permisos_rol_{rol_id}')` en el signal o view que modifica `RolPermiso`.

**Verificación:** Con django-debug-toolbar o `CaptureQueriesContext`, confirmar que múltiples requests autenticadas consecutivas no generan queries a `RolPermiso`.

**Estado:** ⬜ Pendiente

---

### Paso 7.2 — `core/permissions.py`: `select_related` en el accessor de perfil

**Problema:** `request.user.perfil.rol.codigo` traversa dos FKs — dos queries adicionales por request.

**Archivo:** `core/permissions.py`

**Opción A (mínima):** En el middleware de autenticación, asegurar que el user se carga con `select_related('perfil__rol')`.

**Opción B (en el permission class):**
```python
def has_permission(self, request, view):
    try:
        # Cargar perfil y rol en una sola query si no está cacheado
        perfil = (PerfilUsuario.objects
                  .select_related('rol')
                  .get(usuario=request.user))
        request._perfil_cache = perfil  # cachear en el request
    except PerfilUsuario.DoesNotExist:
        return False
    return perfil.tiene_permiso(self.permiso_requerido)
```

**Estado:** ⬜ Pendiente

---

### Paso 7.3 — `empresa/views.py`: cachear `Configuracion.objects.first()`

**Problema:** `ConfiguracionView.get_object()` hace `Configuracion.objects.first()` en cada request. Es un singleton que rara vez cambia.

**Archivo:** `apps/empresa/views.py`

**Cambio:**
```python
from django.core.cache import cache

def get_object(self):
    config = cache.get('config_empresa')
    if config is None:
        config = Configuracion.objects.first()
        cache.set('config_empresa', config, timeout=600)  # 10 minutos
    return config
```

**Invalidación:** En el método `update()` del mismo ViewSet, añadir `cache.delete('config_empresa')` después del save.

**Estado:** ⬜ Pendiente

---

### Paso 7.4 — `inventario/tasks.py`: `bulk_create` para notificaciones

**Problema:** `_notificar_supervisores` llama `crear_notificacion()` en un loop — un DB write por supervisor.

**Archivo:** `apps/inventario/tasks.py`

**Cambio:**
```python
# Antes:
for perfil_id in supervisores_ids:
    crear_notificacion(perfil_id, mensaje, ...)

# Después:
from apps.usuarios.models import Notificacion  # ajustar import

notificaciones = [
    Notificacion(perfil_id=pid, mensaje=mensaje, ...)
    for pid in supervisores_ids
]
Notificacion.objects.bulk_create(notificaciones)
```

**Estado:** ⬜ Pendiente

---

## Fase 8 — Backend: Seguridad en production.py {#fase-8}

> **Mundo:** BE únicamente  
> **Archivos:** `config/settings/production.py`, `config/settings/base.py`, `.env`  
> **Riesgo:** ALTO — `SECURE_SSL_REDIRECT = True` en local sin HTTPS rompe el servidor.  
> **Regla aplicable:** Regla 9 — hacer backup antes. NO aplicar en local sin HTTPS configurado.

### Paso 8.1 — `production.py`: Headers de seguridad HTTP

**Problema:** `production.py` tiene solo ~10 líneas. Faltan headers críticos de seguridad.

**Archivo:** `config/settings/production.py`

**Cambio a aplicar (SOLO en servidor con HTTPS real):**
```python
# Seguridad HTTPS
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Cookies seguras
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True

# HSTS — decirle al browser que solo use HTTPS
SECURE_HSTS_SECONDS = 31536000          # 1 año
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Misc
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True

# Performance de conexión DB
CONN_MAX_AGE = 60  # reusar conexiones por 60s (solo con WSGI, NO con ASGI puro)
# Con Daphne/ASGI: dejar en 0 o usar pgBouncer
```

> ⚠️ **No aplicar** `SECURE_SSL_REDIRECT` ni `CONN_MAX_AGE=60` hasta confirmar que el servidor de producción tiene HTTPS y si usa WSGI o ASGI.

**Estado:** ⬜ Pendiente

---

### Paso 8.2 — `base.py`: Fernet key fuera del código

**Problema:** Línea 22 de `base.py` tiene `default="NucfY_bzRPJsHpQzCKaxkL4oNNGfHHZuPpMONWHfhcg="` — una clave Fernet real hardcodeada en el source code.

**Archivo:** `config/settings/base.py` línea ~22

**Cambio:**
```python
# Antes:
FIELD_ENCRYPTION_KEY = env("FIELD_ENCRYPTION_KEY",
                            default="NucfY_bzRPJsHpQzCKaxkL4oNNGfHHZuPpMONWHfhcg=")

# Después:
FIELD_ENCRYPTION_KEY = env("FIELD_ENCRYPTION_KEY")  # sin default — falla rápido si falta
```

**Añadir al `.env` y `.env.example`:**
```
FIELD_ENCRYPTION_KEY=<generar nueva con: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())">
```

> ⚠️ Generar una nueva clave para producción. La clave actual está comprometida al estar en el código fuente.

**Estado:** ⬜ Pendiente

---

### Paso 8.3 — `celery.py`: default a development settings

**Problema:** `os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")` — si alguien corre Celery en dev sin setear la variable de entorno, usa settings de producción.

**Archivo:** `config/celery.py`

**Cambio:**
```python
# Antes:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
# Después:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
```

**Estado:** ⬜ Pendiente

---

## Fase 9 — SEO para plataforma privada {#fase-9}

> **Nota:** Para un ERP privado (login requerido), el SEO clásico de Google no aplica porque las páginas autenticadas no son indexables. Lo que sí importa:

### Lo que SÍ aplica para un ERP privado

| Mejora | Beneficio real | Dónde |
|---|---|---|
| `robots: noindex, nofollow` | Evita que Google indexe el login o URLs expuestas accidentalmente | `index.html` (ya en Fase 2.3) |
| `lang="es"` correcto | Lectores de pantalla, accesibilidad, corrector ortográfico del browser | `index.html` (ya en Fase 2.3) |
| `theme-color` | Color de barra del browser en móvil — experiencia tipo PWA | `index.html` (ya en Fase 2.3) |
| Títulos descriptivos por página | Ya se usa `PageMeta` — está bien implementado | Mantener |
| `<meta name="description">` | Solo para la página de login, que sí es pública técnicamente | `index.html` (ya en Fase 2.3) |

### Lo que NO aplica para este proyecto

- Open Graph / Twitter Cards — no hay contenido público compartible
- Sitemap XML — no hay páginas públicas que indexar
- Schema.org structured data — solo útil para contenido público
- Keywords meta — obsoleto desde 2009
- Canonical URLs — todas las páginas requieren auth

### Conclusión SEO

Todo el SEO relevante queda cubierto en **Fase 2.3** (meta tags en `index.html`). No hay más trabajo de SEO necesario para un ERP privado.

---

## Estado de ejecución {#estado}

| Fase | Paso | Descripción | Estado |
|---|---|---|---|
| 1 | 1.1 | Vite `manualChunks` | ✅ Completado |
| 1 | 1.2 | ReactQueryDevtools solo en DEV | ✅ Completado |
| 1 | 1.3 | Suspense en rutas lazy | ✅ Completado |
| 1 | 1.4 | `gcTime` en QueryClient | ✅ Completado |
| 2 | 2.1 | Eliminar MutationObserver | ✅ Completado |
| 2 | 2.2 | Google Fonts no bloqueante | ✅ Completado |
| 2 | 2.3 | Meta tags en index.html | ✅ Completado |
| 2 | 2.4 | Dashboard queries con `enabled` | ✅ Completado |
| 2 | 2.5 | Clave localStorage Amatista | ✅ Completado |
| 3 | 3.1 | Eliminar layout.tsx duplicado | ✅ Completado |
| 3 | 3.2 | Eliminar authService.ts muerto | ✅ Completado |
| 3 | 3.3 | Fix link `/ventas/pedido-pos` | ✅ Completado |
| 3 | 3.4 | Fix botón Buy Now en Customizer | ✅ Completado |
| 3 | 3.5 | Fix `key={index}` en tablas | ✅ Completado |
| 3 | 3.6 | Deduplicar ContingenciaBanner | ✅ Completado |
| 3 | 3.7 | Limpiar setTimeout en AddNew | ✅ Completado |
| 4 | 4.1 | Prefetch pedidos en VentaViewSet | ✅ Completado |
| 4 | 4.2 | Prefetch imágenes en VentaViewSet | ✅ Completado |
| 5 | 5.1 | Anotar subcategorias_count | ✅ Completado |
| 5 | 5.2 | Anotar total_items en Solicitudes | ✅ Completado |
| 5 | 5.3 | Prefetch imagen en ProductoList | ✅ Completado |
| 6 | 6.1 | bulk_update en auto_matching | ✅ Completado |
| 6 | 6.2 | bulk_create en importar_extracto | ✅ Completado |
| 6 | 6.3 | 6 queries → 1 aggregate KPIs | ✅ Completado |
| 7 | 7.1 | Cache de permisos por rol | ✅ Completado |
| 7 | 7.2 | select_related en permissions.py | ✅ Completado |
| 7 | 7.3 | Cache Configuracion singleton | ✅ Completado |
| 7 | 7.4 | bulk_create notificaciones | ✅ Completado |
| 8 | 8.1 | Headers seguridad production.py | ✅ Completado |
| 8 | 8.2 | Fernet key fuera del código | ✅ Completado |
| 8 | 8.3 | Celery default a development | ✅ Completado |

**Leyenda:** ⬜ Pendiente · 🔄 En progreso · ✅ Completado · ❌ Bloqueado

---

## Reglas de ejecución {#reglas}

1. **Un problema a la vez, nunca varios en paralelo.** Termina uno completamente y confirma que nada se rompió antes de pasar al siguiente.
2. **Antes de editar cualquier archivo, léelo completo.** No asumir por el nombre o la línea del error.
3. **Si el fix requiere cambios en varios lugares, hacerlos todos o ninguno.**
4. **Nunca usar `as any`, casts forzados, o supresores de errores.**
5. **Después de cada archivo modificado, reportar exactamente qué cambió, en qué línea y por qué.**
6. **Si al leer un archivo la corrección requiere más de lo esperado, detener y consultar antes de continuar.**
7. **BE y FE son mundos separados — nunca mezclarlos en el mismo paso.**
8. **Los cambios de performance (N+1, bulk_create, prefetch) siempre se verifican con una request real después.**
9. **Los cambios de seguridad (production.py, Fernet key) NO se aplican en local sin backup previo.**
10. **`QueryClient`, `vite.config.ts` y `App.tsx` son archivos transversales — leer completo, UN cambio, verificar que la app levanta.**
11. **Antes de eliminar el MutationObserver, verificar qué componentes Preline dependen de él.**
12. **Los cambios de N+1 en BE siempre van con prueba en Django shell contando queries antes y después.**

---

## Orden de prioridad recomendado para comenzar

```
🔴 Crítico antes del despliegue:
   1.1 → 1.2 → 1.3 → 8.2 → 8.3

🟠 Alto impacto, hacer pronto:
   1.4 → 2.1 → 2.2 → 2.3 → 4.1 → 4.2 → 7.1

🟡 Importante, no urgente:
   2.4 → 2.5 → 6.1 → 6.2 → 6.3 → 7.2 → 7.3

🟢 Limpieza, cuando haya tiempo:
   3.x → 5.x → 7.4 → 8.1
```
