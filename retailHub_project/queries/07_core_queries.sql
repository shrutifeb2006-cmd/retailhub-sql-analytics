-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 07_core_queries.sql
-- Description: Basic queries → Joins → Aggregations →
--              Subqueries → CTEs → Window Functions
-- ============================================================

USE retailx_db;

-- ============================================================
-- SECTION 1: BASIC QUERIES
-- ============================================================

-- 1.1 All completed orders above ₹50,000
SELECT
    o.order_id,
    c.full_name        AS customer_name,
    s.store_name,
    o.order_date,
    o.total_amount,
    o.channel
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores    s ON o.store_id    = s.store_id
WHERE o.status       = 'Completed'
  AND o.total_amount > 50000
ORDER BY o.total_amount DESC;

-- 1.2 Products with margin above 40%
SELECT
    p.product_name,
    cat.category_name,
    p.brand,
    p.cost_price,
    p.selling_price,
    ROUND((p.selling_price - p.cost_price) / p.selling_price * 100, 2) AS margin_pct
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
WHERE ((p.selling_price - p.cost_price) / p.selling_price * 100) > 40
ORDER BY margin_pct DESC;

-- 1.3 Customers registered in 2023 who are Premium
SELECT
    customer_id,
    full_name,
    email,
    city,
    segment,
    loyalty_pts,
    created_at
FROM customers
WHERE segment    = 'Premium'
  AND created_at >= '2023-01-01'
  AND created_at <  '2024-01-01'
ORDER BY loyalty_pts DESC;

-- 1.4 Orders placed on the Online channel in 2024
SELECT
    o.order_id,
    c.full_name,
    o.order_date,
    o.status,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.channel    = 'Online'
  AND YEAR(o.order_date) = 2024
ORDER BY o.order_date DESC;

-- 1.5 Stores sorted by target revenue
SELECT
    store_id,
    store_name,
    city,
    region,
    target_revenue,
    opened_date
FROM stores
ORDER BY target_revenue DESC;


-- ============================================================
-- SECTION 2: JOINS
-- ============================================================

-- 2.1 INNER JOIN — Full order details with product line items
SELECT
    o.order_id,
    c.full_name                                         AS customer_name,
    s.store_name,
    p.product_name,
    cat.category_name,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount/100), 2) AS net_amount,
    o.channel,
    o.status
FROM orders o
INNER JOIN customers   c   ON o.customer_id   = c.customer_id
INNER JOIN stores      s   ON o.store_id      = s.store_id
INNER JOIN order_items oi  ON o.order_id      = oi.order_id
INNER JOIN products    p   ON oi.product_id   = p.product_id
INNER JOIN categories  cat ON p.category_id   = cat.category_id
WHERE o.status = 'Completed'
ORDER BY o.order_date DESC;

-- 2.2 LEFT JOIN — Customers who have NEVER placed an order (churned)
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.city,
    c.segment,
    c.created_at
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.created_at;

-- 2.3 LEFT JOIN — Products that have NEVER been sold
SELECT
    p.product_id,
    p.product_name,
    p.brand,
    cat.category_name,
    p.selling_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
JOIN      categories cat  ON p.category_id = cat.category_id
WHERE oi.item_id IS NULL;

-- 2.4 Multi-table JOIN — Payment method vs average order value
SELECT
    pay.payment_method,
    COUNT(o.order_id)             AS total_orders,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    ROUND(SUM(o.total_amount), 2) AS total_revenue
FROM orders o
JOIN payments pay ON o.order_id = pay.order_id
WHERE o.status    = 'Completed'
  AND pay.status  = 'Success'
GROUP BY pay.payment_method
ORDER BY avg_order_value DESC;

-- 2.5 Store ↔ Employee headcount join
SELECT
    s.store_name,
    s.region,
    COUNT(e.employee_id)                    AS headcount,
    ROUND(AVG(e.salary), 2)                 AS avg_salary,
    SUM(e.salary)                           AS total_payroll,
    GROUP_CONCAT(DISTINCT e.role ORDER BY e.role SEPARATOR ', ') AS roles_present
FROM stores    s
LEFT JOIN employees e ON s.store_id = e.store_id AND e.is_active = 1
GROUP BY s.store_id, s.store_name, s.region
ORDER BY headcount DESC;


-- ============================================================
-- SECTION 3: AGGREGATIONS, GROUP BY, HAVING
-- ============================================================

-- 3.1 Revenue and order count by store vs target
SELECT
    s.store_name,
    s.region,
    s.target_revenue,
    COUNT(o.order_id)                                                AS total_orders,
    COALESCE(ROUND(SUM(o.total_amount), 2), 0)                       AS actual_revenue,
    ROUND(COALESCE(SUM(o.total_amount), 0) / s.target_revenue * 100, 1) AS achievement_pct,
    ROUND(COALESCE(SUM(o.total_amount), 0) - s.target_revenue, 2)   AS revenue_gap
FROM stores s
LEFT JOIN orders o ON s.store_id  = o.store_id AND o.status = 'Completed'
GROUP BY s.store_id, s.store_name, s.region, s.target_revenue
ORDER BY actual_revenue DESC;

-- 3.2 Revenue by product category
SELECT
    cat.category_name,
    COUNT(DISTINCT oi.order_id)                                       AS orders_count,
    SUM(oi.quantity)                                                  AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1-oi.discount/100)), 2) AS net_revenue,
    ROUND(AVG(oi.unit_price), 2)                                      AS avg_unit_price
FROM order_items oi
JOIN products   p   ON oi.product_id  = p.product_id
JOIN categories cat ON p.category_id  = cat.category_id
JOIN orders     o   ON oi.order_id    = o.order_id
WHERE o.status = 'Completed'
GROUP BY cat.category_id, cat.category_name
ORDER BY net_revenue DESC;

-- 3.3 HAVING — Customers with more than 3 completed orders
SELECT
    c.customer_id,
    c.full_name,
    c.segment,
    COUNT(o.order_id)            AS order_count,
    ROUND(SUM(o.total_amount),2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.full_name, c.segment
HAVING COUNT(o.order_id) > 3
ORDER BY lifetime_value DESC;

-- 3.4 Monthly revenue aggregation
SELECT
    DATE_FORMAT(order_date, '%Y-%m')      AS month,
    COUNT(order_id)                        AS total_orders,
    COUNT(CASE WHEN status='Completed'  THEN 1 END) AS completed,
    COUNT(CASE WHEN status='Returned'   THEN 1 END) AS returned,
    COUNT(CASE WHEN status='Cancelled'  THEN 1 END) AS cancelled,
    ROUND(SUM(CASE WHEN status='Completed' THEN total_amount ELSE 0 END), 2) AS revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- 3.5 Return rate by product category
SELECT
    cat.category_name,
    COUNT(DISTINCT CASE WHEN o.status='Completed' THEN o.order_id END) AS completed_orders,
    COUNT(DISTINCT CASE WHEN o.status='Returned'  THEN o.order_id END) AS returned_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.status='Returned' THEN o.order_id END) /
        NULLIF(COUNT(DISTINCT o.order_id), 0) * 100, 2
    ) AS return_rate_pct
FROM orders o
JOIN order_items oi  ON o.order_id   = oi.order_id
JOIN products p      ON oi.product_id = p.product_id
JOIN categories cat  ON p.category_id = cat.category_id
GROUP BY cat.category_id, cat.category_name
ORDER BY return_rate_pct DESC;


-- ============================================================
-- SECTION 4: SUBQUERIES
-- ============================================================

-- 4.1 Customers whose lifetime value exceeds the average
SELECT
    c.customer_id,
    c.full_name,
    c.segment,
    ROUND(SUM(o.total_amount), 2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.full_name, c.segment
HAVING SUM(o.total_amount) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT customer_id, SUM(total_amount) AS customer_total
        FROM orders
        WHERE status = 'Completed'
        GROUP BY customer_id
    ) sub
)
ORDER BY lifetime_value DESC;

-- 4.2 Products with stock below reorder level in at least one store
SELECT
    p.product_name,
    cat.category_name,
    p.brand,
    COUNT(*)                   AS stores_with_shortage,
    MIN(i.stock_qty)           AS lowest_stock,
    AVG(i.reorder_level)       AS avg_reorder_level
FROM inventory i
JOIN products   p   ON i.product_id  = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE i.stock_qty <= i.reorder_level
GROUP BY p.product_id, p.product_name, cat.category_name, p.brand
ORDER BY stores_with_shortage DESC, lowest_stock;

-- 4.3 Second-highest revenue order per store
SELECT
    store_name,
    order_id,
    total_amount AS second_highest_order
FROM (
    SELECT
        s.store_name,
        o.order_id,
        o.total_amount,
        DENSE_RANK() OVER (PARTITION BY o.store_id ORDER BY o.total_amount DESC) AS rnk
    FROM orders o
    JOIN stores s ON o.store_id = s.store_id
    WHERE o.status = 'Completed'
) ranked
WHERE rnk = 2;


-- ============================================================
-- SECTION 5: CTEs (Common Table Expressions)
-- ============================================================

-- 5.1 Month-over-Month revenue growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')       AS month,
        ROUND(SUM(total_amount), 2)            AS revenue,
        COUNT(order_id)                        AS orders
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
with_lag AS (
    SELECT
        month,
        revenue,
        orders,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly
)
SELECT
    month,
    revenue,
    orders,
    prev_revenue,
    ROUND((revenue - prev_revenue) / NULLIF(prev_revenue, 0) * 100, 2) AS mom_growth_pct
FROM with_lag
ORDER BY month;

-- 5.2 Cumulative revenue by store (running total)
WITH daily_store_rev AS (
    SELECT
        s.store_name,
        DATE(o.order_date)           AS sale_date,
        SUM(o.total_amount)          AS daily_revenue
    FROM orders o
    JOIN stores s ON o.store_id = s.store_id
    WHERE o.status = 'Completed'
      AND YEAR(o.order_date) = 2023
    GROUP BY s.store_name, DATE(o.order_date)
)
SELECT
    store_name,
    sale_date,
    daily_revenue,
    ROUND(SUM(daily_revenue) OVER (
        PARTITION BY store_name ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue
FROM daily_store_rev
ORDER BY store_name, sale_date;

-- 5.3 Pareto Analysis — products contributing 80% of revenue
WITH product_rev AS (
    SELECT
        p.product_id,
        p.product_name,
        cat.category_name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 2) AS revenue
    FROM order_items oi
    JOIN products   p   ON oi.product_id  = p.product_id
    JOIN categories cat ON p.category_id  = cat.category_id
    JOIN orders     o   ON oi.order_id    = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name, cat.category_name
),
total AS (SELECT SUM(revenue) AS grand_total FROM product_rev),
cumulative AS (
    SELECT
        pr.*,
        ROUND(pr.revenue / t.grand_total * 100, 2) AS revenue_pct,
        ROUND(SUM(pr.revenue) OVER (ORDER BY pr.revenue DESC) / t.grand_total * 100, 2) AS cumulative_pct
    FROM product_rev pr, total t
)
SELECT
    product_name,
    category_name,
    revenue,
    revenue_pct,
    cumulative_pct,
    CASE WHEN cumulative_pct <= 80 THEN 'Top 80%' ELSE 'Long Tail' END AS pareto_label
FROM cumulative
ORDER BY revenue DESC;


-- ============================================================
-- SECTION 6: WINDOW FUNCTIONS
-- ============================================================

-- 6.1 RANK — Products ranked by revenue within each category
SELECT
    cat.category_name,
    p.product_name,
    p.brand,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_revenue,
    RANK() OVER (
        PARTITION BY cat.category_id
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC
    ) AS revenue_rank,
    DENSE_RANK() OVER (
        PARTITION BY cat.category_id
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC
    ) AS dense_rank_val
FROM order_items oi
JOIN products   p   ON oi.product_id  = p.product_id
JOIN categories cat ON p.category_id  = cat.category_id
JOIN orders     o   ON oi.order_id    = o.order_id
WHERE o.status = 'Completed'
GROUP BY cat.category_id, cat.category_name, p.product_id, p.product_name, p.brand
ORDER BY cat.category_name, revenue_rank;

-- 6.2 ROW_NUMBER — Top 3 customers per city by spend
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.city,
        c.segment,
        ROUND(SUM(o.total_amount), 2) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.full_name, c.city, c.segment
)
SELECT *
FROM (
    SELECT
        customer_id,
        full_name,
        city,
        segment,
        total_spend,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_spend DESC) AS city_rank
    FROM customer_spend
) ranked
WHERE city_rank <= 3
ORDER BY city, city_rank;

-- 6.3 LAG / LEAD — Compare each order to the customer's previous order
SELECT
    o.order_id,
    c.full_name,
    o.order_date,
    o.total_amount,
    LAG(o.total_amount)  OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS prev_order_amt,
    LEAD(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS next_order_amt,
    ROUND(o.total_amount -
          LAG(o.total_amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date), 2
    ) AS delta_vs_prev,
    DATEDIFF(o.order_date,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date)
    ) AS days_since_prev_order
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY c.full_name, o.order_date;

-- 6.4 NTILE — Quartile bucketing of customers by spend
SELECT
    customer_id,
    full_name,
    total_spend,
    NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile,
    CASE NTILE(4) OVER (ORDER BY total_spend DESC)
        WHEN 1 THEN 'Top 25% — Whale'
        WHEN 2 THEN 'Upper Mid'
        WHEN 3 THEN 'Lower Mid'
        WHEN 4 THEN 'Bottom 25%'
    END AS quartile_label
FROM (
    SELECT
        c.customer_id,
        c.full_name,
        ROUND(SUM(o.total_amount), 2) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.full_name
) agg
ORDER BY total_spend DESC;

-- 6.5 Moving average — 3-month rolling revenue
WITH monthly_rev AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total_amount)                AS revenue
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg
FROM monthly_rev
ORDER BY month;
