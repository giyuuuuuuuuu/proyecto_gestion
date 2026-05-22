# Crea usuario y base de datos de la app (Fase 0).
# Uso: .\scripts\setup_postgres.ps1
# Te pedirá la contraseña del usuario postgres de tu instalación local.

$ErrorActionPreference = "Stop"

# Preferir la instancia en ejecución (en este equipo suele ser la 17)
$psqlCandidates = @(
    "C:\Program Files\PostgreSQL\17\bin\psql.exe",
    "C:\Program Files\PostgreSQL\18\bin\psql.exe"
)

$psql = $psqlCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $psql) {
    Write-Error "No se encontró psql.exe. Añade PostgreSQL al PATH o edita este script."
}

$secure = Read-Host "Contraseña del usuario postgres" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

$initSql = Join-Path $PSScriptRoot "init_db.sql"
& $psql -U postgres -h localhost -f $initSql

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falló la inicialización de PostgreSQL (código $LASTEXITCODE)."
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host "Listo: usuario gestion_app y base de datos gestion_db."
