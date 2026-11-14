# Guía de configuración

## Requisitos

- Windows con **PostgreSQL 11 o superior** (probado con 16; el autor usa 18.1) y **pgAdmin 4**.
- Conectarse con el usuario **`postgres`** (superusuario). `COPY ... FROM 'archivo'` exige un superusuario o el rol `pg_read_server_files`.
- El repositorio clonado en **`C:\ISW623\sql-data-warehouse-project`**: los scripts de carga leen los CSV desde `C:/ISW623/sql-data-warehouse-project/01_datasets/`.

## Orden de ejecución en pgAdmin

| # | Dónde abrir el Query Tool | Archivo | Cómo |
|---|---|---|---|
| 1 | Base `postgres` | `03_scripts/init_database.sql` | Seleccionar solo `CREATE DATABASE data_warehouse;` y F5 |
| 2 | Base `data_warehouse` | `03_scripts/init_database.sql` | Seleccionar desde `PARTE 2` hasta el final y F5 |
| 3 | `data_warehouse` | `03_scripts/bronze/01_ddl_bronze.sql` | F5 |
| 4 | `data_warehouse` | `03_scripts/bronze/02_load_bronze_copy.sql` | F5 (prueba opcional) |
| 5 | `data_warehouse` | `03_scripts/bronze/03_proc_load_bronze.sql` | F5 |
| 6 | `data_warehouse` | — | `CALL bronze.load_bronze();` y F5 |
| 7 | `data_warehouse` | `04_tests/quality_checks_bronze.sql` | Cada bloque por separado |
| 8 | `data_warehouse` | `03_scripts/silver/01_ddl_silver.sql` | F5 |
| 9 | `data_warehouse` | `03_scripts/silver/02_proc_load_silver.sql` | F5 |
| 10 | `data_warehouse` | — | `CALL silver.load_silver();` y F5 |
| 11 | `data_warehouse` | `04_tests/quality_checks_silver.sql` | Cada bloque por separado |

Para recargar todo más adelante basta con:
```sql
CALL bronze.load_bronze();
CALL silver.load_silver();
```

## Por qué esa carpeta

`COPY` lee los CSV **desde el servicio de PostgreSQL**, no desde el usuario de Windows. Si el proyecto queda en `Descargas`, `Escritorio` u `OneDrive`, el servicio normalmente no tiene permiso y aparece *Permission denied*.

## Reglas

- No abrir ni guardar los CSV con Excel: cambia el formato de fechas.
