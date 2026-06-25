## PHASE 1 :-

#DATABASE CREATION

CREATE DATABASE retail_sales_db;
USE retail_sales_db; 

# TABLES CREATION 

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

# SAMPLE DATA INSERTION

INSERT INTO customers (customer_name, gender, age, city)
VALUES
('Rahul Sharma','Male',24,'Delhi'),
('Priya Patel','Female',22,'Mumbai'),
('Aman Verma','Male',28,'Indore'),
('Sneha Gupta','Female',25,'Pune'),
('Rohit Singh','Male',30,'Bhopal');

INSERT INTO products (product_name, category, price)
VALUES
('Laptop','Electronics',60000),
('Mobile','Electronics',25000),
('Headphones','Accessories',2000),
('Keyboard','Accessories',1500),
('Smart Watch','Electronics',5000);

INSERT INTO orders (customer_id, order_date)
VALUES
(1,'2025-01-10'),
(2,'2025-01-12'),
(3,'2025-01-15'),
(1,'2025-02-01'),
(5,'2025-02-05');

INSERT INTO order_items (order_id, product_id, quantity)
VALUES
(1,1,1),
(1,3,2),
(2,2,1),
(3,4,3),
(4,5,1),
(5,2,2);


##PHASE 2 (Analysis Queries) :-

-- business oveview 

#Total Revenue
SELECT
SUM(p.price * oi.quantity) AS total_revenue
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id;

#Total Orders 
SELECT COUNT(*) AS total_orders
FROM orders;

#Total Customers
SELECT COUNT(*) AS total_customers
FROM customers;

#Avg Order Value 
SELECT
AVG(order_total) AS average_order_value
FROM
(
    SELECT
    o.order_id,
    SUM(p.price * oi.quantity) AS order_total
    FROM orders o
    JOIN order_items oi
    ON o.order_id = oi.order_id
    JOIN products p
    ON oi.product_id = p.product_id
    GROUP BY o.order_id
) t;

-- product analysis 

#Top Selling Products
SELECT
p.product_name,
SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC;

#Revenue By Product
SELECT
p.product_name,
SUM(p.price * oi.quantity) AS revenue
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

#Revenue By Category
SELECT
p.category,
SUM(p.price * oi.quantity) AS revenue
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category;

-- customer analysis

#Top Customers
SELECT
c.customer_name,
SUM(p.price * oi.quantity) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY c.customer_name
ORDER BY total_spent DESC;

# top 3 customers 
SELECT *
FROM
(
    SELECT
        c.customer_name,
        SUM(p.price * oi.quantity) AS total_spent,
        DENSE_RANK() OVER(
            ORDER BY SUM(p.price * oi.quantity) DESC
        ) AS ranking
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY c.customer_name
) x
WHERE ranking <= 3;

#Customer Order Count
SELECT
c.customer_name,
COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_orders DESC;

#Repeat Customer
SELECT
customer_id,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1;

-- time analysis

#Monthly Sales
SELECT
MONTH(order_date) AS month_no,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY MONTH(order_date);

#Monthly Revenue 
SELECT
MONTH(o.order_date) AS month_no,
SUM(p.price * oi.quantity) AS revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY MONTH(o.order_date);

-- windows function

#Customer Ranking 
SELECT
customer_name,
total_spent,
RANK() OVER(ORDER BY total_spent DESC) AS customer_rank
FROM
(
    SELECT
    c.customer_name,
    SUM(p.price * oi.quantity) AS total_spent
    FROM customers c
    JOIN orders o
    ON c.customer_id = o.customer_id
    JOIN order_items oi
    ON o.order_id = oi.order_id
    JOIN products p
    ON oi.product_id = p.product_id
    GROUP BY c.customer_name
) x;

#Product Ranking 
SELECT
product_name,
revenue,
DENSE_RANK() OVER(ORDER BY revenue DESC) AS rank_no
FROM
(
    SELECT
    p.product_name,
    SUM(p.price * oi.quantity) AS revenue
    FROM products p
    JOIN order_items oi
    ON p.product_id = oi.product_id
    GROUP BY p.product_name
) t;

-- CTE (common table expressions)

WITH customer_sales AS
(
SELECT
c.customer_name,
SUM(p.price * oi.quantity) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY c.customer_name
)

SELECT *
FROM customer_sales
WHERE total_spent > 50000;

-- customer spending view 
CREATE VIEW customer_spending AS
SELECT
    c.customer_id,
    c.customer_name,
    SUM(p.price * oi.quantity) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name;

SELECT * FROM customer_spending;

-- Product Revenue View
CREATE VIEW product_revenue AS
SELECT
    p.product_name,
    SUM(p.price * oi.quantity) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_name;

SELECT * FROM product_revenue;

-- indexing

CREATE INDEX idx_customer
ON orders(customer_id);

CREATE INDEX idx_product
ON order_items(product_id);

-- stored procedure 
DELIMITER //

CREATE PROCEDURE GetCategoryRevenue()
BEGIN

SELECT
    p.category,
    SUM(p.price * oi.quantity) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category;

END //

DELIMITER ;

CALL GetCategoryRevenue();

# best performance city
SELECT
c.city,
SUM(p.price * oi.quantity) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.city
ORDER BY revenue DESC;

#highest revenue month 
SELECT
MONTH(o.order_date) AS month_no,
SUM(p.price * oi.quantity) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY MONTH(o.order_date)
ORDER BY revenue DESC;

#most popular category
SELECT
category,
COUNT(*) AS sales_count
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY category
ORDER BY sales_count DESC;

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;


SELECT * FROM customers LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;

SELECT
c.customer_name,
SUM(p.price * oi.quantity) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

SELECT
p.product_name,
SUM(oi.quantity) AS units_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 10;

SELECT
p.category,
SUM(p.price * oi.quantity) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

SELECT
c.city,
SUM(p.price * oi.quantity) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 10;


