# Idea 2 — Seguridad en redes (laboratorio corporativo)

## Objetivo del ejercicio

Diseñar, desplegar y auditar una **red corporativa simulada** en la que se demuestren tres competencias del temario:

1. **IDS/IPS** — detección y, opcionalmente, prevención de intrusiones con **Suricata** o **Snort**.
2. **Firewall perimetral avanzado** — reglas personalizadas en **pfSense** (o firewall de hardware equivalente).
3. **Auditoría y refuerzo** — pruebas de penetración controladas, hallazgos documentados y **plan de mitigación** enlazado a cada riesgo.

No se trata de construir una aplicación grande. El foco es **infraestructura de red**, políticas de seguridad y evidencias (capturas, reglas, alertas, informe).

**Duración orientativa:** 2–3 semanas (o 5–8 sesiones de laboratorio) según profundidad del pentest y del modo IPS.

---

## Alcance mínimo (qué debe quedar demostrado)

| Bloque | Entregable mínimo |
|--------|-------------------|
| IDS/IPS | Suricata o Snort instalado, reglas activas, al menos **5 alertas** reproducibles y documentadas |
| Firewall | pfSense (o HW) con **≥10 reglas** justificadas (WAN/LAN/DMZ, NAT, bloqueos) |
| Auditoría | Informe con metodología, **≥8 hallazgos** (red + servicios), mitigaciones priorizadas |

---

## Topología recomendada (red corporativa simulada)

Laboratorio en **máquinas virtuales** (VirtualBox, VMware o Proxmox). Todas en una red interna aislada del router doméstico (modo host-only / red interna).

```
                    [ Internet simulada ]
                            |
                     +-------------+
                     |   pfSense   |  ← Firewall perimetral (WAN / LAN / DMZ)
                     +------+------+
                            |
          +-----------------+------------------+
          |                 |                  |
    +-----+-----+     +-----+-----+      +-----+-----+
    |  WAN      |     |  LAN      |      |  DMZ      |
    | (ataque)  |     | corp.     |      | servicios |
    +-----------+     +-----+-----+      +-----+-----+
                            |                  |
                     +------+------+    +------+------+
                     | Suricata/   |    | Servidor  |
                     | Snort IDS   |    | web (HTTP) |
                     | (sensor)    |    | + opcional |
                     +-------------+    | app Flask  |
                            |           +------------+
                     +------+------+
                     | Estación    |
                     | admin / SIEM|
                     | (logs)      |
                     +-------------+
```

### Roles de cada VM (plantilla)

| VM | SO sugerido | Rol | IP ejemplo (LAN) |
|----|-------------|-----|-------------------|
| `fw-pfsense` | pfSense CE | Firewall perimetral, NAT, reglas | WAN `10.0.0.1`, LAN `192.168.10.1`, DMZ `192.168.20.1` |
| `ids-suricata` | Debian / Ubuntu | IDS (y opcional IPS en modo inline) | `192.168.10.10` |
| `srv-dmz` | Debian | Servidor web corporativo (nginx o Apache) | `192.168.20.10` |
| `srv-db` | Debian | PostgreSQL **solo en LAN** (no expuesto a WAN) | `192.168.10.20` |
| `ws-corp` | Windows o Linux | Cliente interno (usuario corporativo) | `192.168.10.50` |
| `kali-pentest` | Kali Linux | Máquina de auditoría (solo en laboratorio) | WAN `10.0.0.50` |

**Regla de oro:** PostgreSQL y datos sensibles **nunca** en DMZ ni con puerto abierto en WAN. El acceso desde Internet solo a servicios publicados en DMZ (p. ej. HTTP/HTTPS).

**Opcional:** reutilizar el mini gestor Flask del otro proyecto (`ideas/ideas.md`) como **aplicación corporativa** en `srv-dmz` o en LAN detrás de reverse proxy; así el pentest puede incluir pruebas web además de red.

---

## Bloque 1 — IDS/IPS (Suricata o Snort)

### Elección de herramienta

| Herramienta | Cuándo elegirla |
|-------------|-----------------|
| **Suricata** | Recomendada: IDS/IPS multihilo, buena integración con reglas ET/Open, IPS en inline con `NFQUEUE` |
| **Snort** | Válida si el curso lo exige; misma lógica de despliegue y documentación |

En el documento y la memoria, **fijar una** y ser consistente.

### Modos de despliegue (elegir uno y documentarlo)

1. **IDS pasivo (recomendado para empezar)**  
   - Sensor en LAN con copia de tráfico (port mirroring en virtual switch, o `span` en pfSense si está disponible).  
   - No bloquea; solo genera alertas.  
   - Menor riesgo de cortar el laboratorio por falsos positivos.

2. **IPS inline (opcional / avanzado)**  
   - Suricata entre segmentos o en bridge; acción `drop`/`reject` en reglas.  
   - Demostrar **una** prevención real (p. ej. bloqueo de escaneo agresivo o exploit conocido en tráfico de prueba).

### Tareas concretas

- [ ] Instalar Suricata o Snort en `ids-suricata`.
- [ ] Actualizar reglas (**Emerging Threats Open** o conjunto que proporcione el profesor).
- [ ] Configurar `HOME_NET` y `EXTERNAL_NET` acorde a la topología (`192.168.10.0/24`, `192.168.20.0/24`, `10.0.0.0/24`).
- [ ] Activar logging en archivo y/o **Syslog** hacia la estación de administración.
- [ ] Crear **≥2 reglas personalizadas** (local.rules), por ejemplo:
  - Detección de muchos intentos fallidos SSH desde WAN.
  - Detección de tráfico hacia PostgreSQL (`5432`) desde WAN o DMZ.
  - Alerta por escaneo de puertos (nmap) desde `kali-pentest`.
- [ ] Reproducir ataques de laboratorio y capturar **≥5 alertas** distintas (captura de pantalla + línea del log + timestamp).

### Escenarios de prueba para generar alertas (ética: solo en tu lab)

| Prueba | Origen | Qué debe disparar el IDS |
|--------|--------|---------------------------|
| Escaneo de puertos | Kali → DMZ/LAN | `ET SCAN` o regla custom de reconocimiento |
| Fuerza bruta SSH (simulada, pocas pruebas) | Kali → LAN | Regla custom o firma de brute force |
| Acceso HTTP a rutas sospechosas | Kali → `srv-dmz` | SQLi/XSS en URI (reglas ET web) |
| Tráfico a PostgreSQL desde WAN | Kali → IP LAN:5432 | Regla custom “PostgreSQL desde exterior” |
| Tráfico ICMP flood ligero | Kali → LAN | Opcional: detección de abuso ICMP |

### Evidencias Bloque 1

- Fragmento de `suricata.yaml` / `snort.conf` con redes definidas.
- Archivo `local.rules` con reglas propias comentadas.
- 5 capturas o extractos de `fast.log` / `eve.json` con explicación en español.

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
| 2 | Block | WAN | any | DMZ | any excepto 80/443 | Solo servicios publicados |
| 3 | Pass | WAN | Kali IP | DMZ | 80, 443 | Simular acceso público al portal |
| 4 | Pass | LAN | LAN net | DMZ | 80, 443 | Empleados acceden al portal |
| 5 | Block | DMZ | DMZ net | LAN net | any | DMZ no inicia hacia LAN |
| 6 | Pass | LAN | LAN net | srv-db | 5432 | App/servicios internos a BD |
| 7 | Block | DMZ | any | srv-db | 5432 | La BD no es alcanzable desde DMZ |
| 8 | Block | WAN | any | srv-db | 5432 | BD nunca expuesta |
| 9 | Pass | LAN | LAN net | any | 53, 123 | DNS/NTP internos si aplica |
| 10 | Pass | LAN | ids-suricata | any | Syslog 514 | Centralizar logs del IDS |
| 11 | Alias + Block | WAN | `bogons` o geo | any | any | Bloquear rangos no enrutables (avanzado) |
| 12 | NAT | WAN | — | DMZ web | 80→80 | Publicación controlada del servicio |

**Avanzado (puntos extra):**

- Reglas basadas en **alias** (grupos de IPs de administración vs resto LAN).
- **Schedule** (horario laboral) para restringir gestión del firewall.
- **Suricata package** en pfSense como alternativa al sensor externo (documentar si se usa en lugar de VM dedicada).

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

Herramientas típicas en **Kali** (solo contra tu lab):

- `nmap`, `masscan` (con moderación)
- `nikto`, `dirb` o `gobuster` (servicio web DMZ)
- `hydra` o `ncrack` (fuerza bruta **limitada**, con autorización escrita del profesor)
- `sqlmap` solo si hay vulnerabilidad intencional de práctica
- `wireshark` / `tcpdump` para correlacionar con alertas IDS

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

### Fase 2 — Servicios corporativos (1 sesión)

- [ ] Levantar servidor web en DMZ.
- [ ] Levantar PostgreSQL solo en LAN (opcional: app Flask en LAN o detrás de proxy).
- [ ] Confirmar que WAN no alcanza la BD.

### Fase 3 — IDS/IPS (2 sesiones)

- [ ] Instalar y afinar Suricata o Snort.
- [ ] Reglas ET/Open + reglas custom.
- [ ] Generar y documentar alertas.

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

1. Confirmar hipervisor y si se usará **Suricata** o **Snort**.
2. Crear las VMs según la tabla de roles e IPs.
3. Montar pfSense y validar segmentación antes de instalar el IDS.
4. Ejecutar el primer escaneo desde Kali y verificar que **pfSense bloquea** y **Suricata alerta**.
5. Redactar el informe de hallazgos mientras se aplican mitigaciones (no dejar el informe para el final).

Cuando pases de documentación a implementación, se puede añadir al repo una carpeta `lab/` con diagramas, exports de reglas y plantilla del informe de pentest.
