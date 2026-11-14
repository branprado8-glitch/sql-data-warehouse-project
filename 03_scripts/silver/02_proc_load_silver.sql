/*
===============================================================================
 02_proc_load_silver.sql  -  Procedimiento almacenado silver.load_silver
===============================================================================
 Ejecutar conectado a la base data_warehouse.   (PostgreSQL 11 o superior)
 Qué hace : crea (o reemplaza) silver.load_silver, que toma los datos de
            Bronze, los limpia y estandariza, y los carga en Silver.
            Método de carga (diapositiva 6): carga completa, Truncate & Insert.
            Las reglas de cada tabla están en 02_docs/silver_transformations.md.

 Nombre   : load_<layer>  ->  load_silver   (02_docs/naming_conventions.md)
 Uso      : CALL silver.load_silver();   (después de CALL bronze.load_bronze();)
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time       TIMESTAMP;
    v_batch_start_time TIMESTAMP := clock_timestamp();
    v_rows             BIGINT;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Cargando capa Silver';
    RAISE NOTICE '================================================';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Cargando tablas CRM';
    RAISE NOTICE '------------------------------------------------';

    -- -----------------------------------------------------------------------
    -- silver.crm_cust_info
    --   * quita espacios de nombres
    --   * códigos -> texto (M/S -> Married/Single, M/F -> Male/Female)
    --   * elimina filas sin cst_id
    --   * duplicados: se queda con el registro más reciente de cada cliente
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE UPPER(TRIM(cst_gndr))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    -- -----------------------------------------------------------------------
    -- silver.crm_prd_info
    --   * cat_id  = 5 primeros caracteres de prd_key con '_' (une con ERP)
    --   * prd_key = prd_key desde el carácter 7 (une con las ventas)
    --   * costo vacío -> 0
    --   * código de línea -> texto
    --   * prd_end_dt = día anterior al inicio de la siguiente versión del
    --     mismo producto (las fechas de fin originales son inconsistentes)
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_'),
        SUBSTRING(prd_key FROM 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
    FROM bronze.crm_prd_info;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    -- -----------------------------------------------------------------------
    -- silver.crm_sales_details
    --   * fechas AAAAMMDD -> DATE; 0 o largo distinto de 8 -> NULL
    --   * ventas vacías, negativas o distintas de cantidad * precio
    --     -> se recalculan como cantidad * |precio|
    --   * precio vacío o negativo -> ventas / cantidad
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) <> 8 THEN NULL
             ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_ship_dt  <= 0 OR LENGTH(sls_ship_dt::TEXT)  <> 8 THEN NULL
             ELSE TO_DATE(sls_ship_dt::TEXT,  'YYYYMMDD') END,
        CASE WHEN sls_due_dt   <= 0 OR LENGTH(sls_due_dt::TEXT)   <> 8 THEN NULL
             ELSE TO_DATE(sls_due_dt::TEXT,   'YYYYMMDD') END,
        CASE WHEN sls_sales IS NULL OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0
             THEN sls_sales / NULLIF(sls_quantity, 0)
             ELSE sls_price END
    FROM bronze.crm_sales_details;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Cargando tablas ERP';
    RAISE NOTICE '------------------------------------------------';

    -- -----------------------------------------------------------------------
    -- silver.erp_cust_az12
    --   * quita el prefijo NAS del cid (para unir con crm_cust_info.cst_key)
    --   * fecha de nacimiento futura -> NULL
    --   * género estandarizado: Female / Male / n/a
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4) ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE THEN NULL ELSE bdate END,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    -- -----------------------------------------------------------------------
    -- silver.erp_loc_a101
    --   * quita el guion del cid (para unir con crm_cust_info.cst_key)
    --   * país estandarizado: DE -> Germany, US/USA -> United States,
    --     vacío -> n/a
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN TRIM(cntry) = 'DE'                    THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA')          THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = ''     THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    -- -----------------------------------------------------------------------
    -- silver.erp_px_cat_g1v2
    --   * ya viene limpia: se copia tal cual
    -- -----------------------------------------------------------------------
    v_start_time := clock_timestamp();
    RAISE NOTICE '>> silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '   Filas: %  Duración: % ms', v_rows, round(EXTRACT(EPOCH FROM clock_timestamp() - v_start_time) * 1000);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carga de Silver completada';
    RAISE NOTICE '   Duración total: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - v_batch_start_time) * 1000);
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR durante la carga de la capa Silver';
        RAISE NOTICE 'Mensaje: %', SQLERRM;
        RAISE NOTICE 'Código : %', SQLSTATE;
        RAISE NOTICE '================================================';
        RAISE;
END;
$$;

-- Para ejecutar la carga, seleccionar la línea siguiente (sin los --) y F5:
-- CALL silver.load_silver();
