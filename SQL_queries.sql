                                        -- WINDOW FUNCTIONS --

-- Q: Count total rows in superstore table
SELECT COUNT(*) FROM superstore;

-- Q: View all data in superstore table
SELECT * FROM superstore;

-- Q: View first 10 rows of superstore table
SELECT * FROM superstore LIMIT 10;

-- Q: For each order, show its sales along with the average sales of its category
--    (without collapsing rows - use window function)
SELECT 
    order_id,
    sales,
    category,
    AVG(sales) OVER (PARTITION BY category) AS category_avg
FROM superstore;

-- Q: Number each customer's orders chronologically (oldest = 1)
--    Show customer name, order id, order date, and order number
SELECT 
    customer_name,
    order_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY order_date) AS order_number
FROM superstore
LIMIT 20;

-- Q: Within each category, number products by sales (highest sales = 1)
--    Show category, product name, sales, and row number
SELECT 
    category,
    product_name,
    sales,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS sales_rank
FROM superstore
LIMIT 30;

-- Q: Within each category, RANK products by sales (highest = rank 1)
--    Note: RANK gives same rank to ties, ROW_NUMBER does not
SELECT 
    category,
    product_name,
    sales,
    RANK() OVER (PARTITION BY category ORDER BY sales DESC) AS sales_rank
FROM superstore
LIMIT 30;

-- Q: For each customer, show each order's sales AND the previous order's sales
--    (ordered by date) to compare growth
SELECT 
    customer_name,
    order_id,
    order_date,
    sales,
    LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS previous_order_sales
FROM superstore
LIMIT 30;

-- Q: Same as above but also calculate the difference between current and previous order sales
SELECT 
    customer_name,
    order_id,
    order_date,
    sales,
    LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS previous_order_sales,
    sales - LAG(sales) OVER (PARTITION BY customer_name ORDER BY order_date) AS sales_difference
FROM superstore
LIMIT 30;

-- Q: For each product, show the previous order date
--    (i.e., when was this product last ordered before current order)
SELECT
    product_name,
    sales,
    order_date,
    LAG(order_date) OVER(PARTITION BY product_name ORDER BY order_date) AS previous_date
FROM superstore
LIMIT 30;


                                            -- CTEs --

-- Q: Find each customer's total sales per region,
--    then rank customers within each region (highest total sales = rank 1)
WITH customer_totals AS (
    SELECT 
        customer_name,
        region,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY customer_name, region
)
SELECT 
    customer_name,
    region,
    total_sales,
    RANK() OVER (PARTITION BY region ORDER BY total_sales DESC) AS sales_rank
FROM customer_totals;

-- Q: Same as above but only show customers whose total sales exceed 5000
--    (demonstrate chaining multiple CTEs)
WITH customer_totals AS (
    SELECT 
        customer_name,
        region,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY customer_name, region
),
high_value_customers AS (
    SELECT *
    FROM customer_totals
    WHERE total_sales > 5000
)
SELECT 
    customer_name,
    region,
    total_sales,
    RANK() OVER (PARTITION BY region ORDER BY total_sales DESC) AS sales_rank
FROM high_value_customers;


                                        -- SUBQUERIES --

-- Q: Show all orders where sales are above the overall average sales
--    (subquery inside WHERE)
SELECT order_id, customer_name, sales
FROM superstore
WHERE sales > (SELECT AVG(sales) FROM superstore);

-- Q: Show distinct California customers whose at least one order
--    exceeds the overall average sales
SELECT DISTINCT customer_name, state, sales
FROM superstore
WHERE state = 'California' AND sales > (SELECT AVG(sales) FROM superstore);

-- Q: Show orders where sales exceed 50% of the maximum sale value
SELECT order_id, sales
FROM superstore
WHERE sales > (SELECT MAX(sales) * 0.5 FROM superstore);

-- Q: Show categories where average sales exceed 300
--    (subquery inside FROM - treating result as a temporary table)
SELECT category, avg_sales
FROM (
    SELECT category, AVG(sales) AS avg_sales
    FROM superstore
    GROUP BY category
) AS category_averages
WHERE avg_sales > 300;

-- Q: For each order, show its sales, the overall average, and the difference
--    Note: subquery in SELECT is slower than window functions on large data
SELECT 
    order_id,
    customer_name,
    sales,
    (SELECT AVG(sales) FROM superstore) AS overall_average,
    sales - (SELECT AVG(sales) FROM superstore) AS difference_from_avg
FROM superstore
LIMIT 20;


                                            -- JOINS --

-- Setup: Create a returns table to practice JOINs
CREATE TABLE returns (
    order_id TEXT,
    returned TEXT
);

INSERT INTO returns VALUES
('CA-2017-152156', 'Yes'),
('US-2016-108966', 'Yes'),
('CA-2015-138422', 'Yes'),
('CA-2016-139892', 'Yes'),
('CA-2017-143567', 'Yes');

-- Q: Find the total sales amount of all returned orders (INNER JOIN)
SELECT SUM(s.sales) AS total_returned_sales
FROM superstore s
INNER JOIN returns r ON s.order_id = r.order_id;

-- Q: Show each returned order's id and its total sales
SELECT s.order_id,
       SUM(s.sales) AS returned_order_sales
FROM superstore s
INNER JOIN returns r ON s.order_id = r.order_id
GROUP BY s.order_id;

-- Q: Show California customers who had a returned order
--    (case-insensitive check using LOWER)
SELECT s.customer_name, s.state
FROM superstore s
INNER JOIN returns r ON s.order_id = r.order_id
WHERE s.state = 'California' AND LOWER(r.returned) = 'yes';

-- Q: Count how many returned orders each region had
SELECT s.region, COUNT(r.returned)
FROM superstore s
INNER JOIN returns r ON s.order_id = r.order_id
GROUP BY s.region;

-- Q: Show total sales per category for orders that were NOT returned
--    (LEFT JOIN + NULL filter pattern)
SELECT SUM(s.sales), s.category
FROM superstore s
LEFT JOIN returns r ON s.order_id = r.order_id
WHERE r.returned IS NULL
GROUP BY s.category;


                                            -- HAVING --

-- Q: For Consumer segment only, show category+state combinations
--    where total sales exceed 10000, sorted by total sales descending
SELECT 
    category, state,
    COUNT(*) AS order_count,
    SUM(sales) AS total_sales
FROM superstore
WHERE segment = 'Consumer'        
GROUP BY category, state
HAVING SUM(sales) > 10000         
ORDER BY total_sales DESC;

-- Q: Show customers whose total sales exceed 5000
SELECT SUM(sales), customer_name
FROM superstore
GROUP BY customer_name 
HAVING SUM(sales) > 5000;

-- Q: Show states that have more than 50 orders AND average sales above 200
SELECT state, COUNT(order_id), AVG(sales)
FROM superstore
GROUP BY state
HAVING COUNT(order_id) > 50 AND AVG(sales) > 200;

-- Q: Show sub-categories where total sales of returned orders exceed 1000
SELECT s.sub_category, SUM(s.sales)
FROM superstore s
JOIN returns r ON s.order_id = r.order_id
GROUP BY s.sub_category
HAVING SUM(s.sales) > 1000;


                                        -- CASE WHEN --

-- Q: Label each order's ship mode as Fast/Normal/Slow/Other
SELECT ship_mode,
    CASE 
        WHEN ship_mode = 'First Class'    THEN 'Fast'
        WHEN ship_mode = 'Second Class'   THEN 'Normal'
        WHEN ship_mode = 'Standard Class' THEN 'Slow'
        ELSE 'Other'
    END AS delivery_speed
FROM superstore
LIMIT 50;

-- Q: For each region, count how many orders fall into
--    High (>500), Medium (200-500), and Low (<200) sales buckets
--    (conditional aggregation - all in one query)
SELECT region, COUNT(order_id) AS total_orders,
    SUM(CASE WHEN sales > 500               THEN 1 ELSE 0 END) AS high,
    SUM(CASE WHEN sales BETWEEN 200 AND 500 THEN 1 ELSE 0 END) AS medium,
    SUM(CASE WHEN sales < 200               THEN 1 ELSE 0 END) AS low
FROM superstore
GROUP BY region;

-- Q: Classify each customer as Platinum/Gold/Silver/Bronze based on total sales
--    Show only Platinum and Gold customers
SELECT *
FROM (
    SELECT
        customer_name,
        SUM(sales) AS total_sales,
        CASE
            WHEN SUM(sales) > 10000 THEN 'Platinum'
            WHEN SUM(sales) > 5000  THEN 'Gold'
            WHEN SUM(sales) > 1000  THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM superstore
    GROUP BY customer_name
) AS customer_summary
WHERE customer_tier IN ('Platinum', 'Gold');


                                        -- DATE FUNCTIONS --

-- Q: View raw order and ship dates (stored as TEXT)
SELECT order_date, ship_date 
FROM superstore 
LIMIT 5;

-- Q: Convert order_date from text (DD/MM/YYYY format) to proper DATE type
SELECT 
    order_date,
    TO_DATE(order_date, 'DD/MM/YYYY') AS proper_date
FROM superstore
LIMIT 10;

-- Q: Permanently add proper DATE columns to the table
--    (ALTER TABLE to add columns, UPDATE to fill them)
ALTER TABLE superstore 
ADD COLUMN order_date_proper DATE,
ADD COLUMN ship_date_proper DATE;

UPDATE superstore
SET 
    order_date_proper = TO_DATE(order_date, 'DD/MM/YYYY'),
    ship_date_proper  = TO_DATE(ship_date,  'DD/MM/YYYY');

-- Q: Extract year, month, and day separately from order date
SELECT 
    order_date_proper,
    EXTRACT(YEAR  FROM order_date_proper) AS order_year,
    EXTRACT(MONTH FROM order_date_proper) AS order_month,
    EXTRACT(DAY   FROM order_date_proper) AS order_day
FROM superstore
LIMIT 10;

-- Q: Calculate how long delivery took for each order (ship date - order date)
SELECT 
    order_id,
    order_date_proper,
    ship_date_proper,
    AGE(ship_date_proper, order_date_proper) AS delivery_time
FROM superstore
LIMIT 10;

-- Q: Show total orders and total sales grouped by month
--    (DATE_TRUNC snaps date to first day of each month for clean grouping)
SELECT 
    DATE_TRUNC('month', order_date_proper) AS order_month,
    COUNT(*) AS total_orders,
    SUM(sales) AS monthly_sales
FROM superstore
GROUP BY DATE_TRUNC('month', order_date_proper)
ORDER BY order_month;

-- Q: Show total sales per year
SELECT
    EXTRACT(YEAR FROM order_date_proper) AS year,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY EXTRACT(YEAR FROM order_date_proper)
ORDER BY year;

-- Q: Calculate average delivery days for each shipping mode
SELECT
    ship_mode,
    AVG(
        EXTRACT(DAY FROM AGE(ship_date_proper, order_date_proper))
    ) AS avg_delivery_days
FROM superstore
GROUP BY ship_mode
ORDER BY avg_delivery_days;

-- Q: For each month, find the top-ranked category by total sales
--    (DATE_TRUNC + CTE + RANK combined)
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', ship_date_proper) AS month,
        category,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY
        DATE_TRUNC('month', ship_date_proper),
        category
),
ranked_sales AS (
    SELECT
        month,
        category,
        total_sales,
        RANK() OVER (
            PARTITION BY month
            ORDER BY total_sales DESC
        ) AS ranking
    FROM monthly_sales
)
SELECT
    month,
    category,
    total_sales
FROM ranked_sales
WHERE ranking = 1
ORDER BY month;


                        -- CAPSTONE: COMBINING EVERYTHING --

-- Q: For each month and category, calculate total sales and count of returned orders.
--    Only include month+category combinations where total sales exceed 10000.
--    Rank categories within each month by total sales (highest = rank 1).
--    Also label each order as Returned/Not Returned.
--    Sort final result by month and ranking.
--    (Uses: LEFT JOIN + CASE WHEN + DATE_TRUNC + GROUP BY + HAVING + CTE + RANK)

WITH order_level AS (
    SELECT 
        s.order_id,
        s.category,
        s.sales,
        s.ship_date_proper,
        CASE 
            WHEN r.returned = 'Yes' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM superstore s
    LEFT JOIN returns r ON s.order_id = r.order_id
),
monthly_category AS (
    SELECT 
        DATE_TRUNC('month', ship_date_proper) AS month,
        category,
        SUM(sales) AS total_sales,
        COUNT(CASE WHEN return_status = 'Returned' THEN 1 END) AS returned_orders
    FROM order_level
    GROUP BY DATE_TRUNC('month', ship_date_proper), category
    HAVING SUM(sales) > 10000
)
SELECT 
    month,
    category,
    total_sales,
    returned_orders,
    RANK() OVER (PARTITION BY month ORDER BY total_sales DESC) AS ranking
FROM monthly_category
ORDER BY month, ranking;

