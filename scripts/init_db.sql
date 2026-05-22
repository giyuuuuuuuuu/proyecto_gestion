-- Fase 0: crear usuario y base de datos de la app
-- Ejecutar como superusuario: .\scripts\setup_postgres.ps1

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'gestion_app') THEN
    CREATE ROLE gestion_app WITH LOGIN PASSWORD 'gestion_dev_pass';
  ELSE
    ALTER ROLE gestion_app WITH LOGIN PASSWORD 'gestion_dev_pass';
  END IF;
END
$$;

SELECT 'CREATE DATABASE gestion_db OWNER gestion_app ENCODING ''UTF8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gestion_db')\gexec

GRANT ALL PRIVILEGES ON DATABASE gestion_db TO gestion_app;
