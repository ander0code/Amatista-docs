# DIAGNÓSTICO COMPLETO — Requerimientos Sr. Tito (Amatista)

> **Fecha:** 2026-03-02  
> **Contexto:** Análisis cruzado de lo solicitado por el Sr. Tito vs. lo que existe actualmente en `Amatista-be` y `Amatista-fe`.  
> **Regla:** No se alucina — cada punto se mapea a código real existente o se marca como **NO EXISTE**.

---

## 1. RESUMEN DE LO QUE PIDE EL SR. TITO

Del audio transcrito y las notas, se extraen **8 bloques funcionales**:

| #  | Bloque | Descripción resumida |
|----|--------|---------------------|
| B1 | **Control de Cámara (Stock Orgánico)** | Gestión de ítems perecibles (flores) con ciclo de vida de 5 días, alertas por color (verde/amarillo/rojo), sistema FIFO estricto (lo nuevo atrás, lo viejo adelante), estados: óptimo → fúnebre → descarte |
| B2 | **Ítems Orgánicos vs No Orgánicos** | Clasificar ítems como orgánicos (perecibles, con ciclo de vida) o no orgánicos (sin caducidad). Los orgánicos manejan fecha de entrada y días de vida restantes |
| B3 | **Producto = Receta/Composición de Ítems** | Un "producto" (arreglo floral) es un conjunto de ítems del stock. Al venderse, descuenta los ítems componentes. Soporte para personalización (cambiar composición) |
| B4 | **Alertas y Compras Inteligentes** | Alertas de stock bajo, ítems mermados, vista de más vendidos / menos vendidos (rotación), generación de pedidos de compra con stock mínimo, información para tomar decisiones de compra en el mayorista |
| B5 | **Cotizaciones Formales** | Formulario completo con datos del cliente, productos, condiciones comerciales, fechas emisión/validez, envío por correo. Para corporativos y personas naturales |
| B6 | **Precios Diferenciados (Corporativo / Natural / Personalizado)** | 3 niveles de precio: Persona Natural (precio estándar), Corporativo (precio reducido por empresa, desde 5 unidades), Personalizado (precio especial por composición custom). Descuentos por cantidad configurables |
| B7 | **Campañas / Temporadas** | Sección para gestionar descuentos temporales por campaña (Día de la Madre, San Valentín, etc.). Se aplica a productos seleccionados durante un rango de fechas |
| B8 | **Ventas Corporativas / Pre-venta** | Flujo: registrar empresa → enviar catálogo/cotización → cerrar venta corporativa. Alertas de cotización pendiente de aprobación. Check de gerencia |

---

## 2. DIAGNÓSTICO DETALLADO: QUÉ EXISTE vs. QUÉ FALTA

### B1 — Control de Cámara (Stock Orgánico con Ciclo de Vida)

**Lo que pide el Sr. Tito:**
- Cada ítem orgánico tiene una **fecha de entrada** a la cámara.
- Ciclo de vida estándar: **5 días hábiles**.
- Semáforo por colores:
  - 🟢 **Verde**: 2-3 días (óptimo)
  - 🟡 **Amarillo**: 4 días (precaución)
  - 🔴 **Rojo**: 5+ días (merma)
- Después de 5 días cambia de estado:
  - `optimo` → `funebre` (sirve para arreglos fúnebres, 2 días más de uso)  
  - `funebre` → `descarte` (se bota)  
- El sistema debe ordenar FIFO: **lo nuevo atrás, lo viejo adelante**.
- Alertas automáticas: "Esto ya pasó a merma", "Esto está faltando".

**Lo que EXISTE actualmente:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Lote` con `fecha_vencimiento` | ✅ Existe | `apps/inventario/models.py` |
| Lógica FIFO por `fecha_vencimiento` | ✅ Existe (en `registrar_salida`) | `apps/inventario/services.py` |
| `Producto.requiere_lote` (flag) | ✅ Existe | `apps/inventario/models.py` |
| Alertas de stock bajo (`productos_bajo_stock_minimo`) | ✅ Existe | `apps/inventario/services.py` |
| Task Celery `verificar_lotes_por_vencer` | ✅ Existe | `apps/inventario/tasks.py` |
| Serializer `FifoSugerenciaSerializer` | ✅ Existe | `apps/inventario/serializers.py` |
| Dashboard inventario con `lotes_por_vencer` | ✅ Existe | `apps/inventario/serializers.py` |

**Lo que NO EXISTE (hay que crear):**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Campo `es_perecible` / `tipo_item` (orgánico vs no orgánico) en Producto | ❌ No existe | Media |
| Campo `dias_vida_util` en Producto (default 5, editable) | ❌ No existe | Baja |
| **Estados de frescura** del lote: `optimo` → `funebre` → `descarte` | ❌ No existe (solo `is_active`) | Media |
| Semáforo automático por colores (calculado desde fecha_entrada + dias_vida) | ❌ No existe | Media |
| Task Celery para **actualizar estados de frescura** diariamente | ❌ No existe | Media |
| Vista de "estado de la cámara" con semáforo visual | ❌ No existe en FE | Alta |
| Alerta de ítems que pasaron a fúnebre/descarte | ❌ No existe | Media |
| Ordenamiento FIFO visual (lo viejo primero en la lista) | ⚠️ Parcial (FIFO en code, no en UI) | Baja |

---

### B2 — Ítems Orgánicos vs No Orgánicos

**Lo que pide el Sr. Tito:**
- Al registrar un ítem (insumo/materia prima), indicar si es **orgánico** (perecible) o **no orgánico** (duradero).
- Los orgánicos tienen ciclo de vida con semáforo.
- Los no orgánicos se almacenan sin caducidad.

**Lo que EXISTE:**

| Componente | Estado |
|-----------|--------|
| Modelo `Producto` genérico | ✅ Existe |
| Campo `requiere_lote` (booleano) | ✅ Existe |
| Modelo `Categoria` con jerarquía | ✅ Existe |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Concepto de **Item/Insumo** separado de **Producto Final** | ❌ No existe (hoy todo es `Producto`) | Alta |
| Campo `tipo_producto` con choices: `insumo_organico`, `insumo_no_organico`, `producto_final`, `personalizado` | ❌ No existe | Media |
| Que un `Producto` marque si es perecible y cuántos días de vida tiene | ❌ No existe | Baja |

---

### B3 — Producto = Receta/Composición de Ítems (BOM - Bill of Materials)

**Lo que pide el Sr. Tito:**
- Un **producto** (arreglo floral) está compuesto por varios **ítems** (rosas rojas x5, follaje x3, etc.).
- Al vender un producto, se **descuenta automáticamente** del stock cada ítem componente.
- Soporte para **personalización**: el cliente puede cambiar la composición (2 rosas rojas + 2 rosas rosadas en vez de 4 rojas).
- Un producto personalizado tiene **precio diferente** al estándar.

**Lo que EXISTE:**

| Componente | Estado |
|-----------|--------|
| Modelo `Producto` | ✅ Existe |
| Modelo `DetalleVenta` que vincula `Venta` → `Producto` | ✅ Existe |
| Descuento de stock al vender (en `services.py` de ventas) | ✅ Existe |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Modelo **`RecetaProducto`** (BOM: qué ítems componen un producto) | ❌ No existe | **Alta** |
| Modelo **`DetalleReceta`** (item_id, cantidad_requerida) | ❌ No existe | **Alta** |
| Lógica de **descuento de ítems componentes** al vender (en lugar de solo descontar el producto) | ❌ No existe | **Alta** |
| Concepto de **producto personalizado** (receta custom por venta) | ❌ No existe | Alta |
| Campo `tipo_venta_producto`: `stock` (catálogo), `personalizado`, `corporativo` | ❌ No existe (existe `tipo_venta` pero es `directa`/`online`/`campo`) | Media |
| Cálculo automático de costo del producto basado en sus ítems | ❌ No existe | Media |

---

### B4 — Alertas y Compras Inteligentes

**Lo que pide el Sr. Tito:**
- Al momento de ir a comprar al mayorista, ver **todo lo que falta**.
- Ver qué productos tienen **alta rotación** (se venden mucho) y cuáles están **estancados**.
- Alertas de: stock bajo + ítems mermados (pasaron 5 días) + falta de insumos.
- Generar pedido de compra con **stock mínimo**.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| `productos_bajo_stock_minimo()` | ✅ Existe | `apps/inventario/services.py` |
| Endpoint de alertas stock bajo | ✅ Existe | `apps/inventario/views.py` |
| Clasificación ABC (rotación) | ✅ Existe | `apps/inventario/views.py` (endpoint `rotacion_abc`) |
| `RotacionABCItemSerializer` | ✅ Existe | `apps/inventario/serializers.py` |
| Dashboard inventario con métricas | ✅ Existe | `apps/inventario/views.py` (endpoint `dashboard`) |
| Task Celery `verificar_lotes_por_vencer` | ✅ Existe | `apps/inventario/tasks.py` |
| Componente FE `RotacionABC.tsx` | ✅ Existe | FE inventario |
| Componente FE `DashboardInventario.tsx` | ✅ Existe | FE inventario |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| **Vista de "Lista de Compras"** (lo que falta para reponer) | ❌ No existe | Media |
| Alerta de ítems **mermados** (orgánicos que pasaron 5 días) | ❌ No existe | Media |
| **Generación automática de OC** desde alertas de stock bajo | ❌ No existe | Media |
| Vista para el **mayorista** (Yolanda hace pedido nocturno con info del sistema) | ❌ No existe | Media |
| Combinar alertas de stock bajo + merma + rotación en una sola vista de decisión de compra | ❌ No existe | Media |

---

### B5 — Cotizaciones Formales

**Lo que pide el Sr. Tito:**
- Formulario completo y formal de cotización.
- Incluye: datos cliente, productos, precios, condiciones comerciales, notas.
- Fecha de emisión y fecha de validez.
- Envío a correo del cliente.
- Que sea "bonito" y profesional.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Cotizacion` con todos los campos | ✅ Existe | `apps/ventas/models.py` |
| Modelo `DetalleCotizacion` | ✅ Existe | `apps/ventas/models.py` |
| `CotizacionCreateSerializer` con validación fecha_validez > fecha_emision | ✅ Existe | `apps/ventas/serializers.py` |
| `CotizacionListSerializer`, `CotizacionDetailSerializer` | ✅ Existe | `apps/ventas/serializers.py` |
| Campo `condiciones_comerciales` | ✅ Existe | `apps/ventas/models.py` |
| Campo `notas` | ✅ Existe | `apps/ventas/models.py` |
| CRUD de cotizaciones en BE | ✅ Existe | `apps/ventas/views.py` |
| Página FE de cotizaciones | ✅ Existe | `(ventas)/cotizaciones/` |
| CotizacionModal FE | ✅ Existe | `cotizaciones/components/CotizacionModal.tsx` |
| Cotización detalle FE | ✅ Existe | `(ventas)/cotizacion-detalle/` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| **Envío de cotización por correo** al cliente | ❌ No existe | Media |
| **PDF de cotización** profesional (con logo, diseño formal) | ❌ No existe | Media |
| Selección de tipo de precio (corporativo/natural) en la cotización | ❌ No existe | Media |
| Alerta/notificación cuando la cotización está pendiente de aprobación de gerencia | ❌ No existe (existe `COT_BORRADOR` → `COT_VIGENTE` pero sin notificación) | Baja |
| **Botón "Check" de gerencia** para aprobar cotización | ❌ No existe como flujo explícito | Baja |

---

### B6 — Precios Diferenciados (Corporativo / Natural / Personalizado)

**Lo que pide el Sr. Tito:**
- **Persona Natural**: Precio estándar (ej: rosa a S/7).
- **Corporativo**: Precio reducido (ej: rosa a S/3-4). Aplica a empresas (con RUC) que compran 5+ unidades.
- **Personalizado**: Precio calculado por la composición custom del arreglo.
- Descuento por cantidad configurable (si pasan de X unidades, Y% de descuento).
- El corporativo debe estar "seteado" — no se puede meter a cualquiera.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| `Producto.precio_venta` (un solo precio) | ✅ Existe | `apps/inventario/models.py` |
| `Producto.precio_compra` | ✅ Existe | `apps/inventario/models.py` |
| `DetalleCotizacion.descuento_porcentaje` | ✅ Existe | `apps/ventas/models.py` |
| `DetalleVenta.descuento_porcentaje` | ✅ Existe | `apps/ventas/models.py` |
| `Cliente.segmento` con choicess: `nuevo`, `frecuente`, `vip`, `credito`, **`corporativo`** | ✅ Existe | `apps/clientes/models.py` + `core/choices.py` |
| `Cliente.tipo_documento` (DNI vs RUC) | ✅ Existe | `apps/clientes/models.py` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Campo `precio_corporativo` en Producto | ❌ No existe (solo `precio_venta` único) | Media |
| Modelo **`ListaPrecios`** para manejar múltiples listas (Natural, Corporativo, etc.) | ❌ No existe | **Alta** |
| Modelo **`PrecioProducto`** (producto + lista_precios + precio) | ❌ No existe | **Alta** |
| Lógica de **descuento automático por cantidad** (>5 = X%, >10 = Y%) | ❌ No existe | Media |
| Modelo **`ReglaDescuento`** (cantidad_minima, porcentaje_descuento, aplica_a: segmento) | ❌ No existe | Media |
| Validación: solo clientes con segmento `corporativo` + RUC pueden acceder a precio corporativo | ❌ No existe | Baja |
| Cálculo automático del precio en cotización según segmento del cliente | ❌ No existe | Media |

---

### B7 — Campañas / Temporadas

**Lo que pide el Sr. Tito:**
- Sección de **campañas** (Día de la Madre, San Valentín, Aniversario, etc.).
- Descuento temporal que aplica a productos seleccionados.
- Rango de fechas de vigencia.
- Aplica a todos los productos que estén marcados en esa campaña.

**Lo que EXISTE:**

| Componente | Estado |
|-----------|--------|
| Sección WhatsApp/Campañas en FE | ⚠️ Existe pero es de **campañas de mensajería WhatsApp**, NO de descuentos comerciales |
| Nada en BE para campañas de descuento | ❌ No existe |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| Modelo **`Campana`** (nombre, fecha_inicio, fecha_fin, descuento_porcentaje, is_active) | ❌ No existe | Media |
| Modelo **`ProductoCampana`** (campana_id, producto_id) — relación M2M | ❌ No existe | Baja |
| Lógica de **aplicar descuento de campaña** automáticamente en POS y cotizaciones | ❌ No existe | Media |
| Vista FE de gestión de campañas (CRUD) | ❌ No existe | Media |
| Badge/indicador visual de "En campaña" en el producto | ❌ No existe | Baja |

---

### B8 — Ventas Corporativas / Pre-venta

**Lo que pide el Sr. Tito:**
- Registrar empresa como cliente corporativo (con RUC).
- Enviar catálogo + cotización a empresas cercanas (Miraflores, San Isidro).
- Flujo: Pre-venta → Cotización → Aprobación → Venta.
- Orientado a: fúnebres, cumpleaños ejecutivos, aniversarios empresa, Día de la Madre, Día del Secretario.
- Alertas de cotizaciones pendientes de respuesta.

**Lo que EXISTE:**

| Componente | Estado | Archivo |
|-----------|--------|---------|
| Modelo `Cliente` con `segmento = corporativo` | ✅ Existe | `apps/clientes/models.py` |
| Modelo `Cotizacion` → `OrdenVenta` → `Venta` (flujo completo) | ✅ Existe | `apps/ventas/models.py` |
| `cotizacion_origen` en OrdenVenta | ✅ Existe | `apps/ventas/models.py` |
| CRUD clientes con RUC/DNI | ✅ Existe | `apps/clientes/` |
| Página cliente-detalle con tabs de ventas y cotizaciones | ✅ Existe | FE `(users)/cliente-detalle/` |

**Lo que NO EXISTE:**

| Requerimiento | Estado | Complejidad |
|--------------|--------|-------------|
| **Catálogo de productos** exportable (PDF o enlace web) para enviar a empresas | ❌ No existe | Media |
| **Envío de cotización por email** directo desde el sistema | ❌ No existe | Media |
| Dashboard/CRM: lista de empresas prospecto con estado de seguimiento | ❌ No existe | Alta |
| Alertas de cotizaciones próximas a vencer / sin respuesta | ❌ No existe | Media |
| Historial de interacciones con empresa (llamada, email, visita) | ❌ No existe | Alta |

---

## 3. MAPA DE PRIORIDADES Y DEPENDENCIAS

```
PRIORIDAD 1 (FUNDACIONAL — sin esto no funciona nada más):
═══════════════════════════════════════════════════════════
  ┌─────────────────────────────────────────────┐
  │ B2: Tipo de Producto (orgánico/no orgánico) │ ← Campos nuevos en Producto
  │     + días de vida útil                      │
  └──────────────────┬──────────────────────────┘
                     │ depende de ↑
  ┌──────────────────▼──────────────────────────┐
  │ B1: Estados de Frescura + Semáforo          │ ← Nuevo campo estado_frescura en Lote
  │     + Task Celery diaria                     │    + Task de actualización
  └──────────────────┬──────────────────────────┘
                     │ depende de ↑
  ┌──────────────────▼──────────────────────────┐
  │ B3: Receta/BOM de Producto                  │ ← Nuevos modelos RecetaProducto +
  │     Composición de ítems                    │    DetalleReceta
  └──────────────────┬──────────────────────────┘
                     │ depende de ↑
  ┌──────────────────▼──────────────────────────┐
  │ B4: Alertas inteligentes + Vista de compras │ ← Combina B1 + B2 + stock actual
  └─────────────────────────────────────────────┘

PRIORIDAD 2 (COMERCIAL — para mejorar ventas):
═══════════════════════════════════════════════
  ┌─────────────────────────────────────────────┐
  │ B6: Precios diferenciados                   │ ← Modelo ListaPrecios + PrecioProducto
  │     (Corporativo / Natural / Personalizado) │
  └──────────────────┬──────────────────────────┘
                     │ depende de ↑
  ┌──────────────────▼──────────────────────────┐
  │ B5: Cotizaciones mejoradas                  │ ← PDF + email + selector de lista
  │     (con precios según segmento)            │    de precios
  └──────────────────┬──────────────────────────┘
                     │ depende de ↑
  ┌──────────────────▼──────────────────────────┐
  │ B8: Flujo corporativo completo              │ ← Combina B5 + B6 + catálogo
  └─────────────────────────────────────────────┘

PRIORIDAD 3 (MARKETING):
════════════════════════
  ┌─────────────────────────────────────────────┐
  │ B7: Campañas / Temporadas                   │ ← Independiente, pero se integra
  │     (Descuentos por fecha)                  │    con B6 en el POS
  └─────────────────────────────────────────────┘
```

---

## 4. INVENTARIO DE MODELOS NUEVOS NECESARIOS

### 4.1 Cambios en modelos EXISTENTES

```
apps/inventario/models.py — Producto:
  + tipo_producto:    CharField choices (insumo_organico, insumo_no_organico, producto_final)
  + es_perecible:     BooleanField (default=False, se setea automáticamente si tipo=insumo_organico)
  + dias_vida_util:   PositiveIntegerField (default=5, editable, solo aplica si es_perecible)
  + precio_corporativo: DecimalField (nullable, para precio simplificado sin ListaPrecios)

apps/inventario/models.py — Lote:
  + fecha_entrada:    DateField (cuándo entró a la cámara, auto=now si no se especifica)
  + estado_frescura:  CharField choices (optimo, precaucion, funebre, descarte) default=optimo
  + dias_restantes:   Property calculada (dias_vida_util - días_transcurridos)

core/choices.py:
  + TIPO_PRODUCTO_CHOICES
  + ESTADO_FRESCURA_CHOICES
  + TIPO_PRECIO_CHOICES (si se usa ListaPrecios)
```

### 4.2 Modelos NUEVOS a crear

```python
# ═══ RECETA / BOM (Bill of Materials) ═══

class RecetaProducto(Model):
    """Define la composición de ítems que forman un producto final."""
    producto = FK(Producto)           # El arreglo floral
    nombre = CharField                 # "Receta estándar" / "Versión premium"
    es_default = BooleanField          # La receta por defecto de este producto
    is_active = BooleanField
    created_at / updated_at

class DetalleReceta(Model):
    """Un ítem dentro de una receta."""
    receta = FK(RecetaProducto)
    insumo = FK(Producto)              # El ítem (rosa roja, follaje, etc.)
    cantidad_requerida = DecimalField
    es_sustituible = BooleanField      # Si se puede cambiar por otro

# ═══ LISTAS DE PRECIOS ═══

class ListaPrecios(Model):
    """Lista de precios por segmento."""
    nombre = CharField                 # "Precio Natural", "Precio Corporativo"
    segmento = CharField(choices)      # natural, corporativo
    es_default = BooleanField
    is_active = BooleanField

class PrecioProducto(Model):
    """Precio de un producto en una lista específica."""
    lista_precios = FK(ListaPrecios)
    producto = FK(Producto)
    precio = DecimalField
    unique_together = (lista_precios, producto)

# ═══ DESCUENTOS POR CANTIDAD ═══

class ReglaDescuento(Model):
    """Descuento automático por cantidad."""
    nombre = CharField
    cantidad_minima = IntegerField     # Desde 5 unidades
    descuento_porcentaje = DecimalField
    aplica_a_segmento = CharField      # null=todos, "corporativo", "natural"
    aplica_a_producto = FK(Producto, null=True)  # null=todos
    is_active = BooleanField

# ═══ CAMPAÑAS ═══

class Campana(Model):
    """Campaña de descuento temporal."""
    nombre = CharField                 # "Día de la Madre 2026"
    descripcion = TextField
    fecha_inicio = DateField
    fecha_fin = DateField
    descuento_porcentaje = DecimalField
    is_active = BooleanField
    productos = M2M(Producto)          # Qué productos participan
    created_at / updated_at

# ═══ PERSONALIZACIÓN DE VENTA ═══

class VentaPersonalizada(Model):
    """Cuando el cliente personaliza un arreglo en la venta."""
    detalle_venta = FK(DetalleVenta)   # El ítem de la venta
    es_personalizado = BooleanField
    recarga_personalizacion = DecimalField  # Costo adicional

class DetalleVentaInsumo(Model):
    """Los insumos reales consumidos por cada item vendido."""
    detalle_venta = FK(DetalleVenta)
    insumo = FK(Producto)              # Ítem (rosa, follaje, etc.)
    cantidad = DecimalField
```

---

## 5. IMPACTO EN FRONTEND

| Página FE | Estado actual | Cambios necesarios |
|-----------|---------------|-------------------|
| Producto Create/Edit | ✅ Funciona | Agregar: tipo_producto, es_perecible, dias_vida_util, composición/receta |
| Stock Overview | ✅ Funciona | Agregar: semáforo de frescura por lote, filtro orgánico/no orgánico |
| Dashboard Inventario | ✅ Funciona | Agregar: widget "Estado Cámara", ítems mermados, sugerencia de compras |
| Cotizaciones | ✅ Funciona | Agregar: selector de tipo precio, envío email, vista PDF |
| POS (Cart) | ✅ Funciona | Agregar: personalización de composición, precio según segmento, campañas activas |
| Clientes | ✅ Funciona | Agregar: badge corporativo, historial cotizaciones |
| **Campañas** | ❌ No existe | Crear: CRUD completo de campañas con selector de productos |
| **Vista Compras Inteligentes** | ❌ No existe | Crear: vista unificada de qué comprar (stock bajo + merma + rotación) |
| **Recetas/BOM** | ❌ No existe | Crear: editor de composición de productos |

---

## 6. IMPACTO EN TESTS

Los tests existentes (`tests/test_inventario_services.py`) cubren:
- ✅ `ajustar_stock` — 3 tests
- ✅ `transferir_stock` — 3 tests
- ✅ `seleccionar_lotes_fifo` — 3 tests
- ✅ `registrar_salida` — 4 tests
- ✅ `registrar_entrada` — 3 tests
- ✅ `productos_bajo_stock_minimo` — 2 tests

**Tests NUEVOS necesarios:**
- `test_frescura_services.py` — Estados de frescura, task diaria, semáforo
- `test_receta_services.py` — CRUD receta, descuento de ítems al vender
- `test_precios_services.py` — Precios por segmento, descuentos por cantidad
- `test_campana_services.py` — CRUD campañas, aplicación de descuento
- `test_cotizacion_corporativo.py` — Flujo completo cotización corporativa
- `test_personalizacion_venta.py` — Composición custom y cálculo de precio

---

## 7. RESUMEN EJECUTIVO

| Bloque | % Que ya existe | % Que falta | Esfuerzo estimado |
|--------|----------------|-------------|-------------------|
| B1 — Control Cámara | ~30% (FIFO + lotes existen) | ~70% (semáforo, estados, task) | **Medio** |
| B2 — Orgánico/No Orgánico | ~15% (Producto + Categoría) | ~85% (tipo producto, campos) | **Bajo-Medio** |
| B3 — Receta/BOM | ~5% (Producto existe) | ~95% (todo el sistema BOM) | **Alto** |
| B4 — Alertas + Compras | ~45% (alertas + rotación ABC) | ~55% (vista unificada, merma) | **Medio** |
| B5 — Cotizaciones | ~70% (CRUD completo) | ~30% (PDF, email, precio segmento) | **Medio** |
| B6 — Precios diferenciados | ~20% (segmento corporativo, descuento %) | ~80% (listas precio, reglas) | **Alto** |
| B7 — Campañas | ~0% | ~100% (todo nuevo) | **Medio** |
| B8 — Ventas Corporativas | ~40% (flujo cotización→venta) | ~60% (catálogo, email, CRM) | **Medio-Alto** |

### Orden de implementación recomendado:

1. **Fase 1 — Fundación** (B2 + B1): Tipo de producto + ciclo de vida + semáforo
2. **Fase 2 — BOM** (B3): Recetas de producto + descuento de ítems
3. **Fase 3 — Alertas** (B4): Vista unificada de compras inteligentes
4. **Fase 4 — Precios** (B6): Listas de precios + reglas de descuento
5. **Fase 5 — Cotizaciones** (B5 + B8): PDF + email + flujo corporativo
6. **Fase 6 — Campañas** (B7): CRUD + integración con POS

---

> **NOTA IMPORTANTE:** Este documento es un diagnóstico puro. No se ha implementado ni modificado ningún archivo. Cada fase debe comenzar con tests (TDD) siguiendo el patrón existente del proyecto (`tests/factories.py` → `tests/test_*_services.py` → implementación en `services.py` → serializers → views → FE).
