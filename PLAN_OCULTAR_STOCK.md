# Plan para Ocultar Stock en Amatista

> Amatista NO maneja stock predefinido. Los productos siempre están disponibles para seleccionar. Este documento detalla qué ocultar para que el cliente no vea información de stock.
> 
> **Importante:** Los cambios son SOLO visuales (usar `className="hidden"`). No eliminar campos del estado ni del tipo TypeScript para poder reactivarlos en el futuro.

---

## Estado Actual (ya oculto)

### Frontend - Ya completado en sesión anterior

| Archivo | Qué se ocultó |
|---------|---------------|
| `product-create/components/ProductoForm.tsx` | Stock Mínimo/Máximo (líneas 553, 571) ✅ |
| `product-list/components/ProductoFormModal.tsx` | Stock Mínimo/Máximo (línea 372) ✅ |
| `product-list/components/ProductList.tsx` | Badge stock en grid (línea 226) y tabla (línea 352) ✅ |
| `product-overview/components/ProductDetails.tsx` | Filas stock min/max (líneas 220-236) ✅ |
| `product-overview/components/Ratings.tsx` | Retorna `null` al inicio (línea 10) ✅ |
| `product-overview/components/Product.tsx` | Badge "Stock bajo" (línea 60) ✅ |

---

## Pendiente: Archivos a Modificar

### 1. Dashboard de Inventario

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(inventario)/dashboard-inventario/components/DashboardInventario.tsx`

| Línea | Qué ocultar | Cómo |
|-------|-------------|------|
| 127-138 | `useInventarioAlertasStockRetrieve()` | Eliminar o no usar |
| 168-175 | Tarjeta "Bajo Stock" | `className="hidden"` en el StatCard |
| 225-268 | Tabla completa de alertas de stock bajo | Envolver en `{/* ocultar && (...)}` o retornar null |
| 271 | Componente `<RotacionABC />` | Eliminar o ocultar (usa stock) |

**Verificación:**
```bash
grep -n "stock\|Stock\|alerta\|Alerta" Amatista-fe/src/app/\(admin\)/\(app\)/\(inventario\)/dashboard-inventario/components/DashboardInventario.tsx
```

---

### 2. Productos (Lista de productos - página principal)

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(inventario)/product-list/components/ProductList.tsx`

Ya tiene algunos hidden pero verificar:
- Línea 34-42: función `getSemaforoColor` - ya no se usa si stock oculto, OK
- Línea 207-209: variables `stockActual`, `stockMinimo`, `semaforo` - verificar que no causen errores
- Línea 226: Badge stock - YA ESTÁ OCULTO con `className="hidden"`
- Línea 352: Contenedor de stock en tabla - YA ESTÁ OCULTO con `className="hidden flex"`

**Verificar que no haya errores** (las variables pueden stay pero no se renderizan)

---

### 3. Crear Producto (formulario completo)

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(inventario)/product-create/components/ProductoForm.tsx`

**Estado:** YA ESTÁ OCULTO ✅
- Líneas 553 y 571: `className="hidden"`

**Verificar:**
```bash
grep -n "hidden\|stock" Amatista-fe/src/app/\(admin\)/\(app\)/\(inventario\)/product-create/components/ProductoForm.tsx
```

---

### 4. Stock y Movimientos (página completa)

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(inventario)/stock/components/StockOverview.tsx`

Esta página MUESTRA stock y movimientos. Opciones:

**Opción A (Recomendada):** Ocultar toda la página mostrando un mensaje
- Retornar un componente que diga "Esta sección no está disponible en Amatista"

**Opción B:** Ocultar componentes uno por uno
- Tabs de stock (línea ~150+)
- Tabla de stock por almacén
- Columnas de stock en movimientos

| Línea aprox | Qué es |
|-------------|--------|
| 54-62 | Estado para filtros de stock |
| 72-79 | Carga de alertas de stock |
| 81-90 | Carga de stock por almacén |
| 100+ | Render de tabla de stock |

**Verificación:**
```bash
grep -n "stock\|Stock" Amatista-fe/src/app/\(admin\)/\(app\)/\(inventario\)/stock/components/StockOverview.tsx
```

---

### 5. Reportes (pestaña Inventario)

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/reportes/index.tsx`

| Línea | Qué ocultar | Cómo |
|-------|-------------|------|
| 500-503 | KPI "Bajo Stock" | Eliminar del array o marcar `hidden` |

```tsx
// Cambiar de:
{ label: 'Bajo Stock', value: String(inv.productos_bajo_stock), alert: inv.productos_bajo_stock > 0 }

// A (eliminar esta línea del array)
```

**Verificación:**
```bash
grep -n "Bajo Stock\|productos_bajo_stock" Amatista-fe/src/app/\(admin\)/\(app\)/reportes/index.tsx
```

---

### 6. Backend - Verificar que no bloquee ventas

**Archivo:** `Amatista-be/apps/ventas/services.py`

**Estado:** YA CONFIGURADO ✅
- Línea ~420: `StockInsuficienteError` ya no se lanza
- Si no existe stock: `stock = None`
- Decremento solo si `stock is not None`

**Verificación:**
```bash
cd Amatista-be && source .venv/bin/activate && python manage.py check
```

---

### 7. Otras páginas con stock (revisar)

**Dashboard principal:**
- `Amatista-fe/src/app/(admin)/(dashboards)/index/index.tsx`
- Línea 602: KPI `productos_bajo_stock` → ocultar o cambiar valor

**Topbar Notificaciones:**
- `Amatista-fe/src/components/layouts/topbar/NotificacionesCampana.tsx`
- Línea 55: `stock_bajo` - esto es un tipo de notificación, puede stay

---

## Comando de Verificación Final

```bash
# Backend
cd Amatista-be && source .venv/bin/activate && python manage.py check

# Frontend - buscar cualquier leftover de stock visible
grep -rn "stock_actual\|stock_minimo\|stock_maximo\|Bajo Stock\|Sin stock" Amatista-fe/src/app/\(admin\)/\(app\)/\(inventario\)/ --include="*.tsx" | grep -v "hidden\|className.*hidden" | grep -v "return null" | head -30
```

---

## Para Reactivar Stock en el Futuro

Cuando Amatista decida usar stock:

1. **Frontend:**
   - Quitar `className="hidden"` de los elementos ocultos
   - Cambiar `return null` en Ratings.tsx por el componente original
   - Habilitar las variables y funciones de stock

2. **Backend:**
   - Ya tiene la lógica lista en `ventas/services.py`
   - Solo need quitar el bypass de `stock = None`

---

## Notas

- Los errores TypeScript de `stock_disponible` son falsos positivos - el campo existe en el tipo pero no se usa para bloquear
- El backend NO necesita cambios - ya está configurado para no bloquear ventas
- Los endpoints de API de stock siguen funcionando, pero el frontend ya no los mostrará
