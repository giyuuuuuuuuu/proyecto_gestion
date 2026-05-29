#!/usr/bin/env bash
# =============================================================================
# check-vulns.sh — Verifica que las vulnerabilidades intencionadas (V-01..V-06)
#                  están presentes ANTES del pentest. SOLO laboratorio.
#
#   - Ejecutar en srv-dmz:  sudo bash check-vulns.sh dmz
#   - Ejecutar en srv-db:   sudo bash check-vulns.sh db
#   - Ambos (si el host tiene todo): sudo bash check-vulns.sh all
#
# Salida: tabla PASS/FALLA por cada V-id. No modifica nada (solo comprueba).
# =============================================================================
set -uo pipefail

ROLE="${1:-all}"
PASS="\033[0;32mPRESENTE\033[0m"
FAIL="\033[0;31mFALTA   \033[0m"
NC="\033[0m"

ok=0; ko=0
line() { printf "  %-6s | %-40s | %b\n" "$1" "$2" "$3"; }

check() {  # $1=id  $2=desc  $3=comando-test
  if eval "$3" >/dev/null 2>&1; then line "$1" "$2" "$PASS"; ok=$((ok+1));
  else line "$1" "$2" "$FAIL"; ko=$((ko+1)); fi
}

echo "=== check-vulns.sh — rol: $ROLE ==="
printf "  %-6s | %-40s | %s\n" "ID" "Vulnerabilidad" "Estado"
echo "  -------|------------------------------------------|---------"

if [[ "$ROLE" == "dmz" || "$ROLE" == "all" ]]; then
  check "V-01" "/search.php responde (reflejo sin sanitizar)" \
    "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/search.php?q=test | grep -q 200"
  check "V-02" "/backup/ con autoindex activo" \
    "curl -s http://127.0.0.1/backup/ | grep -qi 'Index of'"
  check "V-03" "/phpinfo.php expuesto" \
    "curl -s http://127.0.0.1/phpinfo.php | grep -qi 'phpinfo'"
  check "V-04" "SSH usuario 'lab' existe" \
    "id lab"
  check "V-05" "FTP anónimo (vsftpd activo, anonymous_enable=YES)" \
    "systemctl is-active vsftpd && grep -q '^anonymous_enable=YES' /etc/vsftpd.conf"
  check "V-EX" "server_tokens on (banner nginx visible)" \
    "grep -rq 'server_tokens on' /etc/nginx/"
fi

if [[ "$ROLE" == "db" || "$ROLE" == "all" ]]; then
  check "V-06a" "PostgreSQL escuchando en 5432" \
    "ss -tlnp 2>/dev/null | grep -q ':5432'"
  # Comprueba que la contraseña débil '1234' funciona para lab_app (vuln intencional)
  check "V-06b" "Login lab_app/1234 aceptado (contraseña débil)" \
    "PGPASSWORD=1234 psql -h 127.0.0.1 -U lab_app -d corp_db -c 'SELECT 1' "
fi

echo "  -------|------------------------------------------|---------"
echo "  Resultado: $ok presentes, $ko faltan."
[[ "$ko" -eq 0 ]] && echo "  OK: entorno listo para el pentest." \
                  || echo "  Revisa las que faltan (¿ejecutaste seed-vulnerabilities.sh?)."
