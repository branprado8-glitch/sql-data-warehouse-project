/*
===============================================================================
 02_load_bronze_copy.sql  -  Scripts de carga (COPY)   (PostgreSQL)
===============================================================================
 Ejecutar conectado a la base data_warehouse.
 Qué hace : vacía cada tabla de Bronze y la vuelve a llenar desde su CSV.
            Método de carga del pptx: carga completa (Truncate & Insert),
            sin transformaciones.
            En PostgreSQL, COPY es el equivalente de BULK INSERT de SQL Server.

 Este archivo sirve para PROBAR la carga tabla por tabla antes de
 envolverla en el procedimiento almacenado (03_proc_load_bronze.sql).

 RUTA DE LOS ARCHIVOS: todas las rutas apuntan a
     C:/ISW623/sql-data-warehouse-project/01_datasets
 (en PostgreSQL se escriben con / aunque sea Windows).
 Si el proyecto está en otra carpeta, en pgAdmin usar Ctrl+Shift+F o el menú
 Edit > Replace y cambiar  C:/ISW623/sql-data-warehouse-project  por la ruta real.

 COPY ... FROM 'archivo' lo lee el SERVICIO de PostgreSQL (no tu usuario de
 Windows) y requiere conectarse con un superusuario (el usuario "postgres").
 Los CSV NO deben abrirse ni guardarse con Excel.
===============================================================================
*/

-- bronze.crm_cust_info  <-  source_crm/cust_info.csv
TRUNCATE TABLE bronze.crm_cust_info;
COPY bronze.crm_cust_info
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/cust_info.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- bronze.crm_prd_info  <-  source_crm/prd_info.csv
TRUNCATE TABLE bronze.crm_prd_info;
COPY bronze.crm_prd_info
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/prd_info.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- bronze.crm_sales_details  <-  source_crm/sales_details.csv
TRUNCATE TABLE bronze.crm_sales_details;
COPY bronze.crm_sales_details
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/sales_details.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- bronze.erp_cust_az12  <-  source_erp/CUST_AZ12.csv
TRUNCATE TABLE bronze.erp_cust_az12;
COPY bronze.erp_cust_az12
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/CUST_AZ12.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- bronze.erp_loc_a101  <-  source_erp/LOC_A101.csv
TRUNCATE TABLE bronze.erp_loc_a101;
COPY bronze.erp_loc_a101
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/LOC_A101.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- bronze.erp_px_cat_g1v2  <-  source_erp/PX_CAT_G1V2.csv
TRUNCATE TABLE bronze.erp_px_cat_g1v2;
COPY bronze.erp_px_cat_g1v2
FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/PX_CAT_G1V2.csv'
WITH (
    FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
    HEADER true,       -- la fila 1 es el encabezado y se salta
    ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
);

-- Comprobación rápida: cantidad de filas cargadas por tabla
SELECT 'crm_cust_info'     AS tabla, COUNT(*) AS filas FROM bronze.crm_cust_info     UNION ALL
SELECT 'crm_prd_info',               COUNT(*)          FROM bronze.crm_prd_info      UNION ALL
SELECT 'crm_sales_details',          COUNT(*)          FROM bronze.crm_sales_details UNION ALL
SELECT 'erp_cust_az12',              COUNT(*)          FROM bronze.erp_cust_az12     UNION ALL
SELECT 'erp_loc_a101',               COUNT(*)          FROM bronze.erp_loc_a101      UNION ALL
SELECT 'erp_px_cat_g1v2',            COUNT(*)          FROM bronze.erp_px_cat_g1v2;
