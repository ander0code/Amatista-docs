# PLAN MEJORAS DISTRIBUCIÓN — Amatista ERP

> **Fecha:** 2026-02-25  
> **Proyecto:** Amatista ERP (Florería)  
> **Objetivo:** Mejorar el flujo de distribución: producción → asignación → entrega

---

## 1. DIAGNÓSTICO ACTUAL

### 1.1 Backend — Estado: ✅ COMPLETO

| Componente | Estado | Detalle |
|------------|--------|---------|
| Modelos | ✅ Listo | `Transportista`, `Pedido`, `SeguimientoPedido`, `EvidenciaEntrega` |
| Estados Producción | ✅ Listo | `pendiente` → `armando` → `listo` |
| Estados Entrega | ✅ Listo | `pendiente` → `confirmado` → `despachado` → `en_ruta` → `entregado` |
| Portal Repartidor | ✅ Listo | `/portal/{token}/` con API completa |
| APIs | ✅ Listo | Asignar, avanzar/revertir producción, confirmar entrega, GPS |

**Endpoints relevantes:**
- `POST /api/v1/distribucion/pedidos/{id}/asignar-transportista`
- `POST /api/v1/distribucion/pedidos/{id}/produccion/avanzar`
- `POST /api/v1/distribucion/pedidos/{id}/produccion/revertir`
- `POST /api/v1/distribucion/pedidos/{id}/despachar`
- `POST /api/v1/distribucion/pedidos/{id}/en-ruta`
- `POST /api/v1/distribucion/pedidos/{id}/confirmar-entrega`
- `GET /api/v1/distribucion/portal/{token}/` — pedidos del repartidor
- `POST /api/v1/distribucion/portal/{token}/pedidos/{id}/confirmar/`

### 1.2 Frontend — Estado: ⚠️ PARCIAL

| Vista | Estado | Problema |
|-------|--------|----------|
| `produccion/index.tsx` | ✅ Listo | Kanban 3 columnas existente |
| `transportistas/index.tsx` | ✅ Listo | Lista de repartidores |
| `transportistas/components/TransportistaFormModal.tsx` | ✅ Listo | Crear repartidor completo |
| `portal-conductor/index.tsx` | ✅ Listo | Portal del repartidor |
| `pedido-detalle/index.tsx` | ✅ Listo | Detalle con acciones |
| `pedidos/index.tsx` | ⚠️ Mal | Botón "Crear pedido" NO debería estar |
| AsignarRepartidorModal | ❌ Falta | Modal con 3 opciones (existente, rápido, app) |

---

## 2. PROBLEMAS A CORREGIR

| # | Problema | Ubicación | Gravedad |
|---|----------|-----------|----------|
| 1 | Botón "Crear pedido" en distribución | `pedidos/index.tsx` | Alta |
| 2 | Falta crear repartidor rápido (temporal) | Nuevo componente | Alta |
| 3 | Falta opción "app de delivery" | Por definir | Media |
| 4 | No se integra producción → asignación | `produccion/index.tsx` | Alta |
| 5 | No hay tipo "app" en transportista | Modelo/API | Media |

---

## 3. PLAN DE TRABAJO

### ETAPA 1: Limpieza Visual ✅ COMPLETADO

#### Paso 1.1: Quitar botón "Crear pedido" de pedidos/index.tsx

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/pedidos/index.tsx`

**Cambio:** Eliminar el botón "Nuevo Pedido" del toolbar.

**Estado:** ✅ COMPLETADO - 2026-02-25

---

### ETAPA 2: Integración Producción → Asignación ✅ COMPLETADO

#### Paso 2.1: Añadir botón "Asignar Repartidor" en produccion/index.tsx

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/produccion/index.tsx`

**Cambio:** Cuando un pedido pasa a estado `listo`, mostrar botón para asignar repartidor.

**Lógica:**
- En cada tarjeta del Kanban, si `estado_produccion === 'listo'` Y `!transportista`, mostrar botón "Asignar Repartidor"
- Click abre modal de asignación

**Estado:** ✅ COMPLETADO - 2026-02-25

---

### ETAPA 3: Modal de Asignación (3 opciones) ✅ COMPLETADO

**Mejora adicional:** Modal reescrito con estilo profesional:
- Tabs tipo "pill buttons" (grid 3 columnas)
- Cards para seleccionar repartidor existente
- Botones grandes para apps de delivery
- Mejor spacing y márgenes

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/pedidos/components/AsignarTransportistaModal.tsx`

**Funcionalidades:**
1. **Pestaña A:** Seleccionar repartidor existente (dropdown)
2. **Pestaña B:** Crear repartidor rápido (nombre + teléfono + tipo vehículo)
3. **Pestaña C:** Asignar app de delivery (Glovo, PedidosYa, etc.)

**Opciones de Apps disponibles:**
- Glovo
- PedidosYa
- Rappi
- Uber Eats

**Opciones de vehículo:**
- Moto
- Carro
- Bicicleta
- A pie

**Estado:** ✅ COMPLETADO - 2026-02-25

---

### ETAPA 4: Modelo Transportista - Tipo App ✅ COMPLETADO

#### Paso 4.1: Añadir campos tipo_transportista y app_nombre

**Archivo:** `Amatista-be/apps/distribucion/models.py`

**Cambios:**
- Añadido campo `tipo_transportista` con choices: 'propio', 'app'
- Añadido campo `app_nombre` para guardar el nombre de la app (Glovo, PedidosYa, etc.)

**Migración:** `0009_transportista_app_nombre_and_more`

**Estado:** ✅ COMPLETADO - 2026-02-25

**Verificar:**
```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-be
source .venv/bin/activate
python manage.py showmigrations
python manage.py check
```

---

## 4. VERIFICACIONES REALIZADAS

### Backend ✅
```bash
python manage.py check  # OK
python manage.py showmigrations  # Sin pendientes
python manage.py spectacular --file ../Amatista-fe/openapi-schema.yaml  # OK
```

### Frontend ✅
```bash
pnpm orval --config orval.config.ts  # Tipos regenerados
pnpm dev  # Servidor funcionando
```

---

## 5. FLUJO IMPLEMENTADO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   VENTAS   │ ──► │ PRODUCCIÓN  │ ──► │  ASIGNAR    │ ──► │  REPARTIDOR │
│  (crear)   │     │ (3 columnas)│     │ (3 opciones)│     │  (portal)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                          │                   │
                     pendiente           existente
                     armando             crear_rápido  
                     listo ──────────►  app_delivery
                                        │
                              ┌─────────┴─────────┐
                              │  EN REPARTO      │
                              │  despachado      │
                              │  en_ruta         │
                              │  entregado       │
                              └──────────────────┘
```

---

## 6. ARCHIVOS MODIFICADOS

### Frontend

| # | Archivo | Acción | Estado |
|---|---------|--------|--------|
| 1 | `pedidos/index.tsx` | Quitar botón "Nuevo Pedido" | ✅ |
| 2 | `produccion/index.tsx` | Añadir botón asignar cuando listo | ✅ |
| 3 | `pedidos/components/AsignarTransportistaModal.tsx` | Modal 3 pestañas | ✅ |

### Backend

| # | Archivo | Acción | Estado |
|---|---------|--------|--------|
| 1 | `apps/distribucion/models.py` | Añadir campos tipo_transportista, app_nombre | ✅ |
| 2 | `migraciones/0009_*.py` | Nueva migración | ✅ |

---

## 3. PLAN DE TRABAJO (Original)

### ETAPA 1: Limpieza Visual

#### Paso 1.1: Quitar botón "Crear pedido" de pedidos/index.tsx

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/pedidos/index.tsx`

**Cambio:** Eliminar el botón "Nuevo Pedido" del toolbar.

```diff
- <button
-   onClick={() => setModalCrearOpen(true)}
-   className="btn btn-sm bg-primary text-white hover:bg-primary/90 flex items-center gap-1.5"
- >
-   <LuPlus className="size-4" />
-   Nuevo Pedido
- </button>
```

**Verificar:**
```bash
# Frontend
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-fe
pnpm dev
# Ir a /distribucion/pedidos y verificar que no hay botón "Nuevo Pedido"
```

---

### ETAPA 2: Integración Producción → Asignación

#### Paso 2.1: Añadir botón "Asignar Repartidor" en produccion/index.tsx

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/produccion/index.tsx`

**Cambio:** Cuando un pedido pasa a estado `listo`, mostrar botón para asignar repartidor.

**Lógica:**
- En cada tarjeta del Kanban, si `estado_produccion === 'listo'` Y `!transportista`, mostrar botón "Asignar Repartidor"
- Click abre modal de asignación

**Verificar:**
```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-fe
pnpm dev
# Ir a /distribucion/produccion
# Avanzar un pedido a "listo"
# Verificar que aparece botón "Asignar Repartidor"
```

---

### ETAPA 3: Modal de Asignación (3 opciones)

#### Paso 3.1: Crear AsignarRepartidorModal.tsx

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/pedidos/components/AsignarRepartidorModal.tsx`

**Funcionalidades:**
1. **Pestaña A:** Seleccionar repartidor existente (dropdown)
2. **Pestaña B:** Crear repartidor rápido (nombre + teléfono + tipo vehículo)
3. **Pestaña C:** Asignar app de delivery (Glovo, PedidosYa, etc.)

**Componente:**
```tsx
// Pseudocódigo
interface Props {
  pedidoId: string;
  onClose: () => void;
  onAssigned: () => void;
}

const AsignarRepartidorModal = ({ pedidoId, onClose, onAssigned }: Props) => {
  const [tab, setTab] = useState<'existente' | 'rapido' | 'app'>('existente');
  
  // Pestaña A: Repartidor existente (useDistribucionTransportistasList)
  // Pestaña B: Crear rápido (useDistribucionTransportistasCreateWithJson)
  // Pestaña C: App (simple dropdown + guardar en notas del pedido)
  
  return (
    <Modal>
      <Tabs value={tab} onChange={setTab}>
        <Tab value="existente">Repartidor Existente</Tab>
        <Tab value="rapido">Crear Rápido</Tab>
        <Tab value="app">App de Delivery</Tab>
      </Tabs>
      
      {tab === 'existente' && <ListaRepartidores />}
      {tab === 'rapido' && <FormRepartidorRapido />}
      {tab === 'app' && <SelectorAppDelivery />}
    </Modal>
  );
};
```

**Verificar:**
```bash
pnpm dev
# Ir a producción, asignar repartidor
# Probar las 3 opciones
```

---

#### Paso 3.2: Crear modal "CrearRepartidorRapidoModal.tsx" (simplificado)

**Archivo:** `Amatista-fe/src/app/(admin)/(app)/(distribucion)/transportistas/components/CrearRepartidorRapidoModal.tsx`

**Campos:**
- Nombre (requerido)
- Teléfono (opcional)
- Tipo vehículo: Moto, Carro, Bicicleta, Pie (dropdown)
- Placa (opcional)

**Nota:** Este modal es una versión simplificada del `TransportistaFormModal` existente.

---

#### Paso 3.3: Añadir opción "App de Delivery" en el modelo

**Backend:** `Amatista-be/apps/distribucion/models.py`

**Cambio:** Añadir choices para tipo de transportista (propio vs app)

```python
class Transportista(models.Model):
    # ... campos existentes ...
    
    TIPO_TRANSPORTISTA_CHOICES = [
        ('propio', 'Repartidor Propio'),
        ('app', 'App de Delivery'),
    ]
    
    tipo_transportista = models.CharField(
        max_length=20,
        choices=TIPO_TRANSPORTISTA_CHOICES,
        default='propio',
    )
    
    app_nombre = models.CharField(
        max_length=50,
        blank=True,
        default='',
        help_text='Nombre de la app si tipo_transportista=app (Glovo, PedidosYa, etc.)',
    )
```

**Migración:**
```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-be
source .venv/bin/activate
python manage.py makemigrations distribucion
python manage.py migrate
python manage.py check
```

**Regenerar OpenAPI:**
```bash
python manage.py spectacular --file ../Amatista-fe/openapi-schema.yaml
```

**Regenerar tipos:**
```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-fe
pnpm orval --config orval.config.ts
```

---

### ETAPA 4: Mejoras del Portal Repartidor (opcional)

**Archivo:** `Amatista-fe/src/app/(public)/portal-conductor/index.tsx`

**Mejoras sugeridas:**
- Mejorar UX mobile
- Añadir botón "Llamar al cliente"
- Añadir botón "Abrir Maps"
- Confirmación con foto obligatoria

---

## 4. VERIFICACIONES POR ETAPA

### 4.1 Verificar Backend

```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-be
source .venv/bin/activate

# Verificar modelos
python manage.py check

# Verificar migraciones
python manage.py showmigrations

# Probar endpoint
python manage.py shell
>>> from apps.distribucion.models import Transportista, Pedido
>>> print(Transportista.objects.count())
>>> print(Pedido.objects.count())
```

### 4.2 Regenerar OpenAPI + Tipos

```bash
# Backend
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-be
source .venv/bin/activate
python manage.py spectacular --file ../Amatista-fe/openapi-schema.yaml

# Frontend
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-fe
pnpm orval --config orval.config.ts
```

### 4.3 Verificar Frontend

```bash
cd /home/anderson/Proyectos-J/J-soluciones/Amatista-fe
pnpm dev
# Abrir http://localhost:5173

# Probar:
# 1. /distribucion/pedidos - NO debe tener botón "Nuevo Pedido"
# 2. /distribucion/produccion - Debe mostrar botón "Asignar" en pedidos listos
# 3. Click en asignar debe abrir modal con 3 pestañas
```

---

## 5. FLUJO FINAL ESPERADO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   VENTAS   │ ──► │ PRODUCCIÓN  │ ──► │  ASIGNAR    │ ──► │  REPARTIDOR │
│  (crear)   │     │ (3 columnas)│     │ (3 opciones)│     │  (portal)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                          │                   │
                     pendiente           seleccionado
                     armando             crear_rapido
                     listo ──────────►  app_delivery
                                        │
                              ┌─────────┴─────────┐
                              │  EN REPARTO      │
                              │  despachado      │
                              │  en_ruta         │
                              │  entregado       │
                              └──────────────────┘
```

---

## 6. ARCHIVOS A MODIFICAR

### Frontend

| # | Archivo | Acción |
|---|---------|--------|
| 1 | `src/app/(admin)/(app)/(distribucion)/pedidos/index.tsx` | Quitar botón "Nuevo Pedido" |
| 2 | `src/app/(admin)/(app)/(distribucion)/produccion/index.tsx` | Añadir botón asignar cuando `listo` |
| 3 | `src/app/(admin)/(app)/(distribucion)/pedidos/components/AsignarRepartidorModal.tsx` | **NUEVO** — Modal 3 opciones |
| 4 | `src/app/(admin)/(app)/(distribucion)/transportistas/components/CrearRepartidorRapidoModal.tsx` | **NUEVO** — Form simplificado |

### Backend

| # | Archivo | Acción |
|---|---------|--------|
| 1 | `apps/distribucion/models.py` | Añadir campos `tipo_transportista`, `app_nombre` |
| 2 | `apps/distribucion/serializers.py` | Actualizar si es necesario |

---

## 7. NOTAS

- El portal del repartidor ya existe y funciona: `/portal/{token}`
- No es necesario crear nuevas APIs, solo usar las existentes
- Los tipos se regenerarán con Orval tras cambios en el backend
- El build de TypeScript tiene 64 errores preexistentes (no de nuestros cambios)
- El servidor dev (`pnpm dev`) funciona sin problemas

---

## 8. PENDIENTES DE DECISIÓN

1. ¿Qué apps de delivery suportar? (Glovo, PedidosYa, Rappi, etc.)
2. ¿El repartidor rápido se guarda permanentemente o es temporal por día?
3. ¿Se necesita notificación al repartidor cuando se le asigna pedido?

---

**Documento generado para参考 — 2026-02-25**
