# Borrador de documentación del proyecto — Fase 0

**Proyecto:** Mini gestor de tareas con login seguro  
**Stack:** Flask + PostgreSQL + HTML/Tailwind (previsto)  
**Estado actual:** Fase 0 completada (preparación). Fases 1–5 pendientes.  
**Audiencia:** Este documento está pensado para que cualquier compañero del equipo pueda entender qué hay en la carpeta del proyecto, cómo se montó, qué problemas aparecieron y cómo resolverlos.

> **Nota:** Este archivo está en `.gitignore` y no se sube al repositorio. Es un borrador interno de trabajo (estilo memoria o ensayo de proyecto final). El README público del repo sigue siendo la guía corta de arranque.

---

## 1. Objetivo del proyecto

La idea central del trabajo (definida en `ideas/ideas.md`) no es construir una aplicación enorme, sino demostrar:

1. **Autenticación segura** (contraseñas hasheadas, sesiones, rutas protegidas).
2. **Acceso controlado a PostgreSQL** (consultas parametrizadas, cada usuario solo ve sus datos).

La funcionalidad elegida es un **mini gestor de tareas**: crear, listar y marcar tareas. Es simple, obliga a usar login y encaja con tablas `users` y `tasks` que se crearán en la Fase 2.

El orden de implementación acordado es:

```
.env + PostgreSQL → schema + seed → login → proteger rutas → CRUD tareas
```

**Importante:** primero que sin login no se acceda a datos sensibles; después el CRUD de tareas.

---

## 2. Qué se hizo en la Fase 0

La Fase 0 es la **preparación del entorno**: Python, dependencias, PostgreSQL, variables de entorno y estructura de carpetas. No hay pantallas HTML todavía ni tablas en la base de datos.

| Tarea | Estado |
|-------|--------|
| Entorno virtual `venv/` | Hecho |
| Dependencias en `requirements.txt` | Hecho |
| Archivo `.env` (local, no en Git) | Hecho en cada máquina |
| Plantilla `.env.example` (sí compartible) | Hecho |
| Scripts de creación y prueba de PostgreSQL | Hecho |
| Esqueleto Flask que responde en `/` | Hecho |
| `schema.sql` y `seed.py` | Vacíos (Fase 2) |
| `auth.py` con login | Vacío (Fase 3) |

---

## 3. Estructura de la carpeta del proyecto

```
proyecto_gestión/
├── app.py                 # Servidor Flask (rutas)
├── db.py                  # Conexión a PostgreSQL
├── auth.py                # Autenticación (pendiente Fase 3)
├── requirements.txt       # Dependencias Python
├── .env                   # Secretos locales (NO en Git)
├── .env.example           # Plantilla para copiar
├── .gitignore             # Qué no subir al repo
├── README.md              # Guía rápida de arranque
├── borrador_documento.md  # Este documento (NO en Git)
├── schema.sql             # Tablas (Fase 2)
├── seed.py                # Usuario de prueba (Fase 2)
├── templates/             # HTML Jinja2 (Fase 1)
├── static/                # CSS, imágenes (favicon, etc.)
├── scripts/
│   ├── init_db.sql        # SQL: usuario y base de datos
│   ├── setup_postgres.ps1 # Ejecuta init_db con psql
│   └── check_db.py        # Prueba la conexión
├── ideas/
│   └── ideas.md           # Planificación y fases del proyecto
└── venv/                  # Entorno virtual (NO en Git)
```

Las carpetas `templates/` y `static/` tienen un archivo `.gitkeep` para que Git guarde la carpeta vacía hasta que haya plantillas o archivos estáticos.

---

## 4. Dependencias Python (`requirements.txt`)

```1:4:requirements.txt
flask>=3.0,<4
psycopg[binary]>=3.1,<4
bcrypt>=4.1,<5
python-dotenv>=1.0,<2
```

| Paquete | Para qué sirve en el proyecto |
|---------|-------------------------------|
| **flask** | Servidor web, rutas, sesiones, plantillas Jinja2 (Fase 1+). |
| **psycopg** | Driver moderno para conectar Python con PostgreSQL. |
| **bcrypt** | Hashear contraseñas antes de guardarlas en la BBDD (Fase 2–3). |
| **python-dotenv** | Cargar variables desde `.env` sin hardcodear secretos en el código. |

### Instalación (cada desarrollador en su PC)

```powershell
cd proyecto_gestión
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 5. Variables de entorno (`.env` y `.env.example`)

Los secretos **no van en el código**. Van en `.env`, que está listado en `.gitignore`:

```9:10:.gitignore
# Variables de entorno (credenciales)
.env
```

### Plantilla compartible (`.env.example`)

```1:3:.env.example
# Copiar a .env y ajustar valores
DATABASE_URL=postgresql://gestion_app:gestion_dev_pass@localhost:5432/gestion_db
SECRET_KEY=genera-una-clave-larga-y-aleatoria-aqui
```

| Variable | Significado |
|----------|-------------|
| `DATABASE_URL` | Cadena de conexión PostgreSQL: usuario, contraseña, host, puerto y nombre de base. |
| `SECRET_KEY` | Clave secreta de Flask para firmar cookies de sesión. Debe ser larga y aleatoria. |

**Para un compañero nuevo:**

1. Clonar el repo.
2. `copy .env.example .env`
3. Generar su propia `SECRET_KEY` (o acordar una solo para pruebas locales en equipo).
4. Mantener el mismo `DATABASE_URL` si cada uno usa PostgreSQL **en su propio PC** con el script `setup_postgres.ps1`.

**No compartir por Git:** el archivo `.env` real ni la contraseña del superusuario `postgres` de Windows.

---

## 6. Conexión a la base de datos (`db.py`)

Este módulo centraliza la conexión. Cualquier script o ruta Flask que necesite PostgreSQL debería usar `get_connection()`.

```1:16:db.py
"""Conexión a PostgreSQL."""
import os

import psycopg
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


def get_connection():
    """Abre una conexión usando DATABASE_URL del entorno."""
    if not DATABASE_URL:
        raise RuntimeError("DATABASE_URL no está definida en .env")
    return psycopg.connect(DATABASE_URL)
```

**Flujo:**

1. `load_dotenv()` lee el archivo `.env` de la raíz del proyecto.
2. `DATABASE_URL` se obtiene del entorno.
3. Si falta, se lanza un error claro (evita conectar con valores vacíos).
4. `psycopg.connect(DATABASE_URL)` abre la conexión.

En fases posteriores, las consultas deberán usar **parámetros** (`%s`), nunca concatenar strings con datos del usuario, para evitar inyección SQL.

---

## 7. Cómo se configuró PostgreSQL correctamente

En Windows el equipo tenía **PostgreSQL 17 en ejecución** (servicio `postgresql-x64-17`). La versión 18 estaba instalada pero parada. Por eso el script de setup busca primero `psql` en la carpeta de la versión 17.

### 7.1. Dos usuarios distintos (origen de muchas confusiones)

| Usuario | Quién es | Contraseña |
|---------|----------|------------|
| **postgres** | Superusuario de la instalación PostgreSQL | La que pusiste **al instalar** PostgreSQL en Windows |
| **gestion_app** | Usuario solo para esta aplicación | `gestion_dev_pass` (definida en `init_db.sql` y en `.env`) |

El script `setup_postgres.ps1` pide la contraseña de **`postgres`**, no la de `gestion_app`.

### 7.2. Script SQL (`scripts/init_db.sql`)

```4:17:scripts/init_db.sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'gestion_app') THEN
    CREATE ROLE gestion_app WITH LOGIN PASSWORD 'gestion_dev_pass';
  ELSE
    ALTER ROLE gestion_app WITH LOGIN PASSWORD 'gestion_dev_pass';
  END IF;
END
$$;

SELECT 'CREATE DATABASE gestion_db OWNER gestion_app ENCODING ''UTF8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gestion_db')\gexec

GRANT ALL PRIVILEGES ON DATABASE gestion_db TO gestion_app;
```

- El bloque `DO $$ ... $$` crea el rol `gestion_app` si no existe; si ya existe, actualiza la contraseña a la de desarrollo.
- La línea con `\gexec` es sintaxis de **psql**: solo crea la base `gestion_db` si aún no existe.
- `GRANT` da permisos al usuario de la app sobre esa base.

### 7.3. Script PowerShell (`scripts/setup_postgres.ps1`)

```18:31:scripts/setup_postgres.ps1
$secure = Read-Host "Contraseña del usuario postgres" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

$initSql = Join-Path $PSScriptRoot "init_db.sql"
& $psql -U postgres -h localhost -f $initSql

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falló la inicialización de PostgreSQL (código $LASTEXITCODE)."
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host "Listo: usuario gestion_app y base de datos gestion_db."
```

**Qué hace:** pide la contraseña de `postgres`, la pasa temporalmente en `PGPASSWORD`, ejecuta `init_db.sql` y borra la variable del entorno por seguridad.

**Ejecución:**

```powershell
.\scripts\setup_postgres.ps1
```

### 7.4. Comprobar que la conexión funciona (`scripts/check_db.py`)

```10:25:scripts/check_db.py
def main() -> int:
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version();")
                version = cur.fetchone()[0]
        print("Conexión OK.")
        print(version)
        return 0
    except Exception as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        print(
            "Si aún no creaste la BBDD, ejecuta: .\\scripts\\setup_postgres.ps1",
            file=sys.stderr,
        )
        return 1
```

El script añade la raíz del proyecto al `sys.path` para poder importar `db` desde la carpeta `scripts/`:

```5:7:scripts/check_db.py
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from db import get_connection
```

**Ejecución desde la raíz del proyecto:**

```powershell
.\venv\Scripts\python scripts\check_db.py
```

Si todo está bien, verás `Conexión OK.` y la versión de PostgreSQL.

---

## 8. Problemas encontrados y cómo se solucionaron

### 8.1. `psql` no reconocido en la terminal

**Síntoma:** al escribir `psql` en PowerShell: *“no se reconoce como nombre de cmdlet”*.

**Causa:** PostgreSQL está instalado en `C:\Program Files\PostgreSQL\17\bin\` pero esa ruta no está en el `PATH` de Windows.

**Solución:** usar la ruta completa dentro de `setup_postgres.ps1`, o añadir `...\PostgreSQL\17\bin` al PATH del sistema. El script ya busca `psql.exe` automáticamente.

---

### 8.2. El comando `psql -U postgres` se quedaba colgado

**Síntoma:** al probar conexión automática, el proceso no terminaba.

**Causa:** PostgreSQL en este equipo usa autenticación `scram-sha-256` en `pg_hba.conf`; `psql` esperaba contraseña de forma interactiva y el entorno automatizado no podía introducirla.

**Solución:** script `setup_postgres.ps1` que pide la contraseña con `Read-Host -AsSecureString` y usa `PGPASSWORD` solo durante la ejecución.

---

### 8.3. Error `UnicodeDecodeError` con `psycopg2`

**Síntoma:** al conectar con `psycopg2-binary`, Python fallaba con:

```text
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xf3 in position 85
```

**Causa:** en Windows, cuando PostgreSQL devuelve mensajes de error en **español** (por ejemplo “la autentificación password falló…”), `psycopg2` a veces no decodifica bien esos bytes (codificación del sistema vs UTF-8).

**Solución:** cambiar el driver a **`psycopg` versión 3** (`psycopg[binary]` en `requirements.txt`). El plan del proyecto ya permitía “psycopg2 o psycopg”. Con `psycopg` los errores se muestran correctamente y la conexión es estable en Windows.

**Lección:** si un compañero en Linux usa `psycopg2` sin problema, en Windows conviene mantener `psycopg` v3 como en este repo.

---

### 8.4. “¿Qué contraseña pongo en setup_postgres?”

**Respuesta:** la del usuario **`postgres`** de tu instalación local (la del instalador de PostgreSQL), **no** `gestion_dev_pass`. Esa última es solo para el usuario de la aplicación y ya va en `.env` después de ejecutar el script.

---

### 8.5. Flask “se queda” y no devuelve el prompt

**Síntoma:** al ejecutar `python app.py`, la terminal no vuelve al cursor.

**Causa:** es el comportamiento **normal** de un servidor web: sigue en ejecución escuchando en el puerto 5000.

**Qué hacer:**

- **Mantener la terminal abierta** mientras uses http://127.0.0.1:5000/
- **Ctrl+C** para parar Flask
- **No cerrar la terminal** si quieres seguir probando; al cerrarla, el proceso Flask termina

```18:19:app.py
if __name__ == "__main__":
    app.run(debug=True, port=5000)
```

`debug=True` recarga el código al guardar cambios (útil en desarrollo; en producción se desactiva).

---

### 8.6. Autenticación fallida para `gestion_app` antes de ejecutar el setup

**Síntoma:** `check_db.py` o `psycopg` muestran que falló la autenticación para `gestion_app`.

**Causa:** la base de datos o el usuario de la app aún no existen, o `.env` no coincide con lo creado en `init_db.sql`.

**Solución:** ejecutar `.\scripts\setup_postgres.ps1` y comprobar que `DATABASE_URL` en `.env` coincide con `.env.example`.

---

## 9. Aplicación Flask (`app.py`)

Por ahora es un **esqueleto** de la Fase 0: carga variables de entorno, configura la clave de sesión y expone una ruta de prueba.

```1:19:app.py
"""Aplicación Flask — mini gestor de tareas."""
import os

from dotenv import load_dotenv
from flask import Flask

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "dev-only-change-me")


@app.route("/")
def index():
    return "Proyecto gestión — Fase 0 lista. Siguiente: Fase 1 (plantillas).", 200


if __name__ == "__main__":
    app.run(debug=True, port=5000)
```

| Línea / bloque | Función |
|----------------|---------|
| `load_dotenv()` | Carga `.env` antes de leer `SECRET_KEY`. |
| `app.secret_key` | Necesaria para `flask.session` en Fase 3 (cookies firmadas). |
| `@app.route("/")` | Ruta temporal hasta tener `dashboard.html`. |
| `app.run(debug=True, port=5000)` | Arranca el servidor de desarrollo en el puerto 5000. |

**Arranque:**

```powershell
.\venv\Scripts\Activate.ps1
python app.py
```

Abrir en el navegador: http://127.0.0.1:5000/

---

## 10. Archivos preparados para fases futuras

### 10.1. `auth.py` (Fase 3 — login y rutas protegidas)

```1:1:auth.py
"""Autenticación y protección de rutas. Se completará en la Fase 3."""
```

Aquí irán funciones como:

- Hashear y verificar contraseñas con `bcrypt`.
- Decorador `@login_required` que redirija a `/login` si no hay sesión.

### 10.2. `schema.sql` (Fase 2 — tablas)

```1:1:schema.sql
-- Fase 2: tablas users y tasks (pendiente de aplicar)
```

Se definirán tablas `users` (email, `password_hash`) y `tasks` (`user_id`, título, `done`), con clave foránea y `ON DELETE CASCADE`.

### 10.3. `seed.py` (Fase 2 — usuario de prueba)

```1:1:seed.py
"""Fase 2: usuario de prueba con contraseña hasheada (pendiente)."""
```

Insertará un usuario de desarrollo con contraseña ya hasheada (nunca en texto plano en PostgreSQL).

### 10.4. `templates/` y `static/` (Fase 1)

Vacíos salvo `.gitkeep`. En Fase 1 se crearán `base.html`, `login.html` y `dashboard.html` con Tailwind vía CDN.

---

## 11. Trabajo en equipo: qué compartir con un compañero

| Compartir | No compartir por Git/chat público |
|-----------|-----------------------------------|
| Repositorio Git (código) | Archivo `.env` |
| `.env.example` y este borrador (si lo pasáis por otro canal) | Contraseña de `postgres` de tu PC |
| README.md | |
| Que ejecute `setup_postgres.ps1` en su máquina | |

Cada persona:

1. Clona el repo.
2. Crea su `venv` e instala `requirements.txt`.
3. `copy .env.example .env` y ajusta `SECRET_KEY` si quiere.
4. Ejecuta `setup_postgres.ps1` con **su** contraseña de `postgres`.
5. `python scripts\check_db.py` → debe decir `Conexión OK.`
6. `python app.py` y prueba en el navegador.

Así todos tienen el **mismo usuario de aplicación** (`gestion_app`) y la **misma base** (`gestion_db`) en PostgreSQL local, sin compartir el superusuario.

---

## 12. Guía rápida de resolución de problemas

| Problema | Qué comprobar |
|----------|----------------|
| `DATABASE_URL no está definida` | Existe `.env` en la raíz y contiene `DATABASE_URL=...` |
| Fallo autenticación `gestion_app` | ¿Ejecutaste `setup_postgres.ps1`? ¿`.env` coincide con `.env.example`? |
| Fallo autenticación `postgres` | Contraseña incorrecta; prueba la de la instalación o pgAdmin |
| `psql` no encontrado | Edita rutas en `setup_postgres.ps1` o instala PostgreSQL |
| Puerto 5000 ocupado | Cierra otro Flask o cambia `port=5001` en `app.py` |
| Página no carga tras cerrar terminal | Flask se detuvo; vuelve a ejecutar `python app.py` |
| `UnicodeDecodeError` con psycopg2 | Usar `psycopg` v3 como en `requirements.txt` actual |

---

## 13. Próximas fases (roadmap)

Resumen según `ideas/ideas.md`:

| Fase | Contenido |
|------|-----------|
| **1** | Plantillas HTML + Tailwind (`login`, `dashboard`) |
| **2** | `schema.sql`, `seed.py`, tablas y usuario de prueba |
| **3** | Login, logout, `@login_required`, sesión Flask |
| **4** | CRUD de tareas filtrando siempre por `user_id` de sesión |
| **5** | Mensajes flash, 404, README ampliado |

---

## 14. Conclusión

La Fase 0 dejó el proyecto **listo para desarrollar encima**: entorno Python aislado, dependencias instaladas, conexión a PostgreSQL probada con scripts, secretos fuera del código y estructura de carpetas alineada con el plan del mini gestor de tareas.

Los puntos críticos para el equipo son:

1. Diferenciar contraseña de **`postgres`** (setup) y de **`gestion_app`** (aplicación en `.env`).
2. No subir `.env` ni este `borrador_documento.md` al repositorio si contienen notas internas sensibles.
3. Usar **`psycopg` v3** en Windows para evitar errores de codificación con mensajes en español.
4. Entender que **Flask debe seguir ejecutándose** en una terminal mientras se prueba en el navegador.

Cuando la Fase 1 empiece, este documento debería ampliarse con las plantillas Jinja2 y ejemplos de rutas que rendericen HTML.

---

*Documento generado como borrador de memoria técnica — Fase 0. Actualizar al completar cada fase.*
