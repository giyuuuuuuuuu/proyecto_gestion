#!/usr/bin/env bash
# =============================================================================
# collect-evidence.sh — Recoge y ORGANIZA las evidencias del pentest (Fase 4).
#
# Toma la salida de exploit-vulns.sh (carpetas evidencias-exploit-*) y/o de
# attack-lab.sh (lab-evidencias-ataque-*), las copia a una estructura ordenada
# por vulnerabilidad y genera un INDICE.md + checklist de capturas manuales
# (pfSense, Suricata, syslog) para que solo tengáis que pegarlas en el PDF.
#
# Uso (en Kali, tras lanzar exploit-vulns.sh):
#   ./collect-evidence.sh                      # busca la carpeta más reciente
#   ./collect-evidence.sh evidencias-exploit-20260529-125100
#   DEST=~/entrega ./collect-evidence.sh       # cambia carpeta destino
#
# No requiere root. No borra las carpetas originales.
# =============================================================================
set -uo pipefail

DEST="${DEST:-./lab-evidencias-final}"
STAMP="$(date +%Y%m%d-%H%M%S)"
SRC="${1:-}"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
note() { echo -e "${G}[*]${NC} $*"; }
warn() { echo -e "${R}[!]${NC} $*"; }

# 1) Localizar carpeta de origen si no se pasó como argumento ----------------
if [[ -z "$SRC" ]]; then
  SRC="$(ls -dt evidencias-exploit-* lab-evidencias-ataque-* 2>/dev/null | head -1 || true)"
fi
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  warn "No encuentro carpeta de evidencias (evidencias-exploit-* / lab-evidencias-ataque-*)."
  warn "Ejecuta primero exploit-vulns.sh o pasa la ruta como argumento."
  exit 1
fi
note "Origen de evidencias: $SRC"

# 2) Estructura destino por vulnerabilidad -----------------------------------
OUT="${DEST}/fase4-${STAMP}"
mkdir -p "$OUT"/{V-01_sqli_xss,V-02_backup,V-03_phpinfo,V-04_ssh,V-05_ftp,V-06_postgres,V-07_recon,capturas-pfSense,capturas-suricata,syslog}

map_copy() {  # $1=patrón  $2=subcarpeta
  shopt -s nullglob
  local f found=0
  for f in "$SRC"/$1; do cp -f "$f" "$OUT/$2/" && found=1; done
  shopt -u nullglob
  [[ "$found" -eq 1 ]] && echo "  ok  $1 -> $2" || echo "  --  (sin $1)"
}

note "Clasificando salidas por vulnerabilidad..."
map_copy "v01-*"        "V-01_sqli_xss"
map_copy "v02-*"        "V-02_backup"
map_copy "v03-*"        "V-03_phpinfo"
map_copy "v04-*"        "V-04_ssh"
map_copy "v05-*"        "V-05_ftp"
map_copy "v06-*"        "V-06_postgres"
map_copy "v07-*"        "V-07_recon"
# Salidas del attack-lab.sh genérico (si existen)
map_copy "nmap-*"       "V-07_recon"
map_copy "nikto-*"      "V-01_sqli_xss"
map_copy "curl-paths*"  "V-01_sqli_xss"
map_copy "hydra-*"      "V-04_ssh"
map_copy "RESUMEN.txt"  "."

# 3) Índice / checklist ------------------------------------------------------
INDEX="$OUT/INDICE.md"
{
  echo "# Índice de evidencias — Fase 4 (pentest)"
  echo ""
  echo "- **Generado:** $(date -Iseconds)"
  echo "- **Origen:** \`$SRC\`"
  echo "- **Equipo atacante:** Kali (WAN)"
  echo ""
  echo "## Evidencias automáticas (salidas de scripts)"
  echo ""
  echo "| V-id | Vulnerabilidad | Carpeta | Ficheros |"
  echo "|------|----------------|---------|----------|"
  for d in V-01_sqli_xss V-02_backup V-03_phpinfo V-04_ssh V-05_ftp V-06_postgres V-07_recon; do
    n=$(ls -1 "$OUT/$d" 2>/dev/null | wc -l | tr -d ' ')
    files=$(ls -1 "$OUT/$d" 2>/dev/null | paste -sd', ' - )
    echo "| ${d%%_*} | ${d#*_} | \`$d/\` | ${files:-—} ($n) |"
  done
  echo ""
  echo "## Capturas MANUALES pendientes (pegar aquí)"
  echo ""
  echo "Estas no las genera el script: hay que tomarlas en pfSense y el syslog."
  echo ""
  echo "| Estado | Carpeta | Captura a tomar |"
  echo "|--------|---------|-----------------|"
  echo "| ☐ | \`capturas-suricata/\` | Services > Suricata > Alerts (filtrar sid 9000001-9000008) |"
  echo "| ☐ | \`capturas-pfSense/\` | Status > System Logs > Firewall (bloqueo a 5432) |"
  echo "| ☐ | \`capturas-pfSense/\` | Firewall > Rules (WAN/LAN/DMZ) |"
  echo "| ☐ | \`syslog/\` | Línea recibida en srv-syslog en el mismo instante |"
  echo ""
  echo "## Correlación triple (rellenar para la memoria)"
  echo ""
  echo "| Hallazgo | Comando Kali | Alerta Suricata (sid) | Log pfSense | Estado |"
  echo "|----------|--------------|-----------------------|-------------|--------|"
  echo "| V-01 SQLi | exploit-vulns.sh v01 | 9000002 | — | ☐ |"
  echo "| V-01 XSS  | exploit-vulns.sh v01 | 9000003 | — | ☐ |"
  echo "| V-02 backup | exploit-vulns.sh v02 | 9000004 | — | ☐ |"
  echo "| V-03 phpinfo | exploit-vulns.sh v03 | 9000005 | — | ☐ |"
  echo "| V-04 SSH brute | exploit-vulns.sh v04 | 9000006 | — | ☐ |"
  echo "| V-05 FTP anon | exploit-vulns.sh v05 | 9000007 | — | ☐ |"
  echo "| V-06 PostgreSQL | exploit-vulns.sh v06 | 9000001 | BLOCK 5432 | ☐ |"
  echo "| V-07 recon | exploit-vulns.sh v07 | 9000008 | regla #3 | ☐ |"
} > "$INDEX"

# 4) Empaquetado opcional ----------------------------------------------------
if command -v tar >/dev/null; then
  tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")" 2>/dev/null \
    && note "Paquete: ${OUT}.tar.gz"
fi

note "Estructura creada en: $OUT"
note "Índice: $INDEX"
echo ""
echo -e "${Y}Siguiente:${NC} toma las capturas manuales (Suricata/pfSense/syslog),"
echo "déjalas en sus carpetas y completa la tabla de correlación del INDICE.md."
