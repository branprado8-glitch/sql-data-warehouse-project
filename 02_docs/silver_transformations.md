# Reglas de transformación de la capa Silver

Capa Silver (diapositiva 6): **datos limpios y estandarizados**. Tablas, carga completa (Truncate & Insert), con limpieza, estandarización, normalización, columnas derivadas y enriquecimiento. **No** hay modelado todavía (eso es Gold).

Este documento parte de los problemas encontrados en [source_analysis.md](source_analysis.md) y define cómo se corrige cada uno. El código está en `03_scripts/silver/02_proc_load_silver.sql`.

## Reglas generales

- Mismos nombres de tabla que Bronze (`<sourcesystem>_<entity>`), en el esquema `silver`.
- Cada tabla agrega la columna técnica **`dwh_create_date`** (prefijo `dwh_`, convenciones): fecha y hora de carga en Silver.
- Los códigos se reemplazan por texto completo y los valores desconocidos se escriben **`n/a`**, nunca vacío, para que los reportes no muestren huecos.
- Los datos se leen **solo de Bronze**, nunca de los CSV.

## Tabla por tabla

### silver.crm_cust_info · 18 494 → 18 484 filas

| Problema en Bronze | Regla en Silver | Tipo de transformación |
|---|---|---|
| 4 filas sin `cst_id` | Se eliminan | Limpieza |
| 6 clientes repetidos (el mismo `cst_id` varias veces) | Se conserva el registro con la `cst_create_date` más reciente (`ROW_NUMBER()`) | Limpieza (deduplicación) |
| Nombres con espacios de más | `TRIM()` | Limpieza |
| `cst_marital_status` en código (M, S) | `Married`, `Single`, otro → `n/a` | Estandarización |
| `cst_gndr` en código (M, F) o vacío | `Male`, `Female`, otro → `n/a` | Estandarización |

### silver.crm_prd_info · 397 filas

| Problema en Bronze | Regla en Silver | Tipo |
|---|---|---|
| `prd_key` mezcla categoría y producto (`CO-RF-FR-R92B-58`) | Columna nueva **`cat_id`** = 5 primeros caracteres con `_` (`CO_RF`), para unir con `erp_px_cat_g1v2.id` | Columna derivada |
| | `prd_key` = desde el carácter 7 (`FR-R92B-58`), para unir con `crm_sales_details.sls_prd_key` | Columna derivada |
| `prd_cost` vacío (2) | `0` | Limpieza |
| `prd_line` en código con espacio (`R `) | `Mountain`, `Road`, `Other Sales`, `Touring`, otro → `n/a` | Estandarización |
| 200 productos con fecha de fin **antes** que la de inicio | `prd_end_dt` = un día antes del inicio de la siguiente versión del mismo producto (`LEAD()`); la versión actual queda con fin vacío | Enriquecimiento |

### silver.crm_sales_details · 60 398 filas

| Problema en Bronze | Regla en Silver | Tipo |
|---|---|---|
| Fechas como número `AAAAMMDD` | Se convierten a `DATE` con `TO_DATE()` | Normalización |
| 19 fechas de orden en 0 o con largo distinto de 8 | `NULL` | Limpieza |
| Ventas vacías, negativas o distintas de cantidad × precio | Se recalculan: `cantidad × |precio|` | Limpieza (regla de negocio: ventas = cantidad × precio) |
| Precio vacío o negativo | `ventas / cantidad` | Limpieza |

### silver.erp_cust_az12 · 18 484 filas

| Problema en Bronze | Regla en Silver | Tipo |
|---|---|---|
| `cid` con prefijo `NAS` (11 042 filas) | Se quita el prefijo, para unir con `crm_cust_info.cst_key` | Limpieza |
| 16 fechas de nacimiento futuras | `NULL` | Limpieza |
| `gen` con `F`, `M`, `Female`, `Male`, espacios o vacío | `Female`, `Male`, otro → `n/a` | Estandarización |

### silver.erp_loc_a101 · 18 484 filas

| Problema en Bronze | Regla en Silver | Tipo |
|---|---|---|
| `cid` con guion (`AW-00011000`) | Se quita el guion, para unir con `crm_cust_info.cst_key` | Limpieza |
| País abreviado (`DE`, `US`, `USA`) | `Germany`, `United States` | Estandarización |
| País vacío o con espacios (337) | `n/a` | Limpieza |

### silver.erp_px_cat_g1v2 · 37 filas

Ya viene limpia: se copia tal cual (más `dwh_create_date`).

## Hallazgo que no se corrige

7 productos del CRM tienen `cat_id = CO_PE`, que **no existe** en `PX_CAT_G1V2`. No es un error de formato sino un dato que falta en el origen, así que no se inventa. Se reporta en `04_tests/quality_checks_silver.sql` y se tendrá en cuenta en Gold.

## Qué queda para Gold

- **Integrar** CRM y ERP en un solo modelo (por ejemplo, completar el género del cliente con el ERP cuando el CRM dice `n/a`).
- Esquema en estrella con **vistas** (`gold.dim_customers`, `gold.dim_products`, `gold.fact_sales`) y claves subrogadas con sufijo `_key`.
