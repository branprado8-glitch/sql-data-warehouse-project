# Guía de configuración

## Requisitos

- Windows con **PostgreSQL 13 o superior** y **pgAdmin 4**.
- Conectarse con el usuario **`postgres`** (superusuario). `COPY ... FROM 'archivo'` exige un superusuario o el rol `pg_read_server_files`.
- El proyecto en `C:\ISW623\sql-data-warehouse-project`.
- Git, para el repositorio.

## Por qué esa carpeta

`COPY` lee los CSV **desde el servicio de PostgreSQL**, no desde tu usuario de Windows. Si el proyecto queda en `Descargas`, `Escritorio` u `OneDrive`, el servicio normalmente no tiene permiso y aparece *Permission denied*. Una carpeta directamente bajo `C:\` evita ese problema.

Si se usa otra carpeta, hay que cambiar la ruta en `02_load_bronze_copy.sql` y `03_proc_load_bronze.sql`. En PostgreSQL las rutas de Windows se escriben con `/`.

## Reglas

- No abrir ni guardar los CSV con Excel: cambia el formato de fechas y separadores.
