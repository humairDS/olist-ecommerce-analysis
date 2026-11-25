WITH first_orders AS (
    SELECT customer_unique_id,
           MIN(strftime('%Y-%m', order_purchase_timestamp)) AS cohort_month
    FROM valid_orders
    GROUP BY customer_unique_id
),
activity AS (
    SELECT DISTINCT customer_unique_id,
           strftime('%Y-%m', order_purchase_timestamp) AS order_month
    FROM valid_orders
),
cohort_counts AS (
    SELECT f.cohort_month,
           (CAST(substr(a.order_month, 1, 4) AS INT) * 12 + CAST(substr(a.order_month, 6, 2) AS INT))
         - (CAST(substr(f.cohort_month, 1, 4) AS INT) * 12 + CAST(substr(f.cohort_month, 6, 2) AS INT))
           AS month_number,
           COUNT(DISTINCT a.customer_unique_id) AS customers
    FROM first_orders f
    JOIN activity a USING (customer_unique_id)
    GROUP BY f.cohort_month, month_number
)
SELECT cohort_month,
       month_number,
       customers,
       ROUND(100.0 * customers /
             FIRST_VALUE(customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 2)
           AS retention_pct
FROM cohort_counts
ORDER BY cohort_month, month_number;


DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments AS
WITH customer_stats AS (
    SELECT o.customer_unique_id,
           CAST(julianday('2018-09-01') - julianday(MAX(o.order_purchase_timestamp)) AS INT) AS recency_days,
           COUNT(DISTINCT o.order_id) AS frequency,
           ROUND(SUM(oi.price), 2)    AS monetary
    FROM valid_orders o
    JOIN order_items oi USING (order_id)
    GROUP BY o.customer_unique_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM customer_stats
)
SELECT *,
       CASE
           WHEN frequency >= 2 AND r_score >= 4 THEN '1. Loyal (repeat, recent)'
           WHEN frequency >= 2                  THEN '2. Repeat (lapsing)'
           WHEN r_score >= 4 AND m_score >= 4   THEN '3. New high-value'
           WHEN r_score >= 4                    THEN '4. New'
           WHEN m_score >= 4                    THEN '5. Lapsed high-value'
           ELSE                                      '6. Lapsed low-value'
       END AS segment
FROM scored;

-- Summary: how big is each segment and how much revenue does it hold?
SELECT segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
       ROUND(SUM(monetary), 0) AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
       ROUND(AVG(monetary), 1) AS avg_spend
FROM customer_segments
GROUP BY segment
ORDER BY segment;


SELECT * FROM customer_segments;
