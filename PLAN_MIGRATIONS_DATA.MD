# MAPEO DE MIGRACIÓN
## DB Amatista (MySQL) → JSOLUCIONES ERP (PostgreSQL)
**Versión 1.0 | Fecha: 2026-02-26**

---

## 1. RESUMEN EJECUTIVO

La DB origen (Amatista / Laravel / MySQL) tiene **5 tablas con datos reales**:
`conductores`, `productos`, `reporte_entregas`, `item_reportes`, `users`.

La migración afecta **10 tablas destino** del ERP. El resto se crea vacío o con datos semilla.

### 1.1 Tablas involucradas

| Tabla Origen (Amatista) | Tabla(s) Destino (ERP) | Relación | Estado |
|---|---|---|---|
| `users` | `usuarios` + `perfiles_usuario` | 1 origen → 2 destino | ✅ Directa |
| `conductores` | `transportistas` | 1:1 | ✅ Directa |
| `productos` | `productos` + `stock` + `almacenes` | 1 origen → 3 destino | ⚠️ Requiere inferencia |
| `reporte_entregas` | `clientes` + `ventas` + `pedidos` | 1 origen → 3 destino | ⚠️ Requiere transformación |
| `item_reportes` | `detalle_ventas` | 1:1 (dump incompleto) | ⚠️ Solo 1 registro visible |
| `auditoria` / `cache` / `sessions` / `migrations` | — | No migrar | ❌ Omitir |

---

## 2. TABLA: `users` → `usuarios` + `perfiles_usuario`

La tabla `users` de Amatista es un modelo plano de Laravel. En el ERP se separa en dos:
- `usuarios`: credenciales y datos de autenticación Django
- `perfiles_usuario`: rol (FK), teléfono, configuraciones 2FA

> ⚠️ **PASO PREVIO**: Crear los roles en la tabla `roles` ANTES de migrar usuarios. Sin los roles la FK `perfiles_usuario.rol_id` no puede resolverse.

### 2.1 Mapeo campo a campo

| Campo Origen (`users`) | Tabla Destino | Campo Destino | Transformación / Nota |
|---|---|---|---|
| `id` (bigint) | `usuarios` | — (nuevo UUID) | Generar `gen_random_uuid()`. Guardar mapping `id_viejo → uuid` para resolver FKs. |
| `name` | `usuarios` | `first_name` + `last_name` | Dividir por primer espacio. Si no hay espacio: `first_name=name`, `last_name=''`. |
| `email` | `usuarios` | `email` | Directo. |
| `password` (bcrypt `$2y$`) | `usuarios` | `password` | Django usa prefijo `bcrypt$$`. Cambiar `$2y$` → `bcrypt$$` al importar. Verificar login post-migración. |
| `created_at` | `usuarios` | `date_joined` | Convertir a `TIMESTAMPTZ`. |
| — (no existe) | `usuarios` | `is_active` | Valor fijo: `TRUE`. |
| — (no existe) | `usuarios` | `is_superuser` | `TRUE` solo si `rol='admin'`. Resto: `FALSE`. |
| — (no existe) | `usuarios` | `is_staff` | `TRUE` solo si `rol='admin'`. Resto: `FALSE`. |
| `id` (ref.) | `perfiles_usuario` | `usuario_id` | FK al UUID recién generado. |
| `rol` | `perfiles_usuario` | `rol_id` | Lookup en tabla `roles` por `codigo`. Ver sección 2.2. |
| — (no existe) | `perfiles_usuario` | `telefono` | Valor: `''`. No existe en origen. |
| — (no existe) | `perfiles_usuario` | `totp_enabled` | Valor fijo: `FALSE`. |
| `password_changed_at` | `perfiles_usuario` | `password_changed_at` | Directo si no es NULL. |
| `updated_at` | `perfiles_usuario` | `updated_at` | Convertir a `TIMESTAMPTZ`. |

### 2.2 Roles a crear antes de migrar

| `codigo` (Amatista) | `nombre` sugerido (ERP) | Descripción |
|---|---|---|
| `admin` | Administrador | Acceso total al sistema. |
| `vendedor` | Vendedor | Gestión de pedidos y clientes. |
| `produccion` | Producción | Vista y gestión del estado de producción. |

---

## 3. TABLA: `conductores` → `transportistas`

Mapeo prácticamente directo. El campo `token` pasa de `VARCHAR(255)` a `UUID`. El campo `ubicacion` no tiene equivalente y se descarta.

| Campo Origen (`conductores`) | Campo Destino (`transportistas`) | Tipo Origen → Destino | Transformación / Nota |
|---|---|---|---|
| `id` (bigint) | — (nuevo UUID) | bigint → UUID | Generar UUID. Guardar mapping `id_viejo → uuid`. |
| `nombre` | `nombre` | Directo | Directo. |
| `telefono` | `telefono` | Directo | Directo. |
| `activo` (tinyint 0/1) | `is_active` (boolean) | tinyint → bool | `1→TRUE`, `0→FALSE`. |
| `last_lat` (decimal 10,8) | `last_lat` (decimal 10,7) | -1 decimal | Redondear a 7 decimales. Acepta NULL. |
| `last_lng` (decimal 11,8) | `last_lng` (decimal 10,7) | -1 decimal | Redondear a 7 decimales. Acepta NULL. |
| `last_location_at` | `last_location_at` | timestamp → TIMESTAMPTZ | Agregar zona horaria UTC. |
| `preferencia_distrito` | `preferencia_zona` | VARCHAR → VARCHAR | Solo renombrar el campo. |
| `token` (VARCHAR 255) | `token` (UUID) | VARCHAR → UUID | Si el string es UUID válido: cast directo. Si no: `gen_random_uuid()`. |
| `ubicacion` | — (no existe) | Sin equivalente | **DESCARTAR.** No hay campo destino equivalente. |
| `created_at` / `updated_at` | `created_at` / `updated_at` | Directo | Convertir a `TIMESTAMPTZ`. |
| — (no existe) | `tipo_vehiculo` | Campo nuevo | Valor por defecto: `''`. |
| — (no existe) | `placa` | Campo nuevo | Valor por defecto: `''`. |
| — (no existe) | `limite_pedidos_diario` | Campo nuevo | Valor por defecto: `20`. |
| — (no existe) | `tipo_transportista` | Campo nuevo | Valor por defecto: `'propio'`. |

---

## 4. TABLA: `productos` → `productos` + `stock` + `almacenes`

La tabla `productos` en Amatista es simple. Al migrar al ERP se expande en tres tablas relacionadas.

> ⚠️ **PASO PREVIO**: Crear un almacén principal antes de migrar productos.
> ```sql
> INSERT INTO almacenes (nombre, es_principal, is_active) VALUES ('Almacén Principal', TRUE, TRUE);
> ```
> Guardar el UUID generado para usarlo al crear registros en `stock`.

### 4.1 Mapeo a tabla `productos`

| Campo Origen | Campo Destino | Tipo | Transformación / Nota |
|---|---|---|---|
| `id` (bigint) | — (nuevo UUID) | bigint → UUID | Generar UUID. Guardar mapping `id_viejo → uuid`. |
| `nombre` | `nombre` | Directo | Directo. |
| `precio` | `precio_venta` (DECIMAL 12,4) | decimal 10,2 → 12,4 | Directo. El ERP usa 4 decimales. |
| — (no existe) | `precio_compra` | Campo nuevo | Valor por defecto: `0`. Actualizar manualmente después. |
| `stock` (int, nullable) | `stock_maximo` | int → decimal | Ver nota sobre stock NULL abajo. |
| — (no existe) | `stock_minimo` | Campo nuevo | Valor por defecto: `0`. |
| `activo` (tinyint) | `is_active` (boolean) | tinyint → bool | `1→TRUE`, `0→FALSE`. |
| `imagen` (varchar path) | — (no existe en productos) | Sin equivalente directo | Migrar a tabla `media_archivos`. Ver sección 4.3. |
| `created_at` | `created_at` | Directo | Convertir a `TIMESTAMPTZ`. |
| `updated_at` | `updated_at` | Directo | Convertir a `TIMESTAMPTZ`. |
| — (no existe) | `sku` (UNIQUE, requerido) | Campo nuevo | Generar: `'PROD-{id_original}'`. Ej: `'PROD-001'`. |
| — (no existe) | `unidad_medida` | ENUM | Valor por defecto: `'NIU'` (Unidad). |
| — (no existe) | `codigo_afectacion_igv` | ENUM | Valor por defecto: `'10'` (Gravado). |
| — (no existe) | `categoria_id` | FK nullable | `NULL`. Asignar categorías manualmente después. |

> ⚠️ **Stock NULL = ilimitado** en Amatista. El ERP no tiene concepto de ilimitado. **Decisión a tomar antes de migrar**: si `stock IS NULL` → no crear fila en `stock`, o poner `stock_maximo=0` como convención de ilimitado. Documentar la decisión elegida.

### 4.2 Registros a crear en tabla `stock`

Por cada producto migrado, crear una fila en `stock`:

| Campo (`stock`) | Valor |
|---|---|
| `producto_id` | UUID del producto recién migrado. |
| `almacen_id` | UUID del almacén principal (creado en paso previo). |
| `cantidad` | Si `productos.stock IS NOT NULL` → usar ese valor. Si `IS NULL` → `0` (o convención de ilimitado elegida). |

### 4.3 Imágenes → `media_archivos`

El campo `imagen` guarda un path relativo (ej: `'productos/archivo.jpg'`). En el ERP las imágenes van en `media_archivos` vinculadas a Cloudflare R2.

| Campo (`media_archivos`) | Valor a insertar |
|---|---|
| `entidad_tipo` | `'producto'` |
| `entidad_id` | UUID del producto migrado. |
| `tipo_archivo` | `'imagen'` |
| `nombre_original` | Nombre del archivo extraído del path de origen. |
| `r2_key` | Subir imagen a R2 primero. Usar la key retornada. |
| `url_publica` | URL pública de R2 después de subir. |
| `mime_type` | Detectar por extensión: `.jpg→'image/jpeg'`, `.webp→'image/webp'`. |
| `tamano_bytes` | Obtener del archivo físico al subirlo a R2. |
| `es_principal` | `TRUE` (es la única imagen del producto). |

---

## 5. TABLA: `reporte_entregas` → `clientes` + `ventas` + `pedidos`

Esta es la tabla más compleja. Cada fila representa simultáneamente:
- Un **cliente** (quien compró)
- Una **venta** implícita (el monto cobrado)
- Un **pedido** (la entrega con destinatario y conductor)

> ❌ **ORDEN CRÍTICO DE MIGRACIÓN**:
> 1. Crear `clientes`
> 2. Crear `ventas` (necesitan `cliente_id`)
> 3. Crear `pedidos` (necesitan `venta_id` y `cliente_id`)
>
> Si se hace en otro orden las FKs fallan.

### 5.1 Extracción de clientes

Amatista no tiene tabla de clientes. El nombre y teléfono del cliente están en `reporte_entregas.nombre_cliente` y `telefono_cliente`. **Hay que deduplicar por teléfono** antes de insertar en `clientes`.

| Campo Origen (`reporte_entregas`) | Campo Destino (`clientes`) | Transformación / Nota |
|---|---|---|
| — (nuevo) | `id` (UUID) | `gen_random_uuid()` por cada cliente único. |
| `nombre_cliente` | `razon_social` | Directo. En personas naturales se usa como nombre completo. |
| — (no existe) | `nombre_comercial` | Igual que `razon_social` o `''`. |
| `telefono_cliente` | `telefono` | Directo. Normalizar: quitar espacios y prefijo `+51`. |
| — (no existe) | `tipo_documento` | Valor: `'0'` (Sin documento / consumidor final). |
| — (no existe) | `numero_documento` | Valor: `'00000000'` o generar uno temporal único por cliente. |
| — (no existe) | `segmento` | Valor: `'nuevo'`. Ajustar manualmente después. |
| — (no existe) | `email` | Valor: `''`. No existe en origen. |
| — (no existe) | `direccion` | Usar `direccion_destinatario` si cliente = destinatario, sino `''`. |
| `created_at` (primer pedido del cliente) | `created_at` | Usar el `created_at` del primer pedido de ese cliente. |

> ℹ️ **DEDUPLICACIÓN**: Agrupar `reporte_entregas` por `telefono_cliente`. Un cliente puede tener múltiples pedidos. Crear solo **1 registro** en `clientes` por teléfono único.

### 5.2 Creación de ventas (implícita)

Cada `reporte_entrega` implica una venta. El ERP requiere que exista una venta antes de un pedido.

| Campo Origen (`reporte_entregas`) | Campo Destino (`ventas`) | Transformación / Nota |
|---|---|---|
| — | `id` | `gen_random_uuid()`. |
| `id` (como base) | `numero` | Formato: `'MIGR-{id_original}'`. Ej: `'MIGR-003'`. |
| `fecha_compra` | `fecha` | Directo (tipo DATE). |
| `created_by` (user id bigint) | `vendedor_id` | Lookup: mapping `user_id → uuid perfil_usuario` (paso 2). |
| `nombre_cliente` (→ FK) | `cliente_id` | UUID del cliente creado en paso 5.1. Acepta NULL ([UPD-10]). |
| `metodo_pago` | `metodo_pago` | Ver tabla de conversión 5.2a. |
| suma de items + `costo_delivery` | `total_venta` | Sumar `item_reportes.precio_unitario * cantidad` + `costo_delivery`. |
| — (no existe) | `tipo_venta` | Valor: `'online'` (viene de web/WhatsApp). |
| `estado` | `estado` | `'entregado'→'completada'`. Resto → `'completada'` también (ERP solo tiene `completada`/`anulada`). |

#### 5.2a Conversión método de pago

| Valor Origen (Amatista) | Valor Destino (`enum_metodo_pago`) | Nota |
|---|---|---|
| `efectivo` | `efectivo` | Directo. |
| `yape` | `yape_plin` | Renombrar. |
| `plin` | `yape_plin` | Renombrar. |
| `izipay` | `tarjeta` | Izipay es POS → tarjeta. |
| `bcp` | `transferencia` | Transferencia bancaria. |
| `interbank` | `transferencia` | Transferencia bancaria. |
| `payum` | `transferencia` | Pasarela de pago → transferencia. |

### 5.3 Mapeo a tabla `pedidos`

| Campo Origen (`reporte_entregas`) | Campo Destino (`pedidos`) | Transformación / Nota |
|---|---|---|
| `id` | — (nuevo UUID) | `gen_random_uuid()`. Guardar mapping. |
| `id` (como base) | `numero` | Formato: `'PED-{id_original}'`. Ej: `'PED-003'`. |
| — (generar) | `codigo_seguimiento` | Generar string aleatorio de 8 chars. Campo UNIQUE. |
| `fecha_compra` | `fecha` | Usar `fecha_compra` como fecha del pedido. |
| venta del paso 5.2 | `venta_id` | UUID de la venta creada para este pedido. |
| cliente del paso 5.1 | `cliente_id` | UUID del cliente. |
| `nombre_destinatario` | `nombre_destinatario` | Directo. |
| `telefono_destinatario` | `telefono_destinatario` | Directo. Normalizar espacios. |
| `direccion_destinatario` | `direccion_entrega` | Directo (TEXT). |
| `enlace_ubicacion` | `enlace_ubicacion` | Directo. NULL si vacío. |
| `distrito` | — (no existe en pedidos) | ⚠️ Sin equivalente. Ver sección 7. |
| `tipo_ubicacion` | — (no existe) | ⚠️ Sin equivalente. Ver sección 7. |
| `turno_entrega` | `turno_entrega` | Directo: `'manana'` \| `'tarde'`. |
| `fecha_entrega` | `fecha_estimada_entrega` | Convertir DATE a TIMESTAMPTZ (hora `00:00:00 UTC`). |
| `observacion` | `notas` | Directo (TEXT). |
| `dedicatoria` | `dedicatoria` | Directo (TEXT). |
| `costo_delivery` | `costo_delivery` | Directo DECIMAL(10,2). |
| `es_urgente` (tinyint 0/1) | `es_urgente` (boolean) | `1→TRUE`, `0→FALSE`. |
| `estado` | `estado` | Ver tabla 5.3a. |
| `estado_produccion` | `estado_produccion` | Ver tabla 5.3b. |
| `produccion_iniciada_en` | `produccion_iniciada_en` | Directo TIMESTAMPTZ. NULL si vacío. |
| `produccion_completada_en` | `produccion_completada_en` | Directo TIMESTAMPTZ. |
| `fecha_confirmacion` | `fecha_confirmacion` | Directo TIMESTAMPTZ. |
| `observacion_conductor` | `observacion_conductor` | Directo (TEXT). |
| `foto_entrega` | `foto_entrega` | Directo path VARCHAR. Migrar imagen a R2 luego. |
| `conductor_id` (bigint) | `transportista_id` (UUID) | Lookup: mapping `conductor_id → uuid transportista` (paso 3). |
| `created_by` (user bigint) | `creado_por_id` (UUID) | Lookup: mapping `user_id → uuid perfil_usuario` (paso 2). |
| `created_at` / `updated_at` | `created_at` / `updated_at` | Convertir a TIMESTAMPTZ. |

#### 5.3a Conversión de estado del pedido

| Valor Origen (`estado`) | Valor Destino (`pedidos.estado`) | Nota |
|---|---|---|
| `pendiente` | `PENDIENTE` | Directo. |
| `en_ruta` | `EN_RUTA` | Directo. |
| `entregado` | `ENTREGADO` | Directo. |
| `no_entregado` | `CANCELADO` | No hay equivalente exacto. Usar `CANCELADO` y guardar nota. |
| `reprogramado` | `PENDIENTE` | No existe en ERP. Usar `PENDIENTE` y registrar en `notas`. |

#### 5.3b Conversión de estado_produccion

| Valor Origen | Valor Destino (`pedidos.estado_produccion`) | Nota |
|---|---|---|
| `pendiente` | `pendiente` | Directo. |
| `listo` | `completado` | Renombrar. |

---

## 6. TABLA: `item_reportes` → `detalle_ventas`

Esta tabla vincula productos con pedidos/ventas.

> ❌ **DUMP INCOMPLETO**: El archivo SQL solo contiene **1 de los 190 registros** de `item_reportes` (el auto_increment llega a 191). Solicitar el dump completo de esta tabla antes de migrar. Sin estos datos no se puede reconstruir qué productos se vendieron en cada pedido.

| Campo Origen (`item_reportes`) | Campo Destino (`detalle_ventas`) | Transformación / Nota |
|---|---|---|
| `id` | — (nuevo UUID) | `gen_random_uuid()`. |
| `reporte_id` | `venta_id` | Lookup: `reporte_id → uuid venta` creada en paso 5.2. |
| `producto_id` | `producto_id` | Lookup: `producto_id (bigint) → uuid producto` (paso 4). |
| `cantidad` | `cantidad` | Directo (int → DECIMAL 12,2). |
| `precio_unitario` | `precio_unitario` | Directo (decimal 10,2 → decimal 12,4). |
| — (calcular) | `subtotal` | `cantidad * precio_unitario`. |
| — (calcular) | `igv` | Si precio incluye IGV: `igv = total - total/1.18`. Si no incluye: `igv = subtotal * 0.18`. |
| — (calcular) | `total` | `subtotal + igv`. |
| `created_at` | `created_at` | Directo TIMESTAMPTZ. |

---

## 7. CAMPOS SIN EQUIVALENTE DIRECTO

Campos del origen que no tienen un campo exacto en el destino.

| Campo Origen | Tabla Origen | Acción Recomendada |
|---|---|---|
| `ubicacion` | `conductores` | **DESCARTAR.** Era texto libre de zona base. No tiene equivalente en `transportistas`. |
| `distrito` | `reporte_entregas` | ⚠️ **Sin campo en `pedidos`**. Opciones: (A) concatenar al inicio de `notas` como `'Distrito: san_isidro \| '`, (B) concatenar a `direccion_entrega`, (C) agregar columna custom. **Decidir antes de migrar.** |
| `tipo_ubicacion` | `reporte_entregas` | ⚠️ Incluir en `notas` como `'Tipo: casa'`. No hay campo en `pedidos`. |
| `estado_anterior` | `reporte_entregas` | Incluir en `notas` o descartar. Dato histórico de estado previo al actual. |
| `nombre_conductor` / `telefono_conductor` (texto) | `reporte_entregas` | **IGNORAR.** Son campos desnormalizados de auditoría. El ERP usa FK `transportista_id`. Ya se resuelve en paso 5.3. |
| `imagen` | `productos` | Migrar a `media_archivos`. Ver sección 4.3. |

---

## 8. TABLAS A CREAR EN BLANCO (sin datos de origen)

Estas tablas del ERP deben existir pero no tienen datos a migrar desde Amatista.

| Tabla ERP | Acción |
|---|---|
| `roles` | Crear 3 roles mínimos: `admin`, `vendedor`, `produccion` (ANTES de migrar usuarios). |
| `permisos` + `rol_permisos` | Crear permisos y asignaciones según configuración del sistema. |
| `almacenes` | Crear al menos 1 almacén principal (ANTES de migrar productos y stock). |
| `categorias` | Crear categorías de productos (flores, chocolates, globos, etc.) manualmente. |
| `configuracion` | Insertar 1 fila con datos de la empresa (RUC, razón social, token Nubefact, etc.). |
| `series_comprobante` | Configurar series `F001` (factura) y `B001` (boleta) según SUNAT. |
| `whatsapp_configuracion` | Insertar fila singleton con credenciales de Meta Business API. |
| `whatsapp_automatizaciones` | Insertar 5 filas fijas (`venta_confirmada`, `pedido_despachado`, etc.) vía migration. |
| `configuracion_kpi` | Insertar 1 fila singleton con umbrales por defecto. |

---

## 9. ORDEN DE EJECUCIÓN DE LA MIGRACIÓN

El orden es crítico por las dependencias de FK. Ejecutar estrictamente en este orden:

| # | Paso | Tabla(s) afectada(s) | Dependencias previas |
|---|---|---|---|
| 1 | Crear roles | `roles` | Ninguna. |
| 2 | Crear permisos y rol_permisos | `permisos`, `rol_permisos` | Paso 1. |
| 3 | Migrar `users` → `usuarios` | `usuarios` | Ninguna. |
| 4 | Migrar `users` → `perfiles_usuario` | `perfiles_usuario` | Pasos 1 y 3. |
| 5 | Migrar `conductores` → `transportistas` | `transportistas` | Ninguna. |
| 6 | Crear almacén principal | `almacenes` | Ninguna. |
| 7 | Migrar `productos` → `productos` | `productos` | Paso 4 (`creado_por_id`). |
| 8 | Crear registros de stock | `stock` | Pasos 6 y 7. |
| 9 | Migrar imágenes de productos a R2 | `media_archivos` | Paso 7. Necesita acceso a archivos físicos. |
| 10 | Extraer clientes únicos → `clientes` | `clientes` | Paso 4 (`creado_por_id`). |
| 11 | Crear ventas desde `reporte_entregas` | `ventas` | Pasos 4 y 10. |
| 12 | Crear pedidos desde `reporte_entregas` | `pedidos` | Pasos 4, 5, 10, 11. |
| 13 | Migrar `item_reportes` → `detalle_ventas` | `detalle_ventas` | Pasos 7 y 11. **Requiere dump completo.** |
| 14 | Configurar empresa, SUNAT, WhatsApp | `configuracion`, `series_comprobante`, `whatsapp_configuracion` | Datos del negocio (manual). |

---

## 10. NOTAS FINALES Y ADVERTENCIAS

> ⚠️ **CONTRASEÑAS**: Django usa el formato `bcrypt$$<hash>`. Laravel bcrypt genera `$2y$...`. Al importar cambiar el prefijo o usar el hasher compatible de Django. Verificar que los usuarios puedan loguearse después de la migración.

> ❌ **MAPPINGS DE IDs**: Es obligatorio mantener una tabla temporal de mapeo `{id_viejo_int → uuid_nuevo}` para cada entidad durante toda la migración. Sin esto no se pueden resolver las FKs cruzadas.

> ❌ **`item_reportes` INCOMPLETO**: Solo hay 1 registro en el dump. Los 190 registros restantes son necesarios para reconstruir el detalle de ventas. Solicitar el dump completo al equipo de Amatista antes de iniciar la migración.

> ⚠️ **DISTRITO sin campo destino**: Decidir la estrategia (sección 7) antes de escribir el script de migración. Una vez ejecutado es difícil corregir.

> ✅ **TESTING POST-MIGRACIÓN**: Verificar que:
> - 100 pedidos migrados coincidan en la nueva DB.
> - 35 productos existan en el catálogo.
> - 11 transportistas estén activos.
> - 5 usuarios puedan loguearse.

> ℹ️ **ENUM CONVERSIONES**: Si aparece un valor no mapeado en las tablas de conversión, el script debe **loguear el caso y usar un valor por defecto** en lugar de fallar con error.

---

*Documento generado: 2026-02-26 · Migración Amatista v1.0 → JSOLUCIONES ERP v4*