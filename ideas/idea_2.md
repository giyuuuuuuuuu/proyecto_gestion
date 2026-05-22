# Idea 2 — Seguridad en redes (laboratorio corporativo)

## Objetivo del ejercicio

Diseñar, desplegar y auditar una **red corporativa simulada** en la que se demuestren tres competencias del temario:

1. **IDS/IPS** — detección y, opcionalmente, prevención de intrusiones con **Suricata** o **Snort**.
2. **Firewall perimetral avanzado** — reglas personalizadas en **pfSense** (o firewall de hardware equivalente).
3. **Auditoría y refuerzo** — pruebas de penetración controladas, hallazgos documentados y **plan de mitigación** enlazado a cada riesgo.

No se trata de construir una aplicación grande. El foco es **infraestructura de red**, políticas de seguridad y evidencias (capturas, reglas, alertas, informe).

**Duración orientativa:** 2–3 semanas (o 5–8 sesiones de laboratorio) según profundidad del pentest y del modo IPS.

**Guías paso a paso:** [`fases/`](../fases/README.md) · **Scripts y Syslog:** [`lab/`](../lab/README.md)

---

## Mejoras recomendadas por el tutor (aplicadas en este plan)

| Mejora | Por qué |
|--------|---------|
| **Suricata en pfSense** (Package Manager) | Evita una VM IDS dedicada; el sensor ve el tráfico real del firewall |
| **Vulnerabilidades intencionadas** en DMZ/LAN | Debian/nginx/PostgreSQL actualizados no dan hallazgos al pentest automatizado |
| **Syslog centralizado** (VM o contenedor Docker) | Correlacionar logs de pfSense + Suricata en un solo sitio |
| **Script de ataque en Kali** | Reproducible: escaneo agresivo Nmap + pruebas web/SSH → alertas IDS |

---

## Alcance mínimo (qué debe quedar demostrado)

| Bloque | Entregable mínimo |
|--------|-------------------|
| IDS/IPS | Suricata en **pfSense** (paquete oficial), reglas activas, al menos **5 alertas** reproducibles y documentadas |
| Firewall | pfSense (o HW) con **≥10 reglas** justificadas (WAN/LAN/DMZ, NAT, bloqueos) |
| Auditoría | Informe con metodología, **≥8 hallazgos** (red + servicios), mitigaciones priorizadas |

---

## Topología recomendada (red corporativa simulada)

Laboratorio en **máquinas virtuales** (VirtualBox, VMware o Proxmox). Todas en una red interna aislada del router doméstico (modo host-only / red interna).

```
                         [ Internet simulada ]
                                 |
                          +-------------+
                          |   pfSense   |
                          |  Firewall   |
                          | + Suricata  |  ← IDS/IPS (paquete oficial)
                          +------+------+
                                 |
           +---------------------+---------------------+
           |                     |                     |
     +-----+-----+         +-----+-----+       +-----+-----+
     |   WAN     |         |   LAN     |       |   DMZ     |
     |  Kali     |         | corp.     |       | web vuln. |
     +-----------+         +-----+-----+       +-----------+
                                 |                     |
                          +------+------+      srv-dmz (nginx+PHP)
                          | srv-syslog  |      fallos intencionados
                          |  o Docker   |
                          +-------------+
                                 ^
                    logs UDP 514 (pfSense + Suricata)
```

### Roles de cada VM (plantilla actualizada)

| VM | SO sugerido | Rol | IP ejemplo |
|----|-------------|-----|------------|
| `fw-pfsense` | pfSense CE | Firewall + **Suricata** (Package Manager) + envío Syslog | WAN `10.0.0.1`, LAN `192.168.10.1`, DMZ `192.168.20.1` |
| `srv-syslog` | Debian **o** Docker en host | Centralizar logs pfSense + Suricata | LAN `192.168.10.5` |
| `srv-dmz` | Debian | Web con **vulnerabilidades de práctica** (ver `lab/scripts/seed-vulnerabilities.sh`) | DMZ `192.168.20.10` |
| `srv-db` | Debian | PostgreSQL en LAN; contraseña débil **solo para el lab** | LAN `192.168.10.20` |
| `ws-corp` | Linux opcional | Cliente interno | LAN `192.168.10.50` |
| `kali-pentest` | Kali Linux | Pentest; script `lab/scripts/attack-lab.sh` | WAN `10.0.0.50` |

> **Ya no hace falta** la VM `ids-suricata` dedicada: Suricata corre dentro de pfSense y inspecciona WAN/DMZ/LAN según configures las interfaces en el paquete.

**Regla de oro:** PostgreSQL y datos sensibles **nunca** en DMZ ni con puerto abierto en WAN. El acceso desde Internet solo a servicios publicados en DMZ (p. ej. HTTP/HTTPS).

**Opcional:** reutilizar el mini gestor Flask del otro proyecto (`ideas/ideas.md`) como **aplicación corporativa** en LAN; mantener en DMZ el servidor vulnerable del script para que Kali tenga hallazgos claros.

---

## Vulnerabilidades intencionadas (obligatorio para el pentest)

Un Debian/nginx/PostgreSQL **parcheados** apenas generan hallazgos con Kali automatizado. El lab debe incluir fallos **controlados y documentados** (solo en VMs del ejercicio):

| Activo | Fallo de práctica | Herramienta que lo detecta | Hallazgo informe |
|--------|-------------------|----------------------------|------------------|
| `srv-dmz` | PHP `search.php` sin sanitizar (SQLi/XSS reflejado) | `attack-lab.sh`, nikto | H-web-01 |
| `srv-dmz` | `/backup/` con autoindex | gobuster / curl | H-web-02 |
| `srv-dmz` | `phpinfo.php` expuesto | nikto | H-web-03 |
| `srv-dmz` | SSH usuario `lab` / `lab123` | hydra, Suricata brute | H-ssh-01 |
| `srv-dmz` | FTP anónimo (vsftpd) | nmap, Suricata | H-ftp-01 |
| `srv-dmz` | `server_tokens on` (banner nginx) | nmap -sV | H-web-04 |
| `srv-db` | Contraseña débil en `lab_app` | hydra desde LAN | H-db-01 |
| `fw-pfsense` | Regla temporal demasiado abierta (antes de mitigar) | revisión manual | H-fw-01 |

**Sembrar vulnerabilidades:** en `srv-dmz` ejecutar [`lab/scripts/seed-vulnerabilities.sh`](../lab/scripts/seed-vulnerabilities.sh). En `srv-db`:

```bash
sudo -u postgres psql -c "ALTER USER lab_app PASSWORD '1234';"
```

En la memoria, dejar claro que son **vulnerabilidades introducidas a propósito** para practicar detección y mitigación.

---

## Syslog centralizado (plus)

Objetivo: ver en un solo sitio eventos de **firewall** y **Suricata**.

**Opción A — Contenedor Docker** (en el PC host con IP en LAN, ej. `192.168.10.2`):

```bash
cd lab && docker compose -f docker-compose.syslog.yml up -d
```

**Opción B — VM `srv-syslog`** (`192.168.10.5`) con `rsyslog` escuchando UDP/TCP 514.

**En pfSense:**

- **Status → System Logs → Settings** → Remote Logging → `192.168.10.5` (o IP del host Docker), puerto **514 UDP**.
- **Services → Suricata → Interfaces → WAN** (y DMZ) → habilitar **Send Alerts to System Log** y, si existe, **Syslog output**.

Correlacionar: hora del `attack-lab.sh` ↔ línea en `/var/log/suricata-remote.log` o Alerts en GUI.

---

## Bloque 1 — IDS/IPS (Suricata en pfSense)

### Despliegue recomendado: paquete oficial en pfSense

1. **System → Package Manager → Available Packages** → instalar **Suricata**.
2. **Services → Suricata → Interfaces** — habilitar inspección en **WAN** y **DMZ** (y LAN si quieres ver tráfico interno).
3. **WAN Preview** o modo **IPS** según versión del paquete (empezar en **IDS** si temes cortar tráfico).
4. Actualizar reglas: pestaña **Updates** → **Emerging Threats Open** (o ruleset del curso).
5. **Global Settings** — definir redes:
   - `HOME_NET`: `192.168.10.0/24,192.168.20.0/24`
   - `EXTERNAL_NET`: `10.0.0.0/24` (WAN simulada con Kali)
6. **Alerts** — dejar habilitado el log; enviar copia a Syslog (bloque Syslog más abajo).

### Reglas personalizadas en pfSense

En **Suricata → WAN → Rules → Custom rules** (o archivo Includes), añadir por ejemplo:

```
alert tcp $EXTERNAL_NET any -> $HOME_NET 5432 (msg:"LAB Acceso PostgreSQL desde exterior"; sid:9000001; rev:1;)
alert tcp 10.0.0.50 any -> $HOME_NET any (msg:"LAB Escaneo desde Kali"; flags:S; threshold:type both, track by_src, count 25, seconds 10; sid:9000002; rev:1;)
```

### Script de ataque reproducible (Kali)

Usar [`lab/scripts/attack-lab.sh`](../lab/scripts/attack-lab.sh): escaneo **agresivo** Nmap (`-T4 -p-`), nikto, rutas web vulnerables, SQLi de prueba y hydra SSH acotado. Ejecutar **después** de sembrar vulnerabilidades.

### Tareas concretas

- [ ] Instalar paquete **Suricata** en pfSense (no VM IDS separada salvo que el profesor exija lo contrario).
- [ ] Actualizar reglas ET/Open desde la GUI de Suricata.
- [ ] Configurar `HOME_NET` / `EXTERNAL_NET` acorde a la topología.
- [ ] Crear **≥2 reglas personalizadas** en Suricata (ejemplos arriba).
- [ ] Ejecutar `attack-lab.sh` desde Kali y capturar **≥5 alertas** en **Services → Suricata → Alerts** (+ copia en Syslog).

### Escenarios de prueba para generar alertas (ética: solo en tu lab)

| Prueba | Origen | Qué debe disparar el IDS |
|--------|--------|---------------------------|
| Escaneo de puertos | Kali → DMZ/LAN | `ET SCAN` o regla custom de reconocimiento |
| Fuerza bruta SSH (simulada, pocas pruebas) | Kali → LAN | Regla custom o firma de brute force |
| Acceso HTTP a rutas sospechosas | Kali → `srv-dmz` | SQLi/XSS en URI (reglas ET web) |
| Tráfico a PostgreSQL desde WAN | Kali → IP LAN:5432 | Regla custom “PostgreSQL desde exterior” |
| Tráfico ICMP flood ligero | Kali → LAN | Opcional: detección de abuso ICMP |

### Evidencias Bloque 1

- Captura **Package Manager** con Suricata instalado.
- Captura **Suricata → Alerts** tras ejecutar `attack-lab.sh`.
- Reglas custom pegadas en la memoria (sid 9000001, 9000002).
- Extracto del **Syslog** centralizado correlacionado con el ataque.

---

## Bloque 2 — Firewall perimetral avanzado (pfSense)

### Despliegue

- [ ] Instalar **pfSense CE** en `fw-pfsense` con **tres interfaces**: WAN, LAN, DMZ.
- [ ] Deshabilitar reglas por defecto permisivas en WAN; política **deny by default** salvo lo explícitamente permitido.
- [ ] Activar logging en reglas críticas (firewall log).

### Reglas personalizadas (mínimo 10, con justificación)

Plantilla de reglas que el ejercicio debe implementar y explicar en la memoria:

| # | Acción | Interfaz | Origen | Destino | Puerto/servicio | Justificación |
|---|--------|----------|--------|---------|-----------------|---------------|
| 1 | Block | WAN | any | LAN net | any | Aislar red interna desde Internet |
| 2 | Block | WAN | any | DMZ | any | Bloqueo por defecto hacia DMZ |
| 3 | Pass | WAN | Kali IP | DMZ | 80, 443, 21, 22 | Portal + SSH/FTP mal expuestos (vuln. práctica) |
| 4 | Pass | LAN | LAN net | DMZ | 80, 443 | Empleados acceden al portal |
| 5 | Block | DMZ | DMZ net | LAN net | any | DMZ no inicia hacia LAN |
| 6 | Pass | LAN | LAN net | srv-db | 5432 | App/servicios internos a BD |
| 7 | Block | DMZ | any | srv-db | 5432 | La BD no es alcanzable desde DMZ |
| 8 | Block | WAN | any | srv-db | 5432 | BD nunca expuesta |
| 9 | Pass | LAN | LAN net | any | 53, 123 | DNS/NTP internos si aplica |
| 10 | Pass | LAN | srv-syslog | any | Syslog 514 | Centralizar logs firewall + Suricata |
| 11 | Alias + Block | WAN | `bogons` o geo | any | any | Bloquear rangos no enrutables (avanzado) |
| 12 | NAT | WAN | — | DMZ web | 80→80 | Publicación controlada del servicio |

**Avanzado (puntos extra):**

- Reglas basadas en **alias** (grupos de IPs de administración vs resto LAN).
- **Schedule** (horario laboral) para restringir gestión del firewall.
- **Suricata package** en pfSense (despliegue **principal** de este plan).

### Evidencias Bloque 2

- Export o capturas de la tabla de reglas de pfSense (Firewall → Rules).
- Diagrama actualizado con flujos permitidos y bloqueados.
- Prueba con `nc`, `curl` o `nmap` desde Kali: demostrar que lo bloqueado **no** pasa y lo permitido **sí**.

---

## Bloque 3 — Auditoría, pentest y refuerzo

### Metodología (documentar en el informe)

Seguir un ciclo claro, aunque sea simplificado:

```
Reconocimiento → Escaneo → Enumeración → Explotación (controlada) → Post-explotación (ligera) → Informe → Mitigación
```

Herramientas en **Kali** (solo contra tu lab):

- **[`lab/scripts/attack-lab.sh`](../lab/scripts/attack-lab.sh)** — escaneo agresivo Nmap + nikto + curl SQLi + hydra acotado (punto de partida del pentest)
- `sqlmap` contra `search.php` si quieres profundizar un hallazgo
- `wireshark` / `tcpdump` para correlacionar con alertas Suricata y Syslog

### Checklist de auditoría de red corporativa

- [ ] **Inventario de activos:** IPs, SO, servicios, propietario (rol de cada VM).
- [ ] **Segmentación:** ¿DMZ puede hablar con LAN? ¿WAN alcanza BD?
- [ ] **Superficie de ataque:** puertos abiertos en WAN y DMZ (resultado `nmap -sV`).
- [ ] **Configuración del firewall:** reglas demasiado permisivas, any-any, falta de logging.
- [ ] **IDS:** ¿hay huecos sin monitorizar? ¿reglas actualizadas?
- [ ] **Servicios:** versiones obsoletas, banners informativos, TLS débil en HTTPS.
- [ ] **Credenciales:** políticas de contraseña en SSH/RDP/web (prueba controlada).
- [ ] **Disponibilidad:** no realizar DoS; solo pruebas ligeras documentadas.

### Plantilla de hallazgos (mínimo 8)

Para cada hallazgo, rellenar:

| Campo | Ejemplo |
|-------|---------|
| ID | H-01 |
| Título | PostgreSQL alcanzable desde DMZ |
| Severidad | Alta / Media / Baja |
| Activo | srv-db 192.168.10.20 |
| Descripción | Qué se probó y qué ocurrió |
| Evidencia | Salida de nmap, captura, log Suricata |
| Mitigación | Regla pfSense #7 + regla IDS + verificación |
| Estado | Abierto / Mitigado / Aceptado |

**Ejemplos de hallazgos esperados en un lab bien montado:**

1. Puerto 22 expuesto en DMZ sin necesidad.  
2. Servicio web con versión antigua y CVE conocido (VM de práctica).  
3. Regla firewall demasiado amplia (WAN → LAN).  
4. Falta de segmentación entre DMZ y LAN.  
5. Ausencia de alertas IDS ante escaneo (sensor mal ubicado).  
6. Contraseñas débiles en SSH (entorno de prueba).  
7. Falta de HTTPS / cookies sin flags seguros (si hay app web).  
8. Logs del firewall no revisados / sin retención.

### Plan de refuerzo (mitigaciones)

Tras el pentest, entregar una tabla **hallazgo → mitigación → responsable → verificación**:

| Hallazgo | Mitigación técnica | Dónde se aplica | Cómo verificar |
|----------|-------------------|-----------------|----------------|
| H-01 | Bloquear 5432 desde DMZ | pfSense + regla IDS | `nmap` desde DMZ falla |
| H-02 | Actualizar nginx / parchear SO | srv-dmz | `nmap -sV` muestra versión nueva |
| … | … | … | … |

Incluir **recomendaciones organizativas** breves: política de cambios en reglas, actualización de firmas IDS semanal, revisiones trimestrales de reglas pfSense.

---

## Fases del proyecto (plan de trabajo)

### Fase 0 — Preparación (1 sesión)

- [ ] Instalar hipervisor y descargar ISOs (pfSense, Debian, Kali).
- [ ] Definir tabla de IPs y nombres de hosts.
- [ ] Crear red interna aislada (sin exponer el lab a Internet real sin control).

### Fase 1 — Red y firewall (2 sesiones)

- [ ] Desplegar pfSense con WAN/LAN/DMZ.
- [ ] Configurar las ≥10 reglas y NAT.
- [ ] Probar conectividad básica (ping/curl) desde cada zona.

### Fase 2 — Servicios + vulnerabilidades de práctica (1 sesión)

- [ ] Levantar servidor web en DMZ y ejecutar `seed-vulnerabilities.sh`.
- [ ] Levantar PostgreSQL en LAN con contraseña débil documentada.
- [ ] Confirmar que WAN no alcanza la BD (antes de mitigar).

### Fase 3 — IDS/IPS en pfSense + Syslog (1–2 sesiones)

- [ ] Instalar paquete Suricata en pfSense.
- [ ] Reglas ET/Open + reglas custom.
- [ ] Syslog centralizado (Docker o srv-syslog).
- [ ] Ejecutar `attack-lab.sh` y documentar alertas.

### Fase 4 — Pentest y informe (2 sesiones)

- [ ] Ejecutar pruebas desde Kali siguiendo metodología.
- [ ] Redactar informe con ≥8 hallazgos.
- [ ] Aplicar mitigaciones y **volver a probar** (estado Mitigado).

### Fase 5 — Defensa oral / entrega final (1 sesión)

- [ ] Presentar topología, demo en vivo de bloqueo firewall + alerta IDS.
- [ ] Entregar paquete de evidencias (PDF o wiki del repo).

---

## Criterios de “ejercicio terminado”

- [ ] Topología documentada con IPs y zonas (WAN/LAN/DMZ).
- [ ] pfSense operativo con ≥10 reglas personalizadas y justificación escrita.
- [ ] Suricata o Snort generando alertas ante pruebas reproducibles (≥5 tipos).
- [ ] Al menos 2 reglas IDS/IPS propias (`local.rules` o equivalente).
- [ ] Informe de auditoría con ≥8 hallazgos y plan de mitigación.
- [ ] Evidencia de **re-test** tras aplicar mitigaciones (antes/después).
- [ ] Todo el pentest realizado **solo** en el laboratorio, con ética y autorización del profesor.

---

## Entregables para el profesor

| # | Documento / artefacto |
|---|------------------------|
| 1 | Memoria PDF (20–40 páginas según nivel): topología, IDS, firewall, pentest, mitigaciones |
| 2 | Diagrama de red (draw.io, Lucidchart o export PNG) |
| 3 | Export de reglas pfSense (o capturas numeradas) |
| 4 | `local.rules` + extracto de configuración Suricata/Snort |
| 5 | Logs de alertas (anonimizados) y correlación con pruebas |
| 6 | Informe de pentest (tabla de hallazgos H-01…H-08+) |
| 7 | Opcional: repo Git con scripts de despliegue y `README` de reproducción del lab |

---

## Riesgos y límites legales (obligatorio leer)

| No hacer | Hacer |
|----------|--------|
| Escanear o atacar redes ajenas (universidad, ISP, Internet) | Solo VMs del laboratorio definidas |
| Dejar Kali con herramientas expuestas en red pública | Red host-only o NAT aislado |
| IPS inline en producción sin pruebas | Probar primero en IDS pasivo |
| Pentest sin autorización escrita | Hoja de autorización del profesor |

---

## Relación con `ideas/ideas.md` (proyecto Flask)

Son **complementarios**, no sustitutos:

| `ideas.md` | `idea_2.md` (este documento) |
|------------|--------------------------------|
| Seguridad de **aplicación** (login, bcrypt, SQL) | Seguridad de **red** (segmentación, IDS, firewall) |
| Flask + PostgreSQL | pfSense + Suricata/Snort + Kali |

**Integración opcional:** desplegar el mini gestor de tareas en `srv-dmz` o LAN; el pentest incluye OWASP básico y el IDS detecta intentos de inyección en HTTP; el firewall impide acceso directo a PostgreSQL.

---

## Siguiente paso concreto

1. Confirmar hipervisor; **Suricata irá en pfSense** (no VM IDS salvo excepción del profesor).
2. Crear VMs: pfSense, srv-dmz, srv-db, srv-syslog (o Docker), Kali.
3. Montar pfSense, reglas y paquete Suricata.
4. Sembrar vulnerabilidades (`seed-vulnerabilities.sh`) y ejecutar `attack-lab.sh` desde Kali.
5. Verificar bloqueo en firewall, alertas en Suricata y líneas en Syslog.
6. Redactar informe con hallazgos reales y mitigaciones.

Implementación: **[`fases/`](../fases/README.md)** · Scripts: **[`lab/`](../lab/README.md)**.
