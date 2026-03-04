# AMATISTA ERP — Flujos por Rol

> Flujos especificos para el negocio de floreria (Amatista, cliente: Sr. Tito).
> Para los flujos genericos del ERP ver tambien context/OVERVIEW.md.

---

## Roles del Sistema

| Rol | Area Principal |
|---|---|
| **Administrador** | Control total |
| **Gerente** | Dashboard ejecutivo, reportes, aprobaciones |
| **Supervisor** | Inventario, ventas, alertas |
| **Vendedor** | Cotizaciones, ordenes, clientes |
| **Cajero** | POS, delivery |
| **Almacenero (Yolanda)** | Recepciones de flores, control camara, transferencias |
| **Contador** | Facturacion, CxC, CxP |
| **Repartidor** | Sus entregas del dia |

---

# FLUJOS ESPECIFICOS DE FLORERIA

## FLUJO FLORISTERIA A — Venta directa en tienda (sin delivery)

```
Cajero abre caja
    ↓
Cliente llega al local → Cajero selecciona productos en POS
    ↓
[Si producto tiene receta y descuenta_insumos=True]
  Sistema valida que hay insumos suficientes en stock para armar el arreglo
  Si no hay stock → error con nombre del insumo faltante
    ↓
Cajero selecciona metodo de pago (efectivo / yape_plin / tarjeta / credito)
[Si cliente corporativo (RUC)] → aplica precio_corporativo automaticamente
[Si hay campana activa] → aplica descuento de temporada automaticamente
    ↓
"Cobrar" → crear_venta_pos() [@transaction.atomic]
    - Venta [estado=COMPLETADA, tipo_venta=directa]
    - DetalleVenta por cada item [estado_produccion=pendiente]
    - Stock descontado de producto final (NO de insumos aun — eso ocurre al producir)
    ↓
Celery emite comprobante electronico (Nubefact OSE)
    ↓
Arreglista ve el item en Kanban de produccion: PENDIENTE → ARMANDO → LISTO
Al marcar "LISTO":
    [Si descuenta_insumos=True y completarProduccion habilitado en FE]:
      completar_produccion_item()
        - Toma receta default del producto
        - Aplica AjustePersonalizacion si existe
        - Descuenta insumos (flores) del stock via FIFO automaticamente
        - Registra DetalleVentaInsumo (inmutable)
    [Si descuenta_insumos=False (default)]:
      Solo marca como listo, sin tocar inventario
    NOTA: La llamada FE a completarProduccion esta actualmente SUSPENDIDA (comentada).
    El Kanban mueve estados pero no descuenta insumos.
    ↓
Cliente retira el arreglo
```

## FLUJO FLORISTERIA B — Venta con delivery (pedido a domicilio)

```
Cajero/Vendedor registra venta + datos de entrega
    ↓
[Igual que Flujo A hasta crear Venta]
    +
crear_pedido() en distribucion:
    - Pedido [estado=PENDIENTE, estado_produccion=pendiente]
    - codigo_seguimiento (8 chars) generado
    - dedicatoria si la hay
    ↓
Arreglista ve en Kanban de produccion: PENDIENTE → ARMANDO → LISTO
Al marcar "LISTO": (mismo comportamiento que Flujo A)
    - Si completarProduccion habilitado: descuenta insumos FIFO
    - Pedido.estado_produccion = listo
    ↓
Supervisor Logistica asigna transportista
Pedido [estado=DESPACHADO → EN_RUTA]
    ↓
Conductor confirma entrega (foto + firma + OTP)
Pedido [estado=ENTREGADO]
    ↓
Cliente puede seguir su pedido en: empresa.com/seguimiento?codigo=XXXX
```

## FLUJO FLORISTERIA C — Recepcion de flores del mayorista (Yolanda)

```
Yolanda llega del mayorista con las flores compradas
    ↓
Entra a /compras/recepciones → selecciona la OC correspondiente
    ↓
Por cada tipo de flor en la OC:
    - Ingresa cantidad recibida
    - Puede dividir en MULTI-LOTE si vienen de fechas distintas:
      Ej: 6 rosas del miercoles + 6 rosas del jueves = 2 sub-lotes
    - Ingresa fecha_entrada de cada sub-lote
    ↓
"Confirmar Recepcion"
    → registrar_recepcion() llama a registrar_entrada() por cada lote
    → Lote creado con:
        - fecha_entrada = fecha indicada por Yolanda
        - estado_frescura = 'optimo' (siempre al ingresar)
        - factor_conversion aplicado: si caja de 100 tallos → stock +100
    → MovimientoStock tipo='entrada' registrado
    ↓
Stock actualizado. Flores visibles en /inventario/camara con semaforo verde.
```

## FLUJO FLORISTERIA D — Control diario de camara (Supervisor/Almacenero)

```
Tarea automatica Celery a las 00:00:
    actualizar_estados_frescura()
    → Recorre lotes activos de insumos_organicos
    → Calcula dias desde fecha_entrada
    → Actualiza estado_frescura:
        1-3 dias → optimo    (verde)
        4 dias   → precaucion (amarillo)
        5-7 dias → funebre   (rojo — solo para arreglos funebres)
        8+ dias  → descarte  (negro — botar)
    ↓
Supervisor entra a /inventario/camara:
    - Ve tabla FIFO: lo mas viejo arriba
    - Contadores por estado en el header: N optimo / N precaucion / N funebre / N descarte
    - Filtra por almacen si tiene varios
    ↓
Si hay flores en "funebre":
    → Reservar para pedidos funebres solamente (badge rojo)
Si hay flores en "descarte":
    → Registrar ajuste de stock (baja) con motivo = "descarte por frescura"
    → Tomar foto como evidencia
    ↓
Tarea Celery a las 20:00 (antes de llamar al mayorista):
    alerta_compras_nocturna()
    → Genera alerta con lista de insumos que hay que comprar manana
    → Notificacion a Yolanda (WhatsApp cuando este activo)
```

## FLUJO FLORISTERIA E — Personalizacion de arreglo en POS

```
Cliente pide: "Ramo Primavera pero con 3 rosas rojas en lugar de 5"
    ↓
Cajero/Vendedor en POS → item del arreglo → boton "Personalizar"
    ↓
Panel lateral:
    - Muestra receta default: 5 rosas rojas, 3 follajes, 1 cinta
    - Vendedor ajusta: rosas_rojas: 3, agrega rosas_blancas: 2
    - Backend calcula costo estimado del ajuste (referencia, no lo que se cobra)
    - Vendedor decide el recargo: S/. 5.00
    - Campo "Nota para el arreglista": "usar moño azul marino exactamente"
    ↓
Se guarda:
    - AjustePersonalizacion: { rosa_roja: 3, rosa_blanca: 2 }
    - DetalleVenta.recargo_personalizacion = 5.00
    - DetalleVenta.notas_arreglista = "usar moño azul marino exactamente"
    ↓
Al marcar "LISTO" en Kanban:
    completar_produccion_item():
    - Receta default: 5 rosas rojas, 3 follajes, 1 cinta
    - Aplica ajuste: reemplaza 5 rosas rojas por 3 rojas + 2 blancas
    - Descuenta: 3 rosas rojas + 2 rosas blancas + 3 follajes + 1 cinta
    - La RecetaProducto del producto NO se modifica
```

---

# FLUJOS GENERICOS DEL ERP (aplican a Amatista igual que al template)

## FLUJO G1 — Emision de comprobante SUNAT

```
Venta completada
    ↓
transaction.on_commit → Celery encola emitir_comprobante_por_venta()
    ↓
[Cola: critical]
Celery llama Nubefact OSE via HTTP:
    PENDIENTE → EN_PROCESO → ACEPTADO ✅
    Si falla: reintento hasta 5 veces
    Si 3 fallos consecutivos → modo contingencia
    ↓
Comprobante.estado_sunat actualizado
WebSocket notifica al frontend: badge SUNAT actualizado en tiempo real
```

## FLUJO G2 — Seguimiento publico de pedido (cliente)

```
Cliente recibe URL: empresa.com/seguimiento?codigo=XXXX
    ↓
GET /publico/seguimiento/{codigo}/  (sin auth)
    ↓
Ve: estado actual, timeline de eventos, datos del pedido
Si EN_RUTA: ve ubicacion en tiempo real del repartidor (GPS via WebSocket)
Si ENTREGADO: ve foto de evidencia
```

## FLUJO G3 — Cierre tributario mensual (Contador)

```
Seleccionar mes → ver checklist previo
    ↓
Todos los comprobantes del mes: CDR aceptado
No hay asientos sin cuadrar
CxC y CxP actualizadas
    ↓
"Generar PLE" → archivos TXT para SUNAT
"Cerrar Periodo" → PIN de firma → periodo = CERRADO
Periodo cerrado: no se puede modificar nada de ese mes
```

---

# Tabla de Accesos por Rol

| Vista / Modulo | Admin | Gerente | Supervisor | Vendedor | Cajero | Almacenero | Contador | Repartidor |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Dashboard global | ✅ | ✅ | Solo almacen | Solo ventas | ❌ | ❌ | Solo finanzas | ❌ |
| POS | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Cotizaciones | ✅ | Solo lectura | ❌ | ✅ propias | ❌ | ❌ | ❌ | ❌ |
| Ordenes de Venta | ✅ | Solo lectura | ❌ | ✅ propias | ❌ | ❌ | ❌ | ❌ |
| Inventario / Stock | ✅ | Solo lectura | ✅ | Consulta | Consulta | ✅ | ❌ | ❌ |
| Control de Camara | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Recetas / BOM | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Kanban Produccion | ✅ | Solo lectura | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Compras / Recepciones | ✅ | Solo lectura | ✅ | ❌ | ❌ | ✅ recepcion | ✅ pago | ❌ |
| Facturacion SUNAT | ✅ | ❌ | ❌ | ❌ | Solo boletas POS | ❌ | ✅ | ❌ |
| CxC / CxP | ✅ | Solo lectura | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Distribucion / Pedidos | ✅ | Solo lectura | ✅ | Solo sus pedidos | ❌ | ❌ | ❌ | Solo sus entregas |
| WhatsApp | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Usuarios y Roles | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Audit Log | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reportes globales | ✅ | ✅ | Solo inventario | Solo propios | Solo cierre caja | ❌ | Finanzas | ❌ |
