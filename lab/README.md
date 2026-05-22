# Laboratorio — Seguridad en redes

Artefactos para [`ideas/idea_2.md`](../ideas/idea_2.md) y guías en [`fases/`](../fases/README.md).

## Mejoras del tutor (resumen)

| Recomendación | Dónde está |
|---------------|------------|
| Suricata en **pfSense** (Package Manager) | [fase3.md](../fases/fase3.md) |
| **Vulnerabilidades intencionadas** en servidores | `scripts/seed-vulnerabilities.sh` + [fase2.md](../fases/fase2.md) |
| **Syslog centralizado** (contenedor o VM) | `docker-compose.syslog.yml` + [fase1/fase3](../fases/) |
| **Script de ataque** en Kali | `scripts/attack-lab.sh` |

## Scripts

```bash
# En srv-dmz (Debian DMZ) — vulnerabilidades de práctica
sudo bash lab/scripts/seed-vulnerabilities.sh

# En Kali (WAN) — escaneo agresivo + pruebas web/SSH
sudo bash lab/scripts/attack-lab.sh 192.168.20.10 192.168.10.20
```

## Syslog con Docker (en el PC host, red LAN accesible)

```bash
cd lab
docker compose -f docker-compose.syslog.yml up -d
docker exec lab-syslog tail -f /var/log/lab-all.log
```

Configura en pfSense: **Status → System Logs → Settings → Remote Logging** → IP del host (ej. `192.168.10.2`) puerto **514 UDP**.

## Evidencias

Guardar salidas en `lab/evidencias/faseN/` (puede estar en `.gitignore`).
