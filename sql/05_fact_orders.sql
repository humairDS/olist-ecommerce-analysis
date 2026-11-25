SELECT oi.order_id,
       oi.order_item_id,
       date(o.order_purchase_timestamp) AS order_date,
       o.customer_unique_id,
       o.customer_state,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       oi.price,
       oi.freight_value,
       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN ROUND(julianday(o.order_delivered_customer_date)
                     - julianday(o.order_purchase_timestamp), 1) END AS delivery_days,
       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN (o.order_delivered_customer_date > o.order_estimated_delivery_date) END AS is_late,
       s.segment,
       s.frequency
FROM order_items oi
JOIN valid_orders o USING (order_id)
JOIN products p USING (product_id)
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN customer_segments s ON s.customer_unique_id = o.customer_unique_id;