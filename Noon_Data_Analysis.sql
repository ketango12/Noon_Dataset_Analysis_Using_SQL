-- 1. How many total orders were placed in January 2025?
      SELECT COUNT(*) AS total_jan_orders
      FROM orders
      WHERE Placed_at BETWEEN '2025-01-01' AND '2025-01-31'

-- Business Insight: Understand overall demand volume in a month to assess seasonality or campaign success.

-- 2. Which cuisine received the highest number of orders?
      SELECT Cuisine, COUNT(*) AS order_count
      FROM orders
      GROUP BY Cuisine
      ORDER BY order_count DESC
      LIMIT 1

-- Business Insight: Helps identify customer preferences for menu planning or promotion focus.

-- 3. How many orders used a promo code?
      SELECT COUNT(*) AS promo_orders
      FROM orders
      WHERE Promo_code_Name IS NOT NULL;

-- Business Insight: Evaluates promo code adoption to understand customer sensitivity to offers.

-- 4. What is the repeat rate of customers (customers with more than one order)?
      SELECT 
            COUNT(DISTINCT Customer_code) FILTER (WHERE order_count > 1) * 100.0 /
            COUNT(DISTINCT Customer_code) AS repeat_rate_percent
      FROM (
      SELECT Customer_code, COUNT(*) AS order_count
      FROM orders
      GROUP BY Customer_code
      ) sub

-- Business Insight: Key metric for retention performance and customer loyalty analysis.
        
-- 5. Which restaurant received the highest number of promo code orders?
      SELECT Restaurant_id, COUNT(*) AS promo_order_count
      FROM orders
      WHERE Promo_code_Name IS NOT NULL
      GROUP BY Restaurant_id
      ORDER BY promo_order_count DESC
      LIMIT 1

-- Business Insight: Determine which restaurants drive promo engagement—valuable for partnership or subsidy allocation.
        
-- 6. Which day of the week has the highest average number of orders?
      SELECT 
            DAYNAME(Placed_at) AS day_of_week,
            COUNT(*) AS order_count
      FROM orders
      GROUP BY day_of_week
      ORDER BY order_count DESC;

-- Business Insight: Optimize delivery operations and ad budgets around peak ordering days.

--  7. Identify customers acquired using a promo who haven't ordered in the last 30 days.
      WITH first_orders AS (
        SELECT 
              Customer_code,
              MIN(Placed_at) AS first_order_date
        FROM orders
        GROUP BY Customer_code
    ),
      promo_first_orders AS (
        SELECT o.Customer_code
        FROM orders o
        JOIN first_orders f ON o.Customer_code = f.Customer_code AND o.Placed_at = f.first_order_date
        WHERE o.Promo_code_Name IS NOT NULL
    ),
     recent_orders AS (
       SELECT DISTINCT Customer_code
       FROM orders
       WHERE Placed_at > DATE('2025-04-08', '-30 days')
    )
     SELECT pfo.Customer_code
     FROM promo_first_orders pfo
     LEFT JOIN recent_orders ro ON pfo.Customer_code = ro.Customer_code
     WHERE ro.Customer_code IS NULL;

-- Business Insight: Spot potential churn from recently acquired users and take action via win-back campaigns.

-- 8. Which promo code has the best conversion rate (Delivered / Total orders using that promo)?
      SELECT 
            Promo_code_Name,
            COUNT(*) AS total_uses,
            SUM(CASE WHEN Order_status = 'Delivered' THEN 1 ELSE 0 END) AS successful_deliveries,
            ROUND(100.0 * SUM(CASE WHEN Order_status = 'Delivered' THEN 1 ELSE 0 END) / COUNT(*), 2) AS conversion_rate_percent
      FROM orders
      WHERE Promo_code_Name IS NOT NULL
      GROUP BY Promo_code_Name
      ORDER BY conversion_rate_percent DESC;

-- Business Insight: Understand which promo codes perform best to improve future marketing efficiency.
  
-- 9. Find customers who ordered from multiple cuisines in the same month.
      SELECT Customer_code
      FROM (
            SELECT Customer_code, MONTH(Placed_at) AS order_month, COUNT(DISTINCT Cuisine) AS cuisine_count
            FROM orders
            GROUP BY Customer_code, MONTH(Placed_at)
         ) sub
      WHERE cuisine_count > 1;

-- Business Insight: Identify adventurous or exploratory customers—great targets for new menu launches or cross-selling campaigns.

-- 10. Find top 3 outlets by cuisine type without using limit and top function.
	    WITH cte AS ( SELECT  
                        cuisine, restaurant_id, COUNT(Order_id) as total_orders,
	                      row_number() over(PARTITION BY cuisine ORDER BY COUNT(Order_id) DESC) AS rn
	                  FROM orders
	                  GROUP BY restaurant_id, cuisine 
               )
      SELECT cuisine, restaurant_id, total_orders
      FROM cte
      WHERE rn <= 3

-- Business Insight: Identify the top 3 outlets by order volume within each cuisine to spotlight high-performing locations for strategic focus and operational efficiency
    
-- 11. Find the daily new customer count from the launch date (Everyday how many new customers are we acquiring)?
	     WITH cte AS ( SELECT customer_code, MIN(placed_at) AS order_date 
                     FROM orders
	                   GROUP BY customer_code
	                   ORDER BY MIN(placed_at)
	               )
    
       SELECT order_date, COUNT(customer_code) AS orders_per_day
	     FROM cte
	     GROUP BY date(order_date)
       ORDER BY date(order_date)

-- Business Insight: Track daily new customer acquisition to measure marketing effectiveness, user growth trends, and optimize customer onboarding strategies.
        
-- 12. Count of all the users that were acquired in Jan 2025 and only placed one order in Jan and did not place any other order.
	     WITH cte as ( SELECT 
                        customer_code, MIN(placed_at) AS first_order_date, 
                        MAX(placed_at) AS latest_order_date
	                   FROM orders 
	                   GROUP BY customer_code
	               )
	
       SELECT cte.*, orders.Promo_code_Name AS first_order_promo
       FROM cte
       JOIN orders
       ON cte.customer_code = orders.Customer_code
       AND
       cte.first_order_date = orders.Placed_at
       WHERE latest_order_date < dateadd(DAY, -7, getdate())
       AND first_order_date < dateadd(MONTH, -1, getdate()) AND orders.Promo_code_Name IS NOT NULL

-- Business Insight: Helping to evaluate retention issues in the first month.
        
-- 13. List customers who placed more than 1 order and all their orders on a promo only.
       SELECT customer_code, count(*) AS no_of_orders, COUNT(promo_code_name) AS promo_orders
       FROM orders
       GROUP BY customer_code
       HAVING COUNT(*) > 1 AND 
       COUNT(*) = COUNT(promo_code_name)

-- Business Insight: Identify loyal yet discount-reliant customers to evaluate promotional dependency and long-term profitability.

