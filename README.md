# Documentación del Proyecto Final

## 1. Público Objetivo

Este reporte está dirigido a **altos mandos de una empresa** con el fin de proporcionarles una visión general sobre la **evolución e histórico de ventas** de las tiendas físicas y las ventas online. La primera página ofrece esta visión global, mientras que las dos páginas siguientes profundizan en el análisis desde la perspectiva de **tiendas y productos**, lo que refuerza el estudio realizado.

---

## 2. Listado de Tablas y Relaciones

El modelo de datos se construyó en **SQL Server** utilizando un **modelo de constelación** con dos tablas de hechos:

* `fct_ventas_consolidada`: Es el resultado de la `UNION` de `fct_ventas` y `fct_ventas_online`.
* `fct_tipo_cambio`
* `dim_producto`
* `dim_prod_sub`
* `dim_tienda`
* `dim_moneda`
* `dim_canal_venta`
* `dim_geografia`
* `dim_calendario`

Las siguientes tablas fueron creadas en **Power BI**:

* `AniosConVentas`
    ```dax
    DISTINCT(
        SELECTCOLUMNS(
            FILTER(
                'fct_ventas',
                NOT ISBLANK('fct_ventas'[id_venta])
            ),
            "Anio", YEAR('fct_ventas'[fecha])
        )
    )
    ```
* `Analisis Ventas Filtrado` (Parámetro de Campo)
    ```dax
    {
        ("Total de Ventas", NAMEOF('medidas'[Total Ventas Filtrado]), 0),
        ("Total de Ventas Online", NAMEOF('medidas'[Total Ventas Online Filtrado]), 1)
    }
    ```

### Relaciones:

La **tabla de hechos (`fct_ventas_consolidada`)** se relaciona con:

* `dim_producto` a través del campo `id_producto`
* `dim_canal_venta` a través del campo `id_canal_venta`
* `dim_tienda` a través del campo `id_tienda`
* `dim_moneda` a través del campo `id_moneda`
* `dim_calendario` a través del campo `fecha`

La tabla `fct_tipo_cambio` se relaciona con:

* `dim_moneda` a través del campo `id_moneda`

La tabla `dim_producto` se relaciona con:

* `fct_ventas_consolidada` a través del campo `id_producto`
* `dim_prod_sub` a través del campo `id_sub`

La tabla `dim_prod_sub` se relaciona con:

* `dim_producto` a través del campo `id_sub`

La tabla `dim_tienda` se relaciona con:

* `fct_ventas_consolidada` a través del campo `id_tienda`
* `dim_geografia` a través del campo `id_geo`

La tabla `dim_geografia` se relaciona con:

* `dim_tienda` a través del campo `id_geo`

La tabla `dim_canal_venta` se relaciona con:

* `fct_ventas_consolidada` a través del campo `id_canal_venta`

La tabla `dim_moneda` se relaciona con:

* `fct_ventas_consolidada` a través del campo `id_moneda`
* `fct_tipo_cambio` a través del campo `id_moneda`

La tabla `dim_calendario` se relaciona con:

* `fct_ventas_consolidada` a través del campo `fecha`

### Columnas Calculadas:

* **Clasificacion Tienda**: Se crea esta columna dentro de la tabla `dim_tienda` para categorizar las tiendas que han superado los **5 millones en ventas** y las que no, con el fin de representarlo en un gráfico circular.
    ```dax
    VAR TotalVentasTienda = CALCULATE([Total Ventas], ALLEXCEPT(dim_tienda, dim_tienda[nombre_tienda]))
    RETURN
        IF(TotalVentasTienda >= 5000000, "Ventas superiores a 5M", "Ventas inferiores a 5M")
    ```

---

## 3. Medidas Creadas

* **AñoSeleccionado**: Toma el valor del año seleccionado por el usuario para filtrar el total de ventas o la cantidad de unidades vendidas.
    ```dax
    SELECTEDVALUE(AniosConVentas[Anio])
    ```
* **Canales de Ventas**: Calcula la cantidad de canales de venta distintos (`id_canal_venta`) en la tabla `dim_canal_venta`, representando la cantidad de canales de venta disponibles en el sistema.
    ```dax
    DISTINCTCOUNT(dim_canal_venta[id_canal_venta])
    ```
* **Cantidad de tiendas**: Calcula la cantidad de tiendas distintas (`id_tienda`) en la tabla `dim_tienda`, representando la cantidad total de tiendas en el sistema.
    ```dax
    DISTINCTCOUNT(dim_tienda[id_tienda])
    ```
* **Productos comercializados**: Calcula la cantidad de productos que han tenido al menos una venta, basándose en los `id_producto` de `fct_ventas`.
    ```dax
    DISTINCTCOUNT(fct_ventas[id_producto])
    ```
* **Cantidad de Unidades Vendidas**: Suma el campo `cant_unid` de la tabla `fct_ventas`, representando el total de unidades vendidas.
    ```dax
    SUM(fct_ventas[cant_unid])
    ```
* **Total Ventas Filtrado**: Dado que la tabla `AniosConVentas` no tiene relación directa con la tabla de hechos de ventas, esta medida filtra el monto total de ventas para el año seleccionado.
    ```dax
    VAR AnioSel = [AñoSeleccionado]
    RETURN
    CALCULATE(
        [Total Ventas],
        FILTER(dim_calendario, YEAR(dim_calendario[fecha]) = AnioSel)
    )
    ```
* **Total Ventas Online Filtrado**: Similar a la medida anterior, esta filtra el monto total de ventas online para el año seleccionado.
    ```dax
    VAR AnioSel = [AñoSeleccionado]
    RETURN
    CALCULATE(
        [Total Ventas Online],
        FILTER(dim_calendario, YEAR(dim_calendario[fecha]) = AnioSel)
    )
    ```
* **Porcentaje tiendas desactivadas**: Mide el porcentaje de tiendas con el estado "Desactivado", cuyo resultado se usará en un KPI.
    ```dax
    VAR TotalTiendas = COUNTROWS(dim_tienda)
    VAR TiendasDesactivadas =
        CALCULATE(
            COUNTROWS(dim_tienda),
            dim_tienda[status_tienda] = "Desactivado"
        )
    RETURN DIVIDE(TiendasDesactivadas, TotalTiendas, 0)
    ```
* **Promedio de costo por producto**: Calcula el costo promedio de los productos comercializados en el sistema, promediando el campo `costo_unit` de `fct_ventas`.
    ```dax
    AVERAGE(fct_ventas[costo_unit])
    ```
* **Promedio Empleados por tienda**: Calcula la cantidad promedio de empleados por tienda, promediando el campo `cant_empleados` de `dim_tienda`.
    ```dax
    AVERAGE(dim_tienda[cant_empleados])
    ```
* **Total Ventas**: Suma el campo `monto_total` de `fct_ventas_consolidada` para obtener el valor total de las ventas realizadas en las tiendas físicas.
    ```dax
    CALCULATE(SUM(fct_ventas_consolidada[monto_total]), fct_ventas_consolidada[Tipo_Tienda] = "Física")
    ```
* **Total Ventas Online**: Suma el campo `monto_total` de `fct_ventas_consolidada` para obtener el valor total de las ventas realizadas de forma online.
    ```dax
    CALCULATE(SUM(fct_ventas_consolidada[monto_total]), fct_ventas_consolidada[Tipo_Tienda] = "Online")
    ```
* **Importe_Convertido_Tiendas_Fisicas**: Utiliza la medida de `Total Ventas` y la multiplica por el tipo de cambio correspondiente para convertir todas las ventas físicas a una misma moneda (el euro).
    ```dax
    SUMX(
        fct_ventas_consolidada,
        VAR Moneda = fct_ventas_consolidada[id_moneda]
        VAR TipoCambio =
            CALCULATE(
                MAX(fct_tipo_cambio[ultimo_valor]),
                fct_tipo_cambio[id_moneda] = Moneda
            )
        RETURN
            [Total Ventas] * TipoCambio
    )
    ```
* **Importe_Convertido_Tiendas_Online**: Similar a la medida anterior, pero para las ventas online, convirtiendo el monto a la misma moneda (el euro).
    ```dax
    SUMX(
        fct_ventas_consolidada,
        VAR Moneda = fct_ventas_consolidada[id_moneda]
        VAR TipoCambio =
            CALCULATE(
                MAX(fct_tipo_cambio[ultimo_valor]),
                fct_tipo_cambio[id_moneda] = Moneda
            )
        RETURN
            [Total Ventas Online] * TipoCambio
    )
    ```
* **Ganancia Neta por Unidad**: Calcula la ganancia neta por unidad vendida, restando el costo unitario (`costo_unit`) del precio unitario (`pcio_unit`) de cada producto.
    ```dax
    SUM(dim_producto[pcio_unit]) - SUM(dim_producto[costo_unit])
    ```
* **Promedio ganancia neta por unidad de producto**: Calcula el promedio de la ganancia neta por unidad, agrupando por categorías de producto.
    ```dax
    AVERAGEX(
        VALUES(dim_producto[nombre_producto]),
        [Ganancia Neta por Unidad]
    )
    ```
* **Variacion Ganancias Fisicas/Online**: Calcula el porcentaje de variación entre las ganancias de las tiendas físicas y las ventas online.
    ```dax
    (([Total Ventas] - [Total Ventas Online]) / [Total Ventas]) * 100
    ```

---

## 4. Pantallas del Reporte

* **Pantalla General**: Ubicada en `img/Pantalla General.png`
* **Pantalla Tiendas**: Ubicada en `img/Tiendas.png`
* **Pantalla Productos**: Ubicada en `img/Productos.png`
* **Modelo de datos**: Ubicado en `img/Modelo de datos.png`

---

## 5. Insights Obtenidos

* Se observó una **mayor ganancia a través de las tiendas físicas** en comparación con las ventas online, con una diferencia significativa.
* En los 3 años de ventas físicas, los **primeros 3 meses mostraron las ganancias más bajas**.
* **Siete tiendas** tuvieron ganancias considerablemente superiores al resto.
* Hubo un **pico en la apertura de tiendas en 2004**, seguido de una meseta sostenida en los años posteriores.
* Existe una correlación: **cuanto mayor es el costo de un producto, menor es la cantidad de unidades vendidas**.
* A excepción de algunos valores atípicos, la **cantidad de empleados por tienda física está balanceada** en relación con los metros cuadrados de la tienda.

---

## 6. Queries SQL

Las queries se encuentran en el archivo `sql/queries.sql`.

Todas las vistas, tanto sus nombres como sus campos, están en español.

Se crearon vistas para `fct_ventas` y `fct_ventas_online`, cada una con **500 mil registros**. Esto se hizo porque cargar las tablas completas (más de 15 millones de registros en `fct_ventas_consolidada`, que es la unión de ambas con un flag para la modalidad de venta) hubiera excedido la capacidad de procesamiento de Power BI.

En la vista `fct_tipo_cambio`, se calcula el tipo de cambio más actual para cada moneda. Esto permite que, en Power BI, se pueda realizar una medida de conversión a una moneda común (el euro) cuando se selecciona un país específico.

## 7. Archivo Power Bi con el reporte
El mismo se encuentra en la raiz del proyecto y se llama Proyecto Final.pbix.