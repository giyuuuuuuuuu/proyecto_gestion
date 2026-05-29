# Tabla de IPs — Laboratorio (Fase 0)

> Direccionamiento **definitivo** del laboratorio aislado. No cambiar una IP sin avisar
> al compañero y actualizar las reglas de pfSense, los scripts y las demás fases.

**Esquema de direccionamiento:** `192.168.x` privado en LAN/DMZ, `10.0.0.x` en WAN.
**Decisión Syslog:** Opción A — VM `srv-syslog` en LAN `192.168.10.5`.

## Tabla de IPs

| Hostname | Rol | Red / Interfaz | IP | Gateway |
|----------|-----|----------------|-----|---------|
| `fw-pfsense` | Firewall | WAN (`lab-wan`) | `10.0.0.1/24` | — |
| `fw-pfsense` | Firewall | LAN (`lab-lan`) | `192.168.10.1/24` | — |
| `fw-pfsense` | Firewall | DMZ / OPT1 (`lab-dmz`) | `192.168.20.1/24` | — |
| `srv-syslog` | Syslog (VM) | LAN | `192.168.10.5/24` | `192.168.10.1` |
| `srv-db` | PostgreSQL | LAN | `192.168.10.20/24` | `192.168.10.1` |
| `ws-corp` | Cliente corporativo | LAN | `192.168.10.50/24` | `192.168.10.1` |
| `srv-dmz` | Servidor web (vulnerable) | DMZ | `192.168.20.10/24` | `192.168.20.1` |
| `kali-pentest` | Atacante / pentest | WAN | `10.0.0.50/24` | `10.0.0.1` |

## Segmentos de red

| Red | Rango | Interfaz pfSense | Hosts |
|-----|-------|------------------|-------|
| WAN (simula Internet) | `10.0.0.0/24` | `10.0.0.1` | pfSense `.1`, Kali `.50` |
| LAN corporativa | `192.168.10.0/24` | `192.168.10.1` | pfSense `.1`, syslog `.5`, BD `.20`, cliente `.50` |
| DMZ | `192.168.20.0/24` | `192.168.20.1` | pfSense `.1`, web `.10` |

## Aliases pfSense (para las reglas de Fase 1)

| Alias | Valor |
|-------|-------|
| `LAN_NET` | `192.168.10.0/24` |
| `DMZ_NET` | `192.168.20.0/24` |
| `KALI_WAN` | `10.0.0.50/32` |
| `SRV_DB` | `192.168.10.20/32` |
| `SRV_DMZ_WEB` | `192.168.20.10/32` |
| `SRV_SYSLOG` | `192.168.10.5/32` |

## Dependencias (por qué estas IPs son fijas)

- `192.168.10.20` (srv-db): reglas pfSense #6/#7/#8 y alerta Suricata sid `9000001` (puerto `5432`).
- `192.168.20.10` (srv-dmz): NAT regla #12 (WAN 80 → `192.168.20.10:80`) y portal web.
- `10.0.0.50` (Kali): alias `KALI_WAN`, regla #3 (acceso controlado WAN → DMZ).
- `192.168.10.5` (srv-syslog): Remote Logging, regla #10 (UDP 514).
- Gateways = IP de pfSense en cada segmento (`.1`).
