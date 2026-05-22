# Fase 2 — Servicios corporativos (DMZ + LAN)

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md)  
**Requisito:** [fase1.md](fase1.md) completada  
**Duración orientativa:** 1 sesión  
**Siguiente fase:** [fase3.md](fase3.md)

---

## Objetivo

Levantar el **servidor web en DMZ**, sembrar **vulnerabilidades intencionadas** (script del repo), configurar **PostgreSQL en LAN** con contraseña débil documentada, y verificar segmentación (WAN no llega a BD). Sin fallos controlados, Kali y Suricata apenas generarán hallazgos.

---

## Tareas

### 2.1 — Servidor web en DMZ (`srv-dmz`)

**IP:** `192.168.20.10/24` — Gateway `192.168.20.1`

- [ ] Instalar Debian/Ubuntu y configurar red estática en DMZ.
- [ ] Copiar el repo o solo el script al servidor DMZ.
- [ ] Ejecutar vulnerabilidades de práctica (**solo lab**):

```bash
sudo bash lab/scripts/seed-vulnerabilities.sh
```

Esto instala nginx+PHP, `/search.php` vulnerable, `/backup/` con autoindex, `phpinfo.php`, SSH `lab`/`lab123`, FTP anónimo.

- [ ] Verificar: `curl http://127.0.0.1/search.php?q=test` y `curl http://127.0.0.1/backup/`
- [ ] Comprobar localmente: `curl http://127.0.0.1`
- [ ] Desde `ws-corp` (LAN): `curl http://192.168.20.10`
- [ ] Desde Kali (WAN): `curl http://10.0.0.1` o IP WAN publicada según NAT → debe mostrar la misma página vía NAT.

**Opcional — HTTPS:**

- [ ] Certificado autofirmado con `openssl` para practicar regla 443 en pfSense.

**Opcional — App Flask (`ideas/ideas.md`):**

- [ ] Desplegar el mini gestor en LAN (`192.168.10.30`) y poner nginx en DMZ como **reverse proxy** solo a rutas públicas; documentar arquitectura.

### 2.2 — PostgreSQL en LAN (`srv-db`)

**IP:** `192.168.10.20/24` — Solo interfaz LAN.

```bash
sudo apt update
sudo apt install -y postgresql
```

- [ ] Editar `postgresql.conf`: `listen_addresses = '192.168.10.20'` (o `*` solo si controlas `pg_hba.conf`).
- [ ] Editar `pg_hba.conf` — permitir solo LAN:

```
# TYPE  DATABASE  USER  ADDRESS           METHOD
host    all       all   192.168.10.0/24   scram-sha-256
```

- [ ] Reiniciar: `sudo systemctl restart postgresql`
- [ ] Crear usuario y BD de prueba:

```bash
sudo -u postgres psql -c "CREATE USER lab_app WITH PASSWORD 'LabDevOnly1!';"
sudo -u postgres psql -c "CREATE DATABASE corp_db OWNER lab_app;"
# Contraseña DÉBIL intencional para hallazgo de auditoría (solo lab):
sudo -u postgres psql -c "ALTER USER lab_app PASSWORD '1234';"
```

- [ ] Documentar en `lab/evidencias/fase2/vulnerabilidades-intencionadas.md` la lista de fallos introducidos (ver tabla en `idea_2.md`).

- [ ] Confirmar que PostgreSQL **escucha** en 5432: `ss -tlnp | grep 5432`

### 2.3 — Cliente corporativo (`ws-corp`) — opcional pero útil

- [ ] VM en LAN `192.168.10.50/24`.
- [ ] Probar acceso a portal: navegador o `curl http://192.168.20.10`.
- [ ] Probar acceso a BD desde LAN (debe funcionar):

```bash
# Si tienes cliente psql
psql -h 192.168.10.20 -U lab_app -d corp_db
```

### 2.4 — Pruebas de segmentación (obligatorias)

Desde **Kali (WAN)** — todo debe **fallar** hacia BD:

```bash
nmap -p 5432 -Pn 192.168.10.20
nc -zv -w 3 192.168.10.20 5432
ping -c 2 192.168.10.20
```

Desde **srv-dmz (DMZ)** — hacia BD debe **fallar**:

```bash
nmap -p 5432 -Pn 192.168.10.20
nc -zv -w 3 192.168.10.20 5432
```

Desde **LAN** — hacia BD debe **funcionar**:

```bash
nmap -p 5432 -Pn 192.168.10.20
```

- [ ] Guardar las tres salidas en `lab/evidencias/fase2/segmentacion-bd.txt`.
- [ ] Captura de reglas pfSense #6, #7, #8 aplicadas.

### 2.5 — Endurecimiento básico de servicios

- [ ] `srv-dmz`: deshabilitar SSH desde WAN (si SSH existe, solo desde LAN con regla futura).
- [ ] Ocultar versión nginx en `nginx.conf` (`server_tokens off;`) — hallazgo menor para Fase 4.
- [ ] `srv-db`: no instalar paquetes innecesarios; firewall local opcional (`ufw allow from 192.168.10.0/24 to any port 5432`).

### 2.6 — Inventario de activos (inicio del informe)

Crear `lab/evidencias/fase2/inventario-activos.md`:

| Activo | IP | SO | Servicios | Zona | Propietario ficticio |
|--------|-----|-----|-----------|------|----------------------|
| fw-pfsense | … | pfSense | firewall | Perímetro | IT |
| srv-dmz | 192.168.20.10 | Debian | nginx:80 | DMZ | Marketing/IT |
| srv-db | 192.168.10.20 | Debian | postgresql:5432 | LAN | DBA |
| … | | | | | |

---

## Criterios de cierre

- [ ] `seed-vulnerabilities.sh` ejecutado; SSH/FTP/web vulnerables operativos.
- [ ] Portal HTTP responde en DMZ y es alcanzable desde LAN y WAN (según NAT/reglas).
- [ ] PostgreSQL activo **solo** en LAN; contraseña débil documentada.
- [ ] Kali y srv-dmz **no** conectan a puerto 5432 de srv-db.
- [ ] LAN **sí** conecta a 5432.
- [ ] Inventario de activos iniciado.

---

## Evidencias

| Archivo | Descripción |
|---------|-------------|
| `index-dmz.html` o captura | Página corporativa |
| `segmentacion-bd.txt` | nmap/nc desde WAN, DMZ, LAN |
| `inventario-activos.md` | Tabla de activos |
| `pg_hba.conf` | Fragmento (sin contraseñas) |

---

## Problemas frecuentes

| Problema | Solución |
|----------|----------|
| curl desde Kali no llega | Revisar NAT 80 y regla WAN→DMZ; probar `curl http://192.168.20.10` desde LAN primero |
| nmap a BD desde LAN falla | `pg_hba`, `listen_addresses`, regla pfSense #6 |
| DMZ alcanza BD | Falta regla #7 o ruta incorrecta entre interfaces |

---

**Anterior:** [fase1.md](fase1.md)  
**Siguiente:** [fase3.md](fase3.md) — IDS/IPS con Suricata o Snort.
