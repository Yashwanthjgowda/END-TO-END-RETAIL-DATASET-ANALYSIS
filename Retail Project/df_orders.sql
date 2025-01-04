create database retail;
use retail;
show tables;
select * from df_orders;
SELECT count(*) from df_orders;

/* 1. find top 10 highest reveue generating products */
SELECT product_id, SUM(list_price * quantity) AS sales
FROM df_orders
GROUP BY product_id

/* 2. Find Top 5 Highest Selling Products in Each Region*/
WITH cte AS (
    SELECT region, product_id, SUM(list_price * quantity) AS sales
    FROM df_orders
    GROUP BY region, product_id
)
SELECT * FROM (
    SELECT *, 
           @row_num := IF(@current_region = region, @row_num + 1, 1) AS rn,
           @current_region := region
    FROM cte
    ORDER BY region, sales DESC
) AS A
WHERE rn <= 5;
 
/* 3.Month-over-Month Growth Comparison for 2022 and 2023 Sales */
WITH cte AS (
    SELECT YEAR(order_date) AS order_year,
           MONTH(order_date) AS order_month,
           SUM(list_price * quantity) AS sales
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_month,
       SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
       SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY order_month
ORDER BY order_month;

/*For Each Category, Which Month Had the Highest Sales*/
WITH cte AS (
    SELECT category, DATE_FORMAT(order_date, '%Y%m') AS order_year_month,
           SUM(list_price * quantity) AS sales
    FROM df_orders
    GROUP BY category, DATE_FORMAT(order_date, '%Y%m')
)
SELECT * FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM cte
) AS a
WHERE rn = 1;

/*Which Subcategory Had the Highest Growth by Profit in 2023 Compared to 2022*/
WITH cte AS (
    SELECT sub_category, YEAR(order_date) AS order_year,
           SUM(list_price * quantity - cost_price * quantity) AS profit
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
)
, cte2 AS (
    SELECT sub_category,
           SUM(CASE WHEN order_year = 2022 THEN profit ELSE 0 END) AS profit_2022,
           SUM(CASE WHEN order_year = 2023 THEN profit ELSE 0 END) AS profit_2023
    FROM cte
    GROUP BY sub_category
)
SELECT *
     , (profit_2023 - profit_2022) AS profit_growth
FROM cte2
ORDER BY profit_growth DESC
LIMIT 1;

SHOW VARIABLES LIKE 'datadir';
