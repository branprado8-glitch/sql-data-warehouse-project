/*
===============================================================================
 quality_checks_bronze.sql  -  Validación de la capa Bronze   (PostgreSQL)
===============================================================================
 Roadmap, paso "Validar: Integridad de datos y chequeos de Esquemas".
 Ejecutar conectado a data_warehouse DESPUÉS de:  CALL bronze.load_bronze();

 Bronze NO se limpia: estas consultas solo confirman que se cargó TODO
 (completitud) y que cada columna quedó en su lugar (esquema).
 Las validaciones de Silver y Gold se agregarán en las siguientes etapas.

 En pgAdmin, F5 muestra solo el resultado de la ÚLTIMA consulta. Ejecutar
 cada bloque por separado: seleccionarlo con el mouse y presionar F5.
===============================================================================
*/

-- 1) COMPLETITUD: filas cargadas vs filas de datos de cada CSV
--    (filas_esperadas = líneas del archivo sin contar el encabezado)
--    La columna resultado debe decir OK en las 6 filas.
SELECT tabla, filas_cargadas, filas_esperadas,
       CASE WHEN filas_cargadas = filas_esperadas THEN 'OK' ELSE 'REVISAR' END AS resultado
FROM (
    SELECT 'crm_cust_info'     AS tabla, (SELECT COUNT(*) FROM bronze.crm_cust_info)     AS filas_cargadas, 18494 AS filas_esperadas UNION ALL
    SELECT 'crm_prd_info',               (SELECT COUNT(*) FROM bronze.crm_prd_info),                          397 UNION ALL
    SELECT 'crm_sales_details',          (SELECT COUNT(*) FROM bronze.crm_sales_details),                   60398 UNION ALL
    SELECT 'erp_cust_az12',              (SELECT COUNT(*) FROM bronze.erp_cust_az12),                       18484 UNION ALL
    SELECT 'erp_loc_a101',               (SELECT COUNT(*) FROM bronze.erp_loc_a101),                        18484 UNION ALL
    SELECT 'erp_px_cat_g1v2',            (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),                        37
) AS conteo;

-- 1b) COLUMNAS: cantidad de columnas de cada tabla vs columnas del CSV.
--     La columna resultado debe decir OK en las 6 filas.
SELECT c.table_name,
       COUNT(*)                                       AS columnas_tabla,
       e.columnas_csv,
       CASE WHEN COUNT(*) = e.columnas_csv THEN 'OK' ELSE 'REVISAR' END AS resultado
FROM information_schema.columns c
JOIN (VALUES ('crm_cust_info', 7), ('crm_prd_info', 7), ('crm_sales_details', 9),
             ('erp_cust_az12', 3), ('erp_loc_a101', 2), ('erp_px_cat_g1v2', 4)
     ) AS e(table_name, columnas_csv)
  ON e.table_name = c.table_name
WHERE c.table_schema = 'bronze'
GROUP BY c.table_name, e.columnas_csv
ORDER BY c.table_name;

-- 2) ESQUEMA: las columnas no quedaron corridas (mirar que cada valor esté
--    bajo su columna: cst_key empieza con "AW", cntry es un país, etc.)
SELECT * FROM bronze.crm_cust_info     LIMIT 5;
SELECT * FROM bronze.crm_prd_info      LIMIT 5;
SELECT * FROM bronze.crm_sales_details LIMIT 5;
SELECT * FROM bronze.erp_cust_az12     LIMIT 5;
SELECT * FROM bronze.erp_loc_a101      LIMIT 5;
SELECT * FROM bronze.erp_px_cat_g1v2   LIMIT 5;

-- 3) TILDES (ENCODING 'UTF8'): deben verse "José", "Muñoz", "Jiménez" bien escritos.
SELECT cst_id, cst_firstname, cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname LIKE '%é%' OR cst_lastname LIKE '%ñ%'
LIMIT 5;

-- 4) VISTAZO a problemas de calidad que SE CORRIGEN EN SILVER (no en Bronze).
--    Sirve para la defensa: Bronze guarda el dato tal como llega.
--    Valores esperados con estos CSV: 4, 29, 17, 12 y 16 (este último
--    depende de la fecha de hoy; con fecha 2026-11-14 da 16).
SELECT 'Clientes con cst_id nulo'               AS hallazgo, COUNT(*) AS cantidad FROM bronze.crm_cust_info     WHERE cst_id IS NULL UNION ALL
SELECT 'Clientes con espacios en el nombre',              COUNT(*)             FROM bronze.crm_cust_info     WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname) UNION ALL
SELECT 'Ventas con fecha de orden = 0',                   COUNT(*)             FROM bronze.crm_sales_details WHERE sls_order_dt = 0 UNION ALL
SELECT 'Ventas con precio negativo o nulo',               COUNT(*)             FROM bronze.crm_sales_details WHERE sls_price IS NULL OR sls_price <= 0 UNION ALL
SELECT 'Clientes ERP con fecha de nacimiento futura',     COUNT(*)             FROM bronze.erp_cust_az12     WHERE bdate > CURRENT_DATE;
