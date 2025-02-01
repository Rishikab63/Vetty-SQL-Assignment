NOTE- The queries are using SQLite syntax.


Table creation and inserting the values


CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME(3),
    refund_item DATETIME(3),
    store_id CHAR(1),
    item_id VARCHAR(10),
    gross_transaction_value VARCHAR(10)
);


INSERT INTO transactions (buyer_id, purchase_time, refund_item, store_id, item_id, gross_transaction_value) VALUES
(3, '2019-09-19 21:19:06.544', NULL, 'a', 'a1', '$58'),
(12, '2019-12-10 20:10:14.324', '2019-12-15 23:19:06.544', 'b', 'b2', '$475'),
(3, '2020-09-01 23:59:46.561', '2020-09-02 21:22:06.331', 'f', 'f9', '$33'),
(2, '2020-04-30 21:19:06.544', NULL, 'd', 'd3', '$250'),
(1, '2020-10-22 22:20:06.531', NULL, 'f', 'f2', '$91'),
(8, '2020-04-16 21:10:22.214', NULL, 'e', 'e7', '$24'),
(5, '2019-09-23 12:09:35.542', '2019-09-27 02:55:02.114', 'g', 'g6', '$61');


CREATE TABLE items (
    store_id CHAR(1),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(50)
);


INSERT INTO items (store_id, item_id, item_category, item_name) VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f5', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');





Q1- What is the count of purchases per month (excluding refunded purchases)?

SELECT 
    strftime('%Y-%m', purchase_time) AS month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_item IS NULL
GROUP BY month
ORDER BY month;

OUTPUT- 

month		purchase_count
2019-09		1
2020-04		2
2020-10		1



Q2- How many stores receive at least 5 orders/transactions in October 2020? 

SELECT store_id, COUNT(*) AS order_count
FROM transactions
WHERE strftime('%Y-%m', purchase_time) = '2020-10'
GROUP BY store_id
HAVING COUNT(*) >= 5;

OUTPUT- 
SQL query successfully executed. However, the result set is empty.



Q3-  For each store, what is the shortest interval (in min) from purchase to refund time?

query- SELECT store_id, 
       MIN((julianday(refund_item) - julianday(purchase_time)) * 1440) AS min_refund_time
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;


output-

store_id	min_refund_time
b		7388.870332762599
f		1282.3295000195503
g		5205.442866459489



Q4-  What is the gross_transaction_value of every store’s first order? 

Query- 
SELECT t1.store_id, 
    t1.gross_transaction_value, 
    t1.purchase_time
FROM transactions t1
WHERE t1.purchase_time = (
    SELECT MIN(t2.purchase_time) 
    FROM transactions t2 
    WHERE t2.store_id = t1.store_id
);


output- 
store_id	gross_transaction_value		purchase_time
a		$58				2019-09-19 21:19:06.544
b		$475				2019-12-10 20:10:14.324
f		$33				2020-09-01 23:59:46.561
d		$250				2020-04-30 21:19:06.544
e		$24				2020-04-16 21:10:22.214
g		$61				2019-09-23 12:09:35.542



Q5- What is the most popular item name that buyers order on their first purchase?

WITH first_purchases AS (
    SELECT buyer_id, MIN(purchase_time) AS first_purchase_time
    FROM transactions
    GROUP BY buyer_id
)
SELECT i.item_name, COUNT(*) AS order_count
FROM transactions t
JOIN first_purchases fp ON t.buyer_id = fp.buyer_id AND t.purchase_time = fp.first_purchase_time
JOIN items i ON t.item_id = i.item_id
GROUP BY i.item_name
ORDER BY order_count DESC
LIMIT 1;


output-  

item_name	order_count
denim pants	1



Q6-  Create a flag in the transaction items table indicating whether the refund can be processed or 
not. The condition for a refund to be processed is that it has to happen within 72 of Purchase 
time. 
Expected Output: Only 1 of the three refunds would be processed in this case 


SELECT 
    buyer_id, 
    purchase_time, 
    refund_item, 
    store_id, 
    item_id, 
    gross_transaction_value,
    CASE 
        WHEN refund_item IS NOT NULL 
             AND (strftime('%s', refund_item) - strftime('%s', purchase_time)) <= 72 * 3600
        THEN 'Refund Processed' 
        ELSE 'Refund Not Processed' 
    END AS refund_status
FROM transactions
WHERE refund_item IS NOT NULL;  -- Only show rows where a refund was attempted


OUTPUT-

buyer_id	purchase_time				refund_item		store_id	item_id	  	gross_transaction_value 	refund_status
12		2019-12-10 20:10:14.324		2019-12-15 23:19:06.544		b		b2			$475			Refund Not Processed
3		2020-09-01 23:59:46.561		2020-09-02 21:22:06.331		f		f9			$33			Refund Processed
5		2019-09-23 12:09:35.542		2019-09-27 02:55:02.114		g		g6			$61 			Refund Not Processed




Q7- Create a rank by buyer_id column in the transaction items table and filter for only the second 
purchase per buyer. (Ignore refunds here) 
Expected Output: Only the second purchase of buyer_id 3 should the output 


WITH RankedTransactions AS (
    SELECT 
        buyer_id, 
        purchase_time, 
        store_id, 
        item_id, 
        gross_transaction_value,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id 
            ORDER BY purchase_time ASC
        ) AS purchase_rank
    FROM transactions
)
SELECT *
FROM RankedTransactions
WHERE purchase_rank = 2;  -- Get only the second purchase per buyer



Output- 

buyer_id	purchase_time			store_id	item_id		gross_transaction_value		purchase_rank
3		2020-09-01 23:59:46.561		f		f9			$33				2




Q8- How will you find the second transaction time per buyer (don’t use min/max; assume there 
were more transactions per buyer in the table) 
Expected Output: Only the second purchase of buyer_id along with a timestamp

Assumption- avoid using MIN/MAX and assumes that there are more transactions per buyer.

Using-julianday() function


WITH RankedTransactions AS (
    SELECT 
        buyer_id, 
        purchase_time, 
        refund_item,
        -- Calculate the adjusted timestamp (if refund is within 72 hours)
        CASE
            WHEN refund_item IS NOT NULL AND 
                 julianday(refund_item) - julianday(purchase_time) <= 3 THEN refund_item
            ELSE purchase_time
        END AS adjusted_purchase_time,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id 
            ORDER BY purchase_time ASC
        ) AS transaction_rank
    FROM transactions
)
SELECT buyer_id, adjusted_purchase_time AS second_transaction_timestamp
FROM RankedTransactions
WHERE transaction_rank = 2; 


Output- 
buyer_id		second_transaction_timestamp
3			2020-09-02 21:22:06.331