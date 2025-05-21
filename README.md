# Documentación Proyecto Final Power BI

## 1. Público Objetivo



---

## 2. Listado de Tablas y Relación entre Ellas

### Modelo Armado en SQL Server

Se diseñó un modelo de datos en estrella, ideal para análisis de tipo OLAP.

**Tablas del modelo:**

- `fct_ventas_consolidada` → UNION de `fct_ventas` y `fct_ventas_online`
- `dim_producto`
- `dim_prod_sub`
- `dim_tienda`
- `dim_geografia`
- `dim_calendario`

**Tablas creadas en Power BI:**

- `AniosConVentas`
```dax
AniosConVentas = 
DISTINCT(
    SELECTCOLUMNS(
        FILTER(
            'fct_ventas',
            NOT ISBLANK('fct_ventas'[id_venta])
        ),
        "Anio", YEAR('fct_ventas'[fecha])
    )
)