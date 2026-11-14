/*
===============================================================================
 01_ddl_bronze.sql  -  DDL de la capa Bronze   (PostgreSQL)
===============================================================================
 Ejecutar conectado a la base data_warehouse.
 Qué hace : crea las 6 tablas de la capa Bronze (borra y vuelve a crear).

 Reglas aplicadas (02_docs/naming_conventions.md):
   - Nombre de tabla: <sourcesystem>_<entity>  (crm_..., erp_...)
   - snake_case en minúscula; las columnas conservan el nombre del CSV
     (las del ERP venían en MAYÚSCULA y se pasan a minúscula).
   - Bronze = datos "tal como se reciben": sin limpieza, sin columnas extra.

 Tipos de datos: elegidos revisando los 6 CSV reales.
   - Textos en VARCHAR(50): el texto más largo mide 32 caracteres.
   - sls_order_dt, sls_ship_dt, sls_due_dt quedan en INTEGER porque vienen
     como 20101229 y hay valores 0 (no son fechas válidas). Se convierten
     en Silver.
   - Fechas con formato AAAA-MM-DD se guardan como DATE.

 ATENCIÓN: borra las tablas si ya existen (se pierden los datos de Bronze,
 que se vuelven a cargar con CALL bronze.load_bronze()).
===============================================================================
*/

-- CRM: información de clientes  (source_crm/cust_info.csv)
DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id              INTEGER,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);

-- CRM: información de productos  (source_crm/prd_info.csv)
DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id        INTEGER,
    prd_key       VARCHAR(50),
    prd_nm        VARCHAR(50),
    prd_cost      INTEGER,
    prd_line      VARCHAR(50),
    prd_start_dt  DATE,
    prd_end_dt    DATE
);

-- CRM: detalle de ventas  (source_crm/sales_details.csv)
DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num   VARCHAR(50),
    sls_prd_key   VARCHAR(50),
    sls_cust_id   INTEGER,
    sls_order_dt  INTEGER,
    sls_ship_dt   INTEGER,
    sls_due_dt    INTEGER,
    sls_sales     INTEGER,
    sls_quantity  INTEGER,
    sls_price     INTEGER
);

-- ERP: datos adicionales del cliente  (source_erp/CUST_AZ12.csv)
DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50)
);

-- ERP: ubicación del cliente  (source_erp/LOC_A101.csv)
DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50)
);

-- ERP: categorías de productos  (source_erp/PX_CAT_G1V2.csv)
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);

-- Comprobación: deben aparecer las 6 tablas del esquema bronze
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'bronze'
ORDER BY table_name;
