-- ============================================================
-- RetailX Retail Sales & Customer Insights System
-- File: 04_insert_products.sql
-- Description: Products and inventory seed data
-- ============================================================

USE retailx_db;

-- -------------------------------------------------------
-- PRODUCTS (50 rows)
-- -------------------------------------------------------
INSERT INTO products (category_id, product_name, brand, sku, cost_price, selling_price) VALUES
-- Smartphones (cat 1)
(1, 'iPhone 15 Pro 256GB',         'Apple',   'APL-IP15P-256',  89000.00, 134900.00),
(1, 'iPhone 14 128GB',             'Apple',   'APL-IP14-128',   52000.00,  79900.00),
(1, 'Samsung Galaxy S24 Ultra',    'Samsung', 'SAM-S24U',       85000.00, 129999.00),
(1, 'Samsung Galaxy A54',          'Samsung', 'SAM-A54',        22000.00,  38999.00),
(1, 'OnePlus 12 5G',               'OnePlus', 'OP-12-5G',       48000.00,  64999.00),
(1, 'Xiaomi 14 Pro',               'Xiaomi',  'XMI-14P',        42000.00,  59999.00),
(1, 'Redmi Note 13 Pro',           'Xiaomi',  'XMI-RN13P',      16000.00,  24999.00),
(1, 'Vivo V30 Pro',                'Vivo',    'VVO-V30P',       28000.00,  44999.00),
-- Laptops (cat 2)
(2, 'Apple MacBook Air M2 256GB',  'Apple',   'APL-MBA-M2',     78000.00, 114900.00),
(2, 'Apple MacBook Pro M3 512GB',  'Apple',   'APL-MBP-M3',    110000.00, 169900.00),
(2, 'Dell XPS 15 i7',              'Dell',    'DL-XPS15-I7',    72000.00, 109999.00),
(2, 'HP Spectre x360 14',          'HP',      'HP-SPCX360-14',  65000.00,  99990.00),
(2, 'Lenovo ThinkPad X1 Carbon',   'Lenovo',  'LNV-X1C',        74000.00, 112000.00),
(2, 'Asus ROG Zephyrus G14',       'Asus',    'ASS-ROG-G14',    80000.00, 119990.00),
(2, 'Acer Aspire 5 i5',            'Acer',    'ACR-ASP5-I5',    32000.00,  49999.00),
(2, 'Lenovo IdeaPad Slim 5',       'Lenovo',  'LNV-IPS5',       28000.00,  44999.00),
-- TVs (cat 3)
(3, 'Samsung QLED 55" 4K',         'Samsung', 'SAM-TV55Q',      45000.00,  74990.00),
(3, 'LG OLED C3 65"',              'LG',      'LG-OLEDC3-65',   95000.00, 149990.00),
(3, 'Sony Bravia XR 55"',          'Sony',    'SNY-BRVXR55',    52000.00,  82990.00),
(3, 'Xiaomi Smart TV 5X 43"',      'Xiaomi',  'XMI-TV5X-43',    16000.00,  28999.00),
(3, 'OnePlus TV 50 Y1S Pro',       'OnePlus', 'OP-TV50Y1S',     18000.00,  31999.00),
-- Tablets (cat 4)
(4, 'Apple iPad Pro 12.9" M2',     'Apple',   'APL-IPDPRO-M2',  72000.00, 112900.00),
(4, 'Apple iPad Air 10.9"',        'Apple',   'APL-IPDAIR',     42000.00,  59900.00),
(4, 'Samsung Galaxy Tab S9',       'Samsung', 'SAM-TABS9',      55000.00,  82999.00),
(4, 'Xiaomi Pad 6',                'Xiaomi',  'XMI-PAD6',       20000.00,  34999.00),
-- Men Clothing (cat 5)
(5, 'Levi\'s 511 Slim Jeans',      'Levi\'s', 'LVS-511-SLM',    1800.00,   3999.00),
(5, 'Allen Solly Formal Shirt',    'Allen Solly','AS-FSHRT',     900.00,    1999.00),
(5, 'Nike Dri-FIT T-Shirt',        'Nike',    'NK-DRFT-TS',      700.00,    1499.00),
(5, 'Peter England Blazer',        'Peter England','PE-BLZ',     3500.00,   7999.00),
(5, 'H&M Casual Chinos',           'H&M',     'HM-CCH',          800.00,    1799.00),
-- Women Clothing (cat 6)
(6, 'W Anarkali Kurti',            'W',       'W-ANK-KRT',      1200.00,   2499.00),
(6, 'Zara Floral Maxi Dress',      'Zara',    'ZR-FLR-MXD',     2500.00,   5499.00),
(6, 'Biba Ethnic Set',             'Biba',    'BB-ETH-SET',     2200.00,   4999.00),
(6, 'H&M Formal Blazer Women',     'H&M',     'HM-FBL-W',       1800.00,   3999.00),
(6, 'Global Desi Palazzo Set',     'Global Desi','GD-PLZ',      1500.00,   3499.00),
-- Footwear (cat 7)
(7, 'Nike Air Max 270',            'Nike',    'NK-AM270',        5500.00,   9999.00),
(7, 'Adidas Ultraboost 23',        'Adidas',  'AD-UB23',         8000.00,  14999.00),
(7, 'Puma Softride Running Shoes', 'Puma',    'PM-SFRT',         2800.00,   5499.00),
(7, 'Bata Formal Oxford',          'Bata',    'BT-FMOX',         1200.00,   2499.00),
(7, 'Red Chief Leather Boots',     'Red Chief','RC-LBTX',        2500.00,   4999.00),
-- Kitchen (cat 8)
(8, 'Prestige Induction Cooktop',  'Prestige','PRE-INCT',        3000.00,   5499.00),
(8, 'Philips Air Fryer HD9252',    'Philips', 'PHL-AF9252',      4500.00,   7999.00),
(8, 'Bajaj Mixer Grinder 750W',    'Bajaj',   'BJ-MG750',        1800.00,   3299.00),
(8, 'Hawkins Pressure Cooker 5L',  'Hawkins', 'HWK-PC5L',         800.00,   1499.00),
(8, 'Borosil Glass Casserole Set', 'Borosil', 'BSL-GCSS',         600.00,   1199.00),
-- Furniture (cat 9)
(9, 'Godrej Interio Office Chair', 'Godrej',  'GDJ-OFCH',        8000.00,  14999.00),
(9, 'Nilkamal Plastic Chair Set',  'Nilkamal','NLK-PCHX4',       1200.00,   2799.00),
(9, 'Wakefit Orthopedic Mattress', 'Wakefit', 'WKF-ORTH-Q',     12000.00,  22999.00),
(9, 'Urban Ladder Bookshelf',      'Urban Ladder','UL-BKSHLF',   6000.00,  12499.00),
(9, 'Pepperfry Coffee Table',      'Pepperfry','PF-CFTBL',        4500.00,   8999.00);

-- -------------------------------------------------------
-- INVENTORY (products × stores = ~200 rows)
-- Realistic stock levels with shortages and stockouts
-- -------------------------------------------------------
INSERT INTO inventory (product_id, store_id, stock_qty, reorder_level) VALUES
-- iPhone 15 Pro
(1,1,42,10),(1,2,18,10),(1,3,25,10),(1,4,5,10),(1,5,120,20),
-- iPhone 14
(2,1,65,15),(2,2,30,15),(2,3,0,15),(2,4,12,15),(2,5,200,30),
-- Galaxy S24 Ultra
(3,1,30,10),(3,2,15,10),(3,3,8,10),(3,4,3,10),(3,5,90,20),
-- Galaxy A54
(4,1,80,20),(4,2,55,20),(4,3,40,20),(4,4,22,20),(4,5,300,50),
-- OnePlus 12
(5,1,35,10),(5,2,20,10),(5,3,12,10),(5,4,0,10),(5,5,150,25),
-- Xiaomi 14 Pro
(6,1,28,10),(6,2,14,10),(6,3,18,10),(6,4,7,10),(6,5,80,20),
-- Redmi Note 13 Pro
(7,1,120,30),(7,2,80,30),(7,3,60,30),(7,4,35,30),(7,5,500,80),
-- Vivo V30 Pro
(8,1,45,15),(8,2,25,15),(8,3,20,15),(8,4,8,15),(8,5,110,25),
-- MacBook Air M2
(9,1,22,8),(9,2,10,8),(9,3,15,8),(9,4,4,8),(9,5,60,15),
-- MacBook Pro M3
(10,1,12,5),(10,2,6,5),(10,3,8,5),(10,4,2,5),(10,5,35,10),
-- Dell XPS 15
(11,1,18,5),(11,2,9,5),(11,3,11,5),(11,4,3,5),(11,5,45,10),
-- HP Spectre
(12,1,14,5),(12,2,7,5),(12,3,9,5),(12,4,2,5),(12,5,40,10),
-- ThinkPad X1
(13,1,10,4),(13,2,5,4),(13,3,7,4),(13,4,1,4),(13,5,30,8),
-- Asus ROG G14
(14,1,16,5),(14,2,8,5),(14,3,10,5),(14,4,3,5),(14,5,50,10),
-- Acer Aspire 5
(15,1,55,15),(15,2,30,15),(15,3,35,15),(15,4,18,15),(15,5,180,30),
-- Lenovo IdeaPad
(16,1,60,15),(16,2,35,15),(16,3,40,15),(16,4,20,15),(16,5,200,35),
-- Samsung QLED 55
(17,1,25,8),(17,2,12,8),(17,3,15,8),(17,4,6,8),(17,5,70,15),
-- LG OLED C3 65
(18,1,8,3),(18,2,4,3),(18,3,5,3),(18,4,1,3),(18,5,20,5),
-- Sony Bravia XR
(19,1,15,5),(19,2,7,5),(19,3,9,5),(19,4,3,5),(19,5,40,10),
-- Xiaomi Smart TV
(20,1,70,20),(20,2,40,20),(20,3,50,20),(20,4,25,20),(20,5,250,50),
-- OnePlus TV
(21,1,50,15),(21,2,28,15),(21,3,35,15),(21,4,0,15),(21,5,180,35),
-- iPad Pro
(22,1,20,6),(22,2,10,6),(22,3,12,6),(22,4,4,6),(22,5,55,12),
-- iPad Air
(23,1,35,10),(23,2,18,10),(23,3,22,10),(23,4,8,10),(23,5,100,20),
-- Galaxy Tab S9
(24,1,25,8),(24,2,12,8),(24,3,15,8),(24,4,5,8),(24,5,70,15),
-- Xiaomi Pad 6
(25,1,55,15),(25,2,30,15),(25,3,35,15),(25,4,18,15),(25,5,200,40),
-- Levi's Jeans
(26,1,200,50),(26,2,150,50),(26,3,180,50),(26,4,90,50),(26,5,600,100),
-- Allen Solly Shirt
(27,1,250,60),(27,2,180,60),(27,3,200,60),(27,4,120,60),(27,5,800,120),
-- Nike T-Shirt
(28,1,300,80),(28,2,220,80),(28,3,250,80),(28,4,140,80),(28,5,1000,150),
-- Peter England Blazer
(29,1,80,20),(29,2,55,20),(29,3,65,20),(29,4,35,20),(29,5,250,50),
-- H&M Chinos
(30,1,180,50),(30,2,130,50),(30,3,150,50),(30,4,80,50),(30,5,550,100),
-- W Anarkali Kurti
(31,1,150,40),(31,2,110,40),(31,3,130,40),(31,4,70,40),(31,5,500,90),
-- Zara Maxi Dress
(32,1,90,25),(32,2,60,25),(32,3,75,25),(32,4,40,25),(32,5,300,60),
-- Biba Ethnic Set
(33,1,110,30),(33,2,80,30),(33,3,95,30),(33,4,55,30),(33,5,380,70),
-- H&M Blazer Women
(34,1,80,20),(34,2,55,20),(34,3,65,20),(34,4,35,20),(34,5,260,50),
-- Global Desi Palazzo
(35,1,120,35),(35,2,85,35),(35,3,100,35),(35,4,55,35),(35,5,420,80),
-- Nike Air Max
(36,1,60,15),(36,2,40,15),(36,3,50,15),(36,4,20,15),(36,5,200,40),
-- Adidas Ultraboost
(37,1,40,10),(37,2,25,10),(37,3,30,10),(37,4,12,10),(37,5,130,25),
-- Puma Softride
(38,1,90,25),(38,2,60,25),(38,3,75,25),(38,4,35,25),(38,5,300,60),
-- Bata Oxford
(39,1,150,40),(39,2,100,40),(39,3,120,40),(39,4,65,40),(39,5,500,90),
-- Red Chief Boots
(40,1,70,20),(40,2,45,20),(40,3,55,20),(40,4,28,20),(40,5,230,45),
-- Prestige Induction
(41,1,55,15),(41,2,35,15),(41,3,45,15),(41,4,20,15),(41,5,200,40),
-- Philips Air Fryer
(42,1,45,12),(42,2,28,12),(42,3,35,12),(42,4,15,12),(42,5,160,30),
-- Bajaj Mixer
(43,1,80,20),(43,2,55,20),(43,3,65,20),(43,4,30,20),(43,5,280,55),
-- Hawkins Cooker
(44,1,120,30),(44,2,80,30),(44,3,95,30),(44,4,50,30),(44,5,400,75),
-- Borosil Set
(45,1,100,25),(45,2,70,25),(45,3,85,25),(45,4,45,25),(45,5,350,65),
-- Godrej Chair
(46,1,30,8),(46,2,18,8),(46,3,22,8),(46,4,10,8),(46,5,100,20),
-- Nilkamal Chair
(47,1,60,15),(47,2,40,15),(47,3,50,15),(47,4,25,15),(47,5,200,40),
-- Wakefit Mattress
(48,1,25,6),(48,2,15,6),(48,3,18,6),(48,4,8,6),(48,5,80,15),
-- Urban Ladder Bookshelf
(49,1,20,5),(49,2,12,5),(49,3,15,5),(49,4,6,5),(49,5,60,12),
-- Pepperfry Coffee Table
(50,1,25,6),(50,2,15,6),(50,3,18,6),(50,4,8,6),(50,5,80,15);

-- Force some critical shortages for demo queries
UPDATE inventory SET stock_qty = 0  WHERE product_id = 2  AND store_id = 3; -- iPhone 14 stockout BLR
UPDATE inventory SET stock_qty = 2  WHERE product_id = 3  AND store_id = 4; -- S24 Ultra critical KOL
UPDATE inventory SET stock_qty = 0  WHERE product_id = 5  AND store_id = 4; -- OnePlus stockout KOL
UPDATE inventory SET stock_qty = 1  WHERE product_id = 10 AND store_id = 4; -- MBP M3 critical KOL
UPDATE inventory SET stock_qty = 0  WHERE product_id = 21 AND store_id = 4; -- OnePlus TV stockout KOL
UPDATE inventory SET stock_qty = 3  WHERE product_id = 18 AND store_id = 4; -- LG OLED critical KOL
