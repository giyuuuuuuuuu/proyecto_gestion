# Mini gestor de tareas (Flask + PostgreSQL)

Proyecto de aprendizaje: autenticación segura y acceso controlado a PostgreSQL.

## Requisitos

- Python 3.11+
- PostgreSQL 17+ (local)

## Fase 0 — Preparación

### 1. Entorno virtual y dependencias

```powershell
cd proyecto_gestión
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Base de datos PostgreSQL

Copia las variables de entorno (si aún no tienes `.env`):

```powershell
copy .env.example .env
```

Crea el usuario y la base de datos (te pedirá la contraseña de `postgres`):

```powershell
.\scripts\setup_postgres.ps1
```

Credenciales de la app (desarrollo):

| Recurso | Valor |
|---------|--------|
| Usuario | `gestion_app` |
| Contraseña | `gestion_dev_pass` |
| Base de datos | `gestion_db` |

### 3. Comprobar conexión

```powershell
.\venv\Scripts\python scripts\check_db.py
```

### 4. Arrancar Flask (esqueleto)

```powershell
.\venv\Scripts\python app.py
```

Abre http://127.0.0.1:5000/

## Estructura

```
app.py          # Rutas Flask
db.py           # Conexión PostgreSQL
auth.py         # Login (Fase 3)
templates/      # HTML Jinja2
static/
schema.sql      # Tablas (Fase 2)
seed.py         # Usuario de prueba (Fase 2)
scripts/        # init_db, check_db, setup
```

## Siguiente paso

**Fase 1:** plantillas `login.html` y `dashboard.html` con Tailwind CDN.
