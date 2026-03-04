# COMANDOS CLAVE — Amatista ERP

> Guia rapida de comandos para compilar, ejecutar y depurar el proyecto.
> Paths absolutos del proyecto en desarrollo local.

---

## BACKEND (Django)

### Ubicacion y entorno

```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Amatista-be
source .venv/bin/activate
```

### Servidor de desarrollo

```bash
python manage.py runserver
# Corre en: http://127.0.0.1:8000
```

### Verificar integridad

```bash
python manage.py check
python manage.py showmigrations
```

### Migraciones

```bash
python manage.py makemigrations
python manage.py makemigrations <app_name>
python manage.py migrate
python manage.py migrate <app_name>
```

### Management commands

```bash
python manage.py seed_permissions    # Crear 8 roles + permisos
python manage.py setup_empresa       # Crear empresa + admin
```

### Generar OpenAPI Schema (para Orval)

```bash
# Siempre desde Amatista-be/
python manage.py spectacular --color --file ../Amatista-fe/openapi-schema.yaml
```

### Shell interactiva

```bash
python manage.py shell
python manage.py shell_plus
```

### Tests

```bash
pytest tests/
pytest tests/test_ventas_services.py
coverage run --source='.' -m pytest tests/
coverage report
```

### Celery

```bash
celery -A config worker -l info
celery -A config beat -l info
celery -A config worker -B -l info   # Worker + Beat juntos (solo dev)
```

### Redis

```bash
sudo systemctl start valkey
sudo systemctl status valkey
```

### Linting y formateo

```bash
ruff check .
ruff format .
```

### Base de datos

```bash
psql -U postgres -d amatista
pg_dump -U postgres amatista > backup.sql
psql -U postgres amatista < backup.sql
```

---

## FRONTEND (React + Vite)

### Ubicacion

```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Amatista-fe
```

### Servidor de desarrollo

```bash
pnpm dev
# Corre en: http://localhost:5173
```

### Instalar dependencias

```bash
pnpm install
```

### Compilar para produccion

```bash
pnpm build
pnpm preview
```

### Generar tipos desde OpenAPI (Orval)

```bash
pnpm orval
```

### Type checking y linting

```bash
pnpm typecheck
pnpm lint
pnpm lint --fix
pnpm format
```

---

## FLUJO COMPLETO: Cambio en BE -> Actualizar FE

```bash
# 1. En Amatista-be/ — hacer cambios, migrar, verificar
source .venv/bin/activate
python manage.py makemigrations && python manage.py migrate
python manage.py check

# 2. Regenerar OpenAPI schema
python manage.py spectacular --color --file ../Amatista-fe/openapi-schema.yaml

# 3. En Amatista-fe/ — regenerar hooks y tipos
pnpm orval

# 4. Verificar que el frontend compila
pnpm typecheck
pnpm build
```

---

## URLs DE DESARROLLO

| Servicio | URL |
|----------|-----|
| Backend API | http://127.0.0.1:8000/api/v1/ |
| Admin Django | http://127.0.0.1:8000/admin/ |
| Swagger UI | http://127.0.0.1:8000/api/docs/ |
| Frontend Dev | http://localhost:5173/ |
| Flower (Celery) | http://localhost:5555/ |

---

## PROBLEMAS COMUNES

### "Port already in use"
```bash
lsof -i :8000 && kill -9 <PID>   # Backend
lsof -i :5173 && kill -9 <PID>   # Frontend
```

### "Orval genera tipos incorrectos"
El problema esta en el backend. Corregir el serializer o el @extend_schema, luego:
```bash
python manage.py spectacular --color --file ../Amatista-fe/openapi-schema.yaml
cd ../Amatista-fe && pnpm orval
```

### "Redis no conecta en dev"
```bash
sudo systemctl start valkey
# Los tests usan LocMemCache (no necesitan Redis)
```

### Tests fallan por migraciones pendientes
```bash
python manage.py showmigrations | grep "\[ \]"
python manage.py migrate
pytest tests/
```
