create database pizzahut;
use pizzahut;



-- Total number of orders-- 
SELECT COUNT(DISTINCT o.order_id) AS total_orders
FROM orders AS o;


-- Total revenue from pizza sales -- 

SELECT ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details AS od
JOIN pizzas AS p ON od.pizza_id = p.pizza_id;


-- Highest-priced pizza -- 
SELECT p.pizza_id, pt.name, p.size, p.price
FROM pizzas AS p
JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- Most common pizza size ordered -- 
SELECT p.size, COUNT(*) AS times_ordered
FROM order_details AS od
JOIN pizzas AS p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY times_ordered DESC
LIMIT 1;

-- Top 5 most ordered pizza types by quantity -- 

SELECT pt.name AS pizza_type, SUM(od.quantity) AS total_quantity
FROM order_details AS od
JOIN pizzas AS p       ON od.pizza_id = p.pizza_id
JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

-- Total quantity of each pizza category ordered -- 

SELECT pt.category, SUM(od.quantity) AS total_quantity
FROM order_details AS od
JOIN pizzas AS p       ON od.pizza_id = p.pizza_id
JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

-- Distribution of orders by hour of the day -- 
SELECT HOUR(CONCAT(o.date, ' ', o.time)) AS hour_of_day,
       COUNT(DISTINCT o.order_id)        AS orders_count
FROM orders AS o
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Category-wise distribution of pizzas (count of pizza types per category) -- 
 
SELECT pt.category, COUNT(DISTINCT pt.pizza_type_id) AS pizza_types_count
FROM pizza_types AS pt
GROUP BY pt.category
ORDER BY pizza_types_count DESC, pt.category;

-- Average number of pizzas ordered per day -- 

WITH per_order_qty AS (
  SELECT od.order_id, SUM(od.quantity) AS pizzas_in_order
  FROM order_details AS od
  GROUP BY od.order_id
),
per_day_qty AS (
  SELECT o.date, SUM(po.pizzas_in_order) AS pizzas_in_day
  FROM orders AS o
  JOIN per_order_qty AS po ON o.order_id = po.order_id
  GROUP BY o.date
)
SELECT ROUND(AVG(pizzas_in_day), 2) AS avg_pizzas_per_day
FROM per_day_qty;

-- Top 3 most ordered pizza types based on revenue --
SELECT pt.name AS pizza_type,
       ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details AS od
JOIN pizzas AS p       ON od.pizza_id = p.pizza_id
JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;
 
-- Percentage contribution of each pizza type to total revenue -- 

WITH type_revenue AS (
  SELECT pt.name AS pizza_type,
         SUM(od.quantity * p.price) AS revenue
  FROM order_details AS od
  JOIN pizzas AS p       ON od.pizza_id = p.pizza_id
  JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
  GROUP BY pt.name
),
total AS (
  SELECT SUM(revenue) AS total_rev FROM type_revenue
)
SELECT tr.pizza_type,
       ROUND(tr.revenue, 2) AS revenue,
       ROUND(tr.revenue / t.total_rev * 100, 2) AS pct_of_total
FROM type_revenue AS tr
CROSS JOIN total AS t
ORDER BY pct_of_total DESC;

-- Cumulative revenue over time (by date) -- 

WITH daily_rev AS (
  SELECT o.date,
         SUM(od.quantity * p.price) AS revenue
  FROM orders AS o
  JOIN order_details AS od ON o.order_id = od.order_id
  JOIN pizzas AS p         ON od.pizza_id = p.pizza_id
  GROUP BY o.date
)
SELECT date,
       ROUND(revenue, 2) AS daily_revenue,
       ROUND(SUM(revenue) OVER (ORDER BY date
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
         AS cumulative_revenue
FROM daily_rev
ORDER BY date;

-- Top 3 most ordered pizza types based on revenue for each category -- 

WITH type_cat_rev AS (
  SELECT pt.category,
         pt.name AS pizza_type,
         SUM(od.quantity * p.price) AS revenue
  FROM order_details AS od
  JOIN pizzas AS p       ON od.pizza_id = p.pizza_id
  JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
  GROUP BY pt.category, pt.name
),
ranked AS (
  SELECT category, pizza_type, revenue,
         DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM type_cat_rev
)
SELECT category, pizza_type, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, revenue DESC;











