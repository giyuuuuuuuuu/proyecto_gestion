# Fase 0 — Preparación del laboratorio

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md)  
**Duración orientativa:** 1 sesión (2–4 h)  
**Siguiente fase:** [fase1.md](fase1.md)

---

## Objetivo

Tener el entorno virtual listo: hipervisor, ISOs, tabla de IPs y red **aislada** del resto de tu red doméstica. Al terminar, todas las VMs existen (aunque aún no estén configuradas por completo).

---

## Decisiones a tomar (rellenar antes de empezar)

| Decisión | Tu elección | Notas |
|----------|-------------|-------|
| Hipervisor | VirtualBox / VMware / Proxmox | |
| IDS | **Suricata en pfSense** ☐ | No VM `ids-suricata` (recomendación tutor) |
| Syslog | Docker en host ☐ / VM `srv-syslog` ☐ | Ver `lab/docker-compose.syslog.yml` |
| Servidor web DMZ | Debian + script vulnerabilidades ☐ | `lab/scripts/seed-vulnerabilities.sh` |
| ¿Integrar app Flask? | Sí ☐ / No ☐ | Opcional en LAN; DMZ vulnerable aparte |

---

## Tabla de IPs (plantilla — copia y ajusta)

| Hostname | Rol | Interfaz / red | IP | Gateway |
|----------|-----|----------------|-----|---------|
| `fw-pfsense` | Firewall | WAN | `10.0.0.1/24` | — |
| `fw-pfsense` | Firewall | LAN | `192.168.10.1/24` | — |
| `fw-pfsense` | Firewall | DMZ (OPT1) | `192.168.20.1/24` | — |
| `srv-syslog` | Syslog (o Docker host) | LAN | `192.168.10.5/24` | `192.168.10.1` |
| `srv-db` | PostgreSQL | LAN | `192.168.10.20/24` | `192.168.10.1` |
| `ws-corp` | Cliente | LAN | `192.168.10.50/24` | `192.168.10.1` |
| `srv-dmz` | Web | DMZ | `192.168.20.10/24` | `192.168.20.1` |
| `kali-pentest` | Pentest | WAN | `10.0.0.50/24` | `10.0.0.1` |

Guarda esta tabla en `lab/evidencias/fase0/tabla-ips.md` (o en un cuaderno del proyecto).

---

## Tareas

### 0.1 — Hipervisor y recursos

- [ ] Instalar o verificar VirtualBox / VMware / Proxmox.
- [ ] Comprobar RAM libre (mínimo **8 GB** recomendado; ideal 16 GB).
- [ ] Comprobar espacio en disco (≥ **60 GB** libres para todas las VMs).

### 0.2 — Descargar ISOs

- [ ] [pfSense CE](https://www.pfsense.org/download/) (AMD64, ISO installer).
- [ ] Debian 12 o Ubuntu Server 22.04 (para `srv-dmz`, `srv-db`, `srv-syslog` opcional).
- [ ] Docker Desktop (opcional, para Syslog con `lab/docker-compose.syslog.yml`).
- [ ] [Kali Linux](https://www.kali.org/get-kali/) (solo para el laboratorio).
- [ ] Opcional: Windows 10/11 ISO para `ws-corp` (o reutilizar otra VM Linux).

### 0.3 — Red virtual aislada

El lab **no** debe escanear tu red de casa ni la de la universidad sin autorización.

**VirtualBox (ejemplo):**

- [ ] Crear red **Host-Only** `vboxnet0` → adaptador `192.168.56.1/24` (solo gestión, opcional).
- [ ] Crear red **Interna** `lab-wan` para WAN simulada.
- [ ] Crear red **Interna** `lab-lan` para LAN corporativa.
- [ ] Crear red **Interna** `lab-dmz` para DMZ.

**Asignación de adaptadores (plan):**

| VM | Adaptador 1 | Adaptador 2 | Adaptador 3 |
|----|-------------|-------------|-------------|
| pfSense | `lab-wan` | `lab-lan` | `lab-dmz` |
| srv-syslog, srv-db, ws-corp | `lab-lan` | — | — |
| srv-dmz | `lab-dmz` | — | — |
| kali | `lab-wan` | — | — |

- [ ] Documentar con captura el esquema de redes del hipervisor.

### 0.4 — Crear VMs (solo creación, sin instalar aún todo)

| VM | vCPU | RAM | Disco |
|----|------|-----|-------|
| `fw-pfsense` | 2 | **2 GB** | 20 GB |
| `srv-dmz` | 1 | 1 GB | 16 GB |
| `srv-db` | 1 | 1 GB | 16 GB |
| `srv-syslog` | 1 | 512 MB | 8 GB |
| `ws-corp` | 1 | 2 GB | 30 GB (opcional) |
| `kali-pentest` | 2 | 2 GB | 40 GB |

- [ ] Crear las **5–6** VMs (sin VM IDS dedicada).
- [ ] Copiar al repo o a Kali: `lab/scripts/attack-lab.sh` y `lab/scripts/seed-vulnerabilities.sh`.

### 0.5 — Documentación y ética

- [ ] Leer sección *Riesgos y límites legales* en `idea_2.md`.
- [ ] Obtener autorización del profesor para pentest (Fase 4) si la exige el centro.
- [ ] Crear carpeta `lab/evidencias/fase0/` y guardar tabla de IPs + capturas.

### 0.6 — Repositorio (opcional)

- [ ] Crear `lab/README.md` con hipervisor usado y versión de ISOs.
- [ ] Añadir `lab/evidencias/` al `.gitignore` si las capturas son muy pesadas.

---

## Comandos útiles (verificación local)

Solo en tu PC, no sustituyen el lab:

```bash
# Ver interfaces (macOS/Linux)
ifconfig | grep -E "inet |flags"

# Ping entre VMs se hará en Fase 1, cuando pfSense esté arriba
```

---

## Criterios de cierre (no pasar a Fase 1 sin esto)

- [ ] Hipervisor operativo con VMs creadas (pfSense con ≥2 GB RAM).
- [ ] Tres redes internas (WAN, LAN, DMZ) definidas y asignadas a pfSense.
- [ ] Tabla de IPs completa y guardada.
- [ ] ISOs descargadas y montables.
- [ ] Compromiso documentado: pentest **solo** contra IPs del lab.

---

## Evidencias a entregar / guardar

| Archivo | Contenido |
|---------|-----------|
| `tabla-ips.md` | IPs finales de cada VM |
| `red-hipervisor.png` | Captura de redes virtuales |
| `vms-creadas.png` | Lista de VMs en el hipervisor |

---

## Problemas frecuentes

| Problema | Solución |
|----------|----------|
| Poca RAM | Apagar `ws-corp` cuando no la uses; reducir RAM de Kali a 2 GB |
| VMs sin red entre sí | Revisar que pfSense tenga las 3 interfaces en redes **internal** distintas |
| Mac con Apple Silicon | pfSense amd64 puede ir lento; valorar pfSense en Proxmox/x86 o hardware viejo |

---

**Siguiente:** [fase1.md](fase1.md) — Instalar pfSense y configurar firewall perimetral.
