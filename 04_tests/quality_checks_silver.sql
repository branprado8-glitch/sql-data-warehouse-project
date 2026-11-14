/*
===============================================================================
 quality_checks_silver.sql  -  Validación de la capa Silver   (PostgreSQL)
===============================================================================
 Ejecutar conectado a data_warehouse DESPUÉS de:  CALL silver.load_silver();

 Cada consulta busca un problema que Silver debía corregir.
 RESULTADO ESPERADO: la columna "problemas" en 0 en todas las filas.
 (Excepción documentada: la consulta 2 muestra filas, es solo informativa.)

 En pgAdmin, F5 muestra solo el resultado de la ÚLTIMA consulta: seleccionar
 cada bloque con el mouse y presionar F5.
===============================================================================
*/

-- 1) RESUMEN DE PROBLEMAS: todas las filas deben dar 0
SELECT 'crm_cust_info: cst_id nulo o repetido' AS chequeo,
       (SELECT COUNT(*) FROM (SELECT cst_id FROM silver.crm_cust_info
                              GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL) x) AS problemas
UNION ALL
SELECT 'crm_cust_info: nombres con espacios de más',
       (SELECT COUNT(*) FROM silver.crm_cust_info
         WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname))
UNION ALL
SELECT 'crm_cust_info: estado civil o género fuera de catálogo',
       (SELECT COUNT(*) FROM silver.crm_cust_info
         WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a')
            OR cst_gndr NOT IN ('Female', 'Male', 'n/a'))
UNION ALL
SELECT 'crm_prd_info: prd_id repetido o nulo',
       (SELECT COUNT(*) FROM (SELECT prd_id FROM silver.crm_prd_info
                              GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL) x)
UNION ALL
SELECT 'crm_prd_info: costo nulo o negativo',
       (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_cost IS NULL OR prd_cost < 0)
UNION ALL
SELECT 'crm_prd_info: fecha de fin antes que la de inicio',
       (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt)
UNION ALL
SELECT 'crm_prd_info: línea fuera de catálogo',
       (SELECT COUNT(*) FROM silver.crm_prd_info
         WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'))
UNION ALL
SELECT 'crm_sales_details: orden después del envío o del vencimiento',
       (SELECT COUNT(*) FROM silver.crm_sales_details
         WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt)
UNION ALL
SELECT 'crm_sales_details: ventas <> cantidad * precio, o valores nulos/negativos',
       (SELECT COUNT(*) FROM silver.crm_sales_details
         WHERE sls_sales <> sls_quantity * sls_price
            OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
            OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0)
UNION ALL
SELECT 'crm_sales_details: producto sin pareja en crm_prd_info',
       (SELECT COUNT(*) FROM silver.crm_sales_details s
         WHERE NOT EXISTS (SELECT 1 FROM silver.crm_prd_info p WHERE p.prd_key = s.sls_prd_key))
UNION ALL
SELECT 'crm_sales_details: cliente sin pareja en crm_cust_info',
       (SELECT COUNT(*) FROM silver.crm_sales_details s
         WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_id = s.sls_cust_id))
UNION ALL
SELECT 'erp_cust_az12: fecha de nacimiento futura',
       (SELECT COUNT(*) FROM silver.erp_cust_az12 WHERE bdate > CURRENT_DATE)
UNION ALL
SELECT 'erp_cust_az12: género fuera de catálogo',
       (SELECT COUNT(*) FROM silver.erp_cust_az12 WHERE gen NOT IN ('Female', 'Male', 'n/a'))
UNION ALL
SELECT 'erp_cust_az12: cid sin pareja en crm_cust_info',
       (SELECT COUNT(*) FROM silver.erp_cust_az12 e
         WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = e.cid))
UNION ALL
SELECT 'erp_loc_a101: país vacío o abreviado (DE, US, USA)',
       (SELECT COUNT(*) FROM silver.erp_loc_a101
         WHERE cntry IS NULL OR TRIM(cntry) = '' OR cntry IN ('DE', 'US', 'USA'))
UNION ALL
SELECT 'erp_loc_a101: cid sin pareja en crm_cust_info',
       (SELECT COUNT(*) FROM silver.erp_loc_a101 l
         WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = l.cid))
UNION ALL
SELECT 'erp_px_cat_g1v2: textos con espacios de más',
       (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2
         WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance));

-- 2) INFORMATIVO: categorías de productos que no existen en el ERP.
--    7 productos tienen un cat_id (CO_PE) que no está en PX_CAT_G1V2.
--    No es un error de limpieza: el dato no existe en el origen. Se reporta.
SELECT cat_id, COUNT(*) AS productos
FROM silver.crm_prd_info p
WHERE NOT EXISTS (SELECT 1 FROM silver.erp_px_cat_g1v2 c WHERE c.id = p.cat_id)
GROUP BY cat_id;

-- 3) CONTEO DE FILAS: Bronze vs Silver
--    Solo crm_cust_info debe tener menos filas (se quitan nulos y duplicados).
SELECT 'crm_cust_info' AS tabla,
       (SELECT COUNT(*) FROM bronze.crm_cust_info) AS filas_bronze,
       (SELECT COUNT(*) FROM silver.crm_cust_info) AS filas_silver
UNION ALL SELECT 'crm_prd_info',      (SELECT COUNT(*) FROM bronze.crm_prd_info),      (SELECT COUNT(*) FROM silver.crm_prd_info)
UNION ALL SELECT 'crm_sales_details', (SELECT COUNT(*) FROM bronze.crm_sales_details), (SELECT COUNT(*) FROM silver.crm_sales_details)
UNION ALL SELECT 'erp_cust_az12',     (SELECT COUNT(*) FROM bronze.erp_cust_az12),     (SELECT COUNT(*) FROM silver.erp_cust_az12)
UNION ALL SELECT 'erp_loc_a101',      (SELECT COUNT(*) FROM bronze.erp_loc_a101),      (SELECT COUNT(*) FROM silver.erp_loc_a101)
UNION ALL SELECT 'erp_px_cat_g1v2',   (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),   (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2);

-- 4) VALORES ESTANDARIZADOS: revisar a ojo que solo aparezcan textos completos
SELECT 'cst_marital_status' AS columna, cst_marital_status AS valor, COUNT(*) FROM silver.crm_cust_info GROUP BY cst_marital_status
UNION ALL SELECT 'cst_gndr', cst_gndr, COUNT(*) FROM silver.crm_cust_info GROUP BY cst_gndr
UNION ALL SELECT 'prd_line', prd_line, COUNT(*) FROM silver.crm_prd_info  GROUP BY prd_line
UNION ALL SELECT 'gen',      gen,      COUNT(*) FROM silver.erp_cust_az12 GROUP BY gen
UNION ALL SELECT 'cntry',    cntry,    COUNT(*) FROM silver.erp_loc_a101  GROUP BY cntry
ORDER BY 1, 2;
