-- 1. Monthly order volume (which months are incomplete?)
SELECT strftime('%Y-%m', order_purchase_timestamp) AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY month
ORDER BY month;

-- 2. Missing values in orders
SELECT SUM(order_approved_at IS NULL) AS no_approval_date,
       SUM(order_delivered_customer_date IS NULL) AS no_delivery_date,
       SUM(order_status = 'delivered' AND order_delivered_customer_date IS NULL) AS delivered_but_no_date
FROM orders;

-- 3. How many orders does each customer place?
SELECT orders_per_customer, COUNT(*) AS customers
FROM (
    SELECT c.customer_unique_id, COUNT(*) AS orders_per_customer
    FROM orders o
    JOIN customers c USING (customer_id)
    GROUP BY c.customer_unique_id
)
GROUP BY orders_per_customer
ORDER BY orders_per_customer;

-- 4. Do the money columns agree?
SELECT (SELECT ROUND(SUM(price), 0) FROM order_items)          AS item_revenue,
       (SELECT ROUND(SUM(freight_value), 0) FROM order_items)  AS freight,
       (SELECT ROUND(SUM(payment_value), 0) FROM order_payments) AS payments_total;