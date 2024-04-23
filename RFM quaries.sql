SELECT*FROM DATA1;
--Average Discount Percentage by Product Name
SELECT [Product Name], AVG(Discount) AS AvgDiscountPercentage
FROM DATA1
GROUP BY [Product Name];
--Total Quantity Sold by Product Name
SELECT [Product Name], SUM(Quantity) AS TotalQuantitySold
FROM DATA1
GROUP BY [Product Name];
--Most Sold Product (by Quantity) in a Single Invoice
SELECT TOP 1 Invoice, [Product Name], MAX(Quantity) AS MaxQuantity
FROM DATA1
GROUP BY Invoice, [Product Name]
ORDER BY MaxQuantity DESC;
--Customers with the Highest Total Revenue
SELECT TOP 5 Customer_ID, SUM([Price After Discount] * Quantity) AS TotalRevenue
FROM DATA1
GROUP BY Customer_ID
ORDER BY TotalRevenue DESC;
--Top Selling Products by Quantity
SELECT TOP 10 [Product Name], SUM(Quantity) AS TotalQuantitySold
FROM DATA1
GROUP BY [Product Name]
ORDER BY TotalQuantitySold DESC;

DECLARE @TODAY_DATE AS DATE = '2024-04-22';

WITH base AS (
  SELECT 
       Customer_ID,
       DATEDIFF(day, MAX([Invoice Date]), @TODAY_DATE) AS Recency,
       COUNT(DISTINCT Invoice) AS Frequency,
       SUM([Price After Discount] * Quantity) AS Monetary
   FROM DATA1 
   GROUP BY Customer_ID
),
RFM_Scores AS (
  SELECT
      Customer_ID
	  ,Recency
	  ,Frequency
	  ,Monetary
	  ,NTILE(7) OVER (ORDER BY Recency DESC) AS R_Score
	  ,NTILE(7) OVER (ORDER BY Frequency ASC) AS F_Score
	  ,NTILE(7) OVER (ORDER BY Monetary ASC) AS M_Score
  FROM base
)

SELECT 
    (R_Score + F_Score + M_Score) / 3 AS rfm_group,
    COUNT(RFM.Customer_ID) AS customer_count,
	SUM(base.Monetary) AS total_revenue,
    ROUND(SUM(base.Monetary) / COUNT(RFM.Customer_ID), 2) AS AVG_REVENUE_PER_CUSTOMER
FROM RFM_Scores AS RFM
INNER JOIN base ON base.Customer_ID = RFM.Customer_ID
GROUP BY (R_Score + F_Score + M_Score) / 3 
ORDER BY rfm_group ASC;

WITH RFM_Scores AS (
    SELECT
        Customer_ID,
        Recency,
        Frequency,
        Monetary,
        NTILE(7) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(7) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(7) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM (
        SELECT 
            Customer_ID,
            DATEDIFF(day, MAX([Invoice Date]), @TODAY_DATE) AS Recency,
            COUNT(DISTINCT Invoice) AS Frequency,
            SUM([Price After Discount] * Quantity) AS Monetary
        FROM DATA1 
        GROUP BY Customer_ID
    ) AS base
)

SELECT 
    Customer_ID,
    Recency,
    Frequency,
    Monetary,
    CASE
        WHEN R_Score <= 2 AND F_Score >= 5 AND M_Score >= 5 THEN 'Champions'
        WHEN R_Score <= 3 AND F_Score >= 4 AND M_Score >= 4 THEN 'Loyal'
        WHEN R_Score <= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Potential Loyalist'
        WHEN R_Score = 7 AND F_Score = 1 AND M_Score = 1 THEN 'New Customers'
        WHEN R_Score <= 3 AND F_Score <= 2 AND M_Score <= 2 THEN 'Promising'
        WHEN R_Score >= 4 AND R_Score <= 6 AND F_Score >= 3 AND F_Score <= 4 AND M_Score >= 3 AND M_Score <= 4 THEN 'Need Attention'
        WHEN R_Score >= 4 AND R_Score <= 6 AND F_Score >= 2 AND F_Score <= 3 AND M_Score >= 2 AND M_Score <= 3 THEN 'About to Sleep'
        WHEN R_Score >= 2 AND R_Score <= 4 AND F_Score >= 4 AND F_Score <= 5 AND M_Score >= 4 AND M_Score <= 5 THEN 'Can''t Lose Them'
        WHEN R_Score >= 4 AND R_Score <= 7 AND F_Score >= 1 AND F_Score <= 2 AND M_Score >= 1 AND M_Score <= 2 THEN 'Hibernating Customers'
        ELSE 'Lost Customers'
    END AS Segment
FROM RFM_Scores;









