# Reglas de firewall pfSense — Fase 1

> Documento preparado **antes** de montar pfSense. El compañero que tiene el lab solo
> debe implementar cada regla en **Firewall → Rules**, marcar la casilla y pegar la
> captura correspondiente. Política base: **deny by default** (bloqueo implícito al final).

**Referencia IPs:** [`../fase0/tabla-ips.md`](../fase0/tabla-ips.md)

## Aliases a crear primero (Firewall → Aliases)

| Alias | Valor | Uso |
|-------|-------|-----|
| `LAN_NET` | `192.168.10.0/24` | Red corporativa interna |
| `DMZ_NET` | `192.168.20.0/24` | Red DMZ |
| `KALI_WAN` | `10.0.0.50/32` | Atacante autorizado (lab) |
| `SRV_DB` | `192.168.10.20/32` | PostgreSQL |
| `SRV_DMZ_WEB` | `192.168.20.10/32` | Servidor web DMZ |
| `SRV_SYSLOG` | `192.168.10.5/32` | Servidor Syslog |

## Tabla de reglas (mínimo 10)

| # | Hecho | Acción | Interfaz | Origen | Destino | Puerto | Log | Justificación |
|---|-------|--------|----------|--------|---------|--------|-----|---------------|
| 1 | ☐ | Block | WAN | any | `LAN_NET` | any | ✅ | Aislar la intranet de Internet (núcleo de la segmentación) |
| 2 | ☐ | Block | WAN | any | `DMZ_NET` | any | ✅ | Bloqueo general hacia DMZ; solo se abre lo explícito (regla #3) |
| 3 | ☐ | Pass | WAN | `KALI_WAN` | `SRV_DMZ_WEB` | 80,443,21,22 | ✅ | Portal público + SSH/FTP expuestos a propósito (hallazgo pentest) |
| 4 | ☐ | Pass | LAN | `LAN_NET` | `SRV_DMZ_WEB` | 80,443 | ☐ | Empleados acceden al portal web |
| 5 | ☐ | Block | DMZ | `DMZ_NET` | `LAN_NET` | any | ✅ | La DMZ nunca inicia conexiones hacia la LAN |
| 6 | ☐ | Pass | LAN | `LAN_NET` | `SRV_DB` | 5432 | ☐ | App/servicios internos acceden a PostgreSQL |
| 7 | ☐ | Block | DMZ | any | `SRV_DB` | 5432 | ✅ | La BD no es alcanzable desde la DMZ |
| 8 | ☐ | Block | WAN | any | `SRV_DB` | 5432 | ✅ | La BD nunca se expone a Internet |
| 9 | ☐ | Pass | LAN | `LAN_NET` | any | 53,123 | ☐ | DNS/NTP internos (si usas resolver) |
| 10 | ☐ | Pass | LAN | `SRV_SYSLOG` | any | 514/udp | ☐ | Centralizar logs de firewall + Suricata |
| 11 | ☐ | Block | WAN | `bogons` | any | any | ✅ | Bloquear rangos no enrutables (avanzado, alias bogons) |
| 12 | ☐ | NAT | WAN | — | `SRV_DMZ_WEB` | 80→80 | ✅ | Publicación controlada del servicio web DMZ |

> **Orden importa:** en pfSense gana la **primera coincidencia**. Coloca los `Pass`
> específicos (p. ej. #3) **antes** de los `Block` amplios de la misma interfaz.

## Justificación ampliada (para la memoria)

- **#1–#2 (deny perimetral):** todo lo que entra por WAN se bloquea salvo lo abierto explícitamente. Es la base del modelo de defensa.
- **#3 (acceso controlado del atacante):** abre solo desde la IP de Kali hacia la web. SSH(22)/FTP(21) se dejan expuestos **a propósito** para generar hallazgos reales en el pentest (Fase 4). No cerrar hasta después de auditar.
- **#4 (LAN → portal):** los empleados sí pueden usar el servicio publicado en DMZ.
- **#5 (DMZ aislada):** si comprometen la web, no debe poder "saltar" a la LAN. Principio de contención.
- **#6 (LAN → BD):** único camino legítimo a PostgreSQL.
- **#7–#8 (proteger BD):** la BD no se alcanza ni desde DMZ ni desde WAN. Correlaciona con la alerta Suricata sid `9000001` (Fase 3).
- **#9 (DNS/NTP):** servicios básicos de salida para la LAN.
- **#10 (Syslog):** permite el envío de logs UDP 514 al `srv-syslog`.
- **#11 (bogons):** descarta tráfico con origen no enrutable (anti-spoofing básico).
- **#12 (NAT):** publica la web de la DMZ al "exterior" de forma controlada.

## Pruebas de verificación (Fase 1.6) — guardar en `prueba-kali-bloqueo.txt`

Desde **Kali** (`10.0.0.50`), debe **fallar**:

```bash
ping -c 2 192.168.10.20
nmap -p 5432 192.168.10.20
```

Desde **Kali**, debe **funcionar** (cuando exista la web en Fase 2):

```bash
nc -zv 192.168.20.10 80
curl -I --connect-timeout 3 http://192.168.20.10
```

Desde **LAN** (`ws-corp` / `srv-db`), debe **funcionar**:

```bash
ping -c 2 192.168.20.10
```

## Evidencias a adjuntar (las pega el compañero del lab)

| Archivo | Contenido | Estado |
|---------|-----------|--------|
| `wan-rules.png` | Captura Firewall → Rules → WAN | ☐ |
| `lan-rules.png` | Captura Firewall → Rules → LAN | ☐ |
| `dmz-rules.png` | Captura Firewall → Rules → DMZ | ☐ |
| `nat-port-forward.png` | Captura NAT → Port Forward (regla #12) | ☐ |
| `prueba-kali-bloqueo.txt` | Salidas ping/nmap/nc/curl | ☐ |
| `firewall-log-block.png` | Log de bloqueo a `5432` desde Kali | ☐ |
