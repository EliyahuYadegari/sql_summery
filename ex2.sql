 						---=== חימום: SELECT / JOIN / Aggregation===---
------------------------------------------------------------------------------------------------------------------------------------------------------------------						
							--=== Top Employees by Orders: ===--
		-- הצג שם עובד ומספר ההזמנות שטיפל בהן. הצג רק עובדים עם יותר מ־75 הזמנות. מיין מהגבוה לנמוך.

SELECT   	 (EMP.first_name||''||EMP.last_name) AS "Employe name:",
		 	 COUNT(ORD.order_id)
FROM 	  	 public.orders ORD
INNER JOIN 	 public.employees EMP 
USING 		 (employee_id)
GROUP BY 1
HAVING COUNT (ORD.order_id) > 75;
------------------------------------------------------------------------------------------------------------------------------------------------------------------

							---=== Inactive Customers: ===---
--הצג לקוחות שלא ביצעו שום הזמנה. החזר: customer_id, company_name.
SELECT  CUS.customer_id,
		CUS.company_name
FROM 	public.customers CUS
LEFT JOIN public.orders ORD
USING(customer_id)
WHERE order_id  IS NULL;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
					---=== Unordered but Premium-Priced Products: ===---
-- הצג מוצרים שאף פעם לא הוזמנו ושמחירם מעל הממוצע הכללי של כל המוצרים. החזר: product_name, unit_price, supplier_name, category_name.
	 ---CTE---
WITH  SUB1 AS (
SELECT  PRO.product_name
		,COUNT(ORD.order_id) CNT 
FROM public.products PRO
LEFT JOIN public.order_details ORD
USING (product_id) GROUP BY 1 
				)
--------------------------MAIN-------------------------------------				
SELECT  PRO.product_name, PRO.unit_price, SUP.company_name, CAT.category_name
FROM  public.suppliers SUP
LEFT JOIN public.products PRO
USING (supplier_id)
LEFT JOIN public.categories CAT 
USING(category_id)
LEFT JOIN public.order_details ORD
USING (product_id)
LEFT JOIN SUB1 
USING (product_name)
WHERE PRO.unit_price > (SELECT AVG(PRO.unit_price) FROM public.products  PRO)  
AND    SUB1.CNT  = 0;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 								---=== CASE ===---
------------------------------------------------------------------------------------------------------------------------------------------------------------------						
							---===Freight Bands:===---
    -- לכל הזמנה, החזר order_id, freight ועמודה מחושבת freight_band: 'Low' אם freight < 50, 'Medium' אם 50–150 ת 'High' אם > 150
							-- מיין לפי freight יורד.
SELECT 	order_id,
		CASE WHEN freight > 150 THEN 'High'
			 WHEN freight BETWEEN 150 AND 150 THEN 'Medium'
			 ELSE 'Low'
		END AS "Freight_Band"	 
FROM public.orders ;			
------------------------------------------------------------------------------------------------------------------------------------------------------------------
							--=== Order Freshness: ===--
		-- לכל הזמנה, הצג order_id, order_date, shipped_date ועמודת status:
		-- 'Pending' אם shipped_date IS NULL
		-- 'On-time' אם
		--shipped_date <= order_date + INTERVAL '5 days'
		-- 'Late' אחרת.
SELECT	 order_id, order_date, shipped_date,
		 CASE WHEN shipped_date IS NULL THEN 'Pending'
		 	  WHEN shipped_date <= order_date + 5  THEN 'On-time'
			   ELSE 'Late'
		 END AS "Order Freshness:"	   
FROM public.orders	;		
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					--=== Stock Status (Products): ===--
		-- הוסף סיווג לוגי לעמודת stock_status לפי units_in_stock ו־units_on_order (אם קיימות אצלך):
		-- 'Out Of Stock' אם units_in_stock = 0
		-- 'Reorder Soon' אם units_in_stock < units_on_order
		-- 'OK' אחרת.
SELECT units_in_stock,units_on_order,
	   CASE WHEN units_in_stock = 0 THEN 'OUT OF STOCK'
	   		WHEN units_in_stock < units_on_order THEN 'Reorder Soon'
			ELSE 'OK'   
		END AS "Stock Status"	
FROM public.products;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
						--=== Window Functions ===--
------------------------------------------------------------------------------------------------------------------------------------------------------------------						
		--=== Two Cheapest per Category (Dense Rank): ===--
	
-- החזר לכל קטגוריה את שני המוצרים הזולים ביותר: category_name, product_name, unit_price, rank_in_category (1=הזול ביותר) באמצעות DENSE_RANK() עם PARTITION BY category_name ORDER BY unit_price ASC.
WITH DNS AS 
(
SELECT CAT.category_name,PRO.product_name,PRO.unit_price,
	 DENSE_RANK() OVER (PARTITION BY category_name ORDER BY unit_price ASC) AS  RNK
FROM public.products PRO
INNER JOIN public.categories CAT
USING(category_id)
ORDER BY 1,RNK
)
SELECT DNS.category_name,
		DNS.product_name,
		DNS.unit_price,
		DNS.RNK
FROM DNS  
WHERE DNS.RNK<=2;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
				--=== Customer Running Total: ===--
		-- לכל לקוח, סדר את ההזמנות שלו כרונולוגית והצג order_id, order_date, order_total ו־running_total – סכום מצטבר באמצעות SUM(order_total) OVER (PARTITION BY customer_id ORDER BY order_date).
		-- רמז: order_total = SUM(od.unit_price * od.quantity * (1 - od.discount)) על order_details בכל order_id.
----------------------CTE-----------------------------		
WITH total AS (
SELECT  
					CUS.customer_id,
					ORD.order_id,
					ORD.order_date, 
					SUM(OD.unit_price * OD.quantity * (1 - OD.discount)) AS order_total				 
FROM 	public.customers CUS
INNER JOIN public.orders ORD
USING (customer_id)
INNER  JOIN  public.order_details OD
USING (order_id)
GROUP BY CUS.customer_id,1,2
)
-------------------MAIN---------------------------------
SELECT DISTINCT 
					total.customer_id,
					total.order_id,
					total.order_date, 
					total.order_total,
					SUM(total.order_total)OVER(PARTITION BY customer_id ORDER BY order_date) AS running_total
FROM  total
GROUP BY  1,2,3,4
ORDER BY 1, order_date ASC	;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--=== Category Revenue Share: ===--
		-- חשב לכל מוצר את אחוז ההכנסה שלו מסך הכנסות הקטגוריה:
		-- product_share = product_revenue / SUM(product_revenue) OVER (PARTITION BY category_name).
		-- החזר category_name, product_name, product_revenue, product_share.
WITH REV AS (
SELECT CAT.category_name, PRO.product_name, SUM(ORD.unit_price) AS product_revenue
FROM public.categories CAT
INNER JOIN public.products PRO 
USING(category_id )
INNER JOIN public.order_details ORD
USING(product_id )
GROUP BY 1,2 
ORDER BY 1
)		
SELECT REV.category_name, REV.product_name,  REV.product_revenue,
		REV.product_revenue/SUM(REV.product_revenue)OVER(PARTITION BY category_name )AS product_share 
FROM  REV
GROUP BY 1,2,3
ORDER BY 1,3
------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--=== Last Order per Customer via Window:===---
		-- מצא לכל לקוח את ההזמנה האחרונה לפי order_date עם ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) = 1.
		-- החזר: company_name, order_id, order_date.
SELECT DISTINCT ON (CUS.customer_id)
					CUS.company_name,
					ORD.order_id,
					ORD.order_date
FROM public.orders ORD
INNER JOIN public.customers CUS
USING (customer_id)
ORDER BY CUS.customer_id, ORD.order_date DESC ;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
 			--===  פונקציות (PL/pgSQL) – בסיס נהדר ===--
		-- Scalar Function – order_total(order_id INT) → NUMERIC:
		-- צור פונקציה שמקבלת order_id ומחזירה סכום הזמנה:
		-- SUM(unit_price * quantity * (1 - discount)).
		-- הוסף COALESCE להגנה על NULL.
CREATE OR REPLACE FUNCTION FN_Scalar(n_order_id INT)
RETURNS NUMERIC AS
$$ 
DECLARE total NUMERIC;
BEGIN

SELECT 
SUM(PRO.unit_price * PRO.quantity * (1 - PRO.discount))  AS T 
INTO TOTAL 
FROM public.products PRO
LEFT JOIN public.order_details ORD
USING(product_id)
WHERE n_order_id=ord.order_id;

RETURN  COALESCE(TOTAL,0);

END;
$$
LANGUAGE plpgsql;

		
------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--=== Set-Returning Function – customer_orders(customer_id INT):===--
		-- אם ללקוח יש הזמנות – החזר טבלה: (order_id, order_date, total_amount) ממוינת לפי תאריך;אם אין – החזר שורה בודדת עם order_id=NULL, order_date=NULL, total_amount=NULL ו/או RAISE NOTICE 'No orders found'.
		-- אתגר קטן: פתר גם עם RETURNS TABLE וגם עם RETURNS SETOF RECORD (עם OUT פרמטרים).

CREATE OR REPLACE FUNCTION fn_Set_Returning(n_customer_id INT)
RETURNS TABLE(X_order_id INT,X_order_date DATE ,X_total_amount INT) AS 
$$
BEGIN
RETURN QUERY 
SELECT 
order_id, 
order_date,
FN_Scalar(order_id) AS total_amount;

IF NOT FOUND THEN 
RAISE NOTICE 'No orders found'; 

END IF ;
END;
$$
LANGUAGE plpgsql;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--=== Scalar Function – customer_tier(customer_id INT) → TEXT:===--
		-- החזר דרגת לקוח לפי סכום ההזמנות הכולל (12 חודשים אחרונים):
		-- VIP אם >= 100,000
		-- Gold אם 50,000–99,999
		-- Regular אחרת.
CREATE OR REPLACE FUNCTION fn_customer_tier(n_customer_id INT)	
RETURNS text AS 
$$
DECLARE R TEXT;

BEGIN
SELECT  
CASE WHEN SUM(PRO.unit_price * PRO.quantity * (1 - PRO.discount)) > 100000 THEN 'VIP'
	 WHEN SUM(PRO.unit_price * PRO.quantity * (1 - PRO.discount)) BETWEEN 50000 AND 99999 THEN 'GOLD'
	ELSE 'Regular'
	END  INTO R
FROM public.products PRO
INNER JOIN public.orders ORD
USING (product_id)
INNER JOIN public.customers CUS
USING (customer_id)
WHERE CUS.customer_id=n_customer_id;

RETURN R;

END;
$$
LANGUAGE plpgsql;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
							--===  CASE + Window + Aggregates ===--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				--=== Monthly Cohort Retention Signal: ===--
		-- חשב עבור כל לקוח את חודש ההצטרפות (חודש ההזמנה הראשונה) ואת מספר החודשים הפעילים מאז (מס’ חודשים שיש בהם לפחות הזמנה). החזר גם עמודת activity_band באמצעות CASE:
		-- 'New' אם חודשים פעילים ≤ 2
		-- 'Active' אם 3–6
		-- 'Loyal' אם > 6
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					--=== Top-N by Category with Ties:===--
		-- החזר לכל קטגוריה את כל המוצרים שנכנסו ל־Top 3 לפי הכנסות, כולל שוויון דירוג. השתמש ב־DENSE_RANK(); החזר: category_name, product_name, product_revenue, rank_in_category עם סינון rank_in_category <= 3.
		-- Employee Productivity Percentile:
		-- חשב לכל עובד את האחוזון (0–100) של מספר ההזמנות שטיפל בהן ביחס לכלל העובדים באמצעות PERCENT_RANK() או CUME_DIST(). החזר: employee, orders_count, percentile.
------------------------------------------------------------------------------------------------------------------------------------------------------------------
					--=== אתגר פרו: “דוח מכירות קצר===--
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- בנה שאילתה אחת שמחזירה שורה אחת לכל לקוח עם:
-- total_orders
-- total_revenue
-- avg_order_value
-- first_order_date / last_order_date
-- status (CASE: 'Dormant' אם אין הזמנות ב־90 הימים האחרונים; 'Active' אחרת).
-- הצג את 10 הלקוחות המכניסים ביותר.
