# AMATISTA ERP — REGLAS DEL AGENTE / DESARROLLADOR

> Leer antes de ejecutar cualquier accion en el proyecto.
> Aplica a cualquier agente de IA o desarrollador que trabaje en Amatista.

---

## 1. REGLAS ABSOLUTAS (NO NEGOCIABLES)

```
AGENTE-01: NUNCA inventar funcionalidades que no esten planificadas en ROADMAP.md.
           Si no esta en el plan, NO se implementa sin consultar primero.

AGENTE-02: NUNCA cambiar el stack tecnologico definido.
           Django, DRF, PostgreSQL, React, Tailwind, Nubefact, Celery, Redis.

AGENTE-03: Si hay ambiguedad, PREGUNTAR antes de implementar.
           NUNCA asumir. NUNCA "interpretar" lo que el usuario quiso decir.

AGENTE-04: NUNCA tocar el frontend a menos que el usuario lo solicite explicitamente.

AGENTE-05: NUNCA alterar la estructura de la DB existente sin autorizacion.
           Si se necesita un cambio, DESCRIBIR primero y esperar aprobacion.

AGENTE-06: Cada cambio debe ser incremental y verificable.
           NO hacer refactors masivos sin autorizacion.

AGENTE-07: Documentar todo endpoint creado (docstring minimo + @extend_schema).

AGENTE-08: Respetar nomenclatura:
           - Espanol para modelos y campos de negocio
           - Ingles para metodos tecnicos y variables internas

AGENTE-09: NUNCA asumir que algo "ya funciona". Verificar leyendo el codigo.

AGENTE-10: NUNCA trabajar en Jsoluciones-be/ o Jsoluciones-fe/ desde aqui
           — esos son el template base READ ONLY desde la perspectiva de Amatista.

AGENTE-11: Los errores LSP en Amatista-be/ son PRE-EXISTENTES (Django Channels, lxml, typing).
           NO son regresiones. NO intentar corregirlos sin autorizacion explicita.

AGENTE-12: El e-commerce usa `tipo_venta='online'` — el campo ya existe en la DB.
           NUNCA crear un modelo separado de "pedido e-commerce" sin consultarlo.
```

---

## 2. DONDE ENCONTRAR CONTEXTO

| Duda | Archivo a leer |
|------|----------------|
| Que es el proyecto, stack, repos | `context/OVERVIEW.md` |
| Que modulos existen y su estado | `context/MODULES.md` |
| Reglas de base de datos, enums | `context/DATABASE.md` |
| Flujos especificos de floreria | `context/FLOWS.md` |
| Servicios, Redis, Celery, Docker | `context/DEVOPS.md` |
| Que viene en el roadmap | `context/ROADMAP.md` |
| Reglas de backend Django/DRF | `rules/BACKEND.md` |
| Reglas de frontend React/TS | `rules/FRONTEND.md` |
| Comandos para correr y depurar | `rules/COMMANDS.md` |
| Schema completo de DB | `DB_SCHEMA_COMPLETO.md` |
| Design system (colores, tipografia) | `DESIGN_SYSTEM.md` |

---

## 3. PROTOCOLO DE TRABAJO

### Antes de escribir codigo

```
1. Leer context/DATABASE.md y verificar en DB_SCHEMA_COMPLETO.md si el campo existe.
2. Identificar que se va a tocar: backend, frontend, o ambos.
3. Leer el archivo de reglas correspondiente.
4. Verificar que no existe algo similar ya implementado.
5. Si el cambio toca la DB: describir al usuario y esperar aprobacion.
```

### Durante el desarrollo

```
1. Trabajar en UNA cosa a la vez.
2. Si encuentro un bug o inconsistencia:
   - Informar ANTES de arreglarlo.
   - NO corregir "de paso" cosas que no se pidieron.
3. Si necesito instalar un paquete nuevo:
   - Verificar compatibilidad.
   - Informar al usuario que se va a instalar y por que.
```

### Despues de escribir codigo

```
1. Verificar que los archivos esten en la ubicacion correcta.
2. Verificar que se respetan los patrones (services.py, no logica en views).
3. Si se creo una migracion, NO aplicarla sin informar al usuario.
4. Actualizar el doc correspondiente en la misma sesion (MODULES.md, DATABASE.md, etc.)
5. Mostrar resumen de lo que se hizo.
```

---

## 4. PERMISOS SIN PEDIR AUTORIZACION

| Accion | Permitido |
|--------|-----------|
| Crear archivos nuevos (services, views, etc.) | Si |
| Agregar campos con default a modelos | Si (informar) |
| Crear migraciones (no aplicar) | Si (informar) |
| Escribir tests | Si |
| Agregar logs / docstrings | Si |
| Crear endpoints nuevos para el modulo en curso | Si |

---

## 5. REQUIERE PERMISO SIEMPRE

| Accion | Requiere permiso |
|--------|-----------------|
| Modificar un modelo existente (campos) | SIEMPRE |
| Renombrar campos o tablas | SIEMPRE |
| Eliminar codigo existente | SIEMPRE |
| Instalar paquetes nuevos | SIEMPRE |
| Cambiar la estructura de carpetas | SIEMPRE |
| Modificar settings.py | SIEMPRE |
| Tocar frontend cuando se pidio solo backend | SIEMPRE |
| Refactorizar codigo que ya funciona | SIEMPRE |
| Aplicar migraciones | SIEMPRE (informar antes) |

---

## 6. PROHIBIDO ABSOLUTAMENTE

| Accion | PROHIBIDO |
|--------|-----------|
| DROP TABLE, DROP COLUMN | PROHIBIDO |
| Eliminar migraciones | PROHIBIDO |
| Borrar registros contables/fiscales de la DB | PROHIBIDO |
| Cambiar el stack | PROHIBIDO |
| Inventar funcionalidades no solicitadas | PROHIBIDO |
| Hardcodear contrasenas, tokens o secretos | PROHIBIDO |
| Usar print() en vez de logging | PROHIBIDO |
| Poner logica de negocio en views o serializers | PROHIBIDO |
| Usar FloatField para dinero | PROHIBIDO |
| Crear raw SQL sin justificacion documentada | PROHIBIDO |
| Guardar access token JWT en localStorage | PROHIBIDO |
| Tocar Jsoluciones-be/ o Jsoluciones-fe/ | PROHIBIDO |

---

## 7. FORMATO DE COMUNICACION

### Cuando propongo un cambio:

```
PROPUESTA DE CAMBIO
-------------------
Modulo: [nombre]
Archivo: [ruta]
Tipo: [nuevo / modificacion / migracion]
Descripcion: [que se va a hacer y por que]
Impacto: [que otros modulos se ven afectados]
Requiere migracion: [Si/No]

Procedo?
```

### Cuando termino una tarea:

```
COMPLETADO
----------
Modulo: [nombre]
Archivos creados/modificados:
  - [ruta]: [descripcion breve]
Endpoints nuevos:
  - [metodo] [url]: [descripcion]
Pendiente:
  - [lo que falta, si aplica]
```

### Cuando detecto un problema:

```
PROBLEMA DETECTADO
------------------
Ubicacion: [archivo:linea]
Descripcion: [que esta mal]
Impacto: [que puede pasar si no se corrige]
Propuesta: [como sugiero solucionarlo]
Riesgo: [bajo / medio / alto]

Quieres que lo corrija?
```
