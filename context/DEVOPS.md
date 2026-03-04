# AMATISTA ERP — ARQUITECTURA DE SERVICIOS (DEVOPS)

> Igual al template JSoluciones con las tareas especificas de floreria agregadas.
> Single-tenant — instancia unica para Amatista.

---

## Diagrama de Servicios

```
┌─────────────────────────────────────────────────────────┐
│                    AMATISTA ERP                         │
│                                                         │
│  Django (ASGI)       <->  PostgreSQL 16                 │
│         |                                               │
│  Django Channels     <->  Redis DB1 (Channel Layer)     │
│         |                                               │
│  Celery Workers      <->  Redis DB0 (Broker)            │
│  Celery Beat                                            │
│         |                                               │
│  Redis DB2 (Cache)                                      │
│         |                                               │
│  Cloudflare R2 (Storage)                                │
│         |                                               │
│  Nubefact OSE (SUNAT)                                   │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Redis — 3 Usos Distintos

| Uso | DB Redis | Descripcion |
|-----|----------|-------------|
| Broker de Celery | DB 0 | Cola de tareas async |
| Channel Layer (WebSockets) | DB 1 | Mensajes en tiempo real via Django Channels |
| Cache general | DB 2 | Queries, JWT blacklist, presigned URLs |

---

## 2. Celery — Colas y Tareas

### Colas por Prioridad

| Cola | Workers | Que procesa |
|------|---------|-------------|
| `critical` | 2 | Emision SUNAT, pagos, apertura/cierre caja |
| `default` | 2 | Tareas generales, inventario, produccion, asientos |
| `notifications` | 1 | WhatsApp, emails |
| `reports` | 1 | Generacion reportes, Excel/PDF |

### Catalogo de Tareas — Especificas de Amatista

#### Inventario (floreria)
| Tarea | Cola | Trigger | Descripcion |
|-------|------|---------|-------------|
| `actualizar_frescura_diaria` | default | Crontab 00:00 | Actualiza `estado_frescura` en todos los lotes activos de insumos organicos segun dias desde `fecha_entrada` |
| `alerta_compras_nocturna` | notifications | Crontab 20:00 | Genera lista de insumos a comprar (stock bajo + flores mermadas + rotacion A) |
| `verificar_stock_minimo` | default | Post-movimiento | Alerta si algun insumo queda bajo stock minimo |
| `alertar_lote_por_vencer` | notifications | Crontab 07:00 | Alerta de lotes proximos a vencer (si fecha_vencimiento existe) |

#### Ventas / Facturacion (critico)
| Tarea | Cola | Trigger |
|-------|------|---------|
| `emitir_comprobante_por_venta` | critical | Post-venta (transaction.on_commit) |
| `reenviar_comprobantes_pendientes` | critical | Crontab cada 5 min |
| `enviar_resumen_diario_boletas` | critical | Crontab 23:50 Lima |
| `enviar_comprobante_cliente_email` | notifications | Post-emision |

#### Finanzas
| Tarea | Cola | Trigger |
|-------|------|---------|
| `alertar_cxc_vencidas` | notifications | Crontab 08:00 |
| `calcular_intereses_mora` | default | Crontab 06:00 |

#### Dashboard
| Tarea | Cola | Trigger |
|-------|------|---------|
| `calcular_kpis_dashboard` | reports | Crontab cada 10 min |

---

## 3. Celery Beat — Schedule

Todas las horas en America/Lima:

```python
"actualizar-frescura-diaria":        crontab(hour=0, minute=0),     # Medianoche — critico para Amatista
"alerta-compras-nocturna":           crontab(hour=20, minute=0),    # 8PM — antes de llamar al mayorista
"alertar-lotes-por-vencer":          crontab(hour=7, minute=0),
"enviar-resumen-diario-sunat":       crontab(hour=23, minute=50),
"reintentar-comprobantes":           cada 300 seg (5 min),
"alertar-cxc-vencidas":              crontab(hour=8, minute=0),
"calcular-intereses-mora":           crontab(hour=6, minute=0),
"precalcular-kpis-dashboard":        cada 600 seg (10 min),
"invalidar-sesiones-expiradas":      cada 3600 seg (1h),
"limpiar-archivos-temporales":       crontab(hour=4, minute=30),
```

---

## 4. Django Channels — WebSockets

| Consumer | Grupo WS | Quien se suscribe | Que emite |
|----------|----------|-------------------|-----------|
| `DashboardConsumer` | `dashboard_{user_id}` | Usuarios con dashboard | KPIs actualizados |
| `NotificacionesConsumer` | `notif_{user_id}` | Todos | Notificaciones (badge header) |
| `FacturacionConsumer` | `factura_{user_id}` | Emisores | Respuesta SUNAT en tiempo real |
| `GPSConsumer` | `gps_{pedido_id}` | Seguimiento de pedidos | Coordenadas GPS conductor |
| `PedidosConsumer` | `pedidos_{sucursal_id}` | Distribucion | Nuevos pedidos, cambios estado |

---

## 5. Cloudflare R2 (Storage)

### 3 Buckets Privados

| Bucket | Contenido | TTL Presigned URL |
|--------|-----------|-------------------|
| `j-soluciones-media` | Fotos de productos/flores, logos | 2h |
| `j-soluciones-documentos` | XMLs, CDRs, PDFs de comprobantes | 1h |
| `j-soluciones-evidencias` | Fotos de entrega, firmas | 2h |

> Nota: Los buckets usan el nombre `j-soluciones-*` — son los mismos del template base.
> Al hacer produccion para Amatista, renombrar o crear buckets `amatista-*`.

---

## 6. Docker Compose (Desarrollo Local)

```yaml
services:
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  celery-worker-critical:
    command: celery -A config worker -Q critical -c 2 -l info

  celery-worker-default:
    command: celery -A config worker -Q default,notifications -c 2 -l info

  celery-worker-reports:
    command: celery -A config worker -Q reports -c 1 -l info

  celery-beat:
    command: celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler

  flower:
    command: celery -A config flower --port=5555
    ports: ["5555:5555"]
```

---

## 7. Servidor ASGI (Produccion)

```bash
uvicorn config.asgi:application \
  --host 0.0.0.0 \
  --port 8000 \
  --workers 4 \
  --lifespan off
```

> NO usar Gunicorn — requiere Uvicorn/Daphne por los WebSockets (ASGI).

---

## 8. Certificados Nubefact

- Certificados DEMO en: `Amatista-be/certs/`
- Para produccion: reemplazar con certificados reales del cliente (RUC del Sr. Tito)
- Variables en `.env`: `NUBEFACT_TOKEN`, `NUBEFACT_WSDL`, `CERT_PFX_PATH`, `CERT_PFX_PASSWORD`

---

## 9. Notas Clave

1. **`actualizar_frescura_diaria` es critica para Amatista** — si no corre a medianoche, el semaforo de frescura no cambia y el control de camara es inutil.
2. **`alerta_compras_nocturna` a las 20:00** — Yolanda llama al mayorista alrededor de esa hora para hacer el pedido del dia siguiente.
3. **Sin multitenant** — las tareas son globales para la instancia de Amatista.
4. **SUNAT es critico** — la cola `critical` NUNCA debe compartirse con tareas de baja prioridad.
5. **GPS en tiempo real** — coordenadas del conductor se guardan en Redis con TTL corto, no en DB. Solo se persisten los eventos de estado (despachado/entregado).
