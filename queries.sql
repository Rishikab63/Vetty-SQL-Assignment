--Q1

SELECT 
    strftime('%Y-%m', purchase_time) AS month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_item IS NULL
GROUP BY month
ORDER BY month;





--Q2

SELECT store_id, COUNT(*) AS order_count
FROM transactions
WHERE strftime('%Y-%m', purchase_time) = '2020-10'
GROUP BY store_id
HAVING COUNT(*) >= 5;






--Q3

SELECT store_id, 
       MIN((julianday(refund_item) - julianday(purchase_time)) * 1440) AS min_refund_time
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;






--Q4

SELECT t1.store_id, 
    t1.gross_transaction_value, 
    t1.purchase_time
FROM transactions t1
WHERE t1.purchase_time = (
    SELECT MIN(t2.purchase_time) 
    FROM transactions t2 
    WHERE t2.store_id = t1.store_id
);




--Q5-

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




--Q6-  

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





--Q7

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







--Q8
--Using-julianday() function


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

