# Fase 3 — IDS/IPS (Suricata en pfSense) + Syslog

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md) — Bloque 1 y Syslog  
**Requisito:** [fase2.md](fase2.md) completada (vulnerabilidades sembradas)  
**Duración orientativa:** 1–2 sesiones  
**Siguiente fase:** [fase4.md](fase4.md)

---

## Objetivo

Instalar el **paquete oficial Suricata** en pfSense (sin VM IDS dedicada), cargar reglas ET/Open, añadir reglas personalizadas, centralizar logs en un **servidor Syslog** y generar **≥5 alertas** ejecutando [`lab/scripts/attack-lab.sh`](../lab/scripts/attack-lab.sh) desde Kali.

---

## Tareas

### 3.1 — Instalar Suricata en pfSense

- [ ] **System → Package Manager → Available Packages**
- [ ] Buscar **Suricata** → **Install** → confirmar.
- [ ] Tras instalar: **Services → Suricata → Installation** → comprobar que no hay errores.

### 3.2 — Interfaces y modo IDS

- [ ] **Services → Suricata → Interfaces**
- [ ] En **WAN**: Enable, modo **IDS** (o IPS solo si el tutor lo pide y has probado antes).
- [ ] En **DMZ** (OPT1): Enable IDS.
- [ ] Opcional LAN: ver tráfico interno ws-corp ↔ srv-db.
- [ ] **Save** en cada pestaña.

### 3.3 — Reglas Emerging Threats

- [ ] **Services → Suricata → Updates** → Install/regenerate rules **Emerging Threats Open**.
- [ ] Esperar a que termine (puede tardar varios minutos).
- [ ] **WAN → Settings → Enable** rule categories: malware, scan, web-client, etc. (según RAM; no activar todo si la VM pfSense es pequeña).

### 3.4 — Redes HOME_NET / EXTERNAL_NET

- [ ] **Services → Suricata → Global Settings**
- [ ] **HOME_NET:** `192.168.10.0/24,192.168.20.0/24`
- [ ] **EXTERNAL_NET:** `10.0.0.0/24` (red WAN con Kali)
- [ ] Guardar y aplicar.

### 3.5 — Reglas personalizadas (≥2)

En **Services → Suricata → WAN → Rules → Custom rules** (o Includes), pegar:

```
alert tcp $EXTERNAL_NET any -> $HOME_NET 5432 (msg:"LAB PostgreSQL desde exterior"; sid:9000001; rev:1;)
alert tcp 10.0.0.50 any -> $HOME_NET any (msg:"LAB Escaneo SYN desde Kali"; flags:S; threshold:type both, track by_src, count 25, seconds 10; sid:9000002; rev:1;)
alert http any any -> $HOME_NET any (msg:"LAB Posible SQLi URI"; flow:established,to_server; http.uri; content:"' OR "; nocase; sid:9000003; rev:1;)
```

- [ ] **Update** / **Reload** rules en Suricata.
- [ ] Copiar reglas a `lab/evidencias/fase3/suricata-custom-rules.txt`.

### 3.6 — Alertas en GUI y system log

- [ ] En cada interfaz Suricata: activar **Send Alerts to System Log**.
- [ ] **Status → System Logs → Firewall** y filtro Suricata si existe.
- [ ] Anotar ruta de alertas: **Services → Suricata → Alerts**.

### 3.7 — Syslog centralizado (plus del tutor)

**Opción A — Docker en el PC host** (IP en LAN accesible desde pfSense, ej. `192.168.10.2`):

```bash
cd lab
docker compose -f docker-compose.syslog.yml up -d
docker exec lab-syslog tail -f /var/log/lab-all.log
```

**Opción B — VM `srv-syslog` (`192.168.10.5`):**

```bash
sudo apt install -y rsyslog
# Escuchar UDP 514 — ver lab/syslog/rsyslog.conf como referencia
```

**En pfSense:**

- [ ] **Status → System Logs → Settings**
- [ ] **Enable Remote Logging** → IP `192.168.10.5` (o host Docker) → puerto **514** → protocolo **UDP**
- [ ] **Save**
- [ ] Regla firewall LAN → srv-syslog puerto 514 (ver [fase1](fase1.md) regla #10)

- [ ] Comprobar que llegan líneas tras un bloqueo o alerta Suricata.

### 3.8 — Ejecutar script de ataque (Kali)

Copiar o montar el repo; en Kali:

```bash
chmod +x lab/scripts/attack-lab.sh
sudo lab/scripts/attack-lab.sh 192.168.20.10 192.168.10.20
# Salida en ./lab-evidencias-ataque-FECHA/
```

- [ ] Anotar hora de inicio/fin del script.
- [ ] Abrir **Services → Suricata → Alerts** y refrescar.
- [ ] Guardar ≥5 alertas distintas en `lab/evidencias/fase3/alertas.md`:

```markdown
### A-01 — Escaneo Nmap
- Hora: ...
- Prueba: attack-lab.sh paso 1
- Alerta Suricata: (mensaje / SID)
- Syslog: (línea opcional)
```

### 3.9 — Correlación firewall + IDS + syslog

- [ ] Mismo instante: intento a `5432` desde Kali → **bloqueo** en Firewall Log + alerta sid **9000001**.
- [ ] Captura triple en `lab/evidencias/fase3/correlacion.png` o tres extractos de texto.

### 3.10 — IPS (opcional)

- [ ] Cambiar WAN a modo **IPS** y bloquear categoría **scan** o regla custom con `drop`.
- [ ] Repetir `nmap -T4` y demostrar que el escaneo se corta o disminuye.
- [ ] Documentar riesgo de falsos positivos.

---

## Criterios de cierre

- [ ] Suricata instalado vía Package Manager y activo en WAN (+ DMZ).
- [ ] Reglas ET/Open cargadas.
- [ ] ≥2 reglas custom (sid 900000x).
- [ ] `attack-lab.sh` ejecutado sin errores críticos.
- [ ] ≥5 alertas documentadas.
- [ ] Syslog recibiendo eventos de pfSense (plus).

---

## Evidencias

| Archivo | Descripción |
|---------|-------------|
| `suricata-package.png` | Package Manager |
| `suricata-alerts.png` | Pestaña Alerts tras ataque |
| `suricata-custom-rules.txt` | Reglas sid 9000001–3 |
| `alertas.md` | A-01 … A-05 |
| `syslog-muestra.log` | Extracto del contenedor/VM syslog |

---

## Problemas frecuentes

| Problema | Solución |
|----------|----------|
| Sin alertas tras nmap | WAN IDS no habilitado; reglas scan no activadas; esperar fin de `attack-lab.sh` |
| pfSense lento | Reducir categorías de reglas; aumentar RAM de VM pfSense a 2 GB |
| Syslog vacío | Regla LAN→514; IP incorrecta; firewall del host bloqueando UDP 514 |
| PHP no ejecuta en DMZ | Vulnerabilidades no sembradas — ejecutar `seed-vulnerabilities.sh` en Fase 2 |

---

**Anterior:** [fase2.md](fase2.md)  
**Siguiente:** [fase4.md](fase4.md) — Pentest con `attack-lab.sh` + informe.
