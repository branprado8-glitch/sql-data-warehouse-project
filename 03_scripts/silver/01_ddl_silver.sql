/*
===============================================================================
 01_ddl_silver.sql  -  DDL de la capa Silver   (PostgreSQL)
===============================================================================
 Ejecutar conectado a la base data_warehouse.
 Qué hace : crea las 6 tablas de la capa Silver (borra y vuelve a crear).

 Reglas aplicadas (02_docs/naming_conventions.md):
   - Mismos nombres que en Bronze: <sourcesystem>_<entity>.
   - Columna técnica dwh_create_date (prefijo dwh_): fecha y hora en que el
     registro se cargó en Silver. La llena el DEFAULT, no el CSV.

 Cambios de estructura respecto a Bronze (ver 02_docs/silver_transformations.md):
   - crm_prd_info      : columna nueva cat_id (derivada de prd_key) y
                         prd_start_dt / prd_end_dt como DATE.
   - crm_sales_details : sls_order_dt, sls_ship_dt, sls_due_dt pasan de
                         INTEGER (AAAAMMDD) a DATE.
===============================================================================
*/

DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
    cst_id              INTEGER,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
    prd_id           INTEGER,
    cat_id           VARCHAR(50),
    prd_key          VARCHAR(50),
    prd_nm           VARCHAR(50),
    prd_cost         INTEGER,
    prd_line         VARCHAR(50),
    prd_start_dt     DATE,
    prd_end_dt       DATE,
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
    sls_ord_num      VARCHAR(50),
    sls_prd_key      VARCHAR(50),
    sls_cust_id      INTEGER,
    sls_order_dt     DATE,
    sls_ship_dt      DATE,
    sls_due_dt       DATE,
    sls_sales        INTEGER,
    sls_quantity     INTEGER,
    sls_price        INTEGER,
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
    cid              VARCHAR(50),
    bdate            DATE,
    gen              VARCHAR(50),
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
    cid              VARCHAR(50),
    cntry            VARCHAR(50),
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
    id               VARCHAR(50),
    cat              VARCHAR(50),
    subcat           VARCHAR(50),
    maintenance      VARCHAR(50),
    dwh_create_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comprobación: deben aparecer las 6 tablas del esquema silver
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'silver'
ORDER BY table_name;
