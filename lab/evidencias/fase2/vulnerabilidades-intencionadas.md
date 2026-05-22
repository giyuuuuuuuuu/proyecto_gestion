# Vulnerabilidades intencionadas — solo laboratorio

> Fallos introducidos a propósito para IDS/IPS y pentest. **No replicar en producción.**

| ID | Activo | Fallo | Cómo se sembró | Herramienta de prueba |
|----|--------|-------|----------------|------------------------|
| V-01 | srv-dmz | SQLi/XSS en `/search.php` | `seed-vulnerabilities.sh` | `attack-lab.sh`, sqlmap |
| V-02 | srv-dmz | `/backup/` autoindex | idem | curl, gobuster |
| V-03 | srv-dmz | `phpinfo.php` | idem | nikto |
| V-04 | srv-dmz | SSH `lab` / `lab123` | idem | hydra |
| V-05 | srv-dmz | FTP anónimo | idem | nmap puerto 21 |
| V-06 | srv-db | PostgreSQL contraseña `1234` | manual `ALTER USER` | hydra desde LAN |
| V-07 | pfSense | Regla WAN 21/22 abierta a Kali | regla #3 fase1 | nmap desde Kali |

**Fecha de siembra:**  
**Autorización del profesor:**  
