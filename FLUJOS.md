# Flujos del sistema — Amatista

## Flujo completo de un pedido

### Variante A — Sin transportista pre-asignado (flujo estándar)

```
1. CREAR PEDIDO
   └── Estado inicial: pendiente
   └── Producción inicial: pendiente
   └── Transportista: sin asignar

2. PRODUCCIÓN (Kanban por producto)
   └── Cada DetalleVenta avanza: pendiente → armando → listo
   └── Cuando TODOS los detalles llegan a "listo":
       Pedido.estado_produccion se actualiza a "listo" automáticamente

3. ASIGNAR TRANSPORTISTA (manual, después de producción)
   └── Solo permitido si Pedido.estado_produccion == "listo"
   └── Pedido pasa a: despachado automáticamente al asignar

4. PORTAL DEL CONDUCTOR — Marcar "En Ruta"
   └── Solo disponible si estado == "despachado"
   └── Pedido pasa a: en_ruta

5. PORTAL DEL CONDUCTOR — Confirmar resultado
   └── Opciones:
       - entregado      → estado = entregado (con foto + observación opcionales)
       - reprogramado   → estado = reprogramado (pedido reagendado)
       - no_entregado   → estado = no_entregado
       - cancelado      → estado = cancelado
```

### Variante B — Con transportista pre-asignado al crear

```
1. CREAR PEDIDO (con transportista pre-asignado)
   └── Estado inicial: pendiente  ← siempre, aunque haya transportista
   └── Producción inicial: pendiente
   └── Transportista: pre-asignado (validando límite diario)

2. PRODUCCIÓN (Kanban por producto)
   └── Cada DetalleVenta avanza: pendiente → armando → listo
   └── Cuando TODOS los detalles llegan a "listo":
       → Pedido.estado_produccion = "listo"
       → AUTO-DESPACHO: si hay transportista pre-asignado y estado es
         pendiente/confirmado, el pedido pasa a "despachado" automáticamente
         con registro en SeguimientoPedido

3. PORTAL DEL CONDUCTOR — Marcar "En Ruta"  (idéntico a Variante A)
4. PORTAL DEL CONDUCTOR — Confirmar resultado  (idéntico a Variante A)
```

---

## Estados del pedido

| Estado | Descripción |
|--------|-------------|
| `pendiente` | Pedido creado, en producción |
| `confirmado` | Pedido confirmado internamente (uso administrativo) |
| `despachado` | Transportista asignado, listo para salir |
| `en_ruta` | El conductor marcó que salió a entregar |
| `entregado` | Entrega confirmada por el conductor |
| `reprogramado` | No se pudo entregar, reagendado |
| `no_entregado` | El conductor no pudo entregar |
| `cancelado` | Pedido cancelado |
| `devuelto` | Pedido devuelto (uso futuro) |

## Estados de producción del pedido

| Estado | Descripción |
|--------|-------------|
| `pendiente` | Ningún producto iniciado |
| `armando` | Al menos un producto en preparación |
| `listo` | Todos los productos terminados |

---

## Lo que NO se puede hacer (reglas de negocio activas)

### Al crear un pedido
- Se puede pre-asignar un transportista al crear, pero el pedido queda siempre en `pendiente`.
- El transportista pre-asignado **no puede despachar** hasta que producción esté `lista`.
- Se valida el límite diario de pedidos del transportista al pre-asignar.

### Al asignar transportista
- No se puede asignar si `estado_produccion != "listo"`.
  → Error: "El pedido debe estar 'listo' en producción."
- No se puede asignar si el pedido está `entregado` o `cancelado`.
- No se puede asignar si el transportista ya alcanzó su límite diario de pedidos.

### Al despachar un pedido
- No se puede despachar sin transportista asignado.
  → Error: "No se puede despachar un pedido sin transportista asignado."
- No se puede despachar si `estado_produccion != "listo"`.
  → Error: "La producción debe estar 'lista'."
- Solo se puede despachar si estado es `pendiente` o `confirmado`.

### Al marcar en ruta
- Solo se puede si el pedido está en `despachado`.
  → Error: "Solo se puede marcar en ruta un pedido despachado."

### Al confirmar entrega
- Solo se puede si el pedido está en `despachado` o `en_ruta`.
- No se puede cancelar un pedido ya `entregado`.

### En producción
- No se puede avanzar un detalle que ya está en `listo`.
- Solo se puede revertir un detalle que está en `listo` (vuelve a `armando`).

---

## Flujo típico de una venta con pedido

### Sin transportista pre-asignado
```
Venta registrada en sistema
        ↓
Pedido creado (pendiente / producción: pendiente)
        ↓
Vista Kanban: productos avanzan pendiente → armando → listo
        ↓
Cuando todos los productos están "listo":
  → Pedido.estado_produccion = listo automáticamente
        ↓
Supervisor asigna transportista desde vista Pedidos
  → Pedido pasa a "despachado"
        ↓
Conductor abre su portal y pulsa "Salí a entregar"
  → Pedido pasa a "en_ruta"
        ↓
Conductor llega al destino y confirma:
  → entregado / reprogramado / no_entregado / cancelado
```

### Con transportista pre-asignado al crear
```
Venta registrada en sistema
        ↓
Pedido creado CON transportista (pendiente / producción: pendiente)
        ↓
Vista Kanban: productos avanzan pendiente → armando → listo
        ↓
Cuando todos los productos están "listo":
  → Pedido.estado_produccion = listo
  → AUTO-DESPACHO: pedido pasa a "despachado" automáticamente
        ↓
Conductor abre su portal y pulsa "Salí a entregar"
  → Pedido pasa a "en_ruta"
        ↓
Conductor llega al destino y confirma:
  → entregado / reprogramado / no_entregado / cancelado
```

---

## Endpoints involucrados

| Acción | Endpoint |
|--------|----------|
| Crear pedido | `POST /api/v1/distribucion/pedidos/` |
| Asignar transportista | `POST /api/v1/distribucion/pedidos/{id}/asignar-transportista/` |
| Despachar | `POST /api/v1/distribucion/pedidos/{id}/despachar/` |
| Marcar en ruta (admin) | `POST /api/v1/distribucion/pedidos/{id}/en-ruta/` |
| Avanzar producción (pedido) | `POST /api/v1/distribucion/pedidos/{id}/produccion/avanzar/` |
| Avanzar producción (detalle) | `POST /api/v1/distribucion/produccion/detalle/{detalle_id}/avanzar/` |
| Revertir producción (detalle) | `POST /api/v1/distribucion/produccion/detalle/{detalle_id}/revertir/` |
| Portal: ver pedidos del día | `GET /api/v1/distribucion/portal/{token}/` |
| Portal: marcar en ruta | `POST /api/v1/distribucion/portal/{token}/pedidos/{id}/en-ruta/` |
| Portal: confirmar resultado | `POST /api/v1/distribucion/portal/{token}/pedidos/{id}/confirmar/` |
| Portal: GPS | `POST /api/v1/distribucion/portal/{token}/ubicacion/` |
