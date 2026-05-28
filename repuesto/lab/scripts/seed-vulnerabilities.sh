#!/usr/bin/env bash
# =============================================================================
# seed-vulnerabilities.sh — Introduce fallos CONTROLADOS para el pentest del lab
# Ejecutar SOLO en srv-dmz (como root). NO usar en producción.
# Uso en srv-dmz: sudo bash seed-vulnerabilities.sh
# =============================================================================
set -euo pipefail

echo ">>> ENTORNO DE PRÁCTICAS — instalando vulnerabilidades intencionadas"
sleep 1

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx php-fpm php-sqlite3 openssh-server vsftpd

# --- 1) Web: listado de directorio y PHP vulnerable ---
mkdir -p /var/www/html/backup
echo "backup-secreto-lab-2024" > /var/www/html/backup/notas.txt
chmod -R 755 /var/www/html/backup

cat > /var/www/html/search.php <<'PHP'
<?php
// VULNERABLE A PROPOSITO — laboratorio
$q = $_GET['q'] ?? '';
echo "<h1>Busqueda corporativa</h1><p>Consulta: " . $q . "</p>";
PHP

# phpinfo expuesto (hallazgo de información)
echo '<?php phpinfo();' > /var/www/html/phpinfo.php

# Nginx: autoindex en /backup y banner visible
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
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
NGX
# Ajustar socket PHP si la versión difiere
PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1)
if [[ -n "$PHP_SOCK" ]]; then
  sed -i "s|php8.2-fpm.sock|$(basename "$PHP_SOCK")|" /etc/nginx/sites-available/lab-vuln
fi
ln -sf /etc/nginx/sites-available/lab-vuln /etc/nginx/sites-enabled/default
systemctl restart nginx php*-fpm 2>/dev/null || systemctl restart nginx

# --- 2) SSH en DMZ con usuario débil (para hydra / alertas) ---
id -u lab &>/dev/null || useradd -m -s /bin/bash lab
echo 'lab:lab123' | chpasswd
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

# --- 3) FTP anónimo (reconocimiento / alertas ET) ---
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

# --- 4) Página de aviso ---
cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Portal Corp — LAB</title></head>
<body>
  <h1>Portal corporativo (entorno de prácticas)</h1>
  <p>Este servidor contiene <strong>vulnerabilidades intencionadas</strong> para IDS/IPS y pentest.</p>
  <ul>
    <li><a href="/search.php?q=test">Búsqueda</a></li>
    <li><a href="/backup/">Backup (autoindex)</a></li>
  </ul>
</body>
</html>
HTML

echo ""
echo ">>> Listo en srv-dmz. Vulnerabilidades activas:"
echo "    - /search.php (reflejo sin sanitizar)"
echo "    - /backup/ (autoindex)"
echo "    - /phpinfo.php"
echo "    - SSH usuario lab / lab123"
echo "    - FTP anónimo puerto 21"
echo ""
echo ">>> En srv-db (LAN), ejecuta aparte:"
echo "    sudo -u postgres psql -c \"ALTER USER lab_app PASSWORD '1234';\""
