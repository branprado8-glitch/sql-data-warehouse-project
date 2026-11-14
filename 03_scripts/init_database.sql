/*
===============================================================================
 init_database.sql  -  EJECUTAR PRIMERO   (PostgreSQL)
===============================================================================
 Proyecto : sql-data-warehouse-project (ISW-623, Clase 09, Arquitectura Medallion)
 Qué hace : PARTE 1 crea la base de datos data_warehouse.
            PARTE 2 crea los esquemas bronze, silver y gold dentro de ella.

 Decisión : UNA sola base con tres esquemas (alternativa 1 del pptx).
            En PostgreSQL una consulta no puede unir tablas de dos bases
            distintas sin extensiones (dblink / postgres_fdw), así que tres
            bases separadas (DW_Bronze, DW_Silver, DW_Gold) complicarían
            pasar datos de una capa a la siguiente.

 IMPORTANTE (pgAdmin):
   - CREATE DATABASE no puede ir junto con otras instrucciones ni dentro de
     una transacción. Por eso son dos partes que se ejecutan por separado.
   - PARTE 1: abrir el Query Tool sobre la base "postgres", SELECCIONAR solo
     la línea CREATE DATABASE y presionar F5.
   - PARTE 2: abrir el Query Tool sobre la base "data_warehouse",
     seleccionar desde "PARTE 2" hasta el final y presionar F5.
===============================================================================
*/

-- ============================== PARTE 1 =====================================
-- (conectado a la base "postgres")
CREATE DATABASE data_warehouse;


-- ============================== PARTE 2 =====================================
-- (conectado a la base "data_warehouse")
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Comprobación: deben aparecer 3 filas (bronze, gold, silver)
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('bronze', 'silver', 'gold')
ORDER BY schema_name;
