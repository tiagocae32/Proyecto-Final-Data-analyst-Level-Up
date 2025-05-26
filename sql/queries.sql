Use Spanish;

DROP VIEW IF EXISTS fct_ventas;
CREATE VIEW fct_ventas AS 
SELECT TOP 500000 FS.SalesKey AS id_venta, FS.DateKey AS fecha, FS.channelKey AS id_canal_venta, FS.StoreKey AS id_tienda,
FS.ProductKey AS id_producto, FS.CurrencyKey AS id_moneda, Fs.SalesAmount as monto_total, FS.SalesQuantity AS cant_unid,
FS.DiscountAmount monto_descuento, FS.DiscountQuantity AS cant_con_desc
FROM FactSales FS;

DROP VIEW IF EXISTS fct_ventas_online;
CREATE VIEW fct_ventas_online AS
SELECT TOP 500000 FOS.OnlineSalesKey as id_venta, FOS.DateKey AS fecha, FOS.StoreKey AS id_tienda,
FOS.ProductKey AS id_producto, FOS.CurrencyKey as id_moneda , FOS.SalesAmount as monto_total, FOS.SalesQuantity AS cant_unid,
FOS.DiscountAmount monto_descuento, FOS.DiscountQuantity AS cant_con_desc
FROM FactOnlineSales FOS;

DROP VIEW IF EXISTS fct_ventas_consolidada;
CREATE VIEW fct_ventas_consolidada AS
SELECT 
	fecha,
    id_venta,
    id_canal_venta,
    id_tienda,
    id_producto,
	id_moneda,
    cant_unid,
    cant_con_desc,
    monto_descuento,
    monto_total,
    'Física' AS Tipo_Tienda
FROM fct_ventas

UNION ALL

SELECT 
	fecha,
    id_venta,
    NULL AS id_canal_venta,
    id_tienda,
    id_producto,
	id_moneda,
    cant_unid,
    cant_con_desc,
    monto_descuento,
    monto_total,
    'Online' AS Tipo_Tienda
FROM fct_ventas_online;

DROP VIEW IF EXISTS dim_tienda;
CREATE VIEW dim_tienda AS
SELECT ds.StoreKey as id_tienda, ds.GeographyKey as id_geo, ds.StoreManager as tipo_tienda,
ds.StoreName as nombre_tienda, ds.Status as status_tienda, ds.OpenDate as fecha_apertura, ds.EmployeeCount as cant_empleados,
ds.SellingAreaSize as m2
FROM DimStore ds;

DROP VIEW IF EXISTS dim_geografia;
CREATE VIEW dim_geografia AS 
SELECT dg.GeographyKey as id_geo, dg.ContinentName as continente, dg.CityName as ciudad, dg.RegionCountryName as pais from DimGeography dg

DROP VIEW IF EXISTS dim_moneda;
CREATE VIEW dim_moneda AS
SELECT DC.CurrencyKey as id_moneda, DC.CurrencyName AS nombre_moneda, DC.CurrencyDescription AS descricpcion_moneda FROM DimCurrency DC

DROP VIEW IF EXISTS fct_tipo_cambio; 
CREATE VIEW fct_tipo_cambio AS
SELECT fc.CurrencyKey as id_moneda, fc.EndOfDayRate as ultimo_valor
FROM FactExchangeRate fc
INNER JOIN (
    SELECT fer.CurrencyKey, MAX(fer.DateKey) AS fecha_max
    FROM FactExchangeRate fer
    GROUP BY fer.CurrencyKey
) AS ult
ON fc.CurrencyKey = ult.CurrencyKey AND fc.DateKey = ult.fecha_max;


/*

-- MODELO SEMANTICO NUMERO 3
DROP VIEW IF EXISTS fct_ventas_diarias_categoria;
CREATE VIEW fct_ventas_diarias_categoria AS 
SELECT FV.fecha, FV.id_canal_venta, FV.id_tienda, DP.id_categoria, 
SUM(FV.monto_total) as monto_total, AVG(FV.pcio_unit) as precio_promedio , AVG(FV.costo_unit) AS costo_promedio, SUM(FV.cant_unid) as unidades_vendidas,
SUM(FV.monto_descuento) as suma_monto_descuento, SUM(FV.cant_con_desc) as unidades_con_descuento,
COUNT(DISTINCT DPS.id_sub) as cant_dist_prodsub, COUNT(DPS.cant_productos_distintos) as cant_dist_prod
FROM fct_ventas FV
INNER JOIN dim_producto DP ON FV.id_producto = DP.id_producto
INNER JOIN dim_prod_sub DPS ON DPS.id_sub = DP.id_sub
GROUP BY FV.fecha, FV.id_canal_venta, FV.id_tienda, DP.id_categoria;

-- MODELO SEMANTICO NUMERO 4
DROP VIEW IF EXISTS fct_ventas_mensuales_prod;

CREATE VIEW fct_ventas_mensuales_prod AS 
SELECT MONTH(FV.fecha) AS MES, FV.id_canal_venta, FV.id_tienda, DP.id_producto, 
SUM(FV.monto_total) as monto_total, AVG(FV.pcio_unit) AS precio_promedio, AVG(FV.costo_unit) as promedio_costo, SUM(FV.cant_unid) as unidades_vendidas,
SUM(FV.monto_descuento) as suma_monto_descuento, SUM(FV.cant_con_desc) as unidades_con_descuento
FROM fct_ventas FV
INNER JOIN dim_producto DP ON FV.id_producto = DP.id_producto
GROUP BY MONTH(FV.fecha), FV.id_canal_venta, FV.id_tienda, DP.id_producto;

-- MODELO SEMANTICO NUMERO 5
DROP VIEW IF EXISTS fct_ventas_mensuales_prodsub;

CREATE VIEW fct_ventas_mensuales_prodsub AS 
SELECT MONTH(FV.fecha) AS MES, FV.id_canal_venta, FV.id_tienda, DPS.id_sub, 
SUM(FV.monto_total) as monto_total,AVG(FV.pcio_unit) as precio_promedio, AVG(FV.costo_unit) as promedio_costo, SUM(FV.cant_unid) as unidades_vendidas,
SUM(FV.monto_descuento) as suma_monto_descuento, SUM(FV.cant_con_desc) as unidades_con_descuento,
COUNT(DPS.cant_productos_distintos) as productos_distintos
FROM fct_ventas FV
INNER JOIN dim_producto DP ON FV.id_producto = DP.id_producto
INNER JOIN dim_prod_sub DPS ON DPS.id_sub = DP.id_sub
GROUP BY MONTH(FV.fecha), FV.id_canal_venta, FV.id_tienda, DPS.id_sub;

-- MODELO SEMANTICO NUMERO 6
DROP VIEW IF EXISTS fct_ventas_mensuales_categoria;

CREATE VIEW fct_ventas_mensuales_categoria AS 
SELECT MONTH(FV.fecha) AS MES, FV.id_canal_venta, FV.id_tienda, DP.id_categoria , 
SUM(FV.monto_total) as monto_total,AVG(FV.pcio_unit) as precio_promedio, AVG(FV.costo_unit) as promedio_costo, SUM(FV.cant_unid) as unidades_vendidas,
SUM(FV.monto_descuento) as suma_monto_descuento, SUM(FV.cant_con_desc) as unidades_con_descuento,
COUNT(DISTINCT DPS.id_sub) as cant_dist_prodsub, COUNT(DPS.cant_productos_distintos) as cant_dist_prod
FROM fct_ventas FV
INNER JOIN dim_producto DP ON FV.id_producto = DP.id_producto
INNER JOIN dim_prod_sub DPS ON DPS.id_sub = DP.id_sub
GROUP BY MONTH(FV.fecha), FV.id_canal_venta, FV.id_tienda, DP.id_categoria;


*/