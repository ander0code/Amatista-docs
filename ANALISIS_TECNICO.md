# Análisis Técnico — Amatista FE + BE

**Fecha:** 2026-02-26  
**Build status:** `pnpm tsc --noEmit` pasa sin errores  
**Scope:** Tipado, inconsistencias BE↔FE, riesgos en producción, workarounds `as any` / `as unknown as`

---

## Severidad

- 🔴 **Crítico** — rompe funcionalidad visible en producción
- 🟡 **Importante** — riesgo real en producción, puede pasar desapercibido
- 🟢 **Menor** — code smell, workaround técnico sin impacto funcional inmediato

---

## 1. Autenticación y Permisos

### 🔴 1.1 `hasPermission` siempre devuelve `false` — todas las guards de permisos están rotas

**Archivo:** `src/context/AuthContext.tsx:~130`  
**Problema:** `permisos` en el tipo `Me` es `readonly unknown[]`. La implementación hace:

```ts
user.permisos.includes(permission as never)
```

`unknown[]` nunca contiene un match real con `never`. Resultado: `hasPermission(...)` **siempre retorna `false`**.

**Impacto:** Todo el control de acceso basado en permisos (`TienePermiso` en el FE) está roto. Módulos que deberían estar ocultos para ciertos roles aparecen o desaparecen incorrectamente.

**Causa raíz BE:** `MeSerializer.get_permisos()` devuelve `List[str]` (codigos de permisos), pero Orval genera el tipo como `readonly unknown[]` porque `@extend_schema_field(serializers.ListField())` no especifica el tipo del item.

**Fix BE:** Cambiar a `@extend_schema_field(serializers.ListField(child=serializers.CharField()))` en `MeSerializer.get_permisos`.  
**Fix FE:** Después de regenerar Orval, `permisos` será `readonly string[]` y `includes` funcionará correctamente.

---

### 🔴 1.2 `WelcomeUser` muestra siempre "Usuario" en lugar del rol real

**Archivo:** `src/app/(admin)/(dashboards)/index/components/WelcomeUser.tsx:21`  
**Problema:** `user?.rol` es de tipo `MeRol = { [key: string]: unknown }`. El código hace:

```ts
ROLE_LABEL[(user?.rol as string | undefined) ?? '']
```

`rol` es un objeto `{ id, codigo, nombre }`, nunca un string. El cast fuerza un `undefined` → el label siempre muestra el fallback `'Usuario'`.

**Causa raíz BE:** `MeSerializer.get_rol()` usa `@extend_schema_field(serializers.DictField())` sin anotar los campos internos. Orval genera `MeRol = { [key: string]: unknown }` en lugar de `{ id: string; codigo: string; nombre: string }`.

**Fix BE:** Usar un serializer explícito para el campo `rol` en `MeSerializer` (ej. `RolInfoSerializer`) con `id`, `codigo`, `nombre` como campos typed.  
**Fix FE:** Después de regenerar Orval, `user.rol.codigo` estará disponible con tipo correcto. `WelcomeUser` y `hasRole` en `AuthContext` deben usar `user.rol.codigo`.

---

### 🔴 1.3 `perfil/index.tsx` no puede leer `totp_enabled` — campo invisible en el tipo

**Archivo:** `src/app/(admin)/(app)/perfil/index.tsx:134`  
**Problema:**

```ts
const totpEnabled = (user as unknown as { totp_enabled?: boolean })?.totp_enabled ?? false;
```

`totp_enabled` existe en `MeSerializer` pero Orval no lo expone en el tipo `Me`. El campo está en el schema OpenAPI pero el tipo generado lo omite.

**Fix:** Verificar que `totp_enabled` aparece en el schema Orval generado (`src/api/models/me.ts`). Si no está, forzar regeneración de Orval tras confirmar que el schema BE lo incluye.

---

### 🟡 1.4 Doble interceptor 401 — riesgo de refresh race condition

**Archivos:** `src/api/fetcher.ts` y `src/services/api.ts`  
**Problema:** Dos instancias HTTP con refresh automático independiente:
- `fetcher.ts` (custom fetch de Orval): captura 401, refresca token, reintenta
- `services/api.ts` (axios): tiene su propio interceptor 401 que también llama a refresh

Si ambas instancias tienen requests simultáneas que reciben 401, **ambas van a intentar el refresh en paralelo**. El primer refresh rota el refresh token; el segundo intento usa el token ya rotado y recibe 401/400, cerrando la sesión del usuario inesperadamente.

**Fix:** Centralizar el refresh token en un único módulo con mutex (un flag `isRefreshing` compartido y una cola de requests en espera). `services/api.ts` y `fetcher.ts` deben compartir la misma lógica de refresh o uno de los dos debe delegarle al otro.

---

### 🟡 1.5 `configuracion/usuarios/index.tsx` — `rol` tipado como opaco

**Archivo:** `src/app/(admin)/(app)/(configuracion)/usuarios/index.tsx:33,269`  
**Problema:**
```ts
const rol = usuario?.rol as unknown as { id?: string } | null;
const rol = u.rol as unknown as { nombre?: string; codigo?: string } | null;
```

Dependencia directa de la estructura interna no tipada de `MeRol`. Si el BE cambia la estructura, este código se rompe silenciosamente.  
**Bloqueado por:** fix 1.2 (tipado correcto de `MeRol`).

---

## 2. Distribución / Mapa

### 🔴 2.1 Mapa de pedidos nunca muestra marcadores

**Archivo:** `src/app/(admin)/(app)/(distribucion)/mapa/index.tsx:155-163`  
**Problema:** El componente filtra pedidos que tengan `latitud`/`longitud`:

```ts
const pedidosConUbicacion = pedidos.filter((p) => {
  const raw = p as unknown as Record<string, unknown>;
  return raw['latitud'] && raw['longitud'];
});
```

**Causa raíz BE:** `PedidoListSerializer` (usado por el endpoint de lista) **no incluye `latitud` ni `longitud`**. Solo `PedidoDetailSerializer` y `MapaPedidoSerializer` tienen esos campos.

**Resultado:** `pedidosConUbicacion` siempre es un array vacío → el mapa nunca muestra marcadores de pedidos.

**Fix BE:** Opción A: Agregar `latitud` y `longitud` a `PedidoListSerializer` (campo decimal, solo lectura).  
Opción B (mejor): Usar un endpoint dedicado que devuelva `MapaPedidoSerializer` (ya existe en `distribucion/serializers.py`) en lugar del endpoint de lista general.

---

### 🟡 2.2 `portal-conductor/index.tsx` — casts de tipo en coordenadas GPS

**Archivo:** `src/app/(public)/portal-conductor/index.tsx:404-405`  
**Problema:**
```ts
lat: lat as unknown as string,
lng: lng as unknown as string,
```

`lat` y `lng` son `number` (de `GeolocationCoordinates`). El serializer BE (`PortalActualizarUbicacionSerializer`) espera `DecimalField` — que DRF acepta tanto como number o string. El cast es innecesario pero no rompe nada.

---

## 3. Facturación

### 🔴 3.1 Filtro por fecha en listado de comprobantes no funciona

**Archivo:** `src/app/(admin)/(app)/(invoice)/list/components/InvoiceList.tsx:127`  
**Problema:**
```ts
useFacturacionComprobantesList({ ... } as Record<string, unknown>)
```

Los parámetros `fecha_desde` y `fecha_hasta` **no existen en `FacturacionComprobantesListParams`** (tipo Orval generado). Se usa el cast para forzarlos, pero el backend podría ignorarlos o causar un error de filtrado.

**Causa raíz:** El endpoint de lista de comprobantes en el BE probablemente tiene esos filtros en el viewset (via `DjangoFilterBackend`) pero drf-spectacular no los está generando correctamente en el schema.

**Fix BE:** Verificar que el viewset de comprobantes declara `filterset_fields = ['fecha_desde', 'fecha_hasta', ...]` o usa un `FilterSet` explícito con esos campos. Luego regenerar Orval.  
**Fix FE:** Eliminar el cast y usar los params tipados.

---

## 4. WhatsApp / Campañas

### 🟡 4.1 Historial de campañas se pierde al recargar

**Archivo:** `src/app/(admin)/(app)/(whatsapp)/campanas/index.tsx`  
**Problema:** Antes del fix actual, el historial era solo estado local. El BE ya tiene `GET /api/v1/whatsapp/campana/` que devuelve las campañas persistidas en BD. Si el FE no usa ese endpoint para el listado inicial, el historial se pierde.

**Verificar:** Si `campanas/index.tsx` ya consume el `GET` para el listado inicial → resuelto. Si sigue usando solo `useState` para acumular campañas → bug activo.

---

### 🟡 4.2 `campanas/index.tsx` — cast de response con campos opcionales

**Archivo:** `src/app/(admin)/(app)/(whatsapp)/campanas/index.tsx:73`  
**Problema:**
```ts
const data = resp as unknown as {
  campana_id: string;
  nombre: string;
  total_contactos: number;
  mensajes_encolados: number;
  estado: string;
};
```

El tipo generado `WhatsappCampanaCreate201` tiene `campana_id?: string` (opcional). El cast lo fuerza como no-opcional. Si el BE devuelve `campana_id` como `null` o lo omite en un error parcial, `data.campana_id` será `undefined` pero el código lo usa sin guard → crash potencial.

**Fix:** No usar cast. Usar el tipo `WhatsappCampanaCreate201` directamente con guards opcionales.

---

### 🟡 4.3 `metricas/index.tsx` — tipo `WhatsappMetricas` definido localmente

**Archivo:** `src/app/(admin)/(app)/(whatsapp)/metricas/index.tsx:80`  
**Problema:**
```ts
const metricas = data as unknown as WhatsappMetricas | undefined;
```

`WhatsappMetricas` es una interfaz definida localmente en el componente. El tipo Orval del endpoint de métricas es opaco. Si el BE cambia la estructura de métricas, el código se rompe silenciosamente.

---

## 5. Inventario

### 🟡 5.1 N+1 en `ProductoListSerializer.get_imagen_url` — confirmado con fallback

**Archivo BE:** `apps/inventario/serializers.py:93-121`  
**Problema:** El serializer tiene un mecanismo con `_imagen_principal_r2_key` como cache via prefetch annotation, pero el **fallback** hace una query individual por producto:

```python
img = MediaArchivo.objects.filter(
    entidad_tipo="producto",
    entidad_id=obj.id,
    ...
).values_list("r2_key", flat=True).first()
```

Si el viewset de productos no anota `_imagen_principal_r2_key` en el queryset, cada producto en el listado genera una query adicional a `MediaArchivo`.

**Verificar:** Que `apps/inventario/views.py` incluye la annotation/prefetch de `_imagen_principal_r2_key` en el queryset del list endpoint.

---

### 🟡 5.2 N+1 en `DetalleVentaSerializer.get_producto_imagen_url`

**Archivo BE:** `apps/ventas/serializers.py` (identificado en análisis previo)  
**Problema:** Cada ítem de detalle de venta hace una query a `MediaArchivo` para obtener la URL de imagen del producto. En un pedido con 20 ítems → 20 queries adicionales.

**Fix:** Usar `prefetch_related` con una annotation en el viewset de `VentaDetail`, similar al mecanismo de `_imagen_principal_r2_key` en inventario.

---

### 🟡 5.3 `dashboard-inventario` y `stock` — respuesta paginada no tipada

**Archivos:**
- `src/app/(admin)/(app)/(inventario)/dashboard-inventario/components/DashboardInventario.tsx:87`
- `src/app/(admin)/(app)/(inventario)/stock/components/StockOverview.tsx:74`

**Problema:**
```ts
const movimientos = (movData?.data as unknown as { results: MovimientoStock[] })?.results ?? [];
const alertas = (alertasData?.data as unknown as { count: number; results: AlertaItem[] }) ?? ...
```

Los endpoints de movimientos y alertas devuelven respuestas paginadas (`{ count, results: [...] }`), pero los tipos Orval no modelan la paginación. El cast es un workaround necesario pero frágil.

**Fix:** Orval debe generar tipos paginados. Verificar que el schema drf-spectacular genera correctamente `PaginatedXxxList` para estos endpoints.

---

## 6. Ventas / POS

### 🟡 6.1 `pedido-pos/index.tsx` — múltiples `as any` en creación

**Archivo:** `src/app/(admin)/(app)/(ventas)/pedido-pos/index.tsx`

| Línea | Problema |
|-------|----------|
| 95 | `response.data as unknown as { venta_numero: string; pedido_numero?: string }` — el tipo real de `POST /ventas/pedido-pos/` no está en Orval |
| 253 | `crearClienteAsync({ data: nuevoClientePayload as any })` — payload no mapeado al tipo correcto |
| 281 | `crearTransportistaAsync({ data: { ... } as any })` — mismo problema |

**Fix:** Regenerar Orval con el schema actualizado del BE. Los endpoints de creación de cliente y transportista deben tener sus serializers bien documentados en drf-spectacular.

---

### 🟢 6.2 `cart/index.tsx:100` — cast innecesario en `VentaDetail`

**Archivo:** `src/app/(admin)/(app)/(ventas)/cart/index.tsx:100`  
**Problema:**
```ts
ventaId: (venta as unknown as { id: string }).id,
```

`VentaDetail` tiene `id: string` directamente. El cast es innecesario. No rompe nada pero es code smell.

---

### 🟡 6.3 `orders/index.tsx` — `ResumenDia` opaco

**Archivo:** `src/app/(admin)/(app)/(ventas)/orders/index.tsx:23`  
**Problema:**
```ts
const resumen = data?.data as unknown as ResumenDia;
```

`ResumenDia` es una interfaz local. El endpoint de resumen del día no está tipado en Orval.

---

### 🟡 6.4 `cotizacion-detalle/index.tsx` — ID de nueva cotización sin tipar

**Archivo:** `src/app/(admin)/(app)/(ventas)/cotizacion-detalle/index.tsx:66`  
**Problema:**
```ts
const nuevaId = (response.data as unknown as { id: string }).id;
```

La respuesta de creación de cotización no tiene tipo generado en Orval.

---

## 7. Dashboard / Reportes

### 🟡 7.1 `index/index.tsx` — múltiples responses de dashboard sin tipar

**Archivo:** `src/app/(admin)/(dashboards)/index/index.tsx:456-462`  

Todos los endpoints de KPIs, comparativo, CxC vencidas, top productos, top clientes y configuración de umbrales tienen sus responses casteadas como `unknown`. Si el BE cambia la estructura de cualquiera de estos endpoints, el dashboard se rompe silenciosamente sin error de TypeScript.

---

### 🟡 7.2 `reportes/index.tsx` — reportes de KPI sin tipar

**Archivo:** `src/app/(admin)/(app)/reportes/index.tsx:196-237`  

Mismo patrón que el dashboard. Los endpoints de reportes (`/reportes/top-productos/`, `/reportes/kpis-financieros/`, etc.) no generan tipos Orval.

---

### 🟡 7.3 `reportes/programados/index.tsx` — `as any` en create y patch

**Archivo:** `src/app/(admin)/(app)/reportes/programados/index.tsx:60,121,136`  
**Problema:**
```ts
const programaciones = ((listRes?.data as any)?.results ?? []) as Programacion[];
// y en mutaciones:
} as any,
data: { activo: !prog.activo } as any,
```

Los endpoints de reportes programados no están tipados en Orval.

---

## 8. Finanzas

### 🟢 8.1 Libros contables — `as any` en respuestas complejas

**Archivos:**
- `libro-diario/components/LibroDiarioList.tsx:40`
- `libro-mayor/components/LibroMayorList.tsx:56`
- `estado-resultados/components/EstadoResultadosReporte.tsx:110`
- `balance-general/components/BalanceGeneralReporte.tsx:62`
- `flujo-caja/components/FlujoCajaReporte.tsx:33`
- `libro-caja/components/LibroCajaList.tsx:38`

**Problema:** Las respuestas de todos los libros contables (diario, mayor, caja, balance, estado de resultados, flujo de caja) se castean como `any`. Los serializers BE existen y están bien definidos en `apps/finanzas/serializers.py`, pero Orval no genera tipos para ellos.

**Causa probable:** Los endpoints de libros contables devuelven respuestas no paginadas con estructuras custom. drf-spectacular las anota correctamente pero Orval puede no generar el tipo si el endpoint no sigue el patrón estándar.

---

## 9. Compras

### 🟢 9.1 `ProrrateoGastosModal` — respuesta casteada

**Archivo:** `src/app/(admin)/(app)/(compras)/orden-compra-detalle/components/ProrrateoGastosModal.tsx:26`  
**Problema:**
```ts
const items = response.data as unknown as ProrrateoItem[];
```

`ProrrateoItem` es una interfaz local que mapea `ProrrateoItemSerializer` del BE. El tipo existe en el schema pero Orval no lo genera para este endpoint.

---

### 🟢 9.2 `RecepcionFormModal` — ID de recepción casteado

**Archivo:** `src/app/(admin)/(app)/(compras)/orden-compra-detalle/RecepcionFormModal.tsx:198`  
**Problema:**
```ts
const recepcionId = (response.data as unknown as { id?: string })?.id;
```

La respuesta de creación de recepción no tiene tipo generado.

---

## 10. Configuración

### 🟡 10.1 `empresa/index.tsx` — campos de configuración no tipados

**Archivo:** `src/app/(admin)/(app)/(configuracion)/empresa/index.tsx:77,400`  
**Problema:**
```ts
nubefact_url: (d as unknown as { nubefact_url?: string }).nubefact_url || '...',
(empresaRes.data as unknown as { modo_contingencia?: boolean }).modo_contingencia
```

El serializer de empresa tiene estos campos (`nubefact_url`, `modo_contingencia`) pero el tipo Orval generado no los incluye. Probablemente el schema del endpoint de empresa no está bien anotado.

---

### 🟡 10.2 `roles/index.tsx` — estructura de permisos de rol casteada

**Archivo:** `src/app/(admin)/(app)/(configuracion)/roles/index.tsx:142`  
**Problema:**
```ts
const permisosActuales = (rolPermisosData?.data as unknown as { permisos?: { id: string }[] })?.permisos ?? [];
```

`RolPermisosResponseSerializer` del BE devuelve `{ rol: string, permisos: [...] }` con `PermisoInfoSerializer`. El tipo Orval no refleja esta estructura correctamente.

---

## 11. Producción / Distribución

### 🟢 11.1 `produccion/index.tsx` — respuesta de productos de producción casteada

**Archivo:** `src/app/(admin)/(app)/(distribucion)/produccion/index.tsx:506`  
**Problema:**
```ts
const responseData = data?.data as unknown as ProduccionProductosResponse;
```

`ProduccionProductosResponse` es una interfaz local. El endpoint de producción no genera tipo Orval.

---

## 12. Inventario — Creación de Producto

### 🟢 12.1 `ProductoForm.tsx` — imagen y categoría casteadas

**Archivo:** `src/app/(admin)/(app)/(inventario)/product-create/components/ProductoForm.tsx:167,198,209`  
**Problema:**
```ts
archivo: imagenFile as unknown as string,
const data = response.data as unknown as { id: string; nombre: string };
```

El campo `archivo` en el endpoint de upload de media espera `File` (multipart), no `string`. El cast engaña a TypeScript. La creación/actualización de categorías también castea la respuesta.

---

## 13. Portal Conductor

### 🟢 13.1 `portal-conductor/index.tsx` — imagen de entrega casteada a string

**Archivo:** `src/app/(public)/portal-conductor/index.tsx:104`  
**Problema:**
```ts
...(foto ? { foto_entrega: foto as unknown as string } : {}),
```

`foto` es `File`. El serializer BE (`PortalConfirmarEntregaSerializer`) tiene `foto_entrega = serializers.ImageField(required=False)`. El envío es multipart/form-data, por lo que el cast no rompe el envío real (el fetch maneja `FormData`), pero el tipo es incorrecto.

---

## 14. Causa Raíz Sistémica — Orval no genera tipos para respuestas custom

**Patrón recurrente en 15+ componentes:** Los endpoints del BE que devuelven respuestas custom (no `ModelSerializer` directo en el `response_class` del viewset) no generan tipos Orval utilizables. Esto ocurre principalmente en:

1. Endpoints de acción custom (`@action`) con `responses={200: {...}}` inline en `@extend_schema`
2. Endpoints que devuelven estructuras anidadas complejas (KPIs, libros contables, reportes)
3. Endpoints de búsqueda que devuelven `{ results: [...] }` sin paginator estándar

**Fix sistémico:** Reemplazar todas las anotaciones `responses={200: {"type": "object", "properties": {...}}}` inline por serializers explícitos con `@extend_schema_field`. Esto permite a drf-spectacular generar el schema correctamente y a Orval producir tipos utilizables.

---

## 15. Resumen por Severidad

### 🔴 Críticos (rompen funcionalidad)

| # | Módulo | Problema | Archivo |
|---|--------|----------|---------|
| 1 | Auth | `hasPermission` siempre `false` — permisos rotos | `AuthContext.tsx` |
| 2 | Auth | `WelcomeUser` siempre muestra "Usuario" | `WelcomeUser.tsx` |
| 3 | Distribución | Mapa nunca muestra marcadores de pedidos | `mapa/index.tsx` + `PedidoListSerializer` |
| 4 | Facturación | Filtro por fecha en comprobantes no funciona | `InvoiceList.tsx` |

### 🟡 Importantes (riesgo en producción)

| # | Módulo | Problema | Archivo |
|---|--------|----------|---------|
| 5 | Auth | Doble interceptor 401 — race condition en refresh | `fetcher.ts` + `api.ts` |
| 6 | Auth | `totp_enabled` invisible en tipo `Me` | `perfil/index.tsx` |
| 7 | Auth | `MeRol` opaco — `rol.codigo` inaccesible con tipo | `configuracion/usuarios/index.tsx` |
| 8 | WhatsApp | Campañas historial — verificar si usa GET de BD | `campanas/index.tsx` |
| 9 | WhatsApp | `campana_id` opcional usado sin guard | `campanas/index.tsx` |
| 10 | Inventario | N+1 potencial en `imagen_url` si falta annotation | `inventario/serializers.py` |
| 11 | Ventas | N+1 en `DetalleVentaSerializer.imagen` | `ventas/serializers.py` |
| 12 | Ventas | POS múltiples `as any` en creación | `pedido-pos/index.tsx` |
| 13 | Dashboard | Todos los KPIs sin tipar — cambios BE silenciosos | `dashboards/index/index.tsx` |
| 14 | Reportes | Reportes y programados sin tipar | `reportes/index.tsx` |
| 15 | Configuración | `empresa` campos `nubefact_url`/`modo_contingencia` opacos | `empresa/index.tsx` |
| 16 | Configuración | Permisos de rol casteados | `roles/index.tsx` |

### 🟢 Menores (code smell / workarounds no críticos)

| # | Módulo | Problema | Archivo |
|---|--------|----------|---------|
| 17 | Ventas | Cast innecesario en `VentaDetail.id` | `cart/index.tsx` |
| 18 | Ventas | `ResumenDia` y `cotizacion` sin tipar | `orders/index.tsx`, `cotizacion-detalle/index.tsx` |
| 19 | Finanzas | Todos los libros contables con `as any` | 6 archivos en `finanzas/` |
| 20 | Compras | Prorrateo y recepción sin tipar | 2 archivos en `compras/` |
| 21 | Producción | `ProduccionProductosResponse` local | `produccion/index.tsx` |
| 22 | Inventario | `ProductoForm` imagen cast incorrecta | `product-create/ProductoForm.tsx` |
| 23 | Portal | Imagen conductor casteada a string | `portal-conductor/index.tsx` |

---

## 16. Plan de Acción Recomendado

### Prioridad 1 — Fixes de impacto crítico (BE primero, luego Orval, luego FE)

1. **`MeSerializer`** — cambiar `get_permisos` a `ListField(child=CharField())`, cambiar `get_rol` a usar `RolInfoSerializer` explícito con `{ id, codigo, nombre }`. Regenerar Orval. Actualizar `AuthContext`, `WelcomeUser`, `configuracion/usuarios`.

2. **`PedidoListSerializer`** — agregar `latitud` y `longitud` (o usar `MapaPedidoSerializer` en el endpoint del mapa). Actualizar `mapa/index.tsx` para eliminar el cast.

3. **Endpoint de comprobantes** — verificar y agregar `fecha_desde`/`fecha_hasta` a `filterset_fields` en el viewset de facturación. Regenerar Orval. Actualizar `InvoiceList.tsx`.

### Prioridad 2 — Eliminar race condition de refresh

4. **Unificar refresh token** — crear un módulo `src/lib/tokenRefresh.ts` con mutex. Hacer que `fetcher.ts` y `services/api.ts` usen el mismo token refresh handler.

### Prioridad 3 — Tipado sistémico (reducir `as unknown as`)

5. **Serializers explícitos en BE** — reemplazar inline `responses` en `@extend_schema` por serializers declarados para: endpoints de campañas, reportes, KPIs del dashboard, libros contables, producción, empresa.

6. **Regenerar Orval** — tras los cambios de schema BE, regenerar tipos. La mayoría de los casts `as unknown as` en finanzas, reportes y dashboard deberían desaparecer.

### Prioridad 4 — Performance

7. **N+1 en `DetalleVentaSerializer`** — agregar `prefetch_related` de media en el viewset de `VentaDetail`.

8. **Verificar annotation en inventario** — confirmar que el viewset de productos siempre anota `_imagen_principal_r2_key`.

---

## 17. Archivos Backend Analizados

| App | Archivos leídos |
|-----|----------------|
| `usuarios` | `serializers/auth.py`, `serializers/usuarios.py`, `models.py` |
| `ventas` | `serializers.py`, `models.py` |
| `distribucion` | `serializers.py` (completo), `models.py` |
| `clientes` | `serializers.py`, `models.py` |
| `facturacion` | `serializers.py`, `models.py` (parcial) |
| `inventario` | `serializers.py` |
| `compras` | `serializers.py` |
| `finanzas` | `serializers.py` |
| `whatsapp` | `serializers.py`, `views.py` |

## 18. Archivos Frontend Analizados

Todos los archivos con `as any` / `as unknown as` identificados via grep + lectura directa de los componentes principales de: `auth`, `ventas` (cart, pedido-pos, orders, cotizacion), `distribucion` (mapa), `facturacion` (invoice/list), `whatsapp` (campanas, metricas), `inventario` (dashboard, stock, product-create), `finanzas` (todos los libros), `compras` (OC detalle), `configuracion` (empresa, roles, usuarios), `reportes`, `dashboards`.
