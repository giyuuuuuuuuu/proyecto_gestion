#!/usr/bin/env bash
# =============================================================================
# seed-vulnerabilities.sh — Siembra las vulnerabilidades INTENCIONADAS del lab.
#                           SOLO laboratorio. NUNCA en producción.
#
#   - En srv-dmz:  sudo bash seed-vulnerabilities.sh dmz     (V-01..V-05 + banner)
#   - En srv-db:   sudo bash seed-vulnerabilities.sh db      (V-06)
#   - Todo junto:  sudo bash seed-vulnerabilities.sh all
#
# Es idempotente: se puede re-ejecutar. Tras sembrar, valida con check-vulns.sh.
# Vulnerabilidades (ver lab/evidencias/fase2/vulnerabilidades-intencionadas.md):
#   V-01 SQLi/XSS en /search.php   V-02 /backup/ autoindex   V-03 phpinfo.php
#   V-04 SSH lab/lab123            V-05 FTP anónimo           V-06 PostgreSQL 1234
# =============================================================================
set -euo pipefail

ROLE="${1:-dmz}"
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
note() { echo -e "${G}[*]${NC} $*"; }
warn() { echo -e "${R}[LAB-ONLY]${NC} $*"; }

[[ "$(id -u)" -eq 0 ]] || { echo "Ejecuta como root: sudo bash $0 $ROLE"; exit 1; }
warn "Entorno de PRÁCTICAS — se instalarán fallos a propósito. Ctrl+C para abortar."
sleep 2

# =============================================================================
seed_dmz() {
  note "Sembrando vulnerabilidades en srv-dmz (V-01..V-05)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq nginx php-fpm php-sqlite3 openssh-server vsftpd curl

  # --- V-02: /backup/ con fichero "sensible" ---
  mkdir -p /var/www/html/backup
  echo "backup-secreto-lab-$(date +%Y)" > /var/www/html/backup/notas.txt
  chmod -R 755 /var/www/html/backup

  # --- V-01: search.php refleja la entrada SIN sanitizar (SQLi/XSS) ---
  cat > /var/www/html/search.php <<'PHP'
<?php
// VULNERABLE A PROPOSITO — laboratorio (refleja sin sanitizar)
$q = $_GET['q'] ?? '';
echo "<h1>Busqueda corporativa</h1><p>Consulta: " . $q . "</p>";
PHP

  # --- V-03: phpinfo expuesto ---
  echo '<?php phpinfo();' > /var/www/html/phpinfo.php

  # --- nginx: autoindex en /backup + banner visible (server_tokens on) ---
  cat > /etc/nginx/sites-available/lab-vuln <<'NGX'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html index.php;
    server_tokens on;

    location /backup/ {
        autoindex on;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGX
  # Ajustar el socket real de PHP-FPM (la versión varía según distro)
  PHP_SOCK="$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1 || true)"
  if [[ -n "$PHP_SOCK" ]]; then
    sed -i "s|unix:/run/php/php-fpm.sock|unix:${PHP_SOCK}|" /etc/nginx/sites-available/lab-vuln
  fi
  ln -sf /etc/nginx/sites-available/lab-vuln /etc/nginx/sites-enabled/default
  nginx -t && (systemctl restart nginx php*-fpm 2>/dev/null || systemctl restart nginx)

  # --- V-04: usuario SSH débil lab/lab123 ---
  id -u lab &>/dev/null || useradd -m -s /bin/bash lab
  echo 'lab:lab123' | chpasswd
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl restart ssh 2>/dev/null || systemctl restart sshd

  # --- V-05: FTP anónimo (vsftpd) ---
  cat > /etc/vsftpd.conf <<'FTP'
listen=YES
anonymous_enable=YES
local_enable=NO
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
pam_service_name=vsftpd
FTP
  systemctl enable --now vsftpd

  # --- Portal de aviso ---
  cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Portal Corp — LAB</title></head>
<body>
  <h1>Portal corporativo (entorno de prácticas)</h1>
  <p>Servidor con <strong>vulnerabilidades intencionadas</strong> para IDS/IPS y pentest.</p>
  <ul>
    <li><a href="/search.php?q=test">Búsqueda</a></li>
    <li><a href="/backup/">Backup (autoindex)</a></li>
  </ul>
</body>
</html>
HTML

  note "srv-dmz listo. Activas: V-01 search.php, V-02 /backup/, V-03 phpinfo, V-04 SSH lab/lab123, V-05 FTP anónimo."
}

# =============================================================================
seed_db() {
  note "Sembrando vulnerabilidad en srv-db (V-06: PostgreSQL con contraseña débil)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq postgresql

  # Escuchar en la IP de LAN (ajusta si tu IP difiere de la tabla de Fase 0)
  PG_CONF="$(ls /etc/postgresql/*/main/postgresql.conf 2>/dev/null | head -1 || true)"
  PG_HBA="$(ls /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1 || true)"
  if [[ -n "$PG_CONF" ]]; then
    sed -i "s/^#*listen_addresses.*/listen_addresses = '192.168.10.20,127.0.0.1'/" "$PG_CONF"
  fi
  # Solo la LAN puede conectar (segmentación; el bloqueo real lo hace pfSense)
  if [[ -n "$PG_HBA" ]] && ! grep -q "192.168.10.0/24" "$PG_HBA"; then
    echo "host    all    all    192.168.10.0/24    scram-sha-256" >> "$PG_HBA"
  fi
  systemctl restart postgresql

  # Usuario/BD de prueba con contraseña DÉBIL intencional (hallazgo de auditoría)
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='lab_app'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE USER lab_app WITH PASSWORD '1234';"
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='corp_db'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE DATABASE corp_db OWNER lab_app;"
  sudo -u postgres psql -c "ALTER USER lab_app PASSWORD '1234';"

  note "srv-db listo. Activa: V-06 PostgreSQL lab_app/1234 escuchando en 192.168.10.20:5432."
}

# =============================================================================
case "${ROLE,,}" in
  dmz) seed_dmz ;;
  db)  seed_db ;;
  all) seed_dmz; seed_db ;;
  *)   echo "Rol desconocido: $ROLE (usa: dmz | db | all)"; exit 1 ;;
esac

echo ""
note "Siembra completada (rol: $ROLE)."
echo -e "${Y}Siguiente:${NC} valida con  sudo bash check-vulns.sh $ROLE"
