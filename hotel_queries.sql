-- HOTEL MANAGEMENT QUERIES

-- 1. Last booked room per user
SELECT user_id, room_no
FROM (
    SELECT user_id, room_no, booking_date,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY booking_date DESC) rn
    FROM bookings
) t WHERE rn = 1;

-- 2. Booking billing in Nov 2021
SELECT bc.booking_id, SUM(bc.item_quantity * i.item_rate) AS total_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM bc.bill_date)=11 AND EXTRACT(YEAR FROM bc.bill_date)=2021
GROUP BY bc.booking_id;

-- 3. Bills > 1000 in Oct 2021
SELECT bill_id, SUM(item_quantity * i.item_rate) AS bill_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM bill_date)=10 AND EXTRACT(YEAR FROM bill_date)=2021
GROUP BY bill_id
HAVING SUM(item_quantity * i.item_rate) > 1000;

-- 4. Most & least ordered items per month
WITH item_orders AS (
    SELECT EXTRACT(MONTH FROM bill_date) AS month, item_id,
           SUM(item_quantity) AS total_qty
    FROM booking_commercials
    WHERE EXTRACT(YEAR FROM bill_date)=2021
    GROUP BY month, item_id
),
ranked AS (
    SELECT *, 
           RANK() OVER (PARTITION BY month ORDER BY total_qty DESC) max_rank,
           RANK() OVER (PARTITION BY month ORDER BY total_qty ASC) min_rank
    FROM item_orders
)
SELECT * FROM ranked WHERE max_rank=1 OR min_rank=1;

-- 5. Second highest bill per month
WITH bill_totals AS (
    SELECT bill_id, EXTRACT(MONTH FROM bill_date) AS month,
           SUM(item_quantity * i.item_rate) AS total_amount
    FROM booking_commercials bc
    JOIN items i ON bc.item_id = i.item_id
    WHERE EXTRACT(YEAR FROM bill_date)=2021
    GROUP BY bill_id, month
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY month ORDER BY total_amount DESC) rnk
    FROM bill_totals
)
SELECT * FROM ranked WHERE rnk=2;
