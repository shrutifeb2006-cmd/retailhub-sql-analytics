-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 02_create_indexes.sql
-- Description: Performance indexes for all major query patterns
-- ============================================================

USE retailx_db;

-- -------------------------------------------------------
-- ORDERS indexes
-- -------------------------------------------------------

-- Filter by date range (most common analytics pattern)
CREATE INDEX idx_orders_date
    ON orders (order_date);

-- Filter completed orders by date (covering for status filter)
CREATE INDEX idx_orders_date_status
    ON orders (order_date, status);

-- Customer order history lookup
CREATE INDEX idx_orders_customer
    ON orders (customer_id, status, order_date);

-- Store performance queries
CREATE INDEX idx_orders_store
    ON orders (store_id, status, order_date);

-- Channel analysis
CREATE INDEX idx_orders_channel
    ON orders (channel, status);

-- -------------------------------------------------------
-- ORDER ITEMS indexes
-- -------------------------------------------------------

-- Join from orders side
CREATE INDEX idx_items_order
    ON order_items (order_id, product_id);

-- Product sales analysis
CREATE INDEX idx_items_product
    ON order_items (product_id);

-- -------------------------------------------------------
-- PRODUCTS indexes
-- -------------------------------------------------------

-- Category browsing / filter
CREATE INDEX idx_products_category
    ON products (category_id, is_active);

-- Brand filter
CREATE INDEX idx_products_brand
    ON products (brand);

-- -------------------------------------------------------
-- CUSTOMERS indexes
-- -------------------------------------------------------

-- City / state segmentation queries
CREATE INDEX idx_customers_segment
    ON customers (segment);

CREATE INDEX idx_customers_city
    ON customers (city, segment);

-- Loyalty points analysis
CREATE INDEX idx_customers_loyalty
    ON customers (loyalty_pts DESC);

-- -------------------------------------------------------
-- INVENTORY indexes
-- -------------------------------------------------------

-- Shortage alert queries (stock_qty vs reorder_level)
CREATE INDEX idx_inventory_stock
    ON inventory (stock_qty, reorder_level);

-- Store inventory view
CREATE INDEX idx_inventory_store
    ON inventory (store_id, product_id);

-- -------------------------------------------------------
-- PAYMENTS indexes
-- -------------------------------------------------------

-- Payment method analysis
CREATE INDEX idx_payments_method
    ON payments (payment_method, status);

-- Failed payment investigation
CREATE INDEX idx_payments_status
    ON payments (status);

-- -------------------------------------------------------
-- EMPLOYEES indexes
-- -------------------------------------------------------

CREATE INDEX idx_employees_store
    ON employees (store_id, role);

-- -------------------------------------------------------
-- VERIFY all indexes
-- -------------------------------------------------------
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    NON_UNIQUE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'retailx_db'
  AND INDEX_NAME   != 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
