# Fase 5 — Entrega final y defensa

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md)  
**Requisito:** [fase4.md](fase4.md) completada  
**Duración orientativa:** 1 sesión

---

## Objetivo

Consolidar todas las evidencias en un **paquete de entrega** listo para el profesor: memoria, diagramas, demo en vivo y comprobación de todos los criterios del ejercicio.

---

## Tareas

### 5.1 — Verificar criterios globales del ejercicio

Marcar cuando esté comprobado (ver también `idea_2.md`):

- [ ] Topología documentada (WAN/LAN/DMZ + IPs).
- [ ] pfSense: ≥10 reglas con justificación ([fase1](fase1.md)).
- [ ] Suricata en pfSense: ≥5 alertas tras `attack-lab.sh` ([fase3](fase3.md)).
- [ ] ≥2 reglas custom Suricata (sid 900000x).
- [ ] Syslog centralizado operativo.
- [ ] Vulnerabilidades intencionadas documentadas ([fase2](fase2.md)).
- [ ] Informe pentest: ≥8 hallazgos + mitigaciones + re-test ([fase4](fase4.md)).
- [ ] Pentest solo en laboratorio autorizado.

### 5.2 — Memoria / informe final (PDF recomendado)

Estructura sugerida (20–40 páginas según nivel):

1. **Portada** — título, autor, fecha, módulo Seguridad en redes.
2. **Índice**
3. **Introducción** — objetivos del ejercicio (IDS/IPS, firewall, auditoría).
4. **Topología** — diagrama + tabla IPs ([fase0](fase0.md)).
5. **Firewall perimetral** — reglas numeradas, NAT, capturas, pruebas ([fase1](fase1.md)).
6. **Servicios corporativos** — DMZ vs LAN, PostgreSQL ([fase2](fase2.md)).
7. **IDS/IPS** — despliegue, reglas ET, `local.rules`, alertas ([fase3](fase3.md)).
8. **Auditoría y pentest** — metodología, hallazgos H-01…, mitigaciones ([fase4](fase4.md)).
9. **Conclusiones y recomendaciones** — organizativas y técnicas.
10. **Anexos** — logs, exports, comandos.

- [ ] Exportar a PDF: `lab/evidencias/fase5/memoria-seguridad-redes.pdf`
- [ ] Revisar ortografía y que cada captura tenga pie de figura.

### 5.3 — Diagrama de red final

- [ ] Diagrama actualizado (draw.io, Lucidchart, Excalidraw o PNG).
- [ ] Incluir: zonas, IPs, flujos permitidos (flechas verdes) y bloqueados (rojas).
- [ ] Guardar: `lab/evidencias/fase5/diagrama-red-final.png` (+ fuente editable si existe).

### 5.4 — Paquete de artefactos técnicos

Comprimir o organizar en carpeta `lab/entrega/`:

| Artefacto | Origen |
|-----------|--------|
| Export reglas pfSense | fase1 |
| `local.rules` + fragmento `suricata.yaml` | fase3 |
| `informe-pentest.md` | fase4 |
| Logs alertas (extractos) | fase3 |
| Salidas re-test | fase4/retest |
| `tabla-ips.md` | fase0 |
| `inventario-activos.md` | fase2/4 |

- [ ] Crear `lab/entrega/INDICE.md` con lista de archivos y descripción de una línea cada uno.
- [ ] Opcional: `lab/entrega.zip` para subir al campus virtual.

### 5.5 — Guion de demo en vivo (10–15 min)

Preparar `lab/evidencias/fase5/guion-demo.md`:

1. **Mostrar topología** (diagrama, 1 min).
2. **Firewall:** desde Kali, `nmap` a BD bloqueado; mostrar log pfSense (2 min).
3. **Servicio web:** `curl` portal en DMZ desde WAN vía NAT (1 min).
4. **IDS:** ejecutar `attack-lab.sh` (o un solo `nmap -T4`); mostrar alertas en **Suricata → Alerts** y una línea en Syslog (3 min).
5. **Pentest:** resumir 2 hallazgos críticos y mitigación aplicada (2 min).
6. **Re-test:** repetir comando que antes funcionaba y ahora falla (2 min).
7. **Preguntas** del profesor.

- [ ] Ensayar la demo al menos una vez.
- [ ] Tener snapshots de VMs por si algo falla el día de la entrega.

### 5.6 — Defensa oral / preguntas preparadas

Preparar respuestas breves para:

- [ ] ¿Por qué DMZ no puede iniciar conexiones a LAN?
- [ ] ¿IDS pasivo vs IPS inline? ¿Cuál usaste y por qué?
- [ ] ¿Cómo evitarías falsos positivos en Suricata?
- [ ] ¿Qué harías si H-01 (BD expuesta) fuera en producción?
- [ ] Diferencia entre **detección** (IDS) y **prevención** (IPS + firewall).

### 5.7 — Repositorio Git (opcional)

- [ ] README en raíz o `lab/README.md` con: hipervisor, IPs, cómo arrancar VMs, orden de fases.
- [ ] Enlazar `fases/README.md` desde el README principal del proyecto.
- [ ] No subir `.env`, contraseñas reales ni `lab/evidencias/` pesado (usar `.gitignore`).

### 5.8 — Autoevaluación final

| Bloque del temario | ¿Cubierto? | Evidencia principal |
|------------------|------------|---------------------|
| IDS/IPS Suricata/Snort | ☐ | alertas.md, local.rules |
| Firewall pfSense | ☐ | reglas-pfsense.md, capturas |
| Auditoría + pentest + mitigación | ☐ | informe-pentest.md, retest |

- [ ] Las tres filas marcadas antes de entregar.

---

## Criterios de cierre

- [ ] PDF/memoria entregable completa.
- [ ] Diagrama final + índice de artefactos.
- [ ] Demo ensayada (guion listo).
- [ ] Todos los checklists de fase0–fase4 revisados.
- [ ] Entrega al profesor según su canal (Moodle, Git, USB).

---

## Evidencias de esta fase

| Archivo | Descripción |
|---------|-------------|
| `memoria-seguridad-redes.pdf` | Documento principal |
| `diagrama-red-final.png` | Topología final |
| `guion-demo.md` | Guión presentación |
| `INDICE.md` | Lista de artefactos en `lab/entrega/` |

---

## Después del ejercicio

- [ ] Apagar VMs y liberar recursos del hipervisor.
- [ ] Guardar snapshots finales del lab por si el profesor pide repetir la demo.
- [ ] Opcional: integrar lecciones en el proyecto Flask (`ideas/ideas.md`) para un trabajo integrado app + red.

---

**Anterior:** [fase4.md](fase4.md)  
**Inicio del lab:** [fase0.md](fase0.md) · **Índice:** [README.md](README.md)
