--  ZEPTO PRODUCT DATA ANALYSIS  |  MySQL
--  Data Source : zepto_products.csv  (merged from zepto_v1.xlsx
--                                     + zepto_v2.csv, 3477 rows)
--  Sections    : 1) Schema  2) Load Data  3) Analysis Queries
-- DROP DATABASE IF EXISTS zepto_db;
CREATE DATABASE zepto_db;
USE zepto_db;

-- Categories lookup table
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE
);

-- Staging table – mirrors CSV columns exactly
CREATE TABLE products_raw (
    category_name          VARCHAR(100),
    name                   VARCHAR(200),
    mrp                    DECIMAL(10,2),
    discount_percent       DECIMAL(5,2),
    available_qty          INT,
    discounted_price       DECIMAL(10,2),
    weight_gms             DECIMAL(10,2),
    out_of_stock           VARCHAR(10),
    quantity               INT
);

-- Final normalised products table
CREATE TABLE products (
    product_id             INT AUTO_INCREMENT PRIMARY KEY,
    name                   VARCHAR(200) NOT NULL,
    category_id            INT NOT NULL,
    mrp                    DECIMAL(10,2) NOT NULL,
    discount_percent       DECIMAL(5,2)  DEFAULT 0,
    discounted_price       DECIMAL(10,2) NOT NULL,
    available_qty          INT           DEFAULT 0,
    weight_gms             DECIMAL(10,2),
    out_of_stock           TINYINT(1)    DEFAULT 0,   -- 0 = in stock, 1 = OOS
    quantity               INT           DEFAULT 1,
    savings_per_unit       DECIMAL(10,2) GENERATED ALWAYS AS
                               (mrp - discounted_price) STORED,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);


-- ─────────────────────────────────────────────────────────────
--  SECTION 2 : LOAD DATA FROM CSV
-- ─────────────────────────────────────────────────────────────

SET GLOBAL local_infile = 1;   -- Enable if using LOCAL keyword

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zepto_products.csv'

INTO TABLE products_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(category_name, name, mrp, discount_percent, available_qty,
 discounted_price, weight_gms, out_of_stock, quantity);

-- Populate categories from raw data
INSERT IGNORE INTO categories (name)
SELECT DISTINCT TRIM(category_name)
FROM products_raw
WHERE category_name IS NOT NULL AND category_name <> '';

-- Populate products (normalised)
INSERT INTO products
    (name, category_id, mrp, discount_percent, discounted_price,
     available_qty, weight_gms, out_of_stock, quantity)
SELECT
    TRIM(r.name),
    c.category_id,
    r.mrp,
    r.discount_percent,
    r.discounted_price,
    r.available_qty,
    r.weight_gms,
    CASE WHEN UPPER(r.out_of_stock) = 'TRUE' THEN 1 ELSE 0 END,
    r.quantity
FROM products_raw r
JOIN categories c ON c.name = TRIM(r.category_name)
WHERE r.name IS NOT NULL AND r.name <> '';

-- Clean up staging table
DROP TABLE products_raw;

-- Quick sanity check
SELECT 'Total products loaded' AS check_label, COUNT(*) AS value FROM products
UNION ALL
SELECT 'Total categories',                      COUNT(*)          FROM categories;


-- ─────────────────────────────────────────────────────────────
--  SECTION 3 : DATA ANALYSIS QUERIES  (15 queries)
-- ─────────────────────────────────────────────────────────────

-- ── Q1. Category-wise Product Count ─────────────────────────
-- How many products does each category have?
SELECT
    c.name                    AS category,
    COUNT(p.product_id)       AS total_products,
    SUM(p.out_of_stock = 0)   AS in_stock,
    SUM(p.out_of_stock = 1)   AS out_of_stock
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.name
ORDER BY total_products DESC;


-- ── Q2. Top 10 Most Discounted Products ─────────────────────
-- Which products offer the highest discount percentage?
SELECT
    name,
    category_id,
    mrp / 100            AS mrp_inr,
    discounted_price / 100 AS price_inr,
    discount_percent,
    savings_per_unit / 100 AS savings_inr
FROM products
WHERE out_of_stock = 0
ORDER BY discount_percent DESC
LIMIT 10;


-- ── Q3. Average Discount by Category ────────────────────────
-- Which category discounts its products the most on average?
SELECT
    c.name                            AS category,
    ROUND(AVG(p.discount_percent), 2) AS avg_discount_pct,
    ROUND(AVG(p.mrp) / 100, 2)       AS avg_mrp_inr,
    ROUND(AVG(p.discounted_price)/100,2) AS avg_selling_price_inr
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY avg_discount_pct DESC;


-- ── Q4. Out-of-Stock Rate by Category ───────────────────────
-- Which categories have the most out-of-stock products?
SELECT
    c.name                                           AS category,
    COUNT(*)                                         AS total,
    SUM(p.out_of_stock)                              AS oos_count,
    ROUND(100.0 * SUM(p.out_of_stock) / COUNT(*), 1) AS oos_pct
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY oos_pct DESC;


-- ── Q5. Price Range Buckets ──────────────────────────────────
-- How are products distributed across price tiers?
SELECT
    CASE
        WHEN discounted_price <  5000  THEN 'Budget     (< ₹50)'
        WHEN discounted_price < 20000  THEN 'Mid-Range  (₹50–₹200)'
        WHEN discounted_price < 50000  THEN 'Premium    (₹200–₹500)'
        ELSE                                'Luxury     (> ₹500)'
    END                        AS price_tier,
    COUNT(*)                   AS product_count,
    ROUND(AVG(discount_percent),1) AS avg_discount_pct
FROM products
GROUP BY price_tier
ORDER BY MIN(discounted_price);


-- ── Q6. Best Value Products (High Discount + In Stock) ──────
-- Top products offering the best deal right now.
SELECT
    p.name,
    c.name                    AS category,
    p.mrp / 100               AS mrp_inr,
    p.discounted_price / 100  AS price_inr,
    p.discount_percent,
    p.savings_per_unit / 100  AS savings_inr,
    p.available_qty
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.out_of_stock = 0
  AND p.discount_percent >= 30
ORDER BY p.savings_per_unit DESC
LIMIT 15;


-- ── Q7. Heaviest Products (Weight Analysis) ─────────────────
-- What are the heaviest items on Zepto?
SELECT
    name,
    category_id,
    ROUND(weight_gms / 1000, 2) AS weight_kg,
    discounted_price / 100      AS price_inr
FROM products
WHERE weight_gms IS NOT NULL
ORDER BY weight_gms DESC
LIMIT 10;


-- ── Q8. Price per Gram (Value for Money) ────────────────────
-- Which products offer the best price-per-gram ratio?
SELECT
    p.name,
    c.name                                                    AS category,
    p.discounted_price / 100                                  AS price_inr,
    p.weight_gms,
    ROUND((p.discounted_price / p.weight_gms) / 100, 4)       AS price_per_gram_inr
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.weight_gms > 0
  AND p.out_of_stock = 0
ORDER BY price_per_gram_inr ASC
LIMIT 10;


-- ── Q9. Total Potential Savings Across Platform ──────────────
-- How much can customers collectively save vs. MRP?
SELECT
    c.name                                     AS category,
    ROUND(SUM(p.mrp * p.available_qty)/100, 2) AS total_mrp_value,
    ROUND(SUM(p.discounted_price * p.available_qty)/100, 2) AS total_selling_value,
    ROUND(SUM(p.savings_per_unit * p.available_qty)/100, 2) AS total_potential_savings
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.out_of_stock = 0
GROUP BY c.category_id, c.name
ORDER BY total_potential_savings DESC;


-- ── Q10. Discount Distribution (Histogram buckets) ──────────
-- How spread out are discount percentages?
SELECT
    CONCAT(FLOOR(discount_percent / 10) * 10, '% – ',
           FLOOR(discount_percent / 10) * 10 + 9, '%') AS discount_bucket,
    COUNT(*)                                             AS product_count
FROM products
GROUP BY FLOOR(discount_percent / 10)
ORDER BY FLOOR(discount_percent / 10);


-- ── Q11. Categories with Zero Out-of-Stock Products ─────────
-- Fully stocked categories.
SELECT c.name AS category, COUNT(*) AS total_products
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.name
HAVING SUM(p.out_of_stock) = 0
ORDER BY total_products DESC;


-- ── Q12. Products with Discount > 50% ───────────────────────
-- Flash-sale level deals.
SELECT
    p.name,
    c.name              AS category,
    p.mrp / 100         AS mrp_inr,
    p.discounted_price / 100 AS price_inr,
    p.discount_percent
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.discount_percent > 50
ORDER BY p.discount_percent DESC;


-- ── Q13. Most Stocked Category ──────────────────────────────
-- Which category has the most inventory units available?
SELECT
    c.name               AS category,
    SUM(p.available_qty) AS total_units_available
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY total_units_available DESC;


-- ── Q14. Window: Rank Products by Discount Within Category ──
-- Top 3 discounted products per category using RANK().
SELECT *
FROM (
    SELECT
        c.name                                                   AS category,
        p.name                                                   AS product,
        p.discount_percent,
        p.discounted_price / 100                                 AS price_inr,
        RANK() OVER (PARTITION BY p.category_id
                     ORDER BY p.discount_percent DESC)           AS rnk
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    WHERE p.out_of_stock = 0
) ranked
WHERE rnk <= 3
ORDER BY category, rnk;


-- ── Q15. Summary Dashboard ──────────────────────────────────
-- A single-query executive summary of the entire catalogue.
SELECT
    (SELECT COUNT(*)                   FROM products)                    AS total_products,
    (SELECT COUNT(*)                   FROM categories)                  AS total_categories,
    (SELECT COUNT(*)                   FROM products WHERE out_of_stock=0) AS in_stock_products,
    (SELECT ROUND(AVG(discount_percent),2) FROM products)                AS avg_discount_pct,
    (SELECT ROUND(MAX(discount_percent),2) FROM products)                AS max_discount_pct,
    (SELECT ROUND(AVG(mrp)/100, 2)     FROM products)                    AS avg_mrp_inr,
    (SELECT ROUND(MIN(discounted_price)/100, 2) FROM products
     WHERE out_of_stock=0)                                               AS cheapest_product_inr,
    (SELECT ROUND(MAX(discounted_price)/100, 2) FROM products)          AS most_expensive_inr;


-- ─────────────────────────────────────────────────────────────
--  END OF PROJECT
-- ─────────────────────────────────────────────────────────────
