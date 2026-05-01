-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 09_optimization_and_views.sql
-- Description: EXPLAIN analysis, query optimization,
--              and BI layer views
-- ============================================================

USE retailx_db;

-- ============================================================
-- SECTION 1: EXPLAIN ANALYSIS
-- Run these BEFORE adding indexes to see baseline performance
-- ============================================================

-- 1.1 Baseline — Top customer revenue (no composite index yet)
EXPLAIN SELECT
    c.customer_id,
    c.full_name,
    SUM(o.total_amount) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status     = 'Completed'
  AND o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.full_name
ORDER BY revenue DESC
LIMIT 10;

-- 1.2 Baseline — Inventory shortage lookup
EXPLAIN SELECT
    p.product_name,
    i.stock_qty,
    i.reorder_level
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_qty <= i.reorder_level;

-- 1.3 After running 02_create_indexes.sql, run again and compare:
-- Expected improvement:
--   type: ALL → ref/range
--   rows: 500 → ~12
--   Extra: Using filesort → Using index

-- ============================================================
-- SECTION 2: OPTIMIZED QUERY PATTERNS
-- ============================================================

-- 2.1 BAD: Correlated subquery (runs once per row)
-- SELECT *, (SELECT SUM(total_amount) FROM orders o2 WHERE o2.customer_id = c.customer_id) FROM customers c;

-- 2.2 GOOD: Derived table / JOIN instead
SELECT
    c.customer_id,
    c.full_name,
    COALESCE(agg.total_revenue, 0) AS total_revenue,
    COALESCE(agg.order_count,   0) AS order_count
FROM customers c
LEFT JOIN (
    SELECT customer_id, SUM(total_amount) AS total_revenue, COUNT(*) AS order_count
    FROM orders WHERE status = 'Completed'
    GROUP BY customer_id
) agg ON c.customer_id = agg.customer_id
ORDER BY total_revenue DESC;

-- 2.3 GOOD: Use covering index — select only indexed columns
SELECT order_id, customer_id, status, order_date
FROM orders
WHERE customer_id = 1
  AND status      = 'Completed'
ORDER BY order_date DESC;

-- 2.4 AVOID: Functions on indexed columns break index usage
-- BAD:  WHERE YEAR(order_date) = 2024         ← index not used
-- GOOD: WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'

SELECT order_id, order_date, total_amount
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
  AND status = 'Completed';

-- 2.5 Use LIMIT for pagination instead of loading all rows
SELECT
    o.order_id,
    c.full_name,
    o.order_date,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Completed'
ORDER BY o.order_date DESC
LIMIT 20 OFFSET 0;   -- page 1; change OFFSET to paginate


-- ============================================================
-- SECTION 3: BI VIEWS
-- ============================================================

-- 3.1 Master sales fact view (used for all BI dashboards)
CREATE OR REPLACE VIEW v_sales_fact AS
SELECT
    o.order_id,
    DATE(o.order_date)                    AS order_date,
    YEAR(o.order_date)                    AS year,
    MONTH(o.order_date)                   AS month,
    QUARTER(o.order_date)                 AS quarter,
    DATE_FORMAT(o.order_date, '%Y-%m')    AS year_month,
    DAYNAME(o.order_date)                 AS day_of_week,
    -- customer
    c.customer_id,
    c.full_name                           AS customer_name,
    c.city                                AS customer_city,
    c.state                               AS customer_state,
    c.segment                             AS customer_segment,
    c.loyalty_pts,
    -- store
    s.store_id,
    s.store_name,
    s.city                                AS store_city,
    s.region,
    s.target_revenue,
    -- product
    p.product_id,
    p.product_name,
    p.brand,
    p.cost_price,
    p.selling_price,
    cat.category_name,
    -- order item
    oi.quantity,
    oi.unit_price,
    oi.discount,
    ROUND(oi.quantity * oi.unit_price, 2)                             AS gross_amount,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount/100), 2)    AS net_amount,
    ROUND(oi.quantity * (oi.unit_price - p.cost_price), 2)           AS gross_profit,
    -- order meta
    o.channel,
    o.status                              AS order_status,
    -- payment
    pay.payment_method,
    pay.status                            AS payment_status
FROM orders o
JOIN customers   c   ON o.customer_id   = c.customer_id
JOIN stores      s   ON o.store_id      = s.store_id
JOIN order_items oi  ON o.order_id      = oi.order_id
JOIN products    p   ON oi.product_id   = p.product_id
JOIN categories  cat ON p.category_id   = cat.category_id
LEFT JOIN payments pay ON o.order_id    = pay.order_id;

-- 3.2 Inventory status view
CREATE OR REPLACE VIEW v_inventory_status AS
SELECT
    i.inventory_id,
    p.product_id,
    p.product_name,
    p.brand,
    cat.category_name,
    p.selling_price,
    s.store_id,
    s.store_name,
    s.region,
    i.stock_qty,
    i.reorder_level,
    GREATEST(0, i.reorder_level - i.stock_qty) AS shortage_units,
    ROUND(i.stock_qty * p.cost_price, 2)        AS inventory_value,
    i.last_updated,
    CASE
        WHEN i.stock_qty = 0                     THEN 'Stockout'
        WHEN i.stock_qty < i.reorder_level       THEN 'Critical'
        WHEN i.stock_qty < i.reorder_level * 1.5 THEN 'Low'
        WHEN i.stock_qty > i.reorder_level * 5   THEN 'Overstocked'
        ELSE 'Healthy'
    END AS stock_status
FROM inventory i
JOIN products   p   ON i.product_id  = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
JOIN stores     s   ON i.store_id    = s.store_id;

-- 3.3 Customer 360 view
CREATE OR REPLACE VIEW v_customer_360 AS
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.city,
    c.state,
    c.segment,
    c.loyalty_pts,
    c.created_at,
    COUNT(DISTINCT o.order_id)                    AS total_orders,
    COUNT(DISTINCT CASE WHEN o.status='Completed' THEN o.order_id END) AS completed_orders,
    COUNT(DISTINCT CASE WHEN o.status='Returned'  THEN o.order_id END) AS returned_orders,
    ROUND(SUM(CASE WHEN o.status='Completed' THEN o.total_amount ELSE 0 END), 2) AS lifetime_value,
    ROUND(AVG(CASE WHEN o.status='Completed' THEN o.total_amount END), 2)        AS avg_order_value,
    MIN(o.order_date)                             AS first_purchase,
    MAX(o.order_date)                             AS last_purchase,
    DATEDIFF(CURDATE(), MAX(o.order_date))        AS days_since_last_purchase,
    MAX(pay.payment_method)                       AS preferred_payment
FROM customers c
LEFT JOIN orders   o   ON c.customer_id = o.customer_id
LEFT JOIN payments pay ON o.order_id    = pay.order_id AND pay.status = 'Success'
GROUP BY c.customer_id, c.full_name, c.email, c.city, c.state,
         c.segment, c.loyalty_pts, c.created_at;

-- 3.4 Monthly KPI summary view
CREATE OR REPLACE VIEW v_monthly_kpi AS
SELECT
    DATE_FORMAT(order_date, '%Y-%m')                               AS month,
    YEAR(order_date)                                               AS year,
    MONTH(order_date)                                              AS month_num,
    COUNT(order_id)                                                AS total_orders,
    COUNT(CASE WHEN status='Completed'  THEN 1 END)                AS completed_orders,
    COUNT(CASE WHEN status='Returned'   THEN 1 END)                AS returned_orders,
    COUNT(CASE WHEN status='Cancelled'  THEN 1 END)                AS cancelled_orders,
    COUNT(DISTINCT customer_id)                                    AS unique_customers,
    ROUND(SUM(CASE WHEN status='Completed' THEN total_amount ELSE 0 END), 2) AS gross_revenue,
    ROUND(AVG(CASE WHEN status='Completed' THEN total_amount END), 2)        AS avg_order_value,
    ROUND(COUNT(CASE WHEN status='Returned'  THEN 1 END) /
          NULLIF(COUNT(order_id), 0) * 100, 2)                     AS return_rate_pct,
    ROUND(COUNT(CASE WHEN status='Cancelled' THEN 1 END) /
          NULLIF(COUNT(order_id), 0) * 100, 2)                     AS cancellation_rate_pct
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m'), YEAR(order_date), MONTH(order_date);


-- ============================================================
-- SECTION 4: PERFORMANCE TIPS (commented reference)
-- ============================================================
/*
CHECKLIST — Before going to production:

1. Run EXPLAIN on every query used by dashboards
   - Aim for type = ref or range, NOT ALL
   - Check Extra column: avoid "Using filesort", "Using temporary"

2. Index guidelines:
   - WHERE columns: index single or composite
   - JOIN columns: always indexed (FKs are auto-indexed in InnoDB)
   - ORDER BY columns: add to end of composite index
   - Avoid indexing low-cardinality columns (e.g., status ENUM)

3. Query rewrites:
   - Replace correlated subqueries with JOINs or CTEs
   - Use UNION ALL instead of UNION when duplicates are OK
   - Use EXISTS instead of IN for large subqueries

4. Schema tips:
   - Keep VARCHAR lengths tight
   - Use TINYINT(1) for boolean flags
   - Archive orders older than 3 years to a separate table
   - Consider partitioning orders by YEAR(order_date) at 1M+ rows

5. Connection pooling:
   - Use connection pool (e.g., PgBouncer equivalent for MySQL)
   - Separate read replica for BI/reporting queries

EXAMPLE EXPLAIN OUTPUT — before and after index:
  Before: type=ALL,  key=NULL,          rows=485, Extra=Using filesort
  After:  type=ref,  key=idx_orders_customer, rows=8,   Extra=Using index
  Improvement: ~60x fewer rows scanned
*/
