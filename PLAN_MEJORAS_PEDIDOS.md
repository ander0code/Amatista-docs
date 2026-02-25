# Plan: Mejora de Vista de Pedidos en Distribución

> Este documento detalla los cambios necesarios para mejorar la vista de pedidos en `/distribucion/pedidos` incluyendo:
> 1. Mostrar tipo de envío (delivery/recogo en tienda)
> 2. Mostrar conductor externo (apps como InDrive, Yango, Uber)
> 3. Mostrar pedidos sin conductor asignado de forma destacados
> 4. Agregar filtros útiles

---

## Estado Actual

### Backend (Amatista-be)
**Modelo Pedido** (`apps/distribucion/models.py`):
- `turno_entrega`: manana, tarde, express ✅ (ya agregado)
- `turno_express_rango`: para express ✅ (ya agregado)
- `transportista`: FK a Transportista (puede ser null)
- **FALTA**: Campo para "tipo de envío" o "conductor externo"

### Frontend (Amatista-fe)
**Vista actual**: `/distribucion/pedidos/index.tsx`
- Tabla con: Número, Cliente/Destinatario, Dirección, Transportista, Fecha, Estado
- Hay opción de asignar conductor (abajo de la tabla)
- **FALTA**: 
  - Tipo de envío (delivery/recogo)
  - Conductor externo (InDrive, Yango, Uber, etc.)
  - Sección de pedidos sin conductor

---

## Cambios Necesarios

### 1. Backend - Agregar tipo de envío y conductor externo

**Archivo**: `Amatista-be/core/choices.py`
```python
# Agregar después de TURNO_ENTREGA_CHOICES:

# Tipo de envío
TIPO_ENVIO_DISTRIBUCION = "distribucion"
TIPO_ENVIO_RECOGO = "recogo"
TIPO_ENVIO_EXTERNO = "externo"  # Apps como InDrive, Yango, Uber

TIPO_ENVIO_CHOICES = [
    (TIPO_ENVIO_DISTRIBUCION, "Delivery (propio)"),
    (TIPO_ENVIO_RECOGO, "Recojo en tienda"),
    (TIPO_ENVIO_EXTERNO, "App externo (InDrive/Yango/Uber)"),
]

# Nombre del conductor externo (para apps)
CONDUCTOR_EXTERNO_NOMBRE = "conductor_externo_nombre"
```

**Archivo**: `Amatista-be/apps/distribucion/models.py`
```python
# Agregar en la clase Pedido:

# Tipo de envío
tipo_envio = models.CharField(
    max_length=20,
    choices=TIPO_ENVIO_CHOICES,
    default=TIPO_ENVIO_DISTRIBUCION,
    help_text="Tipo de envío: delivery propio, recojo en tienda, o app externo",
)

# Para apps externos
conductor_externo_nombre = models.CharField(
    max_length=100,
    blank=True,
    default="",
    help_text="Nombre del conductor de app externa (InDrive, Yango, Uber)",
)

conductor_externo_telefono = models.CharField(
    max_length=20,
    blank=True,
    default="",
    help_text="Teléfono del conductor de app externa",
)

conductor_externo_app = models.CharField(
    max_length=30,
    blank=True,
    default="",
    help_text="Nombre de la app (InDrive, Yango, Uber, etc)",
)
```

**Archivo**: `Amatista-be/apps/distribucion/serializers.py`
```python
# Agregar en PedidoCreateSerializer y PedidoSerializer:
tipo_envio = serializers.CharField(max_length=20, required=False, default="distribucion")
conductor_externo_nombre = serializers.CharField(max_length=100, required=False, default="")
conductor_externo_telefono = serializers.CharField(max_length=20, required=False, default="")
conductor_externo_app = serializers.CharField(max_length=30, required=False, default="")
```

**Archivo**: `Amatista-be/apps/distribucion/services.py`
```python
# Agregar en crear_pedido:
tipo_envio=datos.get("tipo_envio", "distribucion"),
conductor_externo_nombre=datos.get("conductor_externo_nombre", ""),
conductor_externo_telefono=datos.get("conductor_externo_telefono", ""),
conductor_externo_app=datos.get("conductor_externo_app", ""),
```

### 2. Frontend - Actualizar tipos

**Archivo**: `Amatista-fe/src/app/(admin)/(app)/(ventas)/pedido-pos/types.ts`
```typescript
// Agregar en DatosEntrega:
tipo_envio: 'distribucion' | 'recogo' | 'externo';
conductor_externo_nombre?: string;
conductor_externo_telefono?: string;
conductor_externo_app?: string;
```

### 3. Frontend - Actualizar formulario de pedido

**Archivo**: `Amatista-fe/src/app/(admin)/(app)/(ventas)/pedido-pos/components/DatosEntregaForm.tsx`

Agregar después de "Turno de entrega":
```tsx
{/* Tipo de envío */}
<div>
  <label>Tipo de envío *</label>
  <select
    value={datos.tipo_envio}
    onChange={(e) => onChange('tipo_envio', e.target.value)}
  >
    <option value="distribucion">🚚 Delivery (propio)</option>
    <option value="recogo">🏪 Recojo en tienda</option>
    <option value="externo">📱 App externo (InDrive/Yango/Uber)</option>
  </select>
</div>

{/* Solo mostrar si es app externo */}
{datos.tipo_envio === 'externo' && (
  <>
    <div>
      <label>App de transporte *</label>
      <select
        value={datos.conductor_externo_app}
        onChange={(e) => onChange('conductor_externo_app', e.target.value)}
      >
        <option value="">Seleccionar app...</option>
        <option value="indrive">InDrive</option>
        <option value="yango">Yango</option>
        <option value="uber">Uber</option>
        <option value="otro">Otro</option>
      </select>
    </div>
    <div>
      <label>Nombre del conductor</label>
      <input
        value={datos.conductor_externo_nombre}
        onChange={(e) => onChange('conductor_externo_nombre', e.target.value)}
      />
    </div>
    <div>
      <label>Teléfono del conductor</label>
      <input
        value={datos.conductor_externo_telefono}
        onChange={(e) => onChange('conductor_externo_telefono', e.target.value)}
      />
    </div>
  </>
)}
```

### 4. Frontend - Mejorar vista de pedidos

**Archivo**: `Amatista-fe/src/app/(admin)/(app)/(distribucion)/pedidos/index.tsx`

#### 4.1 Agregar filtros
- Filtro por "Sin conductor asignado" (checkbox)
- Filtro por tipo de envío

#### 4.2 Sección de pedidos sin conductor
```tsx
// Arriba de la tabla
{pedidosSinConductor.length > 0 && (
  <div className="card mb-4 border-2 border-warning">
    <div className="card-header bg-warning/10">
      <h6>⚠️ Pedidos sin conductor asignado ({pedidosSinConductor.length})</h6>
    </div>
    <div className="card-body">
      {/* Lista de pedidos sin conductor */}
    </div>
  </div>
)}
```

#### 4.3 Nueva columna en tabla
Agregar columnas:
- **Tipo**: Icono de 🚚 (delivery), 🏪 (recogo), 📱 (app)
- **Conductor**: Si es app externo, mostrar "📱 [App] - [Nombre]"
- **Turno**: Mostrar turno + rango si es express

---

## Orden de Ejecución

### Paso 1: Backend
```bash
cd Amatista-be
source .venv/bin/activate

# 1. Agregar choices
# Editar: core/choices.py

# 2. Agregar campos al modelo
# Editar: apps/distribucion/models.py

# 3. Agregar campos al serializer
# Editar: apps/distribucion/serializers.py

# 4. Agregar campos al servicio
# Editar: apps/distribucion/services.py

# 5. Crear migración
python manage.py makemigrations distribucion
python manage.py migrate distribucion
python manage.py check
```

### Paso 2: Regenerar API
```bash
# En Amatista-be
python manage.py spectacular --file ../Amatista-fe/openapi-schema.yaml

# En Amatista-fe
pnpm orval --config orval.config.ts
```

### Paso 3: Frontend - Tipos
```bash
# Actualizar types.ts en pedido-pos
```

### Paso 4: Frontend - Formulario
```bash
# Actualizar DatosEntregaForm.tsx
```

### Paso 5: Frontend - Vista Pedidos
```bash
# Actualizar /distribucion/pedidos/index.tsx
# - Agregar filtros
# - Agregar sección de pedidos sin conductor
# - Agregar columnas de tipo de envío y conductor externo
```

### Paso 6: Verificación
```bash
# Backend
python manage.py check

# Frontend
pnpm build
```

---

## Archivos a Modificar

### Backend
| Archivo | Cambio |
|---------|--------|
| `core/choices.py` | Agregar `TIPO_ENVIO_CHOICES` |
| `apps/distribucion/models.py` | Agregar campos `tipo_envio`, `conductor_externo_*` |
| `apps/distribucion/serializers.py` | Agregar campos al serializer |
| `apps/distribucion/services.py` | Agregar campos al crear pedido |

### Frontend
| Archivo | Cambio |
|---------|--------|
| `src/app/(admin)/(app)/(ventas)/pedido-pos/types.ts` | Agregar tipos para nuevo flujo |
| `src/app/(admin)/(app)/(ventas)/pedido-pos/components/DatosEntregaForm.tsx` | Agregar campos de tipo de envío |
| `src/app/(admin)/(app)/(distribucion)/pedidos/index.tsx` | Mejorar vista con filtros y sección sin conductor |

---

## Notas

- Los cambios son backward-compatible (no rompen lo existente)
- El campo `tipo_envio` tiene valor por defecto "distribucion"
- Los pedidos existentes seguirán funcionando igual
- Para React-TS, se pueden usar como referencia los componentes en:
  - `React-TS/src/app/(admin)/(app)/(ecommerce)/orders/components/OrderDetailTabel.tsx` (tabla de pedidos)
  - `React-TS/src/app/(admin)/(app)/(ecommerce)/order-overview/components/OrderStatus.tsx` (tracking de estados)
