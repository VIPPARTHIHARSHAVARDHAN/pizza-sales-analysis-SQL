/* =========================================================
   PIZZA SALES ANALYSIS PROJECT
   Author: V. Harsha Vardhan
   Tool: MySQL
   ========================================================= */

/* =======================
   DATABASE CREATION
   ======================= */
CREATE DATABASE IF NOT EXISTS pizza_sales_db;
USE pizza_sales_db;

/* =======================
   TABLE CREATION
   ======================= */

-- Orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
);

-- Pizza types table
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50)
);

-- Pizzas table
CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50),
    size VARCHAR(10),
    price DECIMAL(5,2),
    FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id)
);

-- Order details table
CREATE TABLE order_details (
    order_details_id INT PRIMARY KEY,
    order_id INT,
    pizza_id VARCHAR(50),
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)
);

/* =========================================================
   DATA ANALYSIS QUERIES
   ========================================================= */

-- 1. Retrieve the total number of orders placed
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Calculate the total revenue generated from pizza sales
SELECT 
    SUM(order_details.quantity * pizzas.price) AS total_revenue
FROM order_details
JOIN pizzas 
    ON order_details.pizza_id = pizzas.pizza_id;

-- 3. Identify the highest-priced pizza
SELECT 
    pizza_types.name,
    pizzas.price
FROM pizzas
JOIN pizza_types 
    ON pizzas.pizza_type_id = pizza_types.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;

-- 4. Identify the most common pizza size ordered
SELECT 
    pizzas.size,
    COUNT(order_details.order_details_id) AS order_count
FROM pizzas
JOIN order_details 
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC
LIMIT 1;

-- 5. List the top 5 most ordered pizza types along with their quantities
SELECT 
    pizza_types.name,
    SUM(order_details.quantity) AS total_quantity
FROM pizza_types
JOIN pizzas 
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details 
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.name
ORDER BY total_quantity DESC
LIMIT 5;

-- 6. Find the total quantity of each pizza category ordered
SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS total_quantity
FROM pizza_types
JOIN pizzas 
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details 
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY total_quantity DESC;

-- 7. Determine the distribution of orders by hour of the day
SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY order_hour
ORDER BY order_hour;

-- 8. Category-wise distribution of pizzas
SELECT 
    category,
    COUNT(name) AS total_pizzas
FROM pizza_types
GROUP BY category;

-- 9. Calculate the average number of pizzas ordered per day
SELECT 
    AVG(daily_quantity) AS avg_pizzas_per_day
FROM (
    SELECT 
        orders.order_date,
        SUM(order_details.quantity) AS daily_quantity
    FROM orders
    JOIN order_details 
        ON orders.order_id = order_details.order_id
    GROUP BY orders.order_date
) AS daily_orders;

-- 10. Top 3 most ordered pizza types based on revenue
SELECT 
    pizza_types.name,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM pizza_types
JOIN pizzas 
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details 
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;

-- 11. Percentage contribution of each pizza category to total revenue
SELECT 
    pizza_types.category,
    ROUND(
        SUM(order_details.quantity * pizzas.price) * 100 /
        (SELECT SUM(order_details.quantity * pizzas.price)
         FROM order_details
         JOIN pizzas 
            ON order_details.pizza_id = pizzas.pizza_id), 2
    ) AS revenue_percentage
FROM pizza_types
JOIN pizzas 
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details 
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category;

-- 12. Analyze cumulative revenue generated over time
SELECT 
    order_date,
    SUM(daily_revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM (
    SELECT 
        orders.order_date,
        SUM(order_details.quantity * pizzas.price) AS daily_revenue
    FROM orders
    JOIN order_details 
        ON orders.order_id = order_details.order_id
    JOIN pizzas 
        ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY orders.order_date
) AS revenue_table;

-- 13. Top 3 pizza types by revenue for each category
SELECT 
    category,
    name,
    revenue
FROM (
    SELECT 
        pizza_types.category,
        pizza_types.name,
        SUM(order_details.quantity * pizzas.price) AS revenue,
        RANK() OVER (
            PARTITION BY pizza_types.category
            ORDER BY SUM(order_details.quantity * pizzas.price) DESC
        ) AS revenue_rank
    FROM pizza_types
    JOIN pizzas 
        ON pizza_types.pizza_type_id = pizzas.pizza_type_id
    JOIN order_details 
        ON pizzas.pizza_id = order_details.pizza_id
    GROUP BY pizza_types.category, pizza_types.name
) ranked_pizzas
WHERE revenue_rank <= 3;
