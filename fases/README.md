# Fases del laboratorio — Seguridad en redes

Guías paso a paso para implementar [`ideas/idea_2.md`](../ideas/idea_2.md).

## Orden de trabajo

```
fase0 → fase1 → fase2 → fase3 → fase4 → fase5
```

| Fase | Archivo | Contenido | Sesiones orientativas |
|------|---------|-----------|------------------------|
| 0 | [fase0.md](fase0.md) | Hipervisor, ISOs, IPs, red aislada | 1 |
| 1 | [fase1.md](fase1.md) | pfSense, reglas, NAT, Syslog remoto | 2 |
| 2 | [fase2.md](fase2.md) | Web DMZ + **vulnerabilidades** + PostgreSQL | 1 |
| 3 | [fase3.md](fase3.md) | Suricata en pfSense, Syslog, `attack-lab.sh` | 1–2 |
| 4 | [fase4.md](fase4.md) | Pentest, informe, mitigaciones | 2 |
| 5 | [fase5.md](fase5.md) | Entrega final y defensa | 1 |

## Carpeta de evidencias (recomendado)

Crear en el repo (no obligatorio en Git si pesa mucho):

```
lab/evidencias/
├── fase0/   # tabla IPs, capturas hipervisor
├── fase1/   # reglas pfSense, pruebas nmap
├── fase2/   # curl web, prueba BD bloqueada
├── fase3/   # reglas Suricata pfSense, syslog, alertas
├── fase4/   # informe pentest, antes/después
└── fase5/   # presentación, memoria PDF
```

## Scripts del tutor (en `lab/`)

| Script | Dónde ejecutar |
|--------|----------------|
| [`seed-vulnerabilities.sh`](../lab/scripts/seed-vulnerabilities.sh) | srv-dmz |
| [`attack-lab.sh`](../lab/scripts/attack-lab.sh) | Kali |
| [`docker-compose.syslog.yml`](../lab/docker-compose.syslog.yml) | PC host |

Marca cada checkbox en los `.md` cuando completes la tarea. No pases a la siguiente fase hasta cumplir los **criterios de cierre** de la fase actual.
