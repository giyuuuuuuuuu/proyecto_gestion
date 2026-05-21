# Ideas del proyecto

## Idea central

Queremos hacer una página web con inicio de sesión con una funcionalidad X no debe de ser muy compleja, puedes inventartela si quieres ya que la funcionalidad principal es el inicio de sesión y la puesta en practica para proteger la BBDD que estará por detrás de esta página.

Esa es la idea central: aprender y demostrar **autenticación segura** y **acceso controlado a PostgreSQL**, no construir un producto enorme.

---

## Funcionalidad X recomendada: mini gestor de tareas

Encaja bien con el objetivo del proyecto:

| Criterio | Por qué encaja |
|----------|----------------|
| Simple | Crear, listar y marcar tareas como hechas |
| Necesita login | Cada usuario solo ve sus tareas |
| Usa la BBDD | Tablas `users` y `tasks` con relación clara |
| Demuestra seguridad | Consultas parametrizadas, sesiones, rutas protegidas |

**Alternativas igual de válidas** (si prefieres cambiar el tema):

1. **Lista de contactos personales** — nombre, email, teléfono.
2. **Registro de gastos** — concepto, importe, fecha.
3. **Inventario básico** — producto, cantidad, notas.

Recomendación: quedarse con **tareas**. Es la más rápida de implementar y de probar.

---

## Stack acordado

| Capa | Tecnología | Rol |
|------|------------|-----|
| Interfaz | HTML + Tailwind CSS (CDN) | Páginas limpias sin montar Node |
| Servidor | Python + **Flask** | Rutas, sesiones, plantillas Jinja2 |
| Base de datos | PostgreSQL | Usuarios y datos de la app |
| Driver | `psycopg2` o `psycopg` | Conexión desde Python |

**Por qué Flask y no FastAPI aquí:** menos conceptos (un solo archivo al inicio, plantillas HTML integradas). El foco es login + BBDD, no una API REST compleja.

---

## Qué debe demostrar el proyecto (seguridad)

Estos puntos son el corazón del ejercicio:

1. **Contraseñas hasheadas** con `bcrypt` (nunca en texto plano en PostgreSQL).
2. **Consultas parametrizadas** (`%s` / placeholders) para evitar inyección SQL.
3. **Sesión en servidor** (`flask.session` + `SECRET_KEY` en variable de entorno).
4. **Rutas protegidas** — decorador o función que redirige a `/login` si no hay sesión.
5. **Variables sensibles en `.env`** — `DATABASE_URL`, `SECRET_KEY` (y `.env` en `.gitignore`).
6. **Cookies seguras** en producción: `HttpOnly`, `SameSite`, `Secure` si hay HTTPS.

---

## Plan rápido (fácil y por fases)

Objetivo: tener algo funcionando en **1–2 días** de trabajo tranquilo.

### Fase 0 — Preparación (30–45 min)

- [ ] Crear entorno virtual Python (`venv`).
- [ ] Instalar dependencias: `flask`, `psycopg2-binary`, `bcrypt`, `python-dotenv`.
- [ ] Crear base de datos en PostgreSQL y usuario de la app.
- [ ] Archivo `.env` con `DATABASE_URL` y `SECRET_KEY`.
- [ ] Estructura mínima de carpetas (ver abajo).

### Fase 1 — Esqueleto web (1–2 h)

- [ ] Página de login (HTML + Tailwind).
- [ ] Página principal con listado de tareas (vacía al principio).
- [ ] Flask sirviendo plantillas y archivos estáticos si hace falta.
- [ ] Tailwind vía CDN en `base.html` para no configurar build.

### Fase 2 — Base de datos (1 h)

```sql
-- users
id          SERIAL PRIMARY KEY
email       VARCHAR(255) UNIQUE NOT NULL
password_hash VARCHAR(255) NOT NULL
created_at  TIMESTAMP DEFAULT NOW()

-- tasks
id          SERIAL PRIMARY KEY
user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE
title       VARCHAR(255) NOT NULL
done        BOOLEAN DEFAULT FALSE
created_at  TIMESTAMP DEFAULT NOW()
```

- [ ] Script `schema.sql` o comando de migración manual.
- [ ] Usuario de prueba creado con script `seed.py` (contraseña hasheada).

### Fase 3 — Login y sesión (2–3 h) ⭐ prioridad

- [ ] `POST /login` — verificar email + bcrypt, crear sesión.
- [ ] `GET /logout` — limpiar sesión.
- [ ] Middleware/decorador `@login_required` en rutas de tareas.
- [ ] Redirección automática: logueado → dashboard; anónimo → login.

### Fase 4 — CRUD de tareas (2 h)

- [ ] `GET /` — listar tareas del `user_id` de la sesión.
- [ ] `POST /tasks` — crear tarea (solo título).
- [ ] `POST /tasks/<id>/toggle` — marcar hecha / pendiente.
- [ ] `POST /tasks/<id>/delete` — borrar (comprobar que `user_id` coincide).

Todas las consultas: **siempre** filtrar por `user_id` de la sesión, nunca confiar en el ID que envía el navegador sin verificar propiedad.

### Fase 5 — Pulido mínimo (1 h)

- [ ] Mensajes flash (error login, éxito al crear tarea).
- [ ] Página 404 simple.
- [ ] README con cómo levantar el proyecto localmente.

### Opcional (solo si sobra tiempo)

- [ ] Registro de nuevos usuarios (`/register`).
- [ ] Validación básica de email y longitud de contraseña.
- [ ] Docker Compose con PostgreSQL para compartir el proyecto fácilmente.

---

## Estructura de carpetas sugerida

```
proyecto_gestión/
├── app.py              # Rutas Flask
├── db.py               # Conexión y helpers SQL
├── auth.py             # login_required, hash, verify
├── templates/
│   ├── base.html
│   ├── login.html
│   └── dashboard.html
├── static/             # (vacío o favicon)
├── schema.sql
├── seed.py
├── requirements.txt
├── .env                # no subir a git
└── ideas/
    └── ideas.md
```

Empezar con **un solo `app.py`** está bien; separar en `db.py` y `auth.py` cuando el archivo supere ~150 líneas.

---

## Orden de implementación (resumen)

```
.env + PostgreSQL → schema + seed → login → proteger rutas → CRUD tareas → mensajes UI
```

No invertir el orden: primero que **sin login no se vea nada de la BBDD**, luego la funcionalidad X.

---

## Criterios de “proyecto terminado”

- [ ] Sin sesión, `/` redirige a login.
- [ ] Con sesión válida, se ven solo las tareas del usuario.
- [ ] Contraseñas en PostgreSQL son hashes bcrypt.
- [ ] No hay credenciales en el código fuente (solo en `.env`).
- [ ] El README explica cómo ejecutar el proyecto en local.

---

## Riesgos a evitar (para ir rápido)

| Evitar | Hacer en su lugar |
|--------|-------------------|
| React, Vue, API separada | HTML + Jinja2 en el mismo Flask |
| ORM complejo (SQLAlchemy) al principio | SQL directo con parámetros |
| JWT si no hace falta | Sesión Flask en cookie firmada |
| Muchas pantallas | Login + dashboard de tareas |
| Registro + recuperar contraseña | Un usuario seed en `seed.py` |

---

## Siguiente paso concreto

1. Confirmar funcionalidad X (**tareas** u otra de la lista).
2. Crear `requirements.txt`, `schema.sql` y `app.py` con la página de login vacía.
3. Conectar PostgreSQL y probar que el seed inserta un usuario.
4. Implementar login antes de cualquier consulta a `tasks`.

Cuando quieras pasar de ideas a código, se puede montar el esqueleto de la Fase 0 y 1 en una sola sesión.
