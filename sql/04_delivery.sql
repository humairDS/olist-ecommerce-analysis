SELECT customer_state,
       COUNT(*) AS delivered_orders,
       ROUND(AVG(julianday(order_delivered_customer_date)
               - julianday(order_purchase_timestamp)), 1) AS avg_delivery_days,
       ROUND(100.0 * SUM(order_delivered_customer_date > order_estimated_delivery_date)
             / COUNT(*), 1) AS pct_late
FROM valid_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days DESC;