# Análisis de los sistemas de origen

Roadmap · Construir capa Bronze · **Analizar los sistemas origenes**.
Se responden las preguntas de la diapositiva 11 (contexto de negocio, arquitectura y extracción) y se describe qué trae cada archivo.

## 1. Preguntas de la diapositiva 11

| Pregunta | Respuesta para este proyecto |
|---|---|
| ¿Quién es dueño de los datos? | Dos sistemas: **CRM** (gestión de clientes y ventas) y **ERP** (planificación de recursos: datos extra de clientes y categorías de productos). |
| ¿Qué proceso de negocio soportan? | Las **ventas**: quién compra, qué producto, cuándo y por cuánto. |
| ¿Cómo se almacenan los datos? | Se entregan como **archivos CSV en carpetas** (`01_datasets/source_crm` y `01_datasets/source_erp`). |
| ¿Cómo se integran? | **Extracción de archivos** (File Extract): se cargan con `COPY` de PostgreSQL. |
| ¿Carga incremental o completa? | **Completa** (Truncate & Insert). El alcance pide solo el dato más reciente, sin historial. |
| ¿Tamaño esperado? | Pequeño: unas 135 000 filas en total, unos 5 MB. No hay límites de volumen que preocupen. |
| ¿Cómo no afectar al sistema de origen? | Se trabaja sobre copias en CSV; nunca se conecta a los sistemas reales. |
| ¿Autenticación? | No aplica: los archivos están en la PC. La carga usa el usuario `postgres` del servidor local. |

## 2. Qué trae cada archivo

Revisado sobre los CSV reales: separador coma, sin comillas, primera fila con encabezado, fin de línea de Windows (CRLF), codificación UTF-8.

### CRM

**`cust_info.csv` → `bronze.crm_cust_info`** · información de clientes · 18 494 filas

| Columna | Ejemplo | Tipo en Bronze | Nota |
|---|---|---|---|
| cst_id | 11000 | INTEGER | Clave del cliente en CRM |
| cst_key | AW00011000 | VARCHAR(50) | Clave que lo une con el ERP |
| cst_firstname | ` Jon` | VARCHAR(50) | Trae espacios de más |
| cst_lastname | `Yang ` | VARCHAR(50) | Trae espacios de más |
| cst_marital_status | M / S | VARCHAR(50) | Código: M = Married, S = Single |
| cst_gndr | M / F / vacío | VARCHAR(50) | Código; 4 578 vacíos |
| cst_create_date | 2025-10-06 | DATE | |

**`prd_info.csv` → `bronze.crm_prd_info`** · productos, actuales e históricos · 397 filas

| Columna | Ejemplo | Tipo en Bronze | Nota |
|---|---|---|---|
| prd_id | 210 | INTEGER | |
| prd_key | CO-RF-FR-R92B-58 | VARCHAR(50) | Los primeros 5 caracteres son la categoría (`CO-RF`) |
| prd_nm | HL Road Frame - Black- 58 | VARCHAR(50) | |
| prd_cost | 12 / vacío | INTEGER | 2 vacíos |
| prd_line | `R ` | VARCHAR(50) | Código con espacio al final: M, R, S, T |
| prd_start_dt | 2003-07-01 | DATE | |
| prd_end_dt | 2007-12-28 / vacío | DATE | A veces es **anterior** a la fecha de inicio |

**`sales_details.csv` → `bronze.crm_sales_details`** · ventas y pedidos · 60 398 filas

| Columna | Ejemplo | Tipo en Bronze | Nota |
|---|---|---|---|
| sls_ord_num | SO43697 | VARCHAR(50) | Número de orden |
| sls_prd_key | BK-R93R-62 | VARCHAR(50) | Se une con `prd_key` desde el carácter 7 |
| sls_cust_id | 21768 | INTEGER | Se une con `cst_id` |
| sls_order_dt | 20101229 | INTEGER | Fecha como número AAAAMMDD; hay ceros |
| sls_ship_dt | 20110105 | INTEGER | Igual |
| sls_due_dt | 20110110 | INTEGER | Igual |
| sls_sales | 3578 | INTEGER | Hay vacíos y negativos |
| sls_quantity | 1 | INTEGER | |
| sls_price | 3578 | INTEGER | Hay vacíos y negativos |

### ERP

**`CUST_AZ12.csv` → `bronze.erp_cust_az12`** · fecha de nacimiento y género · 18 484 filas

| Columna | Ejemplo | Tipo en Bronze | Nota |
|---|---|---|---|
| cid | NASAW00011000 | VARCHAR(50) | Algunos traen el prefijo `NAS` |
| bdate | 1971-10-06 | DATE | Hay fechas futuras (hasta 9999-11-20) |
| gen | Male / Female / vacío | VARCHAR(50) | Texto completo, distinto al código del CRM |

**`LOC_A101.csv` → `bronze.erp_loc_a101`** · país del cliente · 18 484 filas

| Columna | Ejemplo | Tipo en Bronze | Nota |
|---|---|---|---|
| cid | AW-00011000 | VARCHAR(50) | Trae un guion que el CRM no tiene |
| cntry | Australia | VARCHAR(50) | 332 vacíos |

**`PX_CAT_G1V2.csv` → `bronze.erp_px_cat_g1v2`** · categorías de productos · 37 filas

| Columna | Ejemplo | Tipo en Bronze |
|---|---|---|
| id | AC_BR | VARCHAR(50) |
| cat | Accessories | VARCHAR(50) |
| subcat | Bike Racks | VARCHAR(50) |
| maintenance | Yes / No | VARCHAR(50) |

Las columnas del ERP vienen en MAYÚSCULA en el CSV (`CID`, `BDATE`...). En Bronze se escriben en minúscula por la regla `snake_case`; el contenido no cambia.

## 3. Cómo se relacionan (diapositiva 5)

```
crm_sales_details.sls_prd_key  ──►  crm_prd_info.prd_key
crm_sales_details.sls_cust_id  ──►  crm_cust_info.cst_id
crm_cust_info.cst_key          ──►  erp_cust_az12.cid
crm_cust_info.cst_key          ──►  erp_loc_a101.cid
crm_prd_info.prd_key           ──►  erp_px_cat_g1v2.id
```

Las claves **no coinciden tal cual** entre los sistemas:

| Mismo dato | CRM | ERP |
|---|---|---|
| Cliente | `AW00011000` | `NASAW00011000` (CUST_AZ12) y `AW-00011000` (LOC_A101) |
| Categoría | `CO-RF-FR-R92B-58` (prd_info) | `CO_RF` (PX_CAT_G1V2) |
| Producto en la venta | `BK-R93R-62` (sales_details) | `BI-RB-BK-R93R-62` (prd_info, mismo sistema CRM) |

## 4. Problemas de calidad encontrados

| Problema | Dónde | Cantidad |
|---|---|---|
| Clientes sin `cst_id` | crm_cust_info | 4 |
| Nombres con espacios de más | crm_cust_info | 29 |
| Género vacío | crm_cust_info | 4 578 |
| Fechas de orden en 0 | crm_sales_details | 17 |
| Precio vacío o negativo | crm_sales_details | 12 |
| Fecha de fin antes que la de inicio | crm_prd_info | 200 |
| Fechas de nacimiento futuras | erp_cust_az12 | 16 (al 2026-11-14) |
| País vacío | erp_loc_a101 | 332 |
| Claves con formatos distintos entre sistemas | CRM vs ERP | todas |

## 5. Por qué no se corrigen en Bronze

Según la diapositiva 6, Bronze guarda los datos **sin procesar, tal como llegan**, y su objetivo es la **trazabilidad y la depuración** ("debugging"). Si se limpiara aquí, se perdería el dato original y no se podría averiguar de dónde viene un error en Silver o Gold. Estas correcciones son trabajo de **Silver** (limpieza, estandarización, normalización).

La única decisión que se toma en Bronze es el **tipo de dato** de cada columna, y se eligió para que **ninguna fila sea rechazada**: por eso las fechas de ventas quedan como `INTEGER` (si fueran `DATE`, los ceros harían fallar la carga).
