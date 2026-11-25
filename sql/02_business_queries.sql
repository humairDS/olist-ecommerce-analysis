-- 0. A clean base: exclude canceled/unavailable orders and incomplete months
CREATE VIEW IF NOT EXISTS valid_orders AS
SELECT o.*, c.customer_unique_id, c.customer_state
FROM orders o
JOIN customers c USING (customer_id)
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- 1. Monthly revenue, average order value and month-over-month growth (CTE + window function)
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,
           COUNT(DISTINCT o.order_id) AS orders,
           ROUND(SUM(oi.price), 0)    AS revenue
    FROM valid_orders o
    JOIN order_items oi USING (order_id)
    GROUP BY month
)
SELECT month, orders, revenue,
       ROUND(revenue * 1.0 / orders, 2) AS avg_order_value,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly;

-- 2. Top 10 categories by revenue, with share of total (window over an aggregate)
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(DISTINCT oi.order_id) AS orders,
       ROUND(SUM(oi.price), 0)     AS revenue,
       ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 1) AS pct_of_revenue
FROM order_items oi
JOIN valid_orders o USING (order_id)
JOIN products p USING (product_id)
LEFT JOIN category_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- 3. Who is the 17-order customer? (outlier check)
SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 0)    AS spend
FROM orders o
JOIN customers c USING (customer_id)
JOIN order_items oi USING (order_id)
GROUP BY c.customer_unique_id
ORDER BY orders DESC
LIMIT 5;