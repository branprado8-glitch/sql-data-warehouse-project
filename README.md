# sql-data-warehouse-project

ISW-623 Bases de Datos Avanzadas · Clase 09 · Arquitectura Medallion (ejercicio).
Universidad Técnica Nacional, Sede San Carlos.

Almacén de datos en **PostgreSQL** que consolida las ventas de dos sistemas de origen (CRM y ERP) entregados como archivos CSV, organizado en las capas Bronze, Silver y Gold.

**Estado actual:** capa Bronze construida (DDL, carga con `COPY` y procedimiento `bronze.load_bronze`). Silver y Gold son las siguientes etapas del roadmap.

## Estructura

```
sql-data-warehouse-project/
├── 00_setup/          Guía de configuración.
├── 01_datasets/       Los seis archivos de origen.
│   ├── source_crm/    cust_info.csv, prd_info.csv, sales_details.csv
│   └── source_erp/    CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv
├── 02_docs/           Requisitos, convenciones, roadmap, análisis de origen y flujo de datos.
├── 03_scripts/
│   ├── init_database.sql            Crea la BD y los esquemas. Ejecutar primero.
│   ├── bronze/
│   │   ├── 01_ddl_bronze.sql        CREATE TABLE de las 6 tablas.
│   │   ├── 02_load_bronze_copy.sql  COPY para probar la carga.
│   │   └── 03_proc_load_bronze.sql  CREATE OR REPLACE PROCEDURE bronze.load_bronze
│   ├── silver/        (siguiente etapa)
│   └── gold/          (siguiente etapa)
└── 04_tests/
    └── quality_checks_bronze.sql    Conteo de filas y columnas de Bronze.
```

## Orden de ejecución

1. `03_scripts/init_database.sql` (parte 1 sobre la base `postgres`, parte 2 sobre `data_warehouse`)
2. `03_scripts/bronze/01_ddl_bronze.sql`
3. `03_scripts/bronze/02_load_bronze_copy.sql` (prueba)
4. `03_scripts/bronze/03_proc_load_bronze.sql` y luego `CALL bronze.load_bronze();`
5. `04_tests/quality_checks_bronze.sql`

## Documentación

- `02_docs/project_requirements.md`: objetivo y especificaciones.
- `02_docs/naming_conventions.md`: convenciones de nomenclatura.
- `02_docs/source_analysis.md`: qué trae cada CSV, relaciones y problemas de calidad.
- `02_docs/data_flow.md` y `data_flow.svg`: flujo de datos entre capas.

## Decisiones de diseño

- **PostgreSQL en lugar de SQL Server.** El pptx está escrito para SQL Server; los equivalentes usados son `BULK INSERT` → `COPY`, y `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE PROCEDURE ... LANGUAGE plpgsql`.
- **Una sola base (`data_warehouse`) con tres esquemas** (`bronze`, `silver`, `gold`) en lugar de tres bases. Es más simple y, en PostgreSQL, una consulta no puede leer tablas de otra base sin extensiones (`dblink`, `postgres_fdw`), lo que complicaría pasar datos de una capa a otra.
- **Gold se implementará con vistas** (diapositiva 6) y todos los nombres van en inglés, según las convenciones.
- **Los CSV se versionan en el repositorio.** Son unos 5 MB y los scripts los necesitan para funcionar.

## Autores

Brandon Prado Mora
