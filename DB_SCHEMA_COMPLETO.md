# AMATISTA ERP — SCHEMA COMPLETO DE BASE DE DATOS

> Extraido directamente de PostgreSQL 16 (db1) en Mar 2026.
> 74 tablas, 33 enums, ~250+ indices.
> Fuente de verdad para cualquier cambio en modelos o migraciones.

---

## 1. CONVENCIONES GLOBALES

| Patron | Regla |
|--------|-------|
| PK | `id UUID DEFAULT gen_random_uuid()` en TODAS las tablas (excepto M2M sin logica) |
| Timestamps | `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()` |
| Soft delete | `is_active BOOLEAN DEFAULT true` en entidades principales |
| Audit | `creado_por_id UUID NULL → perfiles_usuario`, `actualizado_por_id UUID NULL → perfiles_usuario` |
| FK PROTECT | Entidades referenciadas (producto, cliente, proveedor, almacen) |
| FK CASCADE | Detalles que no tienen sentido sin cabecera (detalle_ventas → ventas, etc.) |
| FK SET NULL | Campos opcionales de auditoria (creado_por_id, usuario_id en logs) |
| Monetario | `NUMERIC(12,2)` para montos, `NUMERIC(12,4)` para precio_unitario, `NUMERIC(5,2)` para porcentajes |

---

## 2. ENUMS (33 tipos)

```sql
-- Afectacion IGV SUNAT
enum_afectacion_igv: {10, 20, 30, 21}
-- 10=Gravado, 20=Exonerado, 30=Inafecto, 21=Gravado-retiro

-- Categoria plantilla WhatsApp
enum_categoria_plantilla_wa: {transaccional, marketing, alerta}

-- Entidad para media archivos (R2)
enum_entidad_media: {producto, configuracion, perfil_usuario, evidencia_entrega, proveedor, cliente}

-- Estado asientos contables
enum_estado_asiento: {borrador, confirmado, anulado}

-- Estado comprobante SUNAT
enum_estado_comprobante: {pendiente, aceptado, rechazado, observado, anulado, error, pendiente_reenvio, error_permanente}

-- Estado cotizacion
enum_estado_cotizacion: {borrador, vigente, aceptada, vencida, rechazada}

-- Estado cuenta por cobrar/pagar
enum_estado_cuenta: {pendiente, vencido, pagado, refinanciado}

-- Estado envio Nubefact
enum_estado_envio_nubefact: {enviado, error, pendiente}

-- Estado factura de proveedor
enum_estado_factura_proveedor: {registrada, conciliada, pagada, anulada}

-- Estado mensaje WhatsApp
enum_estado_mensaje_wa: {enviado, entregado, leido, fallido, en_espera}

-- Estado orden de compra
enum_estado_orden_compra: {borrador, pendiente_aprobacion, aprobada, enviada, recibida_parcial, recibida, cerrada, cancelada}

-- Estado orden de venta
enum_estado_orden_venta: {pendiente, confirmada, parcial, completada, cancelada}

-- Estado pedido (distribucion)
enum_estado_pedido: {pendiente, confirmado, despachado, en_ruta, entregado, cancelado, devuelto, reprogramado, no_entregado}

-- Estado plantilla Meta (WhatsApp)
enum_estado_plantilla_meta: {en_revision, aprobada, rechazada}

-- Estado venta
enum_estado_venta: {completada, anulada}

-- Metodo de pago
enum_metodo_pago: {efectivo, tarjeta, transferencia, yape_plin, credito}

-- Modo emision comprobante
enum_modo_emision: {normal, contingencia}

-- Moneda
enum_moneda: {PEN, USD}

-- Motivo nota de credito SUNAT
enum_motivo_nota_credito: {01, 02, 03, 06}
-- 01=Anulacion, 02=Anulacion por error RUC, 03=Correccion por error, 06=Devolucion

-- Motivo nota de debito SUNAT
enum_motivo_nota_debito: {01, 02, 03}
-- 01=Intereses mora, 02=Aumento de valor, 03=Penalidades

-- Prioridad pedido
enum_prioridad_pedido: {normal, express}

-- Referencia movimiento stock
enum_referencia_movimiento: {venta, compra, ajuste_manual, transferencia, devolucion}

-- Segmento cliente
enum_segmento_cliente: {nuevo, frecuente, vip, credito, corporativo}

-- Tipo archivo media
enum_tipo_archivo: {imagen, documento, firma}

-- Tipo comprobante SUNAT
enum_tipo_comprobante: {01, 03, 07, 08}
-- 01=Factura, 03=Boleta, 07=Nota Credito, 08=Nota Debito

-- Tipo cuenta contable
enum_tipo_cuenta_contable: {activo, pasivo, patrimonio, ingreso, gasto}

-- Tipo documento identidad SUNAT
enum_tipo_documento: {1, 6, 4, 7, 0}
-- 1=DNI, 6=RUC, 4=Carnet Extranjeria, 7=Pasaporte, 0=Sin Doc

-- Tipo evidencia entrega
enum_tipo_evidencia: {foto, firma, otp}

-- Tipo movimiento stock
enum_tipo_movimiento: {entrada, salida, transferencia, ajuste, devolucion}

-- Tipo nota credito/debito
enum_tipo_nota: {07, 08}
-- 07=Nota Credito, 08=Nota Debito

-- Tipo recepcion de OC
enum_tipo_recepcion: {total, parcial}

-- Tipo venta
enum_tipo_venta: {directa, online, campo}

-- Unidad de medida SUNAT
enum_unidad_medida: {NIU, KGM, LTR, MTR, BX, DZN, PK, ZZ}
-- NIU=Unidad, KGM=Kilogramo, LTR=Litro, MTR=Metro, BX=Caja, DZN=Docena, PK=Paquete, ZZ=Otro
```

---

## 3. TABLAS — MODULO POR MODULO

### 3.1 Usuarios y Acceso

#### `usuarios` (AbstractUser Django)
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| email | VARCHAR(254) | NO | | UNIQUE — login principal |
| password | VARCHAR(128) | NO | | bcrypt |
| first_name | VARCHAR(150) | NO | | |
| last_name | VARCHAR(150) | NO | | |
| is_active | BOOL | NO | true | |
| is_staff | BOOL | NO | false | Django admin |
| is_superuser | BOOL | NO | false | Django superuser |
| date_joined | TIMESTAMPTZ | NO | now() | |
| last_login | TIMESTAMPTZ | YES | | |

**Indices:** `usuarios_email_key` (UNIQUE email)

---

#### `perfiles_usuario`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| usuario_id | UUID | NO | | FK usuarios CASCADE — UNIQUE |
| rol_id | UUID | NO | | FK roles PROTECT |
| telefono | VARCHAR(20) | NO | '' | |
| avatar | VARCHAR(200) | YES | | R2 key |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| password_changed_at | TIMESTAMPTZ | YES | | |
| totp_enabled | BOOL | NO | | 2FA |
| totp_secret | VARCHAR(64) | NO | | |

**Indices:** `perfiles_usuario_usuario_id_key` (UNIQUE), `idx_perfiles_usuario_rol`

---

#### `roles`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| codigo | VARCHAR(30) | NO | | UNIQUE (admin, gerente, supervisor, vendedor, cajero, almacenero, contador, repartidor) |
| nombre | VARCHAR(100) | NO | |
| descripcion | TEXT | NO | '' |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `permisos`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| codigo | VARCHAR(50) | NO | | UNIQUE (formato: modulo.accion) |
| nombre | VARCHAR(100) | NO | |
| modulo | VARCHAR(30) | NO | |
| descripcion | TEXT | NO | '' |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `rol_permisos` (M2M roles ↔ permisos)
| Columna | Tipo | Null |
|---------|------|------|
| id | UUID | NO |
| rol_id | UUID | NO | FK roles CASCADE |
| permiso_id | UUID | NO | FK permisos CASCADE |
| created_at | TIMESTAMPTZ | NO |
| updated_at | TIMESTAMPTZ | NO |

**Constraint:** UNIQUE(rol_id, permiso_id)

---

#### `sesiones_activas`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| usuario_id | UUID | NO | FK perfiles_usuario |
| jti | VARCHAR | NO | | UNIQUE (JWT ID) |
| activo | BOOL | NO | |
| created_at | TIMESTAMPTZ | NO | now() |

**Indices:** `idx_sesion_usuario_activo` (usuario_id, activo)

---

### 3.2 Inventario

#### `categorias`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| nombre | VARCHAR(100) | NO | |
| descripcion | TEXT | NO | '' |
| categoria_padre_id | UUID | YES | | FK self SET NULL (arbol) |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

**Indices:** `idx_categorias_padre`

---

#### `productos`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| sku | VARCHAR(50) | NO | | UNIQUE |
| nombre | VARCHAR(200) | NO | | |
| descripcion | TEXT | NO | '' | |
| codigo_barras | VARCHAR(50) | NO | '' | |
| categoria_id | UUID | YES | | FK categorias SET NULL |
| unidad_medida | enum_unidad_medida | NO | 'NIU' | |
| precio_compra | NUMERIC(12,4) | NO | 0 | |
| precio_venta | NUMERIC(12,4) | NO | | |
| codigo_afectacion_igv | enum_afectacion_igv | NO | '10' | |
| stock_minimo | NUMERIC(12,2) | NO | 0 | |
| stock_maximo | NUMERIC(12,2) | NO | 0 | |
| requiere_lote | BOOL | NO | false | true para insumos organicos |
| requiere_serie | BOOL | NO | | para productos seriados |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| creado_por_id | UUID | YES | | FK perfiles_usuario SET NULL |
| actualizado_por_id | UUID | YES | | FK perfiles_usuario SET NULL |

**Indices:** `productos_sku_key` (UNIQUE), `idx_productos_nombre`, `idx_productos_sku`, `idx_productos_categoria_activo` (categoria_id, is_active)

**IMPORTANTE Fase 1:** Faltan columnas que se agregarán:
- `tipo_registro` VARCHAR(20) DEFAULT 'producto_final' (insumo_organico | insumo_no_organico | producto_final)
- `descuenta_insumos` BOOL DEFAULT false
- `unidad_compra` VARCHAR(50) DEFAULT ''
- `factor_conversion` INT DEFAULT 1

---

#### `almacenes`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| nombre | VARCHAR(100) | NO | |
| direccion | TEXT | NO | '' |
| sucursal | VARCHAR(100) | NO | '' |
| es_principal | BOOL | NO | false |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `stock`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| producto_id | UUID | NO | | FK productos CASCADE |
| almacen_id | UUID | NO | | FK almacenes CASCADE |
| cantidad | NUMERIC(12,2) | NO | 0 | Stock actual agregado |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Constraint:** UNIQUE(producto_id, almacen_id) — una fila por producto-almacen

**Indices:** `idx_stock_almacen`

---

#### `lotes`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| producto_id | UUID | NO | | FK productos PROTECT |
| numero_lote | VARCHAR(50) | NO | | No tiene default — requerido |
| fecha_vencimiento | DATE | YES | | null = no vence |
| cantidad_inicial | NUMERIC(12,2) | NO | | |
| cantidad_actual | NUMERIC(12,2) | NO | | |
| almacen_id | UUID | NO | | FK almacenes PROTECT |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Indices:** `idx_lotes_producto`, `idx_lotes_almacen`, `idx_lotes_vencimiento`

**IMPORTANTE Fase 1:** Faltan columnas que se agregarán:
- `fecha_entrada` DATE DEFAULT CURRENT_DATE (para FIFO y semaforo frescura)
- `estado_frescura` VARCHAR(20) DEFAULT 'optimo' (optimo | precaucion | funebre | descarte)

---

#### `movimientos_stock`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | PK |
| producto_id | UUID | NO | | FK productos PROTECT |
| almacen_id | UUID | NO | | FK almacenes PROTECT |
| tipo_movimiento | enum_tipo_movimiento | NO | | entrada|salida|transferencia|ajuste|devolucion |
| cantidad | NUMERIC(12,2) | NO | | Siempre positivo |
| almacen_destino_id | UUID | YES | | Solo en transferencias |
| referencia_tipo | enum_referencia_movimiento | YES | | venta|compra|ajuste_manual|transferencia|devolucion |
| referencia_id | UUID | YES | | UUID del doc origen |
| lote_id | UUID | YES | | FK lotes SET NULL |
| motivo | TEXT | NO | '' | |
| usuario_id | UUID | YES | | FK perfiles_usuario SET NULL |
| created_at | TIMESTAMPTZ | NO | now() | Inmutable — NO tiene updated_at |

**Indices:** `idx_mov_producto_fecha`, `idx_mov_almacen_tipo`, `idx_mov_referencia`, `idx_mov_lote`, `idx_mov_usuario`, `idx_mov_almacen_destino`

> Tabla inmutable — NUNCA borrar ni editar registros.

---

#### `ubicaciones_almacen`
| Columna | Tipo | Null |
|---------|------|------|
| id | UUID | NO |
| almacen_id | UUID | NO | FK almacenes |
| codigo | VARCHAR | NO |
| created_at | TIMESTAMPTZ | NO |

**Constraint:** UNIQUE(almacen_id, codigo)

---

### 3.3 Ventas

#### `ventas`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| numero | VARCHAR(20) | NO | | Ej: V001-0001 |
| fecha | DATE | NO | | |
| hora | TIME | YES | | |
| orden_origen_id | UUID | YES | | FK ordenes_venta SET NULL |
| cliente_id | UUID | YES | | FK clientes (nullable = consumidor final) |
| vendedor_id | UUID | NO | | FK perfiles_usuario PROTECT |
| sucursal | VARCHAR(100) | NO | '' | |
| tipo_venta | enum_tipo_venta | NO | 'directa' | directa|online|campo |
| metodo_pago | VARCHAR(30) | NO | 'efectivo' | Denormalizado — formas_pago tiene el detalle |
| total_gravada | NUMERIC(12,2) | NO | 0 | |
| total_igv | NUMERIC(12,2) | NO | 0 | |
| total_descuento | NUMERIC(12,2) | NO | 0 | |
| total_venta | NUMERIC(12,2) | NO | 0 | |
| estado | enum_estado_venta | NO | 'completada' | completada|anulada |
| comprobante_id | UUID | YES | | FK comprobantes SET NULL |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| creado_por_id | UUID | YES | | FK perfiles_usuario SET NULL |

---

#### `detalle_ventas`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| venta_id | UUID | NO | | FK ventas CASCADE |
| producto_id | UUID | NO | | FK productos PROTECT |
| cantidad | NUMERIC(12,2) | NO | | |
| precio_unitario | NUMERIC(12,4) | NO | | |
| descuento_porcentaje | NUMERIC(5,2) | NO | 0 | |
| subtotal | NUMERIC(12,2) | NO | | |
| igv | NUMERIC(12,2) | NO | | |
| total | NUMERIC(12,2) | NO | | |
| lote_id | UUID | YES | | FK lotes SET NULL |
| estado_produccion | VARCHAR(20) | NO | | pendiente|en_produccion|listo|entregado |
| produccion_iniciada_en | TIMESTAMPTZ | YES | | |
| produccion_completada_en | TIMESTAMPTZ | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Indices:** `idx_dv_venta_producto`, `idx_dv_producto`, `idx_dv_lote`, `detalle_ventas_estado_produccion_*`

---

#### `cotizaciones`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| numero | VARCHAR(20) | NO | | UNIQUE |
| fecha_emision | DATE | NO | |
| fecha_validez | DATE | NO | |
| cliente_id | UUID | NO | | FK clientes PROTECT |
| vendedor_id | UUID | NO | | FK perfiles_usuario PROTECT |
| estado | enum_estado_cotizacion | NO | 'borrador' |
| total_gravada | NUMERIC(12,2) | NO | 0 |
| total_igv | NUMERIC(12,2) | NO | 0 |
| total_venta | NUMERIC(12,2) | NO | 0 |
| notas | TEXT | NO | '' |
| condiciones_comerciales | TEXT | NO | '' |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |
| creado_por_id | UUID | YES | |

**Indices:** `uq_cotizaciones_numero`, `idx_cotizaciones_estado_fecha`, `idx_cotizaciones_cliente`, `idx_cotizaciones_vendedor`

---

#### `detalle_cotizaciones`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| cotizacion_id | UUID | NO | FK cotizaciones CASCADE |
| producto_id | UUID | NO | FK productos PROTECT |
| cantidad | NUMERIC(12,2) | NO | |
| precio_unitario | NUMERIC(12,4) | NO | |
| descuento_porcentaje | NUMERIC(5,2) | NO | 0 |
| subtotal | NUMERIC(12,2) | NO | |
| igv | NUMERIC(12,2) | NO | |
| total | NUMERIC(12,2) | NO | |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `ordenes_venta`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| numero | VARCHAR(20) | NO | | UNIQUE |
| fecha | DATE | NO | |
| cotizacion_origen_id | UUID | YES | | FK cotizaciones SET NULL |
| cliente_id | UUID | NO | | FK clientes PROTECT |
| vendedor_id | UUID | NO | | FK perfiles_usuario PROTECT |
| estado | enum_estado_orden_venta | NO | 'pendiente' |
| total_gravada | NUMERIC(12,2) | NO | 0 |
| total_igv | NUMERIC(12,2) | NO | 0 |
| total_venta | NUMERIC(12,2) | NO | 0 |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |
| creado_por_id | UUID | YES | |

---

#### `detalle_ordenes_venta`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| orden_venta_id | UUID | NO | FK ordenes_venta CASCADE |
| producto_id | UUID | NO | FK productos PROTECT |
| cantidad | NUMERIC(12,2) | NO | |
| cantidad_entregada | NUMERIC(12,2) | NO | 0 |
| precio_unitario | NUMERIC(12,4) | NO | |
| descuento_porcentaje | NUMERIC(5,2) | NO | 0 |
| subtotal | NUMERIC(12,2) | NO | |
| igv | NUMERIC(12,2) | NO | |
| total | NUMERIC(12,2) | NO | |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `formas_pago`
| Columna | Tipo | Null |
|---------|------|------|
| id | UUID | NO |
| venta_id | UUID | NO | FK ventas |
| metodo_pago | VARCHAR(30) | NO | (efectivo|tarjeta|transferencia|yape_plin|credito) |
| monto | NUMERIC(12,2) | NO |
| referencia | VARCHAR(100) | NO |
| created_at | TIMESTAMPTZ | NO |

---

### 3.4 Compras

#### `proveedores`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| ruc | VARCHAR(11) | NO | | UNIQUE |
| razon_social | VARCHAR(200) | NO | |
| nombre_comercial | VARCHAR(200) | NO | '' |
| direccion | TEXT | NO | '' |
| email | VARCHAR(254) | NO | '' |
| telefono | VARCHAR(20) | NO | '' |
| contacto_nombre | VARCHAR(100) | NO | '' |
| contacto_telefono | VARCHAR(20) | NO | '' |
| condicion_pago_dias | INT | NO | 0 |
| calificacion | INT | NO | 3 | 1-5 |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `ordenes_compra`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| numero | VARCHAR(20) | NO | | UNIQUE |
| fecha | DATE | NO | |
| fecha_estimada_entrega | DATE | YES | |
| proveedor_id | UUID | NO | | FK proveedores PROTECT |
| estado | enum_estado_orden_compra | NO | 'borrador' |
| almacen_destino_id | UUID | YES | | FK almacenes SET NULL |
| moneda | enum_moneda | NO | 'PEN' |
| total_base | NUMERIC(12,2) | NO | 0 |
| total_igv | NUMERIC(12,2) | NO | 0 |
| total | NUMERIC(12,2) | NO | 0 |
| gastos_logisticos | NUMERIC(12,2) | NO | |
| notas | TEXT | NO | '' |
| aprobado_por_id | UUID | YES | | FK perfiles_usuario SET NULL |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |
| creado_por_id | UUID | YES | |

**Indices:** `idx_oc_estado_fecha`, `idx_oc_proveedor`, `idx_oc_almacen_destino`

---

#### `detalle_ordenes_compra`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| orden_compra_id | UUID | NO | FK ordenes_compra CASCADE |
| producto_id | UUID | NO | FK productos PROTECT |
| cantidad | NUMERIC(12,2) | NO | |
| cantidad_recibida | NUMERIC(12,2) | NO | 0 |
| precio_unitario | NUMERIC(12,4) | NO | |
| subtotal | NUMERIC(12,2) | NO | |
| igv | NUMERIC(12,2) | NO | |
| total | NUMERIC(12,2) | NO | |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `recepciones`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| orden_compra_id | UUID | NO | FK ordenes_compra PROTECT |
| fecha_recepcion | DATE | NO | |
| almacen_id | UUID | NO | FK almacenes PROTECT |
| tipo | enum_tipo_recepcion | NO | | total|parcial |
| observaciones | TEXT | NO | '' |
| recibido_por_id | UUID | YES | FK perfiles_usuario SET NULL |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

**Indices:** `idx_recepciones_orden_compra`, `idx_recepciones_almacen`

---

#### `detalle_recepciones`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| recepcion_id | UUID | NO | | FK recepciones CASCADE |
| detalle_orden_compra_id | UUID | NO | | FK detalle_ordenes_compra PROTECT |
| producto_id | UUID | NO | | FK productos PROTECT |
| cantidad_recibida | NUMERIC(12,2) | NO | | |
| lote_id | UUID | YES | | FK lotes SET NULL — se asigna al recepcionar |
| observaciones | TEXT | NO | '' | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

---

#### `facturas_proveedor`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| proveedor_id | UUID | NO | FK proveedores PROTECT |
| numero_factura | VARCHAR(30) | NO | |
| ruc_proveedor | VARCHAR(11) | NO | |
| fecha_emision | DATE | NO | |
| fecha_vencimiento | DATE | YES | |
| total_base | NUMERIC(12,2) | NO | 0 |
| total_igv | NUMERIC(12,2) | NO | 0 |
| total | NUMERIC(12,2) | NO | 0 |
| orden_compra_id | UUID | YES | FK ordenes_compra SET NULL |
| estado | enum_estado_factura_proveedor | NO | 'registrada' |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

**Constraint:** UNIQUE(proveedor_id, numero_factura) WHERE is_active

---

### 3.5 Facturacion SUNAT

#### `comprobantes`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| tipo_comprobante | enum_tipo_comprobante | NO | | 01=Factura, 03=Boleta |
| serie | VARCHAR(4) | NO | | Ej: F001, B001 |
| numero | INT | NO | | Correlativo |
| fecha_emision | DATE | NO | | |
| hora_emision | TIME | YES | | |
| cliente_id | UUID | NO | | FK clientes PROTECT |
| moneda | enum_moneda | NO | 'PEN' | |
| total_gravada | NUMERIC(12,2) | NO | 0 | |
| total_exonerada | NUMERIC(12,2) | NO | 0 | |
| total_inafecta | NUMERIC(12,2) | NO | 0 | |
| total_igv | NUMERIC(12,2) | NO | 0 | |
| total_venta | NUMERIC(12,2) | NO | 0 | |
| estado_sunat | enum_estado_comprobante | NO | 'pendiente' | |
| pdf_r2_key | VARCHAR(500) | NO | '' | |
| xml_r2_key | TEXT | NO | '' | |
| cdr_r2_key | TEXT | NO | '' | |
| hash_sunat | TEXT | NO | '' | |
| qr_sunat | TEXT | NO | '' | |
| nubefact_request | JSONB | YES | | |
| nubefact_response | JSONB | YES | | |
| modo_emision | enum_modo_emision | NO | 'normal' | |
| venta_id | UUID | YES | | FK ventas SET NULL |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| creado_por_id | UUID | YES | | |

**Constraint:** UNIQUE(tipo_comprobante, serie, numero)
**Indices:** `idx_comprobantes_tipo_fecha`, `idx_comprobantes_cliente_fecha`, `idx_comprobantes_estado`

> Tabla INMUTABLE una vez emitida. Solo soft-delete via estado.

---

#### `series_comprobante`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| tipo_comprobante | enum_tipo_comprobante | NO | |
| serie | VARCHAR(4) | NO | | F001, B001, FC01 |
| correlativo_actual | INT | NO | 0 | Se incrementa con select_for_update() |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

**Constraint:** UNIQUE(tipo_comprobante, serie)

---

#### `notas_credito_debito`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| comprobante_origen_id | UUID | NO | FK comprobantes PROTECT |
| tipo_nota | enum_tipo_nota | NO | | 07=NC, 08=ND |
| serie | VARCHAR(4) | NO | |
| numero | INT | NO | |
| fecha_emision | DATE | NO | |
| motivo_codigo_nc | enum_motivo_nota_credito | YES | |
| motivo_codigo_nd | enum_motivo_nota_debito | YES | |
| motivo_descripcion | TEXT | NO | '' |
| total_gravada | NUMERIC(12,2) | NO | 0 |
| total_igv | NUMERIC(12,2) | NO | 0 |
| total | NUMERIC(12,2) | NO | 0 |
| estado_sunat | enum_estado_comprobante | NO | 'pendiente' |
| pdf_r2_key | VARCHAR(500) | NO | '' |
| xml_r2_key | TEXT | NO | '' |
| cdr_r2_key | TEXT | NO | '' |
| nubefact_request | JSONB | YES | |
| nubefact_response | JSONB | YES | |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |
| creado_por_id | UUID | YES | |

**Constraint:** UNIQUE(tipo_nota, serie, numero)

---

### 3.6 Distribucion

#### `clientes`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| tipo_documento | enum_tipo_documento | NO | | 1=DNI, 6=RUC |
| numero_documento | VARCHAR(15) | NO | | |
| razon_social | VARCHAR(200) | NO | | |
| nombre_comercial | VARCHAR(200) | NO | '' | |
| direccion | TEXT | NO | '' | |
| ubigeo | VARCHAR(6) | NO | '' | |
| email | VARCHAR(254) | NO | '' | |
| telefono | VARCHAR(20) | NO | '' | |
| segmento | enum_segmento_cliente | NO | 'nuevo' | |
| limite_credito | NUMERIC(12,2) | NO | 0 | |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| creado_por_id | UUID | YES | | |
| actualizado_por_id | UUID | YES | | |

**Indice unico:** `idx_clientes_doc_unico` UNIQUE(tipo_documento, numero_documento) WHERE is_active

---

#### `pedidos`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| numero | VARCHAR(20) | NO | | UNIQUE |
| fecha | DATE | NO | | |
| venta_id | UUID | YES | | FK ventas SET NULL |
| cliente_id | UUID | NO | | FK clientes PROTECT |
| nombre_destinatario | VARCHAR(200) | NO | | |
| telefono_destinatario | VARCHAR(20) | NO | | |
| direccion_entrega | TEXT | NO | | |
| latitud | NUMERIC(10,7) | YES | | GPS |
| longitud | NUMERIC(10,7) | YES | | GPS |
| enlace_ubicacion | VARCHAR(2000) | NO | | Google Maps link |
| estado | enum_estado_pedido | NO | 'pendiente' | |
| transportista_id | UUID | YES | | FK transportistas SET NULL |
| fecha_pedido | DATE | YES | | |
| fecha_estimada_entrega | DATE | YES | | |
| fecha_entrega_real | DATE | YES | | |
| fecha_confirmacion | TIMESTAMPTZ | YES | | |
| turno_entrega | VARCHAR(10) | NO | | manana|tarde|noche |
| turno_express_rango | VARCHAR(50) | NO | | |
| es_urgente | BOOL | NO | | |
| prioridad | enum_prioridad_pedido | NO | 'normal' | |
| costo_delivery | NUMERIC(10,2) | NO | | |
| dedicatoria | TEXT | NO | | |
| estado_produccion | VARCHAR(20) | NO | | pendiente|en_produccion|listo |
| produccion_iniciada_en | TIMESTAMPTZ | YES | | |
| produccion_completada_en | TIMESTAMPTZ | YES | | |
| foto_entrega | VARCHAR(100) | YES | | |
| observacion_conductor | TEXT | NO | | |
| codigo_seguimiento | VARCHAR(8) | NO | | UNIQUE — publico |
| notas | TEXT | NO | '' | |
| is_active | BOOL | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| creado_por_id | UUID | YES | | |

**Indices:** `uq_pedidos_numero`, `pedidos_codigo_seguimiento_*` (UNIQUE), `idx_pedidos_estado_fecha`, `idx_pedidos_cliente`, `idx_pedidos_transportista`

---

#### `transportistas`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| nombre | VARCHAR(200) | NO | |
| telefono | VARCHAR(20) | NO | |
| email | VARCHAR(254) | NO | '' |
| tipo_vehiculo | VARCHAR(50) | NO | '' |
| placa | VARCHAR(10) | NO | '' |
| limite_pedidos_diario | INT | NO | 20 |
| token | UUID | NO | | UNIQUE — auth app movil |
| app_nombre | VARCHAR(50) | NO | |
| tipo_transportista | VARCHAR(20) | NO | | interno|externo |
| preferencia_zona | VARCHAR(200) | NO | |
| last_lat | NUMERIC(10,8) | YES | | GPS en tiempo real |
| last_lng | NUMERIC(10,8) | YES | | |
| last_location_at | TIMESTAMPTZ | YES | | |
| is_active | BOOL | NO | true |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

#### `seguimiento_pedidos`
| Columna | Tipo | Null |
|---------|------|------|
| id | UUID | NO |
| pedido_id | UUID | NO | FK pedidos CASCADE |
| estado | enum_estado_pedido | NO |
| latitud | NUMERIC(10,7) | YES |
| longitud | NUMERIC(10,7) | YES |
| descripcion | TEXT | NO |
| fecha_evento | TIMESTAMPTZ | NO |
| created_at | TIMESTAMPTZ | NO |

**Indice:** `idx_seguimiento_pedido`

---

### 3.7 Finanzas

#### `cuentas_por_cobrar`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| cliente_id | UUID | NO | FK clientes PROTECT |
| comprobante_id | UUID | YES | FK comprobantes |
| monto_original | NUMERIC(12,2) | NO | |
| monto_pendiente | NUMERIC(12,2) | NO | |
| fecha_emision | DATE | NO | |
| fecha_vencimiento | DATE | NO | |
| estado | enum_estado_cuenta | NO | 'pendiente' |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

**Indices:** `idx_cxc_cliente`, `idx_cxc_estado_vencimiento`

---

#### `cobros`
| Columna | Tipo | Null |
|---------|------|------|
| id | UUID | NO |
| cuenta_por_cobrar_id | UUID | NO | FK cuentas_por_cobrar PROTECT |
| monto | NUMERIC(12,2) | NO |
| fecha | DATE | NO |
| metodo_pago | VARCHAR(30) | NO |
| referencia | VARCHAR(100) | NO |
| notas | TEXT | NO |
| created_at | TIMESTAMPTZ | NO |
| updated_at | TIMESTAMPTZ | NO |
| creado_por_id | UUID | YES |

---

#### `cuentas_por_pagar`
| Columna | Tipo | Null | Default |
|---------|------|------|---------|
| id | UUID | NO | gen_random_uuid() |
| proveedor_id | UUID | NO | FK proveedores PROTECT |
| factura_proveedor_id | UUID | YES | FK facturas_proveedor |
| monto_original | NUMERIC(12,2) | NO | |
| monto_pendiente | NUMERIC(12,2) | NO | |
| fecha_emision | DATE | NO | |
| fecha_vencimiento | DATE | NO | |
| estado | enum_estado_cuenta | NO | 'pendiente' |
| created_at | TIMESTAMPTZ | NO | now() |
| updated_at | TIMESTAMPTZ | NO | now() |

---

### 3.8 Media y Archivos R2

#### `media_archivos`
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| r2_key | VARCHAR | NO | | UNIQUE — key en Cloudflare R2 |
| bucket_name | VARCHAR | NO | | j-soluciones-media|documentos|evidencias |
| entidad_tipo | enum_entidad_media | NO | | producto|configuracion|etc |
| entidad_id | UUID | NO | | UUID de la entidad |
| tipo_archivo | enum_tipo_archivo | NO | | imagen|documento|firma |
| nombre_original | VARCHAR | NO | | |
| mime_type | VARCHAR | NO | | |
| tamanio | INT | YES | | bytes |
| es_principal | BOOL | NO | false | |
| is_active | BOOL | NO | true | |
| subido_por_id | UUID | YES | | FK usuarios SET NULL |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Indices:** `idx_media_entidad`, `idx_media_bucket_entidad`, `idx_media_principal` (parcial WHERE es_principal=true)

---

### 3.9 Configuracion

#### `configuracion` (singleton)
| Columna | Tipo | Null | Default | Notas |
|---------|------|------|---------|-------|
| id | UUID | NO | gen_random_uuid() | |
| ruc | VARCHAR(11) | NO | | UNIQUE |
| razon_social | VARCHAR(200) | NO | | |
| nombre_comercial | VARCHAR(200) | NO | '' | |
| direccion | TEXT | NO | '' | |
| ubigeo | VARCHAR(6) | NO | '' | |
| departamento | VARCHAR(50) | NO | '' | |
| provincia | VARCHAR(50) | NO | '' | |
| distrito | VARCHAR(50) | NO | '' | |
| telefono | VARCHAR(20) | NO | '' | |
| email | VARCHAR(254) | NO | '' | |
| logo | VARCHAR(200) | YES | | URL o path legacy |
| logo_media_id | UUID | YES | | FK media_archivos |
| nubefact_token | TEXT | NO | '' | |
| nubefact_wsdl | VARCHAR(500) | NO | | |
| nubefact_url_password | TEXT | NO | | |
| cert_pfx_path | VARCHAR(500) | NO | | |
| cert_pfx_password | TEXT | NO | | |
| moneda_principal | enum_moneda | NO | 'PEN' | |
| igv_porcentaje | NUMERIC(5,2) | NO | 18.00 | |
| modo_contingencia | BOOL | NO | | |
| contingencia_activada_at | TIMESTAMPTZ | YES | | |
| singleton | BOOL | NO | true | UNIQUE — garantiza 1 sola fila |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

---

## 4. INDICES CLAVE (para queries de produccion)

### Por tabla de negocio principal

| Tabla | Indice | Columnas | Tipo |
|-------|--------|----------|------|
| productos | idx_productos_categoria_activo | (categoria_id, is_active) | Compuesto |
| stock | stock_producto_id_almacen_id_key | (producto_id, almacen_id) | UNIQUE |
| lotes | idx_lotes_vencimiento | (fecha_vencimiento) | Fecha |
| movimientos_stock | idx_mov_producto_fecha | (producto_id, created_at) | Compuesto |
| movimientos_stock | idx_mov_almacen_tipo | (almacen_id, tipo_movimiento) | Compuesto |
| movimientos_stock | idx_mov_referencia | (referencia_tipo, referencia_id) | Compuesto |
| ventas | — | — | Sin idx compuesto extra (pocas filas en floristeria) |
| detalle_ventas | idx_dv_venta_producto | (venta_id, producto_id) | Compuesto |
| comprobantes | idx_comprobantes_tipo_fecha | (tipo_comprobante, fecha_emision) | Compuesto |
| comprobantes | idx_comprobantes_cliente_fecha | (cliente_id, fecha_emision) | Compuesto |
| clientes | idx_clientes_doc_unico | (tipo_doc, numero_doc) WHERE is_active | UNIQUE PARCIAL |
| pedidos | idx_pedidos_estado_fecha | (estado, fecha) | Compuesto |
| cuentas_por_cobrar | idx_cxc_estado_vencimiento | (estado, fecha_vencimiento) | Compuesto |
| media_archivos | idx_media_principal | (entidad_tipo, entidad_id, es_principal) WHERE es_principal | PARCIAL |

---

## 5. RELACIONES CRITICAS (grafo simplificado)

```
usuarios (1) ──── (1) perfiles_usuario ──── (N) roles
                                        └── (N) permisos [via rol_permisos]

clientes (1) ──── (N) cotizaciones ──── (N) detalle_cotizaciones ──── productos
                └── (N) ordenes_venta ─── (N) ventas ────── (N) detalle_ventas
                                                         └── (1) comprobantes
                                                         └── (N) pedidos

proveedores (1) ── (N) ordenes_compra ── (N) recepciones ── (N) detalle_recepciones
                                                          └── lotes ── stock

productos (1) ─── (N) stock         [cantidad agregada por almacen]
           └──── (N) lotes          [trazabilidad por lote]
           └──── (N) movimientos_stock [historial inmutable]
```

---

## 6. TABLAS INMUTABLES (NUNCA borrar ni editar filas)

| Tabla | Razon |
|-------|-------|
| `comprobantes` | Datos fiscales SUNAT |
| `detalle_comprobantes` | Datos fiscales SUNAT |
| `notas_credito_debito` | Datos fiscales SUNAT |
| `log_envio_nubefact` | Auditoria de comunicacion SUNAT |
| `movimientos_stock` | Log inmutable de inventario |
| `log_actividad` | Auditoria de acciones de usuario |
| `ventas` (con comprobante aceptado) | Una vez emitido el comprobante |

Para "anular": cambiar `estado` a 'anulada'/'anulado' y crear documento inverso (nota de credito, movimiento de devolucion).

---

## 7. MIGRACIONES PENDIENTES FASE 1

Las siguientes columnas NO existen aun en la DB pero se agregaran en Fase 1:

```sql
-- Migración 1a
ALTER TABLE productos ADD COLUMN tipo_registro VARCHAR(20) NOT NULL DEFAULT 'producto_final';
-- Valores: insumo_organico | insumo_no_organico | producto_final

-- Migración 1b
ALTER TABLE productos ADD COLUMN descuenta_insumos BOOLEAN NOT NULL DEFAULT FALSE;

-- Migración 1c
ALTER TABLE productos ADD COLUMN unidad_compra VARCHAR(50) NOT NULL DEFAULT '';
ALTER TABLE productos ADD COLUMN factor_conversion INTEGER NOT NULL DEFAULT 1;

-- Migración 2
ALTER TABLE lotes ADD COLUMN fecha_entrada DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE lotes ADD COLUMN estado_frescura VARCHAR(20) NOT NULL DEFAULT 'optimo';
-- Valores: optimo | precaucion | funebre | descarte
```

---

*Extraido de PostgreSQL 16 — db1. Mar 2026. 74 tablas, 33 enums.*
*NO editar a mano — extraer de nuevo si hay cambios en la DB.*
