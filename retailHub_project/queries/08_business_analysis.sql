-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 08_business_analysis.sql
-- Description: Advanced business intelligence queries
-- ============================================================

USE retailx_db;

-- ============================================================
-- ANALYSIS 1: TOP 10 CUSTOMERS BY REVENUE
-- ============================================================
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.city,
    c.segment,
    c.loyalty_pts,
    COUNT(DISTINCT o.order_id)                AS total_orders,
    ROUND(SUM(o.total_amount), 2)             AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)             AS avg_order_value,
    MIN(o.order_date)                         AS first_purchase,
    MAX(o.order_date)                         AS last_purchase,
    DATEDIFF(CURDATE(), MAX(o.order_date))    AS days_since_last_purchase,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS customer_lifespan_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.full_name, c.email, c.city, c.segment, c.loyalty_pts
ORDER BY lifetime_value DESC
LIMIT 10;


-- ============================================================
-- ANALYSIS 2: RFM CUSTOMER SEGMENTATION
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        c.segment                                     AS current_segment,
        DATEDIFF(CURDATE(), MAX(o.order_date))        AS recency_days,
        COUNT(DISTINCT o.order_id)                    AS frequency,
        ROUND(SUM(o.total_amount), 2)                 AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.full_name, c.email, c.segment
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days  ASC)  AS r_score,   -- lower days = higher recency score
        NTILE(5) OVER (ORDER BY frequency     DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary      DESC) AS m_score
    FROM rfm_base
),
rfm_labeled AS (
    SELECT *,
        CONCAT(r_score, f_score, m_score)        AS rfm_code,
        (r_score + f_score + m_score)            AS rfm_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customer'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'Promising'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 3 THEN 'Potential Loyalist'
            WHEN r_score >= 4 AND f_score >= 4 AND m_score <= 2 THEN 'Recent Customer'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 2 AND m_score >= 2 THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
            WHEN r_score <= 1 AND f_score <= 1                  THEN 'Lost'
            ELSE 'About to Sleep'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    customer_id,
    full_name,
    email,
    current_segment,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_code,
    rfm_total,
    rfm_segment
FROM rfm_labeled
ORDER BY rfm_total DESC, monetary DESC;


-- ============================================================
-- ANALYSIS 3: RFM SEGMENT SUMMARY (for dashboard)
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_id,
        DATEDIFF(CURDATE(), MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id)             AS frequency,
        SUM(o.total_amount)                    AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency    DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary     DESC) AS m_score
    FROM rfm_base
),
rfm_labeled AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customer'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'Promising'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 3 THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 2 AND m_score >= 2 THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
            ELSE 'About to Sleep'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    COUNT(*)                              AS customer_count,
    ROUND(AVG(recency_days), 0)           AS avg_recency_days,
    ROUND(AVG(frequency), 1)              AS avg_frequency,
    ROUND(AVG(monetary), 2)               AS avg_monetary,
    ROUND(SUM(monetary), 2)               AS segment_revenue
FROM rfm_labeled
GROUP BY rfm_segment
ORDER BY segment_revenue DESC;


-- ============================================================
-- ANALYSIS 4: MONTHLY SALES TREND WITH YoY COMPARISON
-- ============================================================
WITH monthly_sales AS (
    SELECT
        YEAR(order_date)                      AS yr,
        MONTH(order_date)                     AS mth,
        DATE_FORMAT(order_date, '%Y-%m')      AS month_str,
        COUNT(order_id)                       AS orders,
        ROUND(SUM(total_amount), 2)           AS revenue
    FROM orders
    WHERE status = 'Completed'
    GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    a.month_str,
    a.yr,
    a.mth,
    a.orders       AS current_orders,
    a.revenue      AS current_revenue,
    b.revenue      AS prev_year_revenue,
    ROUND((a.revenue - b.revenue) / NULLIF(b.revenue, 0) * 100, 2) AS yoy_growth_pct
FROM monthly_sales a
LEFT JOIN monthly_sales b
    ON a.mth = b.mth AND a.yr = b.yr + 1
ORDER BY a.month_str;


-- ============================================================
-- ANALYSIS 5: BEST-SELLING PRODUCTS (by revenue + units)
-- ============================================================
SELECT
    p.product_id,
    p.product_name,
    p.brand,
    cat.category_name,
    p.cost_price,
    p.selling_price,
    ROUND((p.selling_price - p.cost_price) / p.selling_price * 100, 2) AS margin_pct,
    SUM(oi.quantity)                                                     AS total_units_sold,
    COUNT(DISTINCT oi.order_id)                                          AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 2)  AS net_revenue,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC)         AS revenue_rank,
    RANK() OVER (ORDER BY SUM(oi.quantity) DESC)                         AS units_rank
FROM order_items oi
JOIN products   p   ON oi.product_id  = p.product_id
JOIN categories cat ON p.category_id  = cat.category_id
JOIN orders     o   ON oi.order_id    = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, p.brand, cat.category_name,
         p.cost_price, p.selling_price
ORDER BY net_revenue DESC
LIMIT 20;


-- ============================================================
-- ANALYSIS 6: INVENTORY SHORTAGE ALERT
-- ============================================================
SELECT
    p.product_id,
    p.product_name,
    p.brand,
    cat.category_name,
    s.store_name,
    s.city,
    i.stock_qty,
    i.reorder_level,
    GREATEST(0, i.reorder_level - i.stock_qty) AS shortage_units,
    i.last_updated,
    CASE
        WHEN i.stock_qty = 0                    THEN 'STOCKOUT 🔴'
        WHEN i.stock_qty < i.reorder_level      THEN 'CRITICAL 🟠'
        WHEN i.stock_qty < i.reorder_level * 1.5 THEN 'LOW ⚠️'
        ELSE 'OK ✅'
    END AS stock_status
FROM inventory i
JOIN products   p ON i.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
JOIN stores     s ON i.store_id   = s.store_id
WHERE i.stock_qty <= i.reorder_level * 1.5
ORDER BY
    CASE
        WHEN i.stock_qty = 0               THEN 1
        WHEN i.stock_qty < i.reorder_level THEN 2
        ELSE 3
    END,
    shortage_units DESC;


-- ============================================================
-- ANALYSIS 7: STORE PERFORMANCE COMPARISON
-- ============================================================
WITH store_metrics AS (
    SELECT
        s.store_id,
        s.store_name,
        s.region,
        s.target_revenue,
        COALESCE(SUM(CASE WHEN o.status='Completed' THEN o.total_amount END), 0)  AS actual_revenue,
        COUNT(DISTINCT CASE WHEN o.status='Completed' THEN o.order_id END)         AS completed_orders,
        COUNT(DISTINCT CASE WHEN o.status='Returned'  THEN o.order_id END)         AS returned_orders,
        COUNT(DISTINCT CASE WHEN o.status='Cancelled' THEN o.order_id END)         AS cancelled_orders,
        COUNT(DISTINCT o.customer_id)                                              AS unique_customers
    FROM stores s
    LEFT JOIN orders o ON s.store_id = o.store_id
    WHERE o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
       OR o.order_id IS NULL
    GROUP BY s.store_id, s.store_name, s.region, s.target_revenue
)
SELECT
    store_name,
    region,
    target_revenue,
    actual_revenue,
    ROUND(actual_revenue / NULLIF(target_revenue, 0) * 100, 1)        AS achievement_pct,
    completed_orders,
    returned_orders,
    cancelled_orders,
    unique_customers,
    ROUND(actual_revenue / NULLIF(completed_orders, 0), 2)             AS avg_order_value,
    RANK() OVER (ORDER BY actual_revenue DESC)                         AS performance_rank,
    CASE
        WHEN actual_revenue >= target_revenue       THEN 'Exceeding Target ✅'
        WHEN actual_revenue >= target_revenue * 0.8 THEN 'Near Target 🟡'
        ELSE 'Underperforming 🔴'
    END AS performance_label
FROM store_metrics
ORDER BY actual_revenue DESC;


-- ============================================================
-- ANALYSIS 8: CHANNEL PERFORMANCE (Online vs In-Store)
-- ============================================================
SELECT
    o.channel,
    YEAR(o.order_date)                                                  AS year,
    COUNT(order_id)                                                     AS total_orders,
    COUNT(CASE WHEN status='Completed' THEN 1 END)                      AS completed,
    ROUND(SUM(CASE WHEN status='Completed' THEN total_amount ELSE 0 END), 2) AS revenue,
    ROUND(AVG(CASE WHEN status='Completed' THEN total_amount END), 2)  AS avg_order_value,
    ROUND(COUNT(CASE WHEN status='Returned' THEN 1 END) /
          NULLIF(COUNT(order_id), 0) * 100, 2)                         AS return_rate_pct
FROM orders o
GROUP BY o.channel, YEAR(o.order_date)
ORDER BY year, channel;


-- ============================================================
-- ANALYSIS 9: CUSTOMER CHURN ANALYSIS
-- ============================================================
-- Customers who bought in 2022 or 2023 but NOT in 2024
WITH buyers_2023 AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE status = 'Completed'
      AND YEAR(order_date) IN (2022, 2023)
),
buyers_2024 AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE status = 'Completed'
      AND YEAR(order_date) = 2024
)
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.segment,
    c.city,
    MAX(o.order_date)                         AS last_purchase_date,
    DATEDIFF(CURDATE(), MAX(o.order_date))    AS days_inactive,
    COUNT(DISTINCT o.order_id)                AS historical_orders,
    ROUND(SUM(o.total_amount), 2)             AS historical_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IN (SELECT customer_id FROM buyers_2023)
  AND c.customer_id NOT IN (SELECT customer_id FROM buyers_2024)
  AND o.status = 'Completed'
GROUP BY c.customer_id, c.full_name, c.email, c.segment, c.city
ORDER BY historical_spend DESC;


-- ============================================================
-- ANALYSIS 10: EMPLOYEE PRODUCTIVITY (orders per employee)
-- ============================================================
SELECT
    s.store_name,
    e.full_name        AS employee_name,
    e.role,
    e.salary,
    COUNT(DISTINCT o.order_id)                   AS orders_on_floor,
    ROUND(SUM(o.total_amount), 2)                AS store_revenue,
    ROUND(SUM(o.total_amount) / e.salary, 2)     AS revenue_to_salary_ratio
FROM employees e
JOIN stores s ON e.store_id = s.store_id
JOIN orders o ON s.store_id = o.store_id AND o.status='Completed'
WHERE e.role = 'Manager'
GROUP BY s.store_name, e.employee_id, e.full_name, e.role, e.salary
ORDER BY revenue_to_salary_ratio DESC;
