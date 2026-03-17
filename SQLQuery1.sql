
USE [Danny's Dinner];
ALTER AUTHORIZATION ON DATABASE::[Danny's Dinner] TO [sa];



SELECT *
FROM members

SELECT *
FROM menu

SELECT *
FROM sales

                                                                   -- Database Initialization

INSERT INTO members (customer_id, join_date)
VALUES ('C', '2021-01-11');

ALTER TABLE members
ALTER COLUMN customer_id VARCHAR(1) NOT NULL

ALTER TABLE members
ADD CONSTRAINT PK_members PRIMARY KEY (customer_id);


ALTER TABLE menu
ALTER COLUMN product_id INT NOT NULL


ALTER TABLE menu
ADD CONSTRAINT PK_menu PRIMARY KEY (product_id)

ALTER TABLE sales
ADD Order_id INT IDENTITY(1,1) PRIMARY KEY 


                                                                        -- Case Study Questions :


-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
		M.customer_id,
		COUNT(S.product_id) AS Amount
FROM members AS m
INNER JOIN sales AS s
	ON M.customer_id=S.customer_id
GROUP BY M.customer_id


-- 2. How many days has each customer visited the restaurant?

SELECT 
		M.customer_id,
		COUNT ( DISTINCT S.order_date) AS Amount
FROM members AS m
INNER JOIN sales AS s
	ON M.customer_id=S.customer_id
GROUP BY M.customer_id


--3. What was the first item from the menu purchased by each customer?


WITH product_rank AS (

SELECT
		M.customer_id AS customer,
		P.product_name AS product_name,
		RANK() OVER (PARTITION BY M.customer_id ORDER BY S.product_id )AS product_rank
FROM members AS M
INNER JOIN sales AS S
	ON M.customer_id=S.customer_id
INNER  JOIN menu AS P
	ON S.product_id=P.product_id

)
SELECT 
		DISTINCT customer,
		product_name
FROM product_rank 
WHERE product_rank=1


-- 4. What is the most purchased item on the menu and how many times was it been purchased by all customers?


SELECT 
    P.product_name,
    COUNT(S.product_id) AS total_purchases
FROM sales AS S
INNER JOIN menu AS P
    ON S.product_id = P.product_id
GROUP BY P.product_name
ORDER  BY total_purchases DESC;


-- 5.Which item was the most popular for each customer?

WITH customer_item_count AS (
    SELECT
        S.customer_id,
        P.product_name,
        COUNT(*) AS purchase_count,
        RANK() OVER ( PARTITION BY S.customer_id ORDER BY COUNT(*) DESC ) AS rnk
    FROM sales AS S
    INNER JOIN menu AS P
        ON S.product_id = P.product_id
    GROUP BY S.customer_id, P.product_name
)
SELECT
    customer_id,
    product_name,
    purchase_count
FROM customer_item_count
WHERE rnk = 1;


-- 6. Which item was purchased first by the customer after they became a member?


WITH FIRST_ITEM AS (
SELECT 
        M.customer_id AS customer_id ,
        P.product_name AS product_name,
        RANK() OVER (PARTITION BY M.customer_id ORDER BY S.product_id ) AS first_item
FROM sales AS S
INNER JOIN members AS M
    ON S.customer_id=M.customer_id AND M.join_date <=S.order_date
INNER JOIN menu AS P
    ON S.product_id=P.product_id

)
SELECT 
        customer_id,
        product_name,
        first_item
FROM FIRST_ITEM
WHERE first_item=1


-- 7. Which item was purchased just before the customer became a member?

SELECT 
        M.customer_id AS customer_id ,
        P.product_name AS product_name
FROM sales AS S
INNER JOIN members AS M
    ON S.customer_id=M.customer_id AND M.join_date > S.order_date
INNER JOIN menu AS P
    ON S.product_id=P.product_id


-- 8. What is the total items and amount spent on each member before they became a member?

SELECT 
        M.customer_id AS customer_id ,
       COUNT(S.product_id  )  AS total_items ,
        SUM (P.price ) AS total_amount_spent
FROM sales AS S
INNER JOIN members AS M
    ON S.customer_id=M.customer_id AND M.join_date > S.order_date
INNER JOIN menu AS P
    ON S.product_id=P.product_id
GROUP BY M.customer_id
ORDER BY total_amount_spent DESC


-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
       S.customer_id ,
        SUM (
                CASE 
                WHEN P.product_name='sushi'THEN P.price*10*2
                ELSE P.price*10
                END ) AS total_points
FROM sales AS S
INNER JOIN menu AS P
    ON S.product_id=P.product_id
GROUP BY S.customer_id
ORDER BY  total_points DESC

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


SELECT
    S.customer_id,
    SUM(
        CASE
            WHEN S.order_date BETWEEN M.join_date AND DATEADD(DAY, 6, M.join_date)
                THEN P.price * 10 * 2
            WHEN P.product_name = 'sushi'
                THEN P.price * 10 * 2
            ELSE P.price * 10
        END
    ) AS total_points
FROM sales AS S
INNER JOIN menu AS P
    ON S.product_id = P.product_id
INNER JOIN members AS M
    ON S.customer_id = M.customer_id
WHERE S.order_date <= '2021-01-31'
  AND S.customer_id IN ('A', 'B')
GROUP BY S.customer_id;


                                                                   -- Bonus Questions
-- Join All the Things :

SELECT 
    S.customer_id,
    S.order_date,
    P.product_name,
    P.price,
    CASE
    WHEN M.customer_id IS NOT NULL AND M.join_date <=S.order_date THEN 'Y'
    ELSE 'N'
    END AS member_status
FROM sales AS S
INNER JOIN menu AS P
    ON S.product_id=P.product_id
LEFT JOIN members AS M
    ON S.customer_id=M.customer_id
ORDER BY
    S.customer_id,
    S.order_date;


-- Rank All the Things


WITH base_table AS (
    SELECT
        S.customer_id,
        S.order_date,
        P.product_name,
        P.price,
        CASE 
            WHEN M.customer_id IS NOT NULL AND S.order_date >= M.join_date THEN 'Y'
            ELSE 'N'
        END AS member_status
    FROM sales AS S
    INNER JOIN menu AS P
        ON S.product_id = P.product_id
    LEFT JOIN members AS M
        ON S.customer_id = M.customer_id
)
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member_status,
    CASE 
        WHEN member_status = 'Y' 
        THEN RANK() OVER (
            PARTITION BY customer_id, member_status
            ORDER BY order_date
        )
        ELSE NULL
    END AS ranking
FROM base_table
ORDER BY customer_id, order_date;
