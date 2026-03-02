# Flujos de Prueba — Fases 4, 5 y 6

> Fecha: 2026-03-02  
> Objetivo: Validar manualmente en el navegador que todo lo implementado funciona correctamente antes de considerar las fases cerradas.

---

## ANTES DE EMPEZAR

1. Levantar el backend: `cd Amatista-be && python manage.py runserver`
2. Levantar el frontend: `cd Amatista-fe && pnpm dev`
3. Tener al menos:
   - 1 cliente con **RUC** (tipo_documento = `6`) cargado en la base de datos
   - 1 cliente con **DNI** (tipo_documento = `1`)
   - 2-3 productos finales en inventario, con `precio_venta` definido

---

## FASE 4 — Precios Diferenciados

### F4-1: Precio corporativo en ProductoForm

**Pasos:**
1. Ir a `/inventario/productos/crear`
2. Seleccionar tipo de registro = **Producto Final**
3. Verificar que aparece el campo **"Precio Corporativo"** (opcional)
4. Ingresar un precio corporativo (ej. `85.00`) y guardar

**Resultado esperado:**
- El producto se guarda con `precio_corporativo = 85.00`
- Al editar el producto, el campo muestra el valor guardado

**Caso negativo:**
- Seleccionar tipo = **Insumo orgánico** → el campo `precio_corporativo` NO debe aparecer

---

### F4-2: Badge "Precio Corp." en POS al seleccionar cliente con RUC

**Pasos:**
1. Ir a `/ventas/pedido-pos`
2. En la sección "Cliente", buscar y seleccionar el cliente con **RUC**
3. Observar el chip del cliente en la columna derecha

**Resultado esperado:**
- El chip muestra un badge azul **"Precio Corp."** junto al nombre del cliente
- No aparece si el cliente tiene DNI u otro tipo de documento

**Caso negativo:**
- Buscar y seleccionar cliente con **DNI** → badge NO aparece
- Crear cliente nuevo (draft) → badge NO aparece (lógica correcta: draft usa `tipo_documento: '0'`)

---

### F4-3: Aviso de precio corporativo en CotizacionModal

**Pasos:**
1. Ir a `/ventas/cotizaciones`
2. Hacer click en **"Nueva Cotización"**
3. En Step 1 (Cliente), seleccionar el cliente con **RUC**
4. Avanzar hasta el **Step 4 (Resumen)**

**Resultado esperado:**
- En el Step 4, dentro del recuadro de información del cliente, aparece un banner azul con el texto:
  _"Cliente corporativo — se aplica precio corporativo si el producto lo tiene configurado."_

**Caso negativo:**
- Seleccionar cliente con DNI → el banner NO aparece en el Step 4

---

### F4-4: Comportamiento del precio en el backend (verificar con Swagger o logs)

> Este flujo valida la lógica de `resolver_precio()` — requiere acceso a la API directamente.

**Pasos:**
1. Crear una venta en el POS con el cliente RUC y el producto que tiene `precio_corporativo`
2. Revisar en la DB o en el detalle de la venta que `precio_unitario` del detalle usa el precio corporativo

**Resultado esperado:**
- `detalle_venta.precio_unitario` = `precio_corporativo` del producto (no `precio_venta`)

---

## FASE 5 — Cotizaciones Mejoradas

### F5-1: Columna "Aprobada" en la tabla de cotizaciones

**Pasos:**
1. Ir a `/ventas/cotizaciones`
2. Observar la tabla

**Resultado esperado:**
- Existe la columna **"Aprobada"** entre "Estado" y "Acciones"
- Cotizaciones no aprobadas muestran `—`
- Cotizaciones aprobadas muestran ícono de check verde (✓)

---

### F5-2: Descargar PDF de una cotización

**Pasos:**
1. Ir al detalle de cualquier cotización (`/ventas/cotizaciones/{id}`)
2. Hacer click en el botón **"PDF"** (en el top bar) o **"Descargar PDF"** (en el sidebar)

**Resultado esperado:**
- El navegador descarga un archivo `cotizacion-{id}.pdf`
- El archivo abre correctamente y contiene los datos de la cotización
- No aparece error en pantalla

**Posibles errores a reportar:**
- Error 404: el endpoint `/api/v1/ventas/cotizaciones/{id}/pdf/` no existe o la URL es diferente
- Error 500: falla en la generación del PDF (revisar logs del backend)
- El PDF descarga pero está vacío o corrupto

---

### F5-3: Enviar cotización por email

**Pasos:**
1. Ir al detalle de cualquier cotización
2. Hacer click en el botón **"Enviar"** (top bar) o **"Enviar por Email"** (sidebar)
3. Se abre un modal con campo de email
4. Ingresar un email válido (ej. `prueba@test.com`)
5. Hacer click en **"Enviar"**

**Resultado esperado:**
- Toast verde: _"Email enviado correctamente"_
- El modal se cierra automáticamente
- Si tienes acceso a la bandeja del email, debe llegar el correo

**Caso de error:**
- Ingresar email vacío → el botón "Enviar" debe estar deshabilitado
- Presionar "Cancelar" → el modal cierra sin enviar nada

---

### F5-4: Aprobar cotización (solo admin/gerente)

**Pasos con usuario admin/gerente:**
1. Ir al detalle de una cotización
2. Verificar que aparece el botón **"Aprobar"** en el top bar y en el sidebar
3. Hacer click en "Aprobar" → confirmar en el `confirm()` del navegador
4. Esperar la respuesta

**Resultado esperado:**
- Toast verde: _"Cotizacion aprobada"_
- El botón "Aprobar" desaparece (ya no se puede aprobar dos veces)
- Aparece el badge verde **"Aprobada ✓"** junto al badge de estado en el header de la cotización
- En la lista de cotizaciones (`/ventas/cotizaciones`), la columna "Aprobada" muestra el ícono check verde para esta cotización

**Con usuario vendedor/cajero (rol sin permiso):**
- El botón "Aprobar" NO debe aparecer en ningún lugar de la página

---

### F5-5: Badge "Aprobada" en el encabezado del detalle

**Pasos:**
1. Con una cotización ya aprobada (del paso F5-4), recargar la página del detalle

**Resultado esperado:**
- El badge verde **"Aprobada ✓"** aparece junto al badge de estado (ej. "Vigente")
- El campo `aprobada_en` y `aprobada_por_nombre` están disponibles en la cotización (visible en la respuesta de la API)

---

## FASE 6 — Campañas de Temporada

### F6-1: Crear una campaña nueva

**Pasos:**
1. Ir a `/ventas/campanas` (accesible solo para admin)
2. Hacer click en **"Nueva Campaña"**
3. Llenar el formulario:
   - Nombre: `San Valentín 2026`
   - Descripción: opcional
   - Fecha inicio: hoy o fecha pasada (para que esté activa ahora)
   - Fecha fin: mañana o fecha futura
   - Descuento %: `15`
   - Seleccionar 1 o 2 productos de la lista
4. Hacer click en **"Crear Campaña"**

**Resultado esperado:**
- Toast verde: _"Campaña creada"_
- La campaña aparece en la tabla con:
  - Badge rojo **"-15%"** en la columna Descuento
  - Badge verde **"Activa"** en la columna Estado (porque las fechas incluyen hoy)
  - Número de productos seleccionados en la columna Productos

---

### F6-2: Badge "-X%" en el catálogo del POS

**Pasos:**
1. (Después de crear la campaña del paso F6-1 con productos incluidos)
2. Ir a `/ventas/pedido-pos`
3. Observar el catálogo de productos (grilla)

**Resultado esperado:**
- Los productos que están en la campaña activa muestran un badge rojo **"-15%"** sobre su imagen
- Los productos que NO están en la campaña no muestran badge

**Caso negativo (campaña inactiva):**
- Si las fechas de la campaña no incluyen hoy → el badge NO debe aparecer

---

### F6-3: Badge "En campaña" en la lista de inventario

**Pasos:**
1. Ir a `/inventario/productos`
2. Verificar vista **Cards** (grid)
3. Verificar vista **Lista** (table)

**Resultado esperado (vista Cards):**
- Los productos en campaña activa muestran badge rojo **"En campaña"** sobre su imagen (esquina superior izquierda)

**Resultado esperado (vista Lista):**
- Los productos en campaña activa muestran badge rojo **"En campaña"** junto a su nombre en la columna Producto

---

### F6-4: Editar una campaña

**Pasos:**
1. Ir a `/ventas/campanas`
2. Hacer click en el ícono de editar (lápiz) de la campaña creada
3. Cambiar el descuento a `20%` y agregar otro producto
4. Guardar

**Resultado esperado:**
- Toast: _"Campaña actualizada"_
- La tabla refleja el nuevo descuento y número de productos

---

### F6-5: Campaña con fechas futuras (badge NO debe aparecer)

**Pasos:**
1. Crear una campaña con `fecha_inicio` = mañana (fecha futura)
2. Ir al POS e inventario

**Resultado esperado:**
- El badge NO aparece en ningún producto (la campaña no está activa hoy)
- En la tabla de campañas, muestra badge **"Inactiva"**

---

### F6-6: Eliminar una campaña

**Pasos:**
1. Ir a `/ventas/campanas`
2. Hacer click en el ícono de eliminar (papelera) de una campaña
3. Confirmar en el diálogo del navegador

**Resultado esperado:**
- Toast: _"Campaña eliminada"_
- La campaña desaparece de la tabla
- Los badges desaparecen del POS e inventario (en la próxima carga)

---

### F6-7: Descuento de campaña se aplica en el backend al crear venta

> Requiere verificar en la DB o en el detalle de la venta.

**Pasos:**
1. Con una campaña activa que incluya un producto
2. Ir al POS y agregar ese producto al carrito
3. Completar la venta
4. Revisar el detalle de la venta en `/ventas/{id}`

**Resultado esperado:**
- El `descuento_porcentaje` en el `detalle_venta` refleja el descuento de la campaña
- O el `precio_unitario` ya viene con el descuento aplicado (según implementación del backend en `aplicar_descuento_campana()`)

---

## ERRORES CONOCIDOS / COSAS A VIGILAR

| Síntoma | Causa probable | Dónde revisar |
|---------|---------------|--------------|
| Badge "Precio Corp." no aparece con cliente RUC | `tipo_documento` en la respuesta de la API no es `'6'` | Network tab → buscarClientes → inspeccionar campo `tipo_documento` |
| PDF descarga con error 404 | URL del endpoint o el action name en el backend | `ventas/urls.py` → verificar que `pdf` está registrado como action |
| PDF descarga pero está vacío | Error en `generar_cotizacion_pdf()` del backend | Logs del servidor Django |
| Email falla silenciosamente | Configuración de SMTP en settings del backend | `settings.py` → `EMAIL_*` |
| Botón "Aprobar" aparece para un vendedor | `hasRole()` no verifica correctamente | `AuthContext.tsx` → función `hasRole` |
| Campaña activa pero badge no aparece | `campanasData.data` no tiene shape `results` | Network tab → `GET /api/v1/ventas/campanas/` → ver si la respuesta es `{results: [...]}` o `[...]` directo |
| `tsc --noEmit` falla | Error de tipos en algún archivo nuevo | Correr `pnpm tsc --noEmit` y revisar el output |

---

## CHECKLIST FINAL

- [ ] F4-1: Campo `precio_corporativo` visible en ProductoForm (solo tipo=producto_final)
- [ ] F4-2: Badge "Precio Corp." en POS con cliente RUC
- [ ] F4-3: Aviso corporativo en CotizacionModal Step 4
- [ ] F4-4: Backend aplica precio_corporativo en venta/cotización (verificar en DB)
- [ ] F5-1: Columna "Aprobada" visible en tabla de cotizaciones
- [ ] F5-2: Descarga de PDF funciona correctamente
- [ ] F5-3: Envío de email funciona (modal + toast)
- [ ] F5-4: Botón "Aprobar" solo visible para admin/gerente
- [ ] F5-5: Badge "Aprobada ✓" en detalle de cotización aprobada
- [ ] F6-1: CRUD de campañas funciona en `/ventas/campanas`
- [ ] F6-2: Badge "-X%" en POS para productos en campaña activa
- [ ] F6-3: Badge "En campaña" en inventario (grid y lista)
- [ ] F6-4: Editar campaña actualiza los datos
- [ ] F6-6: Eliminar campaña limpia los badges
- [ ] F6-7: Backend aplica descuento de campaña en venta/cotización (verificar en DB)
- [ ] `pnpm tsc --noEmit` = 0 errores ✅ (ya verificado)
