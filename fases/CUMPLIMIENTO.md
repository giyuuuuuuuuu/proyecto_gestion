# Matriz de cumplimiento — Requisitos del ejercicio y del tutor

Usa este documento para verificar, **antes de entregar**, que el laboratorio cumple al pie de la letra.

**Leyenda:** ✅ cubierto en fases · ⚠️ parcial / opcional · ❌ hueco si no lo haces

---

## Requisitos oficiales del temario

| Requisito (texto del enunciado) | ¿Cumple? | Dónde | Evidencia mínima |
|---------------------------------|----------|-------|------------------|
| **Seguridad en redes** (red corporativa simulada) | ✅ | Fase 0–2 | Topología WAN/LAN/DMZ, tabla IPs, inventario activos |
| **IDS/IPS** con Snort o Suricata | ✅ ⚠️ | Fase 3 | Suricata en pfSense; **IPS** en §3.10 (no dejarlo sin hacer) |
| **Firewall perimetral avanzado** con reglas personalizadas | ✅ | Fase 1 | pfSense, ≥10 reglas numeradas + justificación |
| pfSense **o firewall hardware** | ✅ | Fase 1 | pfSense CE (equivalente software) |
| **Auditoría** red corporativa | ✅ | Fase 4 §4.5 | `checklist-auditoria.md` |
| **Pruebas de penetración** | ✅ | Fase 4 | `attack-lab.sh` + informe H-01…H-08 |
| **Recomendaciones de mitigación** | ✅ | Fase 4 §4.7–4.8 | Tabla mitigación + re-test |

### Detalle IDS vs IPS (importante)

El enunciado pide **detección y prevención**:

| Modo | Qué es | Fase | Obligatorio para “al pie de la letra” |
|------|--------|------|--------------------------------------|
| **IDS** | Alerta sin bloquear | 3.2 (modo IDS en WAN/DMZ) | ✅ Sí |
| **IPS** | Bloquea tráfico malicioso | 3.10 (modo IPS + 1 prueba) | ✅ **Sí** — no lo dejes solo como opcional |

---

## Requisitos del tutor

| Recomendación del tutor | ¿Cumple? | Dónde | Evidencia mínima |
|-------------------------|----------|-------|------------------|
| Suricata **paquete oficial en pfSense** (Package Manager) | ✅ | Fase 3 §3.1 | Captura Package Manager + Suricata Alerts |
| **No** VM IDS dedicada | ✅ | Fase 0, 3 | Sin `ids-suricata` en topología |
| **Vulnerabilidades intencionadas** (no solo Debian limpio) | ✅ | Fase 2 | `seed-vulnerabilities.sh` + `vulnerabilidades-intencionadas.md` |
| Syslog: logs **pfSense + Suricata** centralizados | ✅ ⚠️ | Fase 1 §1.7, 3 §3.7 | `syslog-muestra.log`; ver nota abajo |
| Contenedor o servidor Syslog básico | ✅ | `lab/docker-compose.syslog.yml` o `srv-syslog` | Docker o VM 192.168.10.5 |
| Script corto de ataque en Kali (Nmap agresivo, etc.) | ✅ | `lab/scripts/attack-lab.sh` | Fase 3.8, 4.1 + carpeta `lab-evidencias-ataque-*` |

### Nota Syslog + Suricata

pfSense envía el **system log** (incluye alertas Suricata si activas *Send Alerts to System Log*) al servidor remoto. En la memoria, indica:

1. Remote Logging activado (Fase 1/3).
2. Alerta Suricata visible en **GUI** y línea equivalente en **syslog remoto**.

---

## Mapa fase → requisito

| Fase | Enunciado oficial | Tutor |
|------|-------------------|-------|
| 0 | Red corporativa (preparación) | Scripts copiados; sin VM IDS |
| 1 | Firewall perimetral pfSense | Syslog remoto preparado |
| 2 | Servicios corporativos (DMZ/LAN) | Vulnerabilidades sembradas |
| 3 | IDS/IPS Suricata | Suricata en pfSense; script ataque; syslog |
| 4 | Auditoría + pentest + mitigación | Hallazgos reales gracias a vulns |
| 5 | Entrega y comprobación global | Demo con script + correlación logs |

---

## Checklist final (marca antes de entregar)

### Enunciado
- [ ] Diagrama red corporativa (WAN/LAN/DMZ)
- [ ] pfSense con ≥10 reglas personalizadas documentadas
- [ ] Suricata operativo (paquete pfSense)
- [ ] Modo **IDS** demostrado (≥5 alertas)
- [ ] Modo **IPS** demostrado (≥1 bloqueo o prevención documentada)
- [ ] Informe pentest ≥8 hallazgos
- [ ] Mitigaciones aplicadas + re-test

### Tutor
- [ ] Sin máquina Suricata/Snort aparte
- [ ] `seed-vulnerabilities.sh` ejecutado en srv-dmz
- [ ] `attack-lab.sh` ejecutado desde Kali
- [ ] Syslog recibe eventos de pfSense (y Suricata vía system log)
- [ ] Lista de vulns intencionadas en memoria

---

## Huecos conocidos y cómo cerrarlos

| Hueco | Riesgo | Acción |
|-------|--------|--------|
| IPS solo marcado “opcional” | No cumples “prevención” al 100% | Completar Fase 3 §3.10 |
| Fase 2 §2.5 “cerrar SSH en WAN” | Contradice vuln y regla #3 | **No cerrar** SSH/FTP en DMZ hasta después del pentest; mitigar en Fase 4 |
| Snort no documentado | Solo si el profesor exige Snort | Usar Suricata (aceptado en enunciado) o añadir anexo Snort |
| Firewall hardware | Solo si exigen HW físico | Añadir nota: pfSense = firewall perimetral software |

---

## Veredicto

| Conjunto | Estado |
|----------|--------|
| Requisitos oficiales | **Cumple** si completas Fases 1–4 y **no omites IPS (3.10)** |
| Requisitos tutor | **Cumple** en diseño de fases y scripts |
| Riesgo principal | Dejar IPS sin demostrar o endurecer DMZ en Fase 2 antes del pentest |
