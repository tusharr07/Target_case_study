# Time range between which the orders were placed.
SELECT *,
  DATE_DIFF(last_order_date, first_order_date, day) AS total_days
FROM
(
  SELECT
    min(extract(date from order_purchase_timestamp)) first_order_date,
    max(extract(date from order_purchase_timestamp)) last_order_date,
  FROM `target.orders`
)t;
--We're counting the number of orders placed within the timeframe from September 4, 2016, to October 17, 2018. This period spans 773 days


# Total no. of Cities & States of customers from where orders are coming during the given period.
SELECT
  COUNT(distinct customer_state) AS total_state,
  COUNT(distinct customer_city) AS total_city
FROM
  `target.customer`;


## Is there a growing trend in the no. of orders placed over the past years?

SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
  COUNT(order_id) AS total_orders 
FROM `target.orders`
GROUP BY
  EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY
  total_orders;
-- Number of orders are increasing year to year

#Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
SELECT 
  FORMAT_DATE('%B', order_purchase_timestamp) AS month_name,
  COUNT(*) AS order_count
FROM `target.orders`
GROUP BY 
  FORMAT_DATE('%B', order_purchase_timestamp)
ORDER BY
  order_count desc;

#During what time of the day, do the Brazilian customers mostly place their orders?
WITH cte as
(
 SELECT *, 
  CASE 
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 7 and 12 then 'Morining'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 13 and 18 then 'Afternoon'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 19 and 23 then 'Evening'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 0 and 3 then 'Night'
  else 'Dawn' 
  end as order_time
 FROM
  `target.orders`)
SELECT 
  order_time,
  count(*) as order_count
from cte
group by order_time
order by order_count desc;
-- The majority of orders are placed during the afternoon hours, specifically between 1 PM and 6 PM.

# How are the customers distributed across all the states?
SELECT 
  customer_state,
  count(*) as Cust_count
FROM `target.customer`
GROUP BY 
  customer_state
ORDER BY 
  Cust_count desc;

SELECT 
  geolocation_state,
  count(*) as Cust_count
from `target.geolocation`
GROUP BY geolocation_state
ORDER BY Cust_count desc;

# Total & Average value of order price for each state.
SELECT 
  customer_state,
  ROUND(SUM(price)) AS total_order_value,
  ROUND(AVG(price)) as avg_order_value
FROM 
  `target.customer` c
JOIN 
  `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state;

# Total & Average value of order freight for each state.
SELECT 
  customer_state,
  ROUND(SUM(freight_value)) AS total_fright_value,
  ROUND(AVG(freight_value)) as avg_fright_value
FROM 
  `target.customer` c
JOIN 
  `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state;

# Top 5 states with the highest average freight value.
SELECT 
  customer_state,
  ROUND(AVG(freight_value)) as avg_fright_value
FROM 
  `target.customer` c
JOIN
  `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state
ORDER BY 
  avg_fright_value desc
LIMIT 5;

SELECT * 
FROM
(SELECT 
  customer_state,
  ROUND(AVG(freight_value)) as avg_fright_value,
  DENSE_RANK() OVER(order by AVG(freight_value)) as rank
FROM 
  `target.customer` c
JOIN 
  `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state)T  
WHERE T.rank<=5;

# Top 5 states with the lowest average freight value.
SELECT 
  customer_state,
  ROUND(AVG(freight_value)) as avg_fright_value
FROM 
  `target.customer` c
JOIN 
  `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state
ORDER BY 
  avg_fright_value ASC
LIMIT 5;

# Top 5 states with the highest average delivery time.
SELECT
  customer_state,
  ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day))) as avg_delivery_days
FROM `target.customer` c
JOIN `target.orders` o 
USING (customer_id)
JOIN `target.order_items` oi 
USING (order_id)
GROUP BY customer_state
ORDER BY avg_delivery_days ASC;

# Top 5 states with the lowest average delivery time.
SELECT
  customer_state,
  ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day))) as avg_delivery_days
FROM 
  `target.customer` c
JOIN `target.orders` o 
USING 
  (customer_id)
JOIN 
  `target.order_items` oi 
USING 
  (order_id)
GROUP BY 
  customer_state
ORDER BY 
  avg_delivery_days desc
LIMIT 5;

# Top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
SELECT 
  customer_state,
  ROUND(AVG(timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date, day))) as avg_delivery_days
FROM 
  `target.customer` c 
JOIN 
  `target.orders` o 
USING 
  (customer_id)
GROUP BY 
  customer_state
ORDER BY 
  avg_delivery_days desc
limit 5;

# no. of days taken to deliver each order from the order’s purchase date as delivery time.
# Also, calculate the difference (in days) between the estimated & actual delivery date of an order.

SELECT 
  order_id,
  TIMESTAMP_DIFF(order_delivered_customer_date, order_purchase_timestamp, day) as deliver_time , 
  TIMESTAMP_DIFF(order_estimated_delivery_date, order_delivered_customer_date, day) as act_est_diff
from 
  `target.orders`;

# Find the no. of orders placed on the basis of the payment installments that have been paid.
SELECT 
  count(*) as order_count
FROM 
  `target.payments`
where 
  payment_value>0
LIMIT 1000

# Get the month on month no. of orders placed in each state.
SELECT 
  customer_state,
  FORMAT_DATE('%B', order_purchase_timestamp) AS order_month,
  COUNT(*) AS order_count
FROM
(
  SELECT 
    c.customer_state,
    o.order_purchase_timestamp
  FROM 
    `target.customer` c 
  JOIN 
    `target.orders` o 
  USING 
    (customer_id)
) T
GROUP BY 
  customer_state, order_month
ORDER BY 
  customer_state, order_month;

# Find the month on month no. of orders placed using different payment types.

SELECT 
  payment_type,
  order_month,
  count(*) AS mom_order_count
FROM
(
  SELECT 
    order_id,
    payment_type,
    FORMAT_DATE('%b', order_purchase_timestamp) as order_month
  FROM 
    `target.payments` p 
  JOIN 
    `target.orders` o  
  USING
    (order_id)
)T
GROUP BY 
  payment_type,
  order_month
ORDER BY
  payment_type,
  order_month,
  mom_order_count DESC

# Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
SELECT 
  distinct order_year,
  sum(payment_value) as year_order
FROM
(SELECT 
  order_id,
  (payment_value),
  EXTRACT(YEAR FROM order_purchase_timestamp) as order_year,
  order_purchase_timestamp,
  FORMAT_DATE('%B', order_purchase_timestamp) AS order_month
FROM
  `target.orders` o
JOIN
  `target.payments` p  
USING
  (order_id)
ORDER BY 
  order_month)T
WHERE
  T.order_month BETWEEN 'January' AND 'August'
GROUP BY 
  order_year

  select order_id
  from `target.orders`
  where 
    EXTRACT(month FROM order_purchase_timestamp) between 1 AND 8
















