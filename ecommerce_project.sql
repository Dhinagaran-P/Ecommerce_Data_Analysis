CREATE DATABASE ecommerce;
USE ecommerce;

CREATE TABLE order_items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
);

CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(50),
    seller_state VARCHAR(2)
);

CREATE TABLE product_categories (
    product_category_name VARCHAR(50) PRIMARY KEY,
    product_category_name_english VARCHAR(50)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10, 8),
    geolocation_lng DECIMAL(11, 8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

SHOW VARIABLES LIKE 'secure_file_priv';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state);

ALTER TABLE geolocation
MODIFY COLUMN geolocation_lat DECIMAL(10, 8),
MODIFY COLUMN geolocation_lng DECIMAL(11, 8);
DROP TABLE payments;

CREATE TABLE payments (
    order_id VARCHAR(32) ,
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
); 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category.csv'
INTO TABLE product_categories
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @order_purchase_timestamp, @order_approved_at, @order_delivered_carrier_date, @order_delivered_customer_date, @order_estimated_delivery_date)
SET
    order_purchase_timestamp = STR_TO_DATE(@order_purchase_timestamp, '%d-%m-%y %H:%i'),
    order_approved_at = STR_TO_DATE(@order_approved_at, '%d-%m-%y %H:%i'),
    order_delivered_carrier_date = STR_TO_DATE(@order_delivered_carrier_date, '%d-%m-%y %H:%i'),
    order_delivered_customer_date = IF(@order_delivered_customer_date = '', NULL, STR_TO_DATE(@order_delivered_customer_date, '%d-%m-%y %H:%i'));


SELECT SUM(price) AS total_revenue FROM order_items;

SELECT COUNT(*) AS total_orders FROM orders;

SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM customers;

SELECT AVG(payment_value) AS avg_order_value FROM payments;

SELECT 
    product_id,
    COUNT(*) AS total_sales
FROM 
    order_items
GROUP BY 
    product_id
ORDER BY 
    total_sales DESC
LIMIT 10; 

SELECT 
    seller_id,
    COUNT(*) AS total_orders
FROM 
    order_items
GROUP BY 
    seller_id
ORDER BY 
    total_orders DESC
LIMIT 10; 

SELECT 
    product_category_name,
    COUNT(*) AS total_products
FROM 
    products
GROUP BY 
    product_category_name
ORDER BY 
    total_products DESC;

SELECT 
    AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_shipping_time
FROM 
    orders
WHERE 
    order_delivered_customer_date IS NOT NULL;

SELECT customer_state, COUNT(*) AS customer_count
FROM customers
GROUP BY customer_state
ORDER BY customer_count DESC;

SELECT 
    p.product_id,
    p.product_category_name,
    COUNT(*) AS total_sales
FROM 
    products p
JOIN 
    order_items oi ON p.product_id = oi.product_id
GROUP BY 
    p.product_id
ORDER BY 
    total_sales DESC
LIMIT 
    10;

SELECT 
    payment_type,
    COUNT(*) AS payment_count,
    SUM(payment_value) AS total_payment_amount
FROM 
    payments
GROUP BY 
    payment_type;

SELECT 
    order_status,
    COUNT(*) AS order_count
FROM 
    orders
GROUP BY 
    order_status;

SELECT 
    geolocation_state,
    COUNT(*) AS location_count
FROM 
    geolocation
GROUP BY 
    geolocation_state
ORDER BY 
    location_count DESC;

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    SUM(oi.price) AS total_sales
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    order_month
ORDER BY
    order_month desc;

SELECT
    g.geolocation_state,
    COUNT(DISTINCT c.customer_id) AS customer_count
FROM
    customers c
JOIN
    geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
GROUP BY
    g.geolocation_state
ORDER BY
    customer_count DESC;

SELECT
    pc.product_category_name,
    COUNT(oi.product_id) AS total_sales
FROM
    product_categories pc
LEFT JOIN
    products p ON pc.product_category_name = p.product_category_name
LEFT JOIN
    order_items oi ON p.product_id = oi.product_id
GROUP BY
    pc.product_category_name
ORDER BY
    total_sales DESC
LIMIT 10;

SELECT
    AVG(TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_approved_at)) AS avg_approval_time_hours
FROM
    orders o;
SELECT
    c.customer_state,
    AVG(oi.price) AS avg_order_value
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_state;

SELECT
    pc.product_category_name,
    AVG(pmt.payment_installments) AS avg_payment_installments
FROM
    product_categories pc
LEFT JOIN
    products p ON pc.product_category_name = p.product_category_name
LEFT JOIN
    order_items oi ON p.product_id = oi.product_id
LEFT JOIN
    payments pmt ON oi.order_id = pmt.order_id
GROUP BY
    pc.product_category_name
ORDER BY
    avg_payment_installments DESC;

SELECT
    c.customer_city,
    o.order_status,
    COUNT(o.order_id) AS order_count
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_city, o.order_status
ORDER BY
    c.customer_city, order_count DESC;

SELECT
    pc.product_category_name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM
    product_categories pc
LEFT JOIN
    products p ON pc.product_category_name = p.product_category_name
LEFT JOIN
    order_items oi ON p.product_id = oi.product_id
LEFT JOIN
    orders o ON oi.order_id = o.order_id
GROUP BY
    pc.product_category_name;

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS total_sales
FROM
    sellers s
LEFT JOIN
    order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN
    orders o ON oi.order_id = o.order_id
GROUP BY
    s.seller_id, s.seller_city, s.seller_state
ORDER BY
    total_sales DESC;

SELECT
    c.customer_id,
    SUM(oi.price) AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders,
    AVG(oi.price) AS avg_order_value
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_id
ORDER BY
    total_spent DESC;

SELECT
    c.customer_city,
    pc.product_category_name,
    COUNT(DISTINCT oi.order_id) AS order_count
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
JOIN
    products p ON oi.product_id = p.product_id
JOIN
    product_categories pc ON p.product_category_name = pc.product_category_name
GROUP BY
    c.customer_city, pc.product_category_name
ORDER BY
    order_count DESC;

SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS total_sales
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY
    year, month;

SELECT
    c.customer_state,
    AVG(oi.price) AS avg_order_value
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    avg_order_value DESC;

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(o.order_id) AS total_orders,
    SUM(oi.price) AS total_sales
FROM
    sellers s
LEFT JOIN
    order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN
    orders o ON oi.order_id = o.order_id
GROUP BY
    s.seller_id, s.seller_city, s.seller_state
ORDER BY
    total_sales DESC;

SELECT
    s.seller_state,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_approved_at)) AS avg_shipping_time
FROM
    sellers s
JOIN
    order_items oi ON s.seller_id = oi.seller_id
JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.order_delivered_customer_date IS NOT NULL
GROUP BY
    s.seller_state
ORDER BY
    avg_shipping_time ASC;

SELECT
    c.customer_id,
    COUNT(o.order_id) AS total_orders,
    SUM(oi.price) AS total_spent,
    AVG(oi.price) AS avg_order_value
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_id
ORDER BY
    total_spent DESC;

SELECT
    pc.product_category_name_english,
    COUNT(oi.order_item_id) AS total_items_sold,
    SUM(oi.price) AS total_revenue
FROM
    product_categories pc
JOIN
    products p ON pc.product_category_name = p.product_category_name
JOIN
    order_items oi ON p.product_id = oi.product_id
GROUP BY
    pc.product_category_name_english
ORDER BY
    total_revenue DESC;

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS total_spent
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_spent DESC;

SELECT
    DATE(o.order_approved_at) AS order_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT oi.order_item_id) AS total_items_sold,
    SUM(oi.price) AS total_revenue
FROM
    orders o
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    order_date
ORDER BY
    order_date;



















































