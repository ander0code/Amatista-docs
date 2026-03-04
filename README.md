# Amatista ERP — Documentacion

> Capsula de contexto del proyecto Amatista ERP (floreria, cliente: Sr. Tito).
> Fork del template JSoluciones con modulos especificos de floreria.
> Single-tenant. Una sola instalacion.

---

## Indice rapido

| Pregunta | Archivo |
|----------|---------|
| Que es el proyecto, stack, arquitectura | `context/OVERVIEW.md` |
| Que modulos existen y su estado actual | `context/MODULES.md` |
| Reglas de DB, enums, choices, migraciones pendientes | `context/DATABASE.md` |
| Flujos de roles y flujos especificos de floreria | `context/FLOWS.md` |
| Redis, Celery, Docker, tareas programadas | `context/DEVOPS.md` |
| Que viene: BOM, e-commerce, campanias | `context/ROADMAP.md` |
| E-commerce: auditoria, gaps, plan de integracion | `context/ECOMMERCE.md` |
| Reglas del agente / desarrollador | `rules/AGENT.md` |
| Reglas de backend Django/DRF | `rules/BACKEND.md` |
| Reglas de frontend React/TS | `rules/FRONTEND.md` |
| Comandos para correr y depurar | `rules/COMMANDS.md` |
| Schema completo de DB (74 tablas, 33 enums) | `DB_SCHEMA_COMPLETO.md` |
| Design system (colores, tipografia, logo) | `DESIGN_SYSTEM.md` |

---

## Estructura del repo

```
Amatista-docs/
├── README.md                    <- Este archivo
├── DB_SCHEMA_COMPLETO.md        <- Schema PostgreSQL completo (fuente de verdad)
├── DESIGN_SYSTEM.md             <- Colores, tipografia, logo de Amatista
├── context/
│   ├── OVERVIEW.md              <- Vision general, stack, arquitectura
│   ├── MODULES.md               <- Estado de los 11 modulos
│   ├── DATABASE.md              <- Reglas DB, enums, migraciones pendientes
│   ├── FLOWS.md                 <- Flujos por rol + flujos especificos de floreria
│   ├── DEVOPS.md                <- Redis, Celery, Docker, tareas programadas
│   ├── ROADMAP.md               <- Proximos pasos: BOM, e-commerce, campanias
│   └── ECOMMERCE.md             <- Auditoria template, gaps, plan integracion
└── rules/
    ├── AGENT.md                 <- Reglas del agente / desarrollador
    ├── BACKEND.md               <- Reglas de backend Django/DRF
    ├── FRONTEND.md              <- Reglas de frontend React/TS
    └── COMMANDS.md              <- Comandos de desarrollo
```

---

## Repositorios del proyecto

| Repo | Path local | Descripcion |
|------|------------|-------------|
| `Amatista-be` | `../Amatista-be/` | Backend Django/DRF (ERP + API publica futura) |
| `Amatista-fe` | `../Amatista-fe/` | Frontend React/TS (panel ERP interno) |
| `JS-FE-Shop` | `../JS-FE-Shop/` | Frontend Next.js 16 (e-commerce publico, solo UI por ahora) |
| `Amatista-docs` | `../Amatista-docs/` | Este repo de documentacion |

> Template base (READ ONLY desde Amatista): `../Jsoluciones-be/` y `../Jsoluciones-fe/`

---

## Regla de actualizacion de docs

**Actualizar los docs relevantes EN LA MISMA SESION en que se hace un cambio en el codigo.**

| Si cambias... | Actualizar... |
|--------------|---------------|
| Modelo / campo / migracion | `context/DATABASE.md` + `DB_SCHEMA_COMPLETO.md` |
| Endpoint nuevo | `rules/BACKEND.md` (seccion endpoints) |
| Estado de modulo | `context/MODULES.md` |
| Libreria nueva | `context/OVERVIEW.md` |
| Componente / patron FE | `rules/FRONTEND.md` |
| Flujo de rol o de negocio | `context/FLOWS.md` |
| Redis / Celery / Docker / config | `context/DEVOPS.md` |
| Proximos pasos o plan | `context/ROADMAP.md` |
| E-commerce (FE shop o BE publico) | `context/ECOMMERCE.md` |
