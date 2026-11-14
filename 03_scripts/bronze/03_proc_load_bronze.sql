/*
===============================================================================
 03_proc_load_bronze.sql  -  Procedimiento almacenado bronze.load_bronze
===============================================================================
 Ejecutar conectado a la base data_warehouse.   (PostgreSQL 11 o superior)
 Qué hace : crea (o reemplaza) el procedimiento bronze.load_bronze, que carga
            las 6 tablas de Bronze desde los CSV (Truncate & Insert) y muestra
            en la pestaña "Messages" cuánto tardó cada tabla.

 Nombre   : load_<layer>  ->  load_bronze   (02_docs/naming_conventions.md)
 SQL Server usa CREATE OR ALTER PROCEDURE; PostgreSQL usa
 CREATE OR REPLACE PROCEDURE ... LANGUAGE plpgsql.

 RUTA DE LOS ARCHIVOS: todas las rutas apuntan a
     C:/ISW623/sql-data-warehouse-project/01_datasets
 (en PostgreSQL se escriben con / aunque sea Windows).
 Si el proyecto está en otra carpeta, en pgAdmin usar Ctrl+Shift+F o el menú
 Edit > Replace y cambiar  C:/ISW623/sql-data-warehouse-project  por la ruta real.

 COPY ... FROM 'archivo' lo lee el SERVICIO de PostgreSQL (no tu usuario de
 Windows) y requiere conectarse con un superusuario (el usuario "postgres").
 Los CSV NO deben abrirse ni guardarse con Excel.

 Uso      : CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time       TIMESTAMP;
    v_batch_start_time TIMESTAMP := clock_timestamp();
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Cargando capa Bronze';
    RAISE NOTICE '================================================';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Cargando tablas CRM';
    RAISE NOTICE '------------------------------------------------';

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;
    COPY bronze.crm_cust_info
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/cust_info.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;
    COPY bronze.crm_prd_info
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/prd_info.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;
    COPY bronze.crm_sales_details
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_crm/sales_details.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Cargando tablas ERP';
    RAISE NOTICE '------------------------------------------------';

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;
    COPY bronze.erp_cust_az12
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;
    COPY bronze.erp_loc_a101
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/LOC_A101.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    COPY bronze.erp_px_cat_g1v2
    FROM 'C:/ISW623/sql-data-warehouse-project/01_datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FORMAT csv,        -- archivo separado por comas; campo vacío = NULL
        HEADER true,       -- la fila 1 es el encabezado y se salta
        ENCODING 'UTF8'    -- tildes y eñes (José, Muñoz)
    );
    RAISE NOTICE '   Duración: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carga de Bronze completada';
    RAISE NOTICE '   Duración total: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_batch_start_time) * 1000);
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR durante la carga de la capa Bronze';
        RAISE NOTICE 'Mensaje: %', SQLERRM;
        RAISE NOTICE 'Código : %', SQLSTATE;
        RAISE NOTICE '================================================';
        RAISE;  -- vuelve a lanzar el error para que pgAdmin lo muestre
END;
$$;

-- Para ejecutar la carga, seleccionar la línea siguiente (sin los --) y F5:
-- CALL bronze.load_bronze();
