# Fase 1 — Red y firewall perimetral (pfSense)

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md) — Bloque 2  
**Requisito:** [fase0.md](fase0.md) completada  
**Duración orientativa:** 2 sesiones  
**Siguiente fase:** [fase2.md](fase2.md)

---

## Objetivo

Desplegar **pfSense** con interfaces WAN, LAN y DMZ; aplicar **≥10 reglas** personalizadas con logging; configurar NAT hacia DMZ; preparar **remote Syslog** hacia `srv-syslog` o Docker; dejar listo el host para instalar el paquete **Suricata** en Fase 3.

---

## Tareas

### 1.1 — Instalación de pfSense

- [ ] Arrancar VM `fw-pfsense` con ISO pfSense CE.
- [ ] Instalar en disco virtual (opción típica: UFS, desarrollo).
- [ ] Asignar interfaces en el asistente:
  - WAN → red `lab-wan`
  - LAN → red `lab-lan`
  - OPT1 → renombrar a **DMZ** → red `lab-dmz`
- [ ] Acceder a la GUI: `https://192.168.10.1` desde una VM en LAN (o NAT temporal durante setup).
- [ ] Cambiar contraseña admin por defecto.
- [ ] Ajustar IPs si difieren de la tabla de Fase 0:
  - WAN: `10.0.0.1/24`
  - LAN: `192.168.10.1/24`
  - DMZ: `192.168.20.1/24`

### 1.2 — Política base (deny by default)

- [ ] **Firewall → Rules → WAN:** revisar que no exista regla “allow all” hacia LAN.
- [ ] Desactivar o no usar reglas automáticas que abran LAN desde WAN sin justificación.
- [ ] Activar **Log** en reglas de bloqueo críticas (icono de registro en cada regla).

### 1.3 — Reglas personalizadas (checklist mínimo 10)

Implementar y **anotar la justificación** en `lab/evidencias/fase1/reglas-pfsense.md`:

| # | Hecho | Acción | Origen → Destino | Puerto | Justificación (1 línea) |
|---|-------|--------|------------------|--------|-------------------------|
| 1 | ☐ | Block | WAN → LAN net | any | Aislar intranet |
| 2 | ☐ | Block | WAN → DMZ | any | Bloqueo general hacia DMZ |
| 3 | ☐ | Pass | WAN (Kali `10.0.0.50`) → DMZ | 80,443,21,22 | Portal + **mal config** SSH/FTP expuestos (hallazgo pentest) |
| 4 | ☐ | Pass | LAN → DMZ | 80,443 | Empleados al portal |
| 5 | ☐ | Block | DMZ → LAN net | any | DMZ no inicia a LAN |
| 6 | ☐ | Pass | LAN → `192.168.10.20` | 5432 | App interna a PostgreSQL |
| 7 | ☐ | Block | DMZ → `192.168.10.20` | 5432 | BD no desde DMZ |
| 8 | ☐ | Block | WAN → `192.168.10.20` | 5432 | BD nunca en Internet |
| 9 | ☐ | Pass | LAN → any | 53,123 | DNS/NTP (si usas resolver) |
| 10 | ☐ | Pass | LAN → `192.168.10.5` (srv-syslog) | 514/udp | Syslog centralizado |
| 11 | ☐ | Block | WAN → bogons | any | Avanzado: alias bogons |
| 12 | ☐ | NAT | WAN → `192.168.20.10` | 80→80 | Publicar web DMZ |

**Alias recomendados (Firewall → Aliases):**

- [ ] `LAN_NET` = `192.168.10.0/24`
- [ ] `DMZ_NET` = `192.168.20.0/24`
- [ ] `KALI_WAN` = `10.0.0.50/32`
- [ ] `SRV_DB` = `192.168.10.20/32`
- [ ] `SRV_DMZ_WEB` = `192.168.20.10/32`

### 1.4 — NAT y reenvío de puertos

- [ ] **Firewall → NAT → Port Forward:** WAN TCP 80 → `192.168.20.10:80` (cuando `srv-dmz` exista).
- [ ] Aplicar cambios (**Apply Changes**).
- [ ] Captura de pantalla de reglas WAN, LAN y DMZ ordenadas (deny al final implícito).

### 1.5 — Instalar VMs de red (mínimo para probar)

- [ ] Instalar Debian/Ubuntu en `srv-dmz` y `srv-db` (solo SO + red estática por ahora).
- [ ] Instalar Kali en `kali-pentest` con IP WAN `10.0.0.50/24`, gateway `10.0.0.1`.
- [ ] Configurar IP estática en `srv-db`: `192.168.10.20/24`, GW `192.168.10.1`.

**Ejemplo netplan (Debian/Ubuntu, `srv-db`):**

```yaml
# /etc/netplan/01-lab.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [192.168.10.20/24]
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses: [192.168.10.1]
```

```bash
sudo netplan apply
```

### 1.6 — Pruebas de conectividad y bloqueo

Desde **Kali** (`10.0.0.50`):

```bash
# Debe FALLAR (LAN bloqueada desde WAN)
ping -c 2 192.168.10.20
nmap -p 5432 192.168.10.20

# Debe FUNCIONAR cuando srv-dmz tenga web (Fase 2); si aún no hay web, probar regla con nc
nc -zv 192.168.20.10 80
curl -I --connect-timeout 3 http://192.168.20.10
```

Desde **ws-corp** o `srv-db` (LAN):

```bash
ping -c 2 192.168.20.10
# Tras Fase 2: curl http://192.168.20.10
```

- [ ] Guardar salidas en `lab/evidencias/fase1/prueba-kali-bloqueo.txt`.
- [ ] Revisar **Status → System Logs → Firewall** y ver entradas **block** en intentos a LAN/5432.

### 1.7 — Remote Syslog (preparación plus)

- [ ] Levantar `srv-syslog` o `docker compose -f lab/docker-compose.syslog.yml up -d`.
- [ ] En pfSense: **Status → System Logs → Settings** → Remote log target `192.168.10.5:514` UDP (ajustar IP).
- [ ] Generar un bloqueo de prueba (ping WAN→LAN) y ver línea en el syslog remoto.

### 1.8 — Documentación de reglas

- [ ] Rellenar tabla de justificación (sección 1.3) con capturas numeradas.
- [ ] Exportar o fotografiar **Firewall → Rules** para WAN, LAN, DMZ.
- [ ] Actualizar diagrama de red (PNG) con flujos permitidos y caja “Suricata (Fase 3)”.

---

## Criterios de cierre

- [ ] pfSense accesible y con 3 interfaces activas.
- [ ] ≥10 reglas implementadas con justificación escrita.
- [ ] Desde Kali: **no** hay ping/nmap exitoso a `192.168.10.20:5432`.
- [ ] Logs de firewall muestran bloqueos esperados.
- [ ] NAT 80 configurado (aunque el servidor web se complete en Fase 2).

---

## Evidencias

| Archivo | Descripción |
|---------|-------------|
| `reglas-pfsense.md` | Tabla #1–12 + justificación |
| `wan-rules.png` / `lan-rules.png` | Capturas GUI |
| `prueba-kali-bloqueo.txt` | Salida ping/nmap/curl |
| `firewall-log-block.png` | Log de bloqueo a BD |

---

## Problemas frecuentes

| Problema | Solución |
|----------|----------|
| No llego a la GUI | Conectar gestión desde LAN temporal; revisar que la PC host no comparta la misma subred conflictiva |
| Regla no bloquea | Orden de reglas: la primera coincidencia gana; poner Pass específicos antes que Block amplios |
| Kali sin salida | Gateway `10.0.0.1`, interfaz en `lab-wan` |

---

**Anterior:** [fase0.md](fase0.md)  
**Siguiente:** [fase2.md](fase2.md) — Servicios corporativos (web DMZ + PostgreSQL LAN).
