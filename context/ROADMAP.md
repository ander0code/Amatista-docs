# AMATISTA ERP — Roadmap y Proximos Pasos

> Plan de implementacion priorizado para completar el ERP de Amatista
> y agregar el e-commerce que se integrara en la siguiente fase.

---

## 1. Estado Actual (Mar 2026)

| Modulo | BE | FE | Promedio |
|--------|:--:|:--:|:--------:|
| Ventas / POS | ~90% | ~75% | ~83% |
| Inventario + Control Camara | ~90% | ~80% | ~85% |
| BOM / Recetas + Produccion | ~90% | ~70% | ~80% |
| Facturacion Electronica | ~87% | ~85% | ~86% |
| Distribucion y Seguimiento | ~85% | ~80% | ~83% |
| Compras y Proveedores | ~85% | ~80% | ~83% |
| Gestion Financiera | ~88% | ~85% | ~87% |
| WhatsApp | ~45% | ~65% | ~55% |
| Dashboard y Reportes | ~90% | ~95% | ~93% |
| Usuarios y Roles | ~95% | ~95% | ~95% |
| E-commerce (Tienda Web) | 0% | UI only | ~5% |

> **Modelo de negocio:** Produccion bajo pedido. `crear_venta_pos()` NO descuenta stock.
> El descuento de insumos ocurre al marcar "listo" en Kanban via `completar_produccion_item()`.

---

## 2. Fases del ERP — Estado Real

> **IMPORTANTE:** Las Fases 1-6 que se planificaron originalmente YA estan implementadas
> en el backend (modelos, migraciones, services, views, tasks). Lo que puede faltar
> es completar algunas partes del frontend o habilitar features que estan suspendidas.

### FASE 1 — Control de Camara + Multi-lote: IMPLEMENTADA

**Backend:** COMPLETO
- Campos `tipo_registro`, `descuenta_insumos`, `unidad_compra`, `factor_conversion` en Producto (migracion `0006`)
- Campos `fecha_entrada`, `estado_frescura` en Lote (migracion `0006`)
- `actualizar_estados_frescura()` — task Celery diaria 00:00 (`inventario/tasks.py:85`)
- `obtener_estado_camara()` — endpoint `GET /inventario/camara/` (`inventario/views.py:975`)
- `registrar_salida()` con FIFO (`inventario/services.py:487`)
- `seleccionar_lotes_fifo()` (`inventario/services.py:749`)
- `alertar_lotes_por_vencer` — task diaria 7:00 (`inventario/tasks.py:128`)

**Frontend:** COMPLETO
- Vista "Control de Camara" (`/inventario/camara`) existe en Amatista-fe
- Widget "Estado Camara" en DashboardInventario (link a camara)
- RecetaEditor integrado en formulario de producto

**Pendiente FE:** Verificar UI multi-lote en recepcion de compras.

---

### FASE 2 — BOM: Recetas + Descuento de Insumos: IMPLEMENTADA (FE parcial)

**Backend:** COMPLETO
- Tablas `receta_producto`, `detalle_receta` (migracion `0007`)
- Tablas `ajuste_personalizacion`, `detalle_venta_insumo` (migracion `0011`)
- Campos `notas_arreglista`, `recargo_personalizacion` en DetalleVenta (migracion `0011`)
- `RecetaViewSet` con CRUD + verificar_disponibilidad + calcular_costo_ajuste (`inventario/views.py:1016`)
- `crear_receta()` (`inventario/services.py:1081`)
- `completar_produccion_item()` (`inventario/services.py:1353`)
- `verificar_disponibilidad_insumos()` (`inventario/services.py:1174`)
- `calcular_costo_receta()` y `calcular_costo_estimado_ajuste()` (`inventario/services.py:1229, 1269`)
- Validacion en `crear_venta_pos()`: si `descuenta_insumos=True` sin receta → error

**Frontend:** PARCIAL
- `RecetaEditor.tsx` existe y funcional
- Kanban existe con boton "Marcar como listo"
- **SUSPENDIDO:** La llamada a `completarProduccion` (que descuenta insumos) esta COMENTADA en el Kanban FE. El boton "Listo" mueve estado pero NO llama al endpoint de inventario.
- Panel "Personalizar" en POS: campos existen en BE, UI no construida

---

### FASE 3 — Compras Inteligentes: IMPLEMENTADA (FE por verificar)

**Backend:** COMPLETO
- `generar_lista_compras()` (`inventario/services.py:1465`)
- `generar_oc_desde_lista_compras()` (`inventario/services.py:1633`)
- Endpoints `GET /inventario/lista-compras/` y `POST /inventario/lista-compras/generar-oc/`
- Task `alerta_compras_nocturna` a las 20:00 (`inventario/tasks.py:187`)

**Frontend:** Por verificar si vista `/inventario/compras-inteligentes` existe.

---

### FASE 4 — Precios Diferenciados: IMPLEMENTADA

**Backend:** COMPLETO
- Campo `precio_corporativo` en Producto (migracion `0008`)
- Tabla `regla_descuento` (migracion `0008`)
- `resolver_precio()` integrado en `crear_venta_pos()` (`ventas/services.py:121`)

**Frontend:** Verificar si Badge "Precio Corp." se muestra en POS.

---

### FASE 5 — Cotizaciones Mejoradas: IMPLEMENTADA

**Backend:** COMPLETO
- `generar_cotizacion_pdf()` (`ventas/services.py:1491`)
- `enviar_cotizacion_email()` (`ventas/services.py:1935`)
- `aprobar_cotizacion()` (`ventas/services.py:2070`)
- Campos `aprobada_por` + `aprobada_en` en cotizaciones (migracion `0012`)

**Frontend:** Por verificar botones PDF/Email/Aprobar.

---

### FASE 6 — Campanias de Temporada: IMPLEMENTADA

**Backend:** COMPLETO
- Tablas `campana` + `campana_producto` (migracion `0013`)
- `obtener_campanas_activas()` (`ventas/services.py:1974`)
- `aplicar_descuento_campana()` (`ventas/services.py:1991`)
- `crear_campana()` y `actualizar_campana()` (`ventas/services.py:2011, 2039`)

**Frontend:** Verificar CRUD campanas y badge en POS.

---

## 3. E-commerce (Proxima Gran Feature)

> El e-commerce NO reemplaza el ERP. Vive **al lado**, consumiendo la misma API.
> Los pedidos del e-commerce entran al sistema como Ventas con `tipo_venta='online'`.

### Frontend e-commerce: JS-FE-Shop

Repo: `../JS-FE-Shop/` — Fork del template de e-commerce adaptado para Amatista.

**Stack:** Next.js 16 (App Router, Turbopack), React 19, TypeScript (strict), Tailwind CSS 4, Headless UI, Phosphor Icons, Swiper.

**Estado actual del template: SOLO UI PRESENTACIONAL (0% logica)**

El template trae:
- 13 rutas (3 variantes de home, shop, product-details x2, cart, checkout, wishlist, account, contact, blog x2)
- ~100 componentes con estructura limpia
- Sistema de temas CSS (verde/naranja) via custom properties HSL
- Capa de abstraccion API lista en `src/lib/api/client.ts` → apunta a `localhost:8000/api`
- Types de Product, Category, Navigation definidos
- `siteConfig` ya con branding "Amatista"

Lo que el template **NO tiene** (hay que construirlo):
- Sin estado real de carrito (4 items hardcodeados, totales fijos)
- Sin checkout funcional (formulario sin onSubmit)
- Sin auth (login/register son formularios visuales sin logica)
- Sin rutas dinamicas (`/product/[slug]` no existe — pages son estaticas)
- Sin panel admin/dashboard
- Sin state management (no Redux, Zustand, ni Context)
- Componentes importan de data estatica, no de la capa API
- Cart count hardcodeado a `2` en todos los headers

**Evaluacion: 6/10 — util como base de UI, requiere trabajo significativo de integracion.**

### Donde encaja en Amatista

```
JS-FE-Shop (Next.js 16)
  NEXT_PUBLIC_API_URL=https://api.amatista.com/api
         ↓  consume API publica (AllowAny + rate-limit)
Amatista BE
  ├── /api/publico/productos/          ← catalogo (AllowAny)
  ├── /api/publico/categorias/         ← categorias (AllowAny)
  ├── /api/publico/disponibilidad/{id}/ ← calcula desde receta
  ├── /api/publico/carrito/            ← session/token based
  ├── /api/publico/checkout/           ← crea Venta + Pedido
  ├── /api/publico/auth/               ← registro/login de clientes
  ├── ventas/      ← cada compra web genera Venta [tipo_venta='online']
  ├── distribucion/ ← si hay delivery, genera Pedido (ya existe)
  └── facturacion/ ← emite boleta/factura automaticamente (ya existe)
```

### Problema especifico de floreria con e-commerce: STOCK DE INSUMOS

Este es el punto critico que diferencia a Amatista del e-commerce generico:

```
Cliente web pide: "Ramo Primavera" x1
    ↓
El sistema NO puede simplemente descontar 1 unidad de "Ramo Primavera" del stock
porque los arreglos se arman al momento con las flores disponibles en la camara.
    ↓
El problema:
  - Si hay 10 ramos "Primavera" en el sistema pero solo 3 rosas en la camara (que
    necesita 5 rosas c/u), el sistema mostraria stock de 10 pero solo puede armar 0.
  - Mostrar "10 disponibles" cuando en realidad no se puede armar ni uno es un error grave.
    ↓
La solucion:
  Mostrar disponibilidad calculada desde los INSUMOS, no desde el producto final.
  Disponibilidad = floor(stock_insumo_escaso / cantidad_requerida_por_receta)
  Si hay 8 rosas y la receta pide 5 → disponibilidad real = 1 (se puede armar 1 ramo)
```

### Modelo de negocio vs e-commerce

El negocio opera por **produccion bajo pedido**: `crear_venta_pos()` NO descuenta stock.
Fases 1-6 del ERP (Camara, BOM, Compras, Precios, Cotizaciones, Campanas) **YA estan implementadas en el backend**.

Para e-commerce hay dos opciones:
- **Opcion A (catalogo simple):** Productos como "Disponible/No disponible". El cliente encarga y el equipo lo arma. Compatible con el modelo actual sin cambios.
- **Opcion B (disponibilidad calculada):** Usar `verificar_disponibilidad_insumos()` (ya existe) para mostrar cuantos arreglos se pueden armar. Requiere recetas cargadas y `descuenta_insumos=True` por producto.

**NO hay bloqueo tecnico para empezar el e-commerce.** Las Fases 1-2 ya existen en el codigo.

### Lo que hay que agregar al modelo `Producto` para e-commerce

```python
# Agregar a apps/inventario/models.py — Producto
slug             = models.SlugField(unique=True, blank=True)    # URL amigable
descripcion_larga = models.TextField(blank=True, default="")   # Descripcion completa
destacado        = models.BooleanField(default=False)           # Mostrar en portada
orden_display    = models.PositiveIntegerField(default=0)       # Orden en catalogo
```

### Lo que existe vs lo que falta para el e-commerce

| Componente | Existe | Falta |
|------------|--------|-------|
| Catalogo de productos | SI — `apps/inventario/Producto` | Endpoint publico sin JWT + 4 campos |
| Fotos del producto | SI — `apps/media/MediaArchivo` | Asociacion al catalogo web |
| Control de stock de insumos | SI — `lotes` + `registrar_salida()` FIFO | Calcular disponibilidad desde receta |
| Crear Venta | SI — `crear_venta_pos()` | Pasar `tipo_venta='online'` |
| Distribucion/Delivery | SI — `apps/distribucion/Pedido` | Solo conectar |
| Facturacion SUNAT | SI — `apps/facturacion/` | Nada — funciona igual |
| Frontend e-commerce | SI — `JS-FE-Shop` (solo UI) | Conectar a API, estado carrito, auth, rutas dinamicas |
| Carrito con TTL | NO | Crear `CarritoWeb` + reserva en Redis |
| Pasarela de pago | NO | Integrar Culqi |
| Endpoints publicos | NO | `urls_publicas.py` en inventario + ventas |
| Auth de clientes | NO | Registro/login separado del staff |
| Panel ERP para pedidos web | NO | Vista que filtre por `tipo_venta='online'` |
| **Disponibilidad calculada desde receta** | NO | **Critico para floreria** — calcular desde insumos |

### Trabajo en JS-FE-Shop (cuando se conecte al backend)

| Tarea FE | Prioridad | Complejidad |
|----------|-----------|-------------|
| Crear `/product/[slug]` ruta dinamica | Critica | Media |
| State management para carrito (Zustand o Context) | Critica | Media |
| Conectar componentes a `src/lib/api/` en vez de data estatica | Critica | Media |
| Auth de clientes (login/register funcional) | Critica | Media |
| Checkout funcional (formulario → POST /checkout/) | Critica | Alta |
| Integrar pasarela de pago (Culqi) | Critica | Alta |
| Adaptar theme a design system Amatista (colores, logo) | Media | Baja |
| Quitar secciones no relevantes (blog, marcas, newsletter) | Baja | Baja |
| Loading states, error boundaries | Media | Baja |

### Endpoints a crear en Amatista-be

```
# Catalogo publico (AllowAny + rate-limit)
GET  /api/publico/productos/                    ← catalogo paginado, filtros
GET  /api/publico/productos/{slug}/             ← detalle con imagenes
GET  /api/publico/categorias/                   ← arbol de categorias
GET  /api/publico/disponibilidad/{producto_id}/ ← calcula desde receta + stock insumos

# Carrito (session-based o token anonimo)
POST /api/publico/carrito/agregar/              ← CarritoWeb + reserva Redis TTL
GET  /api/publico/carrito/                      ← ver carrito actual
PATCH /api/publico/carrito/{item_id}/           ← actualizar cantidad
DELETE /api/publico/carrito/{item_id}/          ← remover item

# Auth de clientes (separado del auth staff)
POST /api/publico/auth/registro/               ← crear cuenta cliente
POST /api/publico/auth/login/                  ← obtener token
POST /api/publico/auth/refresh/                ← refrescar token

# Checkout
POST /api/publico/checkout/                    ← confirmar pedido + pago Culqi
GET  /api/publico/mis-pedidos/                 ← historial del cliente (auth requerido)
```

---

## 4. Cronograma Sugerido

| Etapa | Que | Estado |
|-------|-----|--------|
| ~~Fase 1~~ | ~~Camara + Multi-lote~~ | **IMPLEMENTADO** en BE + FE |
| ~~Fase 2~~ | ~~BOM / Recetas + Produccion~~ | **IMPLEMENTADO** en BE. FE parcial (completarProduccion suspendido) |
| ~~Fase 3~~ | ~~Compras Inteligentes~~ | **IMPLEMENTADO** en BE. FE por verificar |
| ~~Fase 4~~ | ~~Precios Diferenciados~~ | **IMPLEMENTADO** en BE. FE por verificar |
| ~~Fase 5~~ | ~~Cotizaciones Mejoradas~~ | **IMPLEMENTADO** en BE. FE por verificar |
| ~~Fase 6~~ | ~~Campanias de Temporada~~ | **IMPLEMENTADO** en BE. FE por verificar |
| **E-commerce** | Campos e-commerce en Producto (slug, etc.) | Pendiente — migracion |
| **E-commerce** | Endpoints publicos en Amatista-be | Pendiente — sin bloqueo tecnico |
| **E-commerce** | Preparar JS-FE-Shop (rutas, state, auth) | Pendiente |
| **E-commerce** | Conectar JS-FE-Shop a API real | Despues de endpoints |
| **E-commerce** | Integrar Culqi (pasarela de pago) | Pendiente — requiere credenciales |
| FE pendiente | Habilitar `completarProduccion` en Kanban | La llamada esta comentada en FE |
| FE pendiente | Panel "Personalizar" en POS | Campos existen en BE, UI no construida |

---

## 5. Lo que NO hace Amatista ERP

- **No es multi-tenant** — una sola instalacion para Amatista (Sr. Tito)
- **No es SaaS** — instalacion dedicada
- **No tiene app movil nativa** — el portal del conductor es web responsiva
- **No reemplaza un sistema contable especializado** — genera PLE/asientos pero no es un ERP contable completo
