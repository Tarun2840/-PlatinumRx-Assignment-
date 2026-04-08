-- CLINIC MANAGEMENT QUERIES

-- 1. Revenue by channel
SELECT sales_channel, SUM(amount) AS total_revenue
FROM clinic_sales
WHERE EXTRACT(YEAR FROM datetime)=2021
GROUP BY sales_channel;

-- 2. Top 10 customers
SELECT uid, SUM(amount) AS total_spent
FROM clinic_sales
WHERE EXTRACT(YEAR FROM datetime)=2021
GROUP BY uid
ORDER BY total_spent DESC
LIMIT 10;

-- 3. Monthly revenue, expense, profit
WITH revenue AS (
    SELECT EXTRACT(MONTH FROM datetime) AS month, SUM(amount) AS revenue
    FROM clinic_sales
    WHERE EXTRACT(YEAR FROM datetime)=2021
    GROUP BY month
),
expenses_data AS (
    SELECT EXTRACT(MONTH FROM datetime) AS month, SUM(amount) AS expense
    FROM expenses
    WHERE EXTRACT(YEAR FROM datetime)=2021
    GROUP BY month
)
SELECT r.month, r.revenue, e.expense,
       (r.revenue - e.expense) AS profit,
       CASE WHEN (r.revenue - e.expense)>0 THEN 'Profitable' ELSE 'Not Profitable' END status
FROM revenue r JOIN expenses_data e ON r.month=e.month;

-- 4. Most profitable clinic per city
WITH profit_data AS (
    SELECT c.city, cs.cid,
           SUM(cs.amount) - COALESCE(SUM(e.amount),0) AS profit
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid=c.cid
    LEFT JOIN expenses e ON cs.cid=e.cid
    WHERE EXTRACT(MONTH FROM cs.datetime)=9
    GROUP BY c.city, cs.cid
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY city ORDER BY profit DESC) rnk
    FROM profit_data
)
SELECT * FROM ranked WHERE rnk=1;

-- 5. Second least profitable clinic per state
WITH profit_data AS (
    SELECT c.state, cs.cid,
           SUM(cs.amount) - COALESCE(SUM(e.amount),0) AS profit
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid=c.cid
    LEFT JOIN expenses e ON cs.cid=e.cid
    WHERE EXTRACT(MONTH FROM cs.datetime)=9
    GROUP BY c.state, cs.cid
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY state ORDER BY profit ASC) rnk
    FROM profit_data
)
SELECT * FROM ranked WHERE rnk=2;
