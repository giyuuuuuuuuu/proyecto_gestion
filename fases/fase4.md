# Fase 4 — Pentest, informe y mitigaciones

**Referencia:** [`ideas/idea_2.md`](../ideas/idea_2.md) — Bloque 3  
**Requisito:** [fase3.md](fase3.md) completada  
**Duración orientativa:** 2 sesiones  
**Siguiente fase:** [fase5.md](fase5.md)

---

## Objetivo

Ejecutar la auditoría desde Kali usando **`attack-lab.sh`** como base reproducible, ampliar con pruebas manuales, documentar **≥8 hallazgos** (muchas saldrán de las vulnerabilidades sembradas), mitigar y **re-test**.

---

## Antes de empezar

- [ ] Autorización del profesor guardada (si aplica).
- [ ] Confirmar que Kali solo usa interfaz `lab-wan` / redes del lab.
- [ ] Snapshot de las VMs por si necesitas revertir tras una prueba agresiva.

---

## Metodología (seguir en orden)

```
1. Reconocimiento   → inventario, DNS, whois ficticio
2. Escaneo          → nmap -sS -sV
3. Enumeración      → versiones, dirs web, usuarios SSH
4. Análisis vuln.   → nikto, pruebas manuales
5. Explotación      → solo PoC controlado, sin DoS
6. Informe          → hallazgos H-01…
7. Mitigación       → cambios + re-test
```

---

## Tareas

### 4.1 — Ataque reproducible con script del repo

Desde **Kali** (`10.0.0.50`):

```bash
chmod +x lab/scripts/attack-lab.sh
sudo OUT_DIR=lab/evidencias/fase4/ataque-script \
  lab/scripts/attack-lab.sh 192.168.20.10 192.168.10.20
```

- [ ] Revisar `RESUMEN.txt` y logs `nmap-agresivo-dmz.*` generados por el script.
- [ ] Abrir **pfSense → Suricata → Alerts** justo después del script; exportar capturas.
- [ ] Revisar **Syslog** centralizado en la misma ventana de tiempo.

### 4.2 — Reconocimiento adicional (manual)

```bash
nmap -sn 10.0.0.0/24
nmap -sS -sV -p 21,22,80,443 192.168.20.10 -oA lab/evidencias/fase4/nmap-manual-dmz
sqlmap -u "http://192.168.20.10/search.php?q=test" --batch --level=1 --risk=1 2>&1 | tee lab/evidencias/fase4/sqlmap.txt || true
```

- [ ] Completar inventario en `inventario-activos.md`.
- [ ] Identificar puertos **22 y 21** abiertos en DMZ como hallazgos (vulnerabilidades sembradas).

**Desde srv-dmz (simular atacante en DMZ comprometido):**

```bash
nmap -sV -p 1-65535 192.168.10.20 -oA lab/evidencias/fase4/nmap-dmz-to-db
```

- [ ] Documentar si algún puerto inesperado responde (hallazgo de segmentación).

### 4.3 — Enumeración web (DMZ)

```bash
nikto -h http://192.168.20.10 -o lab/evidencias/fase4/nikto-dmz.txt
gobuster dir -u http://192.168.20.10 -w /usr/share/wordlists/dirb/common.txt -o lab/evidencias/fase4/gobuster-dmz.txt
```

- [ ] Probar cabeceras, métodos HTTP, archivos expuestos (`/server-status`, `.git`, etc.).
- [ ] Si hay app Flask: probar login, SQLi en formularios (coordinar con proyecto app).

### 4.4 — Pruebas de autenticación (limitadas)

Solo con listas **pequeñas** y autorización:

```bash
# Ejemplo MUY acotado — cambiar objetivo si no hay SSH
hydra -l admin -P /usr/share/wordlists/metasploit/unix_passwords.txt ssh://192.168.10.20 -t 4 -f -V
```

- [ ] Máximo 2–3 minutos de brute force; documentar política de contraseñas débil como hallazgo.
- [ ] Verificar que Suricata generó alerta (Fase 3) y pfSense registró intentos si aplica.

### 4.5 — Checklist de auditoría corporativa

Marcar cada ítem en `lab/evidencias/fase4/checklist-auditoria.md`:

- [ ] Inventario de activos completo
- [ ] Segmentación DMZ → LAN → BD
- [ ] Reglas firewall sin any-any peligroso
- [ ] Logging pfSense activo en bloqueos
- [ ] IDS con reglas actualizadas
- [ ] Versiones de SO/servicios documentadas (`nmap -sV`)
- [ ] Política de contraseñas / SSH root
- [ ] Sin pruebas de DoS

### 4.6 — Redactar hallazgos (mínimo 8)

Crear `lab/evidencias/fase4/informe-pentest.md` usando esta plantilla por hallazgo:

```markdown
## H-01 — Título corto
| Campo | Valor |
|-------|-------|
| Severidad | Alta / Media / Baja |
| Activo | IP o hostname |
| Vector | WAN / DMZ / LAN |
| Descripción | Qué se hizo y qué se observó |
| Evidencia | Archivo nmap, captura, log Suricata |
| CVSS / impacto | Opcional: estimación cualitativa |
| Mitigación | Acción concreta |
| Verificación | Comando re-test |
| Estado | Abierto → Mitigado |
```

**Hallazgos sugeridos para completar los 8:**

| ID | Tema | Origen típico |
|----|------|----------------|
| H-01 | BD alcanzable desde DMZ/WAN (o intento bloqueado + alerta) | nmap 5432 + Suricata 9000001 |
| H-02 | SSH en DMZ con credencial débil `lab` | hydra en attack-lab.sh |
| H-03 | SQLi reflejada en search.php | curl / sqlmap |
| H-04 | Regla WAN demasiado permisiva | revisión pfSense |
| H-05 | Sin HTTPS / cookies inseguras | curl -I, app web |
| H-06 | Contraseñas débiles SSH/DB | hydra controlado |
| H-07 | IDS no alerta en escaneo | comparar con Fase 3 |
| H-08 | Logs firewall sin revisión | procedimiento |

- [ ] Completar H-01 … H-08 (o más).
- [ ] Cada hallazgo con evidencia adjunta o referencia a archivo.

### 4.7 — Plan de mitigación

Tabla en `informe-pentest.md`:

| Hallazgo | Mitigación | Dónde | Responsable |
|----------|------------|-------|-------------|
| H-01 | Reglas #7 #8 pfSense + regla Suricata 9000001 | fw + ids | Admin red |
| H-02 | Cerrar SSH en DMZ; solo gestión desde LAN | srv-dmz | Sysadmin |
| H-03 | `apt upgrade` nginx; `server_tokens off` | srv-dmz | Sysadmin |
| … | … | … | … |

- [ ] Aplicar mitigaciones en el lab (no solo escribirlas).
- [ ] Incluir 2–3 **recomendaciones organizativas** (actualización firmas IDS, revisión trimestral de reglas).

### 4.8 — Re-test (obligatorio)

Tras mitigar, volver a ejecutar:

```bash
sudo lab/scripts/attack-lab.sh 192.168.20.10 192.168.10.20
```

Por cada H-0x mitigado:

```bash
# Ejemplo H-01: debe seguir fallando desde Kali
nmap -p 5432 -Pn 192.168.10.20
```

- [ ] Captura o salida **antes** y **después** en `lab/evidencias/fase4/retest/`.
- [ ] Cambiar estado a **Mitigado** en el informe.
- [ ] Si no se puede mitigar: marcar **Aceptado** con justificación de riesgo residual.

### 4.9 — Correlación IDS + firewall + pentest + syslog

- [ ] Elegir 2 hallazgos y mostrar triple evidencia: comando Kali + log Suricata + log pfSense.
- [ ] Añadir sección *Lecciones aprendidas* (½ página).

---

## Criterios de cierre

- [ ] Informe con ≥8 hallazgos completos.
- [ ] Metodología documentada (las 7 fases resumidas).
- [ ] ≥5 mitigaciones aplicadas y verificadas con re-test.
- [ ] Ninguna prueba ejecutada fuera del rango IP del laboratorio.
- [ ] Correlación IDS/firewall en al menos 2 casos.

---

## Evidencias

| Archivo | Descripción |
|---------|-------------|
| `informe-pentest.md` | Hallazgos + mitigaciones + re-test |
| `checklist-auditoria.md` | Checklist marcado |
| `nmap-*.xml` / `.nmap` | Escaneos |
| `retest/` | Salidas post-mitigación |

---

## Problemas frecuentes

| Problema | Solución |
|----------|----------|
| Kali no alcanza DMZ | Regla #3 WAN; NAT; gateway 10.0.0.1 |
| Pocos hallazgos | Revisar configuración débil **intencional** de práctica (banner, ssh en DMZ) |
| Informe sin re-test | Reservar última hora solo para repetir nmap/curl tras cada cambio |

---

**Anterior:** [fase3.md](fase3.md)  
**Siguiente:** [fase5.md](fase5.md) — Entrega final y defensa.
