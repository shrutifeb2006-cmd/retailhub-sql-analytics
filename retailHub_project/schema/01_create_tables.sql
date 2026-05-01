-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 01_create_tables.sql
-- Description: Full 3NF normalized schema for MySQL 8.0
-- ============================================================

DROP DATABASE IF EXISTS retailx_db;
CREATE DATABASE retailx_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE retailx_db;

-- -------------------------------------------------------
-- 1. CATEGORIES
-- -------------------------------------------------------
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50)  NOT NULL UNIQUE,
    parent_cat    VARCHAR(50)  NULL,
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- 2. STORES
-- -------------------------------------------------------
CREATE TABLE stores (
    store_id       INT AUTO_INCREMENT PRIMARY KEY,
    store_name     VARCHAR(100) NOT NULL,
    city           VARCHAR(50)  NOT NULL,
    state          VARCHAR(50)  NOT NULL,
    region         ENUM('North','South','East','West','Online') NOT NULL,
    target_revenue DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    opened_date    DATE,
    is_active      TINYINT(1)   NOT NULL DEFAULT 1
);

-- -------------------------------------------------------
-- 3. EMPLOYEES
-- -------------------------------------------------------
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id    INT          NOT NULL,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE,
    role        ENUM('Manager','Sales','Support','Inventory') NOT NULL,
    hire_date   DATE,
    salary      DECIMAL(10,2) NOT NULL,
    is_active   TINYINT(1)    NOT NULL DEFAULT 1,
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- -------------------------------------------------------
-- 4. CUSTOMERS
-- -------------------------------------------------------
CREATE TABLE customers (
    customer_id  INT AUTO_INCREMENT PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(150) UNIQUE,
    phone        VARCHAR(15)  NULL,          -- nullable: some customers skip phone
    city         VARCHAR(50),
    state        VARCHAR(50),
    pincode      VARCHAR(10),
    segment      ENUM('Premium','Regular','New') NOT NULL DEFAULT 'New',
    loyalty_pts  INT          NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login   DATETIME     NULL
);

-- -------------------------------------------------------
-- 5. PRODUCTS
-- -------------------------------------------------------
CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    category_id   INT          NOT NULL,
    product_name  VARCHAR(150) NOT NULL,
    brand         VARCHAR(80),
    sku           VARCHAR(30)  UNIQUE NOT NULL,
    cost_price    DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_price CHECK (selling_price >= cost_price),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- -------------------------------------------------------
-- 6. ORDERS
-- -------------------------------------------------------
CREATE TABLE orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT          NULL,         -- nullable: walk-in / guest orders
    store_id      INT          NOT NULL,
    order_date    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        ENUM('Completed','Returned','Cancelled','Pending') NOT NULL DEFAULT 'Pending',
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    channel       ENUM('In-Store','Online') NOT NULL,
    notes         TEXT         NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (store_id)    REFERENCES stores(store_id)
);

-- -------------------------------------------------------
-- 7. ORDER ITEMS
-- -------------------------------------------------------
CREATE TABLE order_items (
    item_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT           NOT NULL,
    product_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount   DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    CONSTRAINT chk_qty      CHECK (quantity > 0),
    CONSTRAINT chk_discount CHECK (discount BETWEEN 0 AND 100),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- -------------------------------------------------------
-- 8. PAYMENTS
-- -------------------------------------------------------
CREATE TABLE payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    order_id       INT           NOT NULL UNIQUE,
    payment_method ENUM('UPI','Credit Card','Debit Card','COD','Net Banking') NOT NULL,
    amount         DECIMAL(12,2) NOT NULL,
    status         ENUM('Success','Failed','Refunded') NOT NULL DEFAULT 'Success',
    transaction_ref VARCHAR(60) NULL,
    paid_at        DATETIME NULL,            -- nullable: NULL when Failed
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- -------------------------------------------------------
-- 9. INVENTORY
-- -------------------------------------------------------
CREATE TABLE inventory (
    inventory_id  INT AUTO_INCREMENT PRIMARY KEY,
    product_id    INT NOT NULL,
    store_id      INT NOT NULL,
    stock_qty     INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 10,
    last_updated  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_product_store (product_id, store_id),
    CONSTRAINT chk_stock CHECK (stock_qty >= 0),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id)   REFERENCES stores(store_id)
);

-- -------------------------------------------------------
-- VERIFY
-- -------------------------------------------------------
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'retailx_db'
ORDER BY TABLE_NAME;
