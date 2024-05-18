# Time range between which the orders were placed.

SELECT *,
  DATE_DIFF(last_order_date, first_order_date, day) AS total_days
FROM
(
  SELECT
    MIN(extract(date from order_purchase_timestamp)) first_order_date,
    MAX(extract(date from order_purchase_timestamp)) last_order_date,
  FROM `target.orders`
)t;

-- We are analyzing the number of orders placed over a 773-day period, from September 4, 2016, to October 17, 2018. --



# Total no. of Cities & States of customers from where orders are coming.

SELECT
  COUNT(distinct customer_state) AS total_state,
  COUNT(distinct customer_city) AS total_city
FROM
  `target.customer`;



## Is there a growing trend in the no. of orders placed over the past years?

WITH yearly_orders AS (
  SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
    COUNT(*) AS order_count
  FROM
    `target.orders`
  GROUP BY
    EXTRACT(YEAR FROM order_purchase_timestamp)
)
SELECT
  order_year,
  order_count,
  ROUND(CASE WHEN LAG(order_count) OVER (ORDER BY order_year) IS NULL THEN NULL
       ELSE (order_count - LAG(order_count) OVER (ORDER BY order_year)) * 100.0 / LAG(order_count) OVER (ORDER BY order_year) END, 2) AS order_change_pct
FROM
  yearly_orders
ORDER BY
  order_year;



# Monthly seasonality in terms of the no. of orders being placed?

SELECT 
  FORMAT_DATE('%B', order_purchase_timestamp) AS month_name,
  COUNT(*) AS order_count
FROM `target.orders`
GROUP BY 
  month_name
ORDER BY
  order_count DESC;

-- Order volume shows seasonal peaks in August, May and July.



# During what time of the day, the customers mostly place their orders?

SELECT 
  (CASE 
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 7 and 12 THEN 'Morining'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 13 and 18 THEN 'Afternoon'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 19 and 23 THEN 'Evening'
    WHEN EXTRACT(hour from order_purchase_timestamp) BETWEEN 0 and 3 THEN 'Night'
   else 'Dawn' 
   end) AS order_time,
  count(*) AS order_count
FROM
  `target.orders`
GROUP BY 
  order_time
ORDER BY
  order_count desc;

-- Peak order times occur in the afternoon, between 1 PM and 6 PM. --



# Distribution of Customer across all the states.

SELECT 
  customer_state,
  COUNT(distinct customer_id) AS Cust_count
FROM `target.customer`
GROUP BY 
  customer_state
ORDER BY 
  Cust_count desc;

-- Most no. of customers are coming from state with code SP --



# Month on month no. of orders placed in each state. 

SELECT 
  customer_state,
  FORMAT_DATE('%B', order_purchase_timestamp) AS order_month,
  COUNT(*) AS order_count
FROM
  `target.customer` c 
JOIN 
  `target.orders` o 
USING 
  (customer_id)
GROUP BY 
  customer_state, 
  order_month
ORDER BY 
  customer_state, 
  order_month;



# Total & Average value of order price for each state.

SELECT 
  customer_state,
  ROUND(SUM(price)) AS total_order_value,
  ROUND(AVG(price)) AS avg_order_value
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
  ROUND(AVG(freight_value)) AS avg_fright_value
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
  avg_fright_value DESC;



# Top 5 states with the highest and lowest average freight value.

SELECT 
  H.customer_state AS highest_freight_state,
  H.avg_freight AS highest_avg_freight,
  L.customer_state AS lowest_freight_state,
  L.avg_freight AS lowest_avg_freight
FROM
  (SELECT
      customer_state,
      ROUND(AVG(freight_value), 2) AS avg_freight,
      RANK() OVER (ORDER BY AVG(freight_value) DESC) AS highest_rank
    FROM
      `target.customer` c
    JOIN
      `target.orders` o
    USING (customer_id)
    JOIN
    `target.order_items` oi
    USING (order_id)
    GROUP BY
      customer_state
    ORDER BY
      highest_rank asc
    LIMIT 5
    ) AS H
JOIN
  (
    SELECT
      customer_state,
      ROUND(AVG(freight_value), 2) AS avg_freight,
      DENSE_RANK() OVER (ORDER BY AVG(freight_value) ASC) AS lowest_rank
    FROM
      `target.customer` c
    JOIN
      `target.orders` o
    USING (customer_id)
    JOIN
      `target.order_items` oi
    USING 
      (order_id)
    GROUP BY
      customer_state
    ORDER BY
      lowest_rank asc
    LIMIT 5
    ) AS L
ON
  H.highest_rank= L.lowest_rank;



# Top 5 states with the highest and lowest average delivery time.

SELECT 
  H.customer_state AS high_time_state,
  H.avg_delivery_days AS high_avg_days,
  L.customer_state AS low_time_state,
  L.avg_delivery_days AS low_avg_days
FROM
  (SELECT
      customer_state,
      ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day)), 2) as avg_delivery_days,
      DENSE_RANK() OVER (ORDER BY ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day)), 2) DESC) AS highest_rank
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
      highest_rank asc
    LIMIT 5
    ) AS H
JOIN
  (
    SELECT
      customer_state,
      ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day)), 2) as avg_delivery_days,
      DENSE_RANK() OVER (ORDER BY ROUND(AVG(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, day)), 2) ASC) AS lowest_rank
    FROM
      `target.customer` c
    JOIN
      `target.orders` o
    USING (customer_id)
    JOIN
      `target.order_items` oi
    USING 
      (order_id)
    GROUP BY
      customer_state
    ORDER BY
      lowest_rank asc
    LIMIT 5
    ) AS L
ON
  H.highest_rank= L.lowest_rank;
 


# Top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

SELECT 
  H.customer_state AS fast_del_state,
  H.avg_delivery_days AS high_avg_days,
  L.customer_state AS slow_del_state,
  L.avg_delivery_days AS low_avg_days
FROM
  (SELECT
      customer_state,
      ROUND(AVG(timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date, day)), 2) as  avg_delivery_days,
      DENSE_RANK() OVER (ORDER BY ROUND(AVG(timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date, day)), 2) DESC) AS highest_rank
    FROM
      `target.customer` c
    JOIN
      `target.orders` o
    USING
      (customer_id)
    GROUP BY
      customer_state
    ORDER BY
      highest_rank asc
    LIMIT 5
    ) AS H
JOIN
  (
    SELECT
      customer_state,
      ROUND(AVG(timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date, day)), 2) as  avg_delivery_days,
      DENSE_RANK() OVER (ORDER BY ROUND(AVG(timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date, day)), 2) ASC) AS lowest_rank
    FROM
      `target.customer` c
    JOIN
      `target.orders` o
    USING 
      (customer_id)
    GROUP BY
      customer_state
    ORDER BY
      lowest_rank asc
    LIMIT 5
    ) AS L
ON
  H.highest_rank= L.lowest_rank;
 


# No. of days taken to deliver each order from the order’s purchase date and difference between the estimated & actual delivery date of an order.

SELECT 
  order_id,
  TIMESTAMP_DIFF(order_delivered_customer_date, order_purchase_timestamp, day) AS deliver_time , 
  TIMESTAMP_DIFF(order_estimated_delivery_date, order_delivered_customer_date, day) AS act_est_diff
FROM
  `target.orders`
GROUP BY 
  customer_state;


# Distribution of orders across different payment installment options.

SELECT 
  payment_installments,
  COUNT(*) AS order_count,
  ROUND(COUNT(*)/ (SELECT COUNT(*) FROM `target.payments`)* 100, 2) AS per_of_total
FROM
  `target.payments`  
GROUP BY 
  payment_installments
ORDER BY 
  payment_installments;

-- Over 50% of orders are placed using a single installment payment plan, indicating a customer preference for one-time payments.



# No. of orders placed using different payment types.

SELECT 
  payment_type,
  COUNT(*) as total_orders
FROM 
  `target.payments`
GROUP BY 
  payment_type;

-- Most preferred payment type is credit card for customers in Brazil.



# Month on month no. of orders placed using different payment types.

SELECT 
  payment_type,
  FORMAT_DATE('%B',order_purchase_timestamp) AS order_month,
  COUNT(*) AS mom_sales
FROM 
  `target.orders` o
JOIN
  `target.payments` p
USING
  (order_id)
GROUP BY 
  payment_type,
  order_month
ORDER BY
  payment_type;


# Percentage increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).

SELECT 
  T.order_year,
  FORMAT_DATE('%B', DATE(2017, order_month, 1)) as order_month,
  avg_payment,
  R.order_year,
  FORMAT_DATE('%B', DATE(2018, order_month, 1)) as order_month,
  next_avg_payment,
  ROUND(((next_avg_payment- avg_payment)/avg_payment) * 100, 2) AS per_change
FROM
  (
    SELECT 
      EXTRACT(YEAR FROM order_purchase_timestamp) as order_year,
      EXTRACT(month FROM order_purchase_timestamp) AS order_month,
      ROUND(AVG(payment_value)) as avg_payment
    FROM
      `target.orders` o
    JOIN
      `target.payments` p  
    USING
      (order_id)
    GROUP BY
      order_year, 
      order_month
    HAVING
      order_month BETWEEN 1 AND 8 AND
      order_year= 2017)T
JOIN 
  (
    SELECT 
      EXTRACT(YEAR FROM order_purchase_timestamp) as order_year,
      EXTRACT(month FROM order_purchase_timestamp) AS order_month,
      ROUND(AVG(payment_value)) as next_avg_payment
    FROM
      `target.orders` o
    JOIN
      `target.payments` p  
    USING
      (order_id)
    GROUP BY
      order_year, 
      order_month
    HAVING
      order_month BETWEEN 1 AND 8 AND
      order_year= 2018)R
USING 
    (order_month)
ORDER BY
  per_change desc;


