# AMATISTA ERP — REGLAS DE FRONTEND

> Aplica unicamente a Amatista-fe/.
> Para el template base ver Jsoluciones-docs/rules/FRONTEND.md.

---

## 1. STACK (NO CAMBIAR)

| Tecnologia | Version | Proposito |
|-----------|---------|-----------|
| React | 19 | Framework UI |
| TypeScript | 5.8 | Tipado estatico |
| Vite | 7 | Build tool + dev server con proxy |
| Tailwind CSS | 4 | Estilos |
| Preline | 3.2 | Interacciones JS |
| TanStack React Query | 5 | Data fetching, cache, mutations |
| Orval | 8 | Genera hooks y tipos desde OpenAPI |
| react-hot-toast | - | Notificaciones toast |
| react-apexcharts | - | Graficos dashboard |
| react-hook-form | - | Formularios complejos |
| pnpm | - | Package manager |

**NO agregar:** Zustand / Redux / Axios / dayjs / MUI / Ant Design

---

## 2. COLORES Y DESIGN SYSTEM

Ver `DESIGN_SYSTEM.md` en la raiz del repo para los valores exactos.

```css
/* Color primario de Amatista — NO usar azul del template */
--color-primary: #8E338A;          /* Purpura Amatista */
--color-primary-hover: #72287E;
--color-brand-surface: #FFF5F7;    /* Rosa Nude — fondo de pagina */
--color-brand-dark: #1A1A2E;       /* Titulos */
```

Fuentes: **Playfair Display** (titulos H1-H3) + **Montserrat** (cuerpo y UI).

NUNCA usar `Inter` o `DM Sans` — esas son del template JSoluciones.

---

## 3. REGLAS ESTRICTAS

### Arquitectura
```
FRONT-01: Orval genera los hooks y tipos. NUNCA escribir tipos de API a mano.
FRONT-02: NUNCA escribir fetch() a mano para endpoints del backend.
          Siempre usar los hooks generados por Orval (src/api/generated/).
FRONT-03: El frontend se adapta al backend. Si falta un campo, se pide al backend.
FRONT-04: Toda pagina que consume datos DEBE manejar: loading, error, datos.
FRONT-05: Estado del servidor = React Query. Estado global = AuthContext. Estado local = useState.
```

### Reglas especificas de Amatista (floreria)
```
FRONT-F01: El semaforo de frescura usa colores especificos:
           optimo    → verde    (#22C55E o badge verde de Tailwind)
           precaucion → amarillo (#EAB308 o badge amarillo)
           funebre   → rojo     (#EF4444 o badge rojo)
           descarte  → negro    (#1F2937 o badge oscuro)
           NUNCA otros colores para frescura.

FRONT-F02: La vista /inventario/camara muestra los lotes FIFO (mas viejo arriba).
           El orden es fecha_entrada ASC — NO modificar este orden.

FRONT-F03: En el POS, cuando hay AjustePersonalizacion:
           - El precio unitario NO cambia.
           - El recargo_personalizacion se suma al total del DetalleVenta.
           - El costo_estimado que retorna el backend es SOLO referencia para el vendedor.

FRONT-F04: Campanas activas se muestran como badges sobre el producto en el POS.
           NO modificar el precio en el badge — solo mostrar "Campana -X%".

FRONT-F05: En el Kanban de produccion, el boton "Listo" llama a:
           POST /ventas/detalle-ventas/{id}/completar/
           Este endpoint descuenta los insumos FIFO en el backend.
           El frontend NUNCA calcula ni descuenta stock.
```

### Formularios
```
FRONT-06: Formularios simples (busqueda, filtros) -> useState directo.
          Formularios complejos (POS, crear producto, cotizacion) -> react-hook-form.
FRONT-07: Validacion client-side es UX, NO seguridad. El backend siempre valida.
FRONT-08: Errores del servidor se muestran tal cual vienen del backend.
```

### Seguridad
```
FRONT-09: Toda ruta protegida usa ProtectedRoute con verificacion de auth.
FRONT-10: NUNCA mostrar IDs de la DB (UUIDs) al usuario.
FRONT-11: NUNCA mostrar precio_compra de los productos en el frontend publico.
```

### Performance
```
FRONT-12: staleTime para datos casi estaticos (categorias, recetas): 10 min.
          staleTime para datos dinamicos (stock, ventas del dia): 30 seg.
FRONT-13: Paginacion es del servidor (20 por pagina). NUNCA cargar todo.
FRONT-14: Busquedas con debounce de 300ms minimo.
```

---

## 4. COMPONENTES CLAVE (ya implementados)

| Componente | Ubicacion | Descripcion |
|-----------|-----------|-------------|
| `DataTable` | `components/common/DataTable.tsx` | Tabla generica paginada con filtros |
| `RowDropdown` | `components/common/RowDropdown.tsx` | Menu de acciones por fila (portal, no se corta) |
| `PhoneInput` | `components/common/PhoneInput.tsx` | Input telefono con selector de pais (default Peru) |
| `DistritoSelect` | `components/common/DistritoSelect.tsx` | Selector departamento > distrito Peru |
| `WebSocketManager` | `context/WebSocketManager.tsx` | WS globales (notificaciones + dashboard) |
| `tokenRefresh` | `lib/tokenRefresh.ts` | Mutex para refresh JWT — evita race condition |

---

## 5. PATRON DE PAGINA

```tsx
// Estructura basica de toda pagina con datos
function MiPagina() {
  const { data, isLoading, isError } = useMiQueryGeneradoPorOrval()

  if (isLoading) return <LoadingSpinner />
  if (isError) return <ErrorMessage message="Error al cargar datos" />

  return (
    <div>
      {/* Contenido */}
    </div>
  )
}
```

---

## 6. CHECKLIST ANTES DE CADA CAMBIO

- [ ] Los colores usados son del design system de Amatista (purpura, no azul)?
- [ ] Los hooks de API son generados por Orval (no fetch a mano)?
- [ ] Se manejan los 3 estados de React Query (loading, error, data)?
- [ ] Hay debounce en las busquedas?
- [ ] Los formularios complejos usan react-hook-form?
- [ ] No se muestran UUIDs al usuario?
- [ ] Las acciones criticas (eliminar, anular) tienen modal de confirmacion?
- [ ] El semaforo de frescura usa los colores correctos?
