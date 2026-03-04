# AMATISTA ERP — BASE DE DATOS

> Reglas, convenciones y enums de la base de datos.
> Ver `DB_SCHEMA_COMPLETO.md` en la raiz del repo para el schema completo extraido de PostgreSQL.
> Aplica unicamente a Amatista-be/.

---

## 1. Mixins Obligatorios (core/mixins.py)

Todo modelo hereda de uno o mas de estos:

```python
class TimestampMixin(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class SoftDeleteMixin(models.Model):
    is_active = models.BooleanField(default=True)

class AuditMixin(models.Model):
    creado_por = models.ForeignKey('usuarios.PerfilUsuario', SET_NULL, null=True, related_name='+')
    actualizado_por = models.ForeignKey('usuarios.PerfilUsuario', SET_NULL, null=True, related_name='+')
```

- Modelos de negocio: heredan TimestampMixin + SoftDeleteMixin + AuditMixin
- Modelos inmutables (movimientos_stock, log_actividad, detalle_venta_insumo): solo TimestampMixin

---

## 2. Reglas de Base de Datos

```
DB-01: NUNCA modificar tablas/columnas existentes sin autorizacion del usuario.
DB-02: NUNCA eliminar migraciones. Solo crear nuevas.
DB-03: Toda tabla tiene: id (UUID PK), created_at, updated_at.
       Excepciones: tablas inmutables de log (sin updated_at).
DB-04: Soft delete (is_active=False). NUNCA DELETE en registros contables/fiscales.
DB-05: Toda FK tiene on_delete explicito:
       - PROTECT para entidades referenciadas (cliente, producto, proveedor)
       - CASCADE solo para detalles que NO tienen sentido sin cabecera
       - SET_NULL para campos opcionales (creado_por, lote en detalles)
DB-06: Indices compuestos en tablas de alto volumen.
DB-07: unique_together o UniqueConstraint donde la logica lo requiere.
DB-08: NUNCA raw SQL sin justificacion documentada en el codigo.
DB-09: Campos monetarios: DecimalField(max_digits=12, decimal_places=2).
       Precio unitario: DecimalField(max_digits=12, decimal_places=4).
       Porcentajes: DecimalField(max_digits=5, decimal_places=2).
       NUNCA FloatField para dinero.
DB-10: Las migraciones se versionan en Git.
```

---

## 3. Tablas que NUNCA se Borran

Solo soft delete o cambio de estado. NUNCA `DELETE`:

| Tabla | Razon |
|-------|-------|
| comprobantes, notas_credito_debito | Datos fiscales SUNAT |
| log_envio_nubefact | Log inmutable de intentos |
| ventas (con comprobante aceptado) | Una vez emitido el comprobante |
| movimientos_stock | Log inmutable de inventario |
| detalle_venta_insumo | Trazabilidad de produccion (inmutable) |
| log_actividad | Auditoria de seguridad |

---

## 4. Protocolo para Cambios en DB

```
1. Describir el cambio al usuario (campo, tipo, motivo, impacto en otras tablas)
2. Esperar aprobacion EXPLICITA
3. Crear migracion (makemigrations)
4. Mostrar el archivo de migracion generado al usuario
5. NUNCA aplicar migrate automaticamente en produccion sin backup
```

---

## 5. Enums y Choices Centralizados (core/choices.py)

Todos los choices estan en `core/choices.py`. NUNCA redefinir localmente.

### Tipo de Registro (especifico de Amatista — Fase 1)

```python
TIPO_REG_INSUMO_ORGANICO    = "insumo_organico"      # Rosa, girasol, follaje — perecible
TIPO_REG_INSUMO_NO_ORGANICO = "insumo_no_organico"   # Cinta, base, adorno — no perecible
TIPO_REG_PRODUCTO_FINAL     = "producto_final"        # Arreglo floral para venta
```

> NOTA: Campo `tipo_registro` en tabla `productos` — pendiente de migracion (Fase 1).

### Estado de Frescura (especifico de Amatista — Fase 1)

```python
FRESCURA_OPTIMO     = "optimo"      # Dias 1-3 — verde
FRESCURA_PRECAUCION = "precaucion"  # Dia 4 — amarillo
FRESCURA_FUNEBRE    = "funebre"     # Dias 5-7 — rojo (solo arreglos funebres)
FRESCURA_DESCARTE   = "descarte"    # Dia 8+ — negro (botar)
```

> NOTA: Campo `estado_frescura` en tabla `lotes` — pendiente de migracion (Fase 1).
> Los umbrales son FIJOS (no configurables). Se basan en `fecha_entrada` del lote.

### Roles de Usuario

```python
ROL_ADMIN = 'admin'
ROL_GERENTE = 'gerente'
ROL_SUPERVISOR = 'supervisor'
ROL_VENDEDOR = 'vendedor'
ROL_CAJERO = 'cajero'
ROL_ALMACENERO = 'almacenero'
ROL_CONTADOR = 'contador'
ROL_REPARTIDOR = 'repartidor'
```

### Estados de Cotizacion

```python
COTIZACION_BORRADOR = 'borrador'
COTIZACION_VIGENTE = 'vigente'
COTIZACION_ACEPTADA = 'aceptada'
COTIZACION_VENCIDA = 'vencida'
COTIZACION_RECHAZADA = 'rechazada'
```

### Estados de Venta

```python
VENTA_COMPLETADA = 'completada'
VENTA_ANULADA = 'anulada'
```

### Tipos de Venta

```python
TIPO_VENTA_DIRECTA = 'directa'
TIPO_VENTA_ONLINE  = 'online'   # Reservado para e-commerce futuro
TIPO_VENTA_CAMPO   = 'campo'    # Venta desde campo (vendedor movil)
```

### Estados de Comprobante SUNAT

```python
ESTADO_COMP_PENDIENTE = 'pendiente'
ESTADO_COMP_ACEPTADO = 'aceptado'
ESTADO_COMP_RECHAZADO = 'rechazado'
ESTADO_COMP_OBSERVADO = 'observado'
ESTADO_COMP_ANULADO = 'anulado'
ESTADO_COMP_ERROR = 'error'
ESTADO_COMP_PENDIENTE_REENVIO = 'pendiente_reenvio'
ESTADO_COMP_ERROR_PERMANENTE = 'error_permanente'
```

### Tipos de Comprobante

```python
TIPO_FACTURA = '01'
TIPO_BOLETA = '03'
TIPO_NOTA_CREDITO = '07'
TIPO_NOTA_DEBITO = '08'
```

### Estados de Pedido (Distribucion)

```python
PEDIDO_PENDIENTE = 'pendiente'
PEDIDO_CONFIRMADO = 'confirmado'
PEDIDO_DESPACHADO = 'despachado'
PEDIDO_EN_RUTA = 'en_ruta'
PEDIDO_ENTREGADO = 'entregado'
PEDIDO_CANCELADO = 'cancelado'
PEDIDO_DEVUELTO = 'devuelto'
PEDIDO_REPROGRAMADO = 'reprogramado'
PEDIDO_NO_ENTREGADO = 'no_entregado'
```

### Estado de Produccion (Kanban por item)

```python
PRODUCCION_PENDIENTE    = 'pendiente'
PRODUCCION_EN_PROCESO   = 'en_produccion'
PRODUCCION_LISTO        = 'listo'
PRODUCCION_ENTREGADO    = 'entregado'
```

Aplica a `DetalleVenta.estado_produccion` (item del arreglo) y `Pedido.estado_produccion` (el pedido completo).

### Tipos de Movimiento de Stock

```python
MOV_ENTRADA = 'entrada'
MOV_SALIDA = 'salida'
MOV_TRANSFERENCIA = 'transferencia'
MOV_AJUSTE = 'ajuste'
MOV_DEVOLUCION = 'devolucion'
```

### Metodos de Pago

```python
PAGO_EFECTIVO = 'efectivo'
PAGO_TARJETA = 'tarjeta'
PAGO_TRANSFERENCIA = 'transferencia'
PAGO_YAPE_PLIN = 'yape_plin'
PAGO_CREDITO = 'credito'
```

### Segmentos de Cliente

```python
SEG_NUEVO = 'nuevo'
SEG_FRECUENTE = 'frecuente'
SEG_VIP = 'vip'
SEG_CREDITO = 'credito'
SEG_CORPORATIVO = 'corporativo'
```

---

## 6. Estructura de las Apps en DB

| App | Tablas principales | Notas especiales Amatista |
|-----|-------------------|--------------------------|
| empresa | configuracion | Singleton (1 sola fila) |
| usuarios | usuario, roles, permisos, perfiles_usuario, log_actividad | |
| clientes | clientes | unique_together (tipo_doc, numero_doc) WHERE is_active |
| proveedores | proveedores | RUC unico |
| inventario | productos, categorias, almacenes, stock, lotes, movimientos_stock, ubicaciones_almacen, receta_producto, detalle_receta, series, regla_descuento, transferencias, detalle_transferencia | stock tiene UNIQUE(producto, almacen) |
| ventas | cotizaciones, ordenes_venta, ventas, detalle_ventas, formas_pago, ajuste_personalizacion, detalle_venta_insumo, campanas, campana_producto, comisiones_vendedor | detalle_venta tiene `estado_produccion`, `notas_arreglista`, `recargo_personalizacion` |
| facturacion | comprobantes, notas_credito_debito, series_comprobante | UNIQUE(tipo, serie, numero) |
| media | media_archivos | Relacion polimorfica (entidad_tipo + entidad_id) |
| compras | ordenes_compra, detalle_ordenes_compra, recepciones, detalle_recepciones, facturas_proveedor | |
| finanzas | cuentas_por_cobrar, cobros, cuentas_por_pagar | |
| distribucion | transportistas, pedidos, seguimiento_pedidos | pedido tiene `estado_produccion` |
| whatsapp | configuracion_wa (singleton), plantilla, mensaje, log_wa | |

---

## 7. Migraciones Aplicadas (Fases 1-6)

> Todas las fases planificadas originalmente YA tienen sus migraciones creadas en el codigo.
> Verificar en la DB de produccion si fueron aplicadas.

### Inventario (9 migraciones)
```
0001_initial.py
0002_solicitudtransferencia_detallesolicitudtransferencia_and_more.py
0003_alter_movimientostock_referencia_tipo.py
0004_add_serie_modelo.py
0005_alter_serie_options_and_more.py
0006_fase1_tipo_registro_frescura.py       ← Fase 1: tipo_registro, descuenta_insumos, fecha_entrada, estado_frescura
0007_fase2_receta_producto.py              ← Fase 2: receta_producto, detalle_receta
0008_fase4_precio_corporativo_regla_descuento.py  ← Fase 4: precio_corporativo, regla_descuento
0009_alter_regladescuento_id.py
```

### Ventas (14 migraciones)
```
0001_initial.py
0002_caja_formapago.py
0003_add_comision_vendedor.py
0004_venta_cliente_nullable.py
0005_detalle_venta_estado_produccion.py     ← estado_produccion en DetalleVenta
0006_remove_venta_caja.py
0007_delete_caja.py
0008_alter_formapago_metodo_pago_alter_venta_metodo_pago.py
0009_add_mixto_metodo_pago.py
0010_create_numero_sequences.py
0011_fase2_ajuste_personalizacion_dvi.py    ← Fase 2: ajuste_personalizacion, detalle_venta_insumo, notas_arreglista, recargo_personalizacion
0012_fase5_cotizacion_aprobacion.py         ← Fase 5: aprobada_por, aprobada_en en cotizaciones
0013_fase6_campana.py                       ← Fase 6: campana, campana_producto
0014_alter_campana_id_alter_campanaproducto_id_and_more.py
```

## 8. Migraciones Pendientes (E-commerce)

> Estos campos NO existen en el codigo. Se necesitan para el e-commerce.

```python
# Agregar a apps/inventario/models.py — Producto
slug              = models.SlugField(unique=True, blank=True)       # URL amigable para e-commerce
descripcion_larga = models.TextField(blank=True, default="")        # Descripcion completa para web
destacado         = models.BooleanField(default=False)              # Mostrar en portada
orden_display     = models.PositiveIntegerField(default=0)          # Orden en catalogo web
```

---

## 9. Referencia Schema SQL

El archivo `DB_SCHEMA_COMPLETO.md` en la raiz de este repo contiene el schema completo:
- Todas las tablas con sus columnas y tipos exactos
- Enums definidos a nivel de DB (33 enums)
- Indices y constraints
- Relaciones FK

SIEMPRE verificar en ese archivo antes de "inventar" campos. Si no esta ahi, no existe en la DB.
