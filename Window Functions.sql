SELECT COUNT(*) FROM superstore;
SELECT * FROM superstore LIMIT 10;
SELECT 
    customer_name,
    order_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY order_date) AS order_number
FROM superstore
LIMIT 20;

SELECT 
    category,
    product_name,
    sales,
    RANK() OVER (PARTITION BY category ORDER BY sales DESC) AS sales_rank
FROM superstore
LIMIT 30;

SELECT 
    customer_name,
    order_id,
    order_date,
    sales,
    LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS previous_order_sales
FROM superstore
LIMIT 30;

SELECT 
    customer_name,
    order_id,
    order_date,
    sales,
    LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS previous_order_sales,
    sales - LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS sales_difference
FROM superstore
LIMIT 30;

SELECT 
    category,
    product_name,
    sales,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS sales_rank
FROM superstore
LIMIT 30;

SELECT
    product_name,
    sales,
	order_date,
	LAG(order_date) OVER(PARTITION BY product_name ORDER BY order_date ) AS Previous_date
FROM superstore
LIMIT 30;