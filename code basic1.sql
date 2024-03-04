select * from [atliq1].dbo.Sheet1$
--1) Total number of stores
select count (distinct store_id) as total_stores from [atliq1].dbo.Sheet1$

--2)how many promo types are there 
select distinct (promo_type) as types_of_promo from [atliq1].dbo.Sheet1$ --(This query retrieves all unique values in the 'PromoType' column from the table)

--3)how many  campaigns are there 
select distinct (dim_campaigns#campaign_name) as types_of_campaign from [atliq1].dbo.Sheet1$

--4)List of products where base price >500 and that are featured in promo type of BOGOF
SELECT DISTINCT dim_products#product_name as Atliq_product_name, base_price, promo_type
FROM [atliq1].dbo.Sheet1$
WHERE base_price > 500 AND promo_type ='BOGOF';

--5)number of stores in each city
select dim_stores#city,count(distinct store_id) as num_of_stores from [atliq1].dbo.Sheet1$ group by dim_stores#city order by num_of_stores desc

select * from [atliq1].dbo.Sheet1$

--6) each campaign along with the total revenue generated before and after the campaign
SELECT 
    [quantity_sold(before_promo)] AS quantity_sold_before_promo,
    [quantity_sold(after_promo)] AS quantity_sold_after_promo,
    base_price,
    ([quantity_sold(before_promo)] * base_price) AS total_revenue_before_promotion,
    ([quantity_sold(after_promo)] * base_price) AS total_revenue_after_promotion
FROM [atliq1].dbo.Sheet1$

--7)Total Revenue Before and After Promotion, Grouped by Base Price and Campaign Name 
SELECT 
    base_price,
    dim_campaigns#campaign_name,
    SUM([quantity_sold(before_promo)] * base_price) AS total_revenue_before_promotion,
    SUM([quantity_sold(after_promo)] * base_price) AS total_revenue_after_promotion
FROM [atliq1].dbo.Sheet1$
GROUP BY
    base_price,
    dim_campaigns#campaign_name;

	--8)ISU prcentage calculation
	SELECT 
    dim_campaigns#campaign_name,
    base_price,
    SUM([quantity_sold(before_promo)] * base_price) AS total_revenue_before_promotion,
    SUM([quantity_sold(after_promo)] * base_price) AS total_revenue_after_promotion,
    ((SUM([quantity_sold(after_promo)] * base_price) - SUM([quantity_sold(before_promo)] * base_price)) / SUM([quantity_sold(before_promo)] * base_price)) * 100 AS isu_percentage
FROM [atliq1].dbo.Sheet1$
GROUP BY
    dim_campaigns#campaign_name,
    base_price;

	--9)incremental sold quantity percentage for each category during the Diwali campaign
	WITH CategoryStats AS (
    SELECT
        dim_products#category,
        SUM([quantity_sold(before_promo)]) AS total_quantity_before_promo,
        SUM([quantity_sold(after_promo)]) AS total_quantity_after_promo
    FROM [atliq1].dbo.Sheet1$
    WHERE  dim_campaigns#campaign_name = 'Diwali' -- Adjust this condition based on your campaign name
    GROUP BY dim_products#category
)

SELECT
    dim_products#category,
    ROUND(((total_quantity_after_promo - total_quantity_before_promo) / total_quantity_before_promo) * 100, 2) AS isc_percentage,
    RANK() OVER (ORDER BY ((total_quantity_after_promo - total_quantity_before_promo) / total_quantity_before_promo) DESC) AS rank_order
FROM CategoryStats;


--10)top 5 products ranked by incremental revenue percentage across all the campaigns
WITH ProductStats AS (
    SELECT
        dim_products#product_name,
        dim_products#category,
        SUM([quantity_sold(before_promo)] * base_price) AS total_revenue_before_promo,
        SUM([quantity_sold(after_promo)] * base_price) AS total_revenue_after_promo
    FROM [atliq1].dbo.Sheet1$
    GROUP BY dim_products#product_name, dim_products#category
)

SELECT TOP 5
    dim_products#product_name,
    dim_products#category,
    ROUND(((total_revenue_after_promo - total_revenue_before_promo) / total_revenue_before_promo) * 100, 2) AS ir_percentage,
    RANK() OVER (ORDER BY ((total_revenue_after_promo - total_revenue_before_promo) / total_revenue_before_promo) DESC) AS rank_order
FROM ProductStats
ORDER BY rank_order;

--11)Maximum quantity sold after the promo
select max([quantity_sold(after_promo)]) AS  Maximum_quantity_sold_after_promo from [atliq1].dbo.Sheet1$

--12)Maximum quantity sold before the promo
select max([quantity_sold(before_promo)]) AS  Maximum_quantity_sold_before_promo from [atliq1].dbo.Sheet1$

--13) Average incremental revenue for each product before promotion
select dim_products#product_name,cast(avg([quantity_sold(before_promo)] * base_price) as int) AS Avg_incremental_revenue_for_each_product from [atliq1].dbo.Sheet1$ 
group by dim_products#product_name

--14) Average incremental revenue for each product after promotion
select dim_products#product_name,cast(avg([quantity_sold(after_promo)] * base_price) as int) AS Avg_incremental_revenue_for_each_product from [atliq1].dbo.Sheet1$ 
group by dim_products#product_name

--15) incremental revenue for each product
select 
    dim_products#product_name,
    SUM([quantity_sold(after_promo)] * base_price) - SUM([quantity_sold(before_promo)] * base_price) AS incremental_revenue
FROM [atliq1].dbo.Sheet1$
GROUP BY dim_products#product_name;

--16)Highest incremental revenue for each product
WITH ProductIncrementalRevenue AS (
    SELECT 
        dim_products#product_name,
        SUM([quantity_sold(after_promo)] * base_price) - SUM([quantity_sold(before_promo)] * base_price) AS incremental_revenue
    FROM [atliq1].dbo.Sheet1$
    GROUP BY dim_products#product_name
)

SELECT 
    dim_products#product_name,
    MAX(incremental_revenue) AS highest_incremental_revenue
FROM ProductIncrementalRevenue
GROUP BY dim_products#product_name;

--17) Top two products with the highest incremental revenue,
WITH ProductIncrementalRevenue AS (
    SELECT 
        dim_products#product_name,
        SUM([quantity_sold(after_promo)] * base_price) - SUM([quantity_sold(before_promo)] * base_price) AS incremental_revenue
    FROM [atliq1].dbo.Sheet1$
    GROUP BY dim_products#product_name
)

SELECT TOP 2 WITH TIES
    dim_products#product_name,
    incremental_revenue
FROM ProductIncrementalRevenue
ORDER BY incremental_revenue DESC;



