--  1. Find the staff members who handled more rentals than the average rentals per staff member,
--  and also show for each one their rank compared to other staff by total rentals. Return: staff_id,
--  staff_name, total_rentals, average_all, rank.
WITH CONT AS (
SELECT  STA.staff_id,
		STA.first_name ,
		STA.last_name,
		COUNT(REN.rental_id) AS CNT
FROM public.staff	STA	
INNER JOIN public.rental REN USING (staff_id)
GROUP BY 1,2
)
SELECT  staff_id
		first_name,
		last_name,CNT AS total_rentals ,
		(SELECT  AVG(CNT) AS AVRG  FROM CONT) AS  average_all,
		RANK()OVER(ORDER BY CNT DESC) 
FROM CONT
WHERE (SELECT  AVG(CNT) AS AVRG  FROM CONT) < CNT
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  2. For each category, show: number of films, average rental rate, the longest film (title + length),
--  and the shortest film (title + length). Categories with no films should still appear.
WITH CTE AS (
SELECT CAT.name,	
	   COUNT(F.film_id) AS CNT,
	   AVG(F.rental_rate) AS AVARGE,
	   MAX (F.length) AS  LONGEST,
	   MIN(F.length) AS SHORTEST
FROM public.category CAT	
LEFT JOIN   public.film_category   USING(category_id) 
LEFT JOIN public.film F USING (film_id)
GROUP BY 1 
)
, LONG AS (
SELECT CAT.NAME,
		F.title AS LONGY,
		f.length 
FROM public.category CAT 
LEFT JOIN public.film_category USING (category_id)
LEFT JOIN film F USING  (film_id)
LEFT JOIN  CTE USING (name) 
WHERE CAT.NAME=CTE.NAME AND f.length = CTE.LONGEST 
GROUP BY 1,2,3
),
SHORT AS (
SELECT 	CAT.NAME,
		F.title AS SHORTY,
		f.length 
FROM public.category CAT 
LEFT JOIN public.film_category USING (category_id)
LEFT JOIN film F USING  (film_id)
LEFT JOIN  CTE USING (name) 
WHERE CAT.NAME=CTE.NAME AND f.length = CTE.SHORTEST 
GROUP BY 1,2,3
)
SELECT  CTE.NAME,
		CTE.AVARGE,
		CTE.LONGEST,
		LONG.LONGY,
		CTE.SHORTEST,
		SHORT.SHORTY
FROM CTE 
LEFT JOIN LONG USING(NAME)
LEFT  JOIN SHORT USING(NAME);

--OR 

WITH CTE AS (
SELECT CAT.name,	
	   COUNT(F.film_id) AS CNT,
	   AVG(F.rental_rate) AS AVARGE,
	   MAX (F.length) AS  LONGEST,
	   MIN(F.length) AS SHORTEST
FROM public.category CAT	
LEFT JOIN   public.film_category   USING(category_id) 
LEFT JOIN public.film F USING (film_id)
GROUP BY 1 
)
, LONG AS (
SELECT DISTINCT ON (CAT.NAME)  CAT.NAME,
		F.title AS LONGY,
		f.length 
FROM public.category CAT 
LEFT JOIN public.film_category USING (category_id)
LEFT JOIN film F USING  (film_id)
LEFT JOIN  CTE USING (name) 
WHERE CAT.NAME=CTE.NAME AND f.length = CTE.LONGEST 
GROUP BY 1,2,3
),
SHORT AS (
SELECT DISTINCT ON (CAT.NAME)  	CAT.NAME,
		F.title AS SHORTY,
		f.length 
FROM public.category CAT 
LEFT JOIN public.film_category USING (category_id)
LEFT JOIN film F USING  (film_id)
LEFT JOIN  CTE USING (name) 
WHERE CAT.NAME=CTE.NAME AND f.length = CTE.SHORTEST 
GROUP BY 1,2,3
)
SELECT  CTE.NAME,
		CTE.AVARGE,
		CTE.LONGEST,
		LONG.LONGY,
		CTE.SHORTEST,
		SHORT.SHORTY
FROM CTE 
LEFT JOIN LONG USING(NAME)
LEFT  JOIN SHORT USING(NAME);
--or 
WITH CATCOUNT(category_id,name,"count","avg",film_id,title,"length",LONG,SHORT)
AS(
SELECT C.category_id,C.name,
COUNT(F.film_id) OVER (PARTITION BY category_id),
ROUND(AVG(F.rental_rate) OVER (PARTITION BY category_id),2),
F.film_id,
F.title,
F.length,
RANK() OVER(PARTITION BY category_id ORDER BY length DESC) AS "LONG",
RANK() OVER(PARTITION BY category_id ORDER BY length ASC) AS "SHORT"
FROM category C
LEFT JOIN film_category FC
USING(category_id)
LEFT JOIN film F
USING(film_id)
)
SELECT category_id,name,"count","avg",film_id,title,"length"
FROM CATCOUNT 
WHERE LONG=1 OR SHORT =1;


------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  3. Find the films that have never been rented and whose rental rate is above the overall average
--  rental rate. Return: film title, category name, rental rate.(27)
SELECT F.film_id,F.title,CAT.name,F.rental_rate
FROM  public.film F
LEFT JOIN public.inventory  USING ( film_id)
LEFT JOIN public.rental REN USING (inventory_id)
LEFT JOIN public.film_category USING (film_id)
LEFT JOIN public.category CAT USING (category_id)
WHERE REN.rental_id IS  NULL AND (SELECT AVG(rental_rate) FROM public.film )< rental_rate
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  4. Find the two shortest films (by length) in each category. Return: category name, film title, length,
--  and the rank of the film (1 = shortest).
WITH RNKD AS (
SELECT CAT.name,
		F.title,
		F.length,
		RANK()OVER(PARTITION BY name ORDER BY  length ASC )AS rnk
FROM public.category CAT
INNER JOIN public.film_category USING(category_id)
INNER JOIN public.film F USING (film_id)
)
SELECT * FROM RNKD
WHERE rnk =1
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  5. For each customer, return their last rental. Show: customer name, rental ID, rental date.
SELECT DISTINCT ON (customer_id) 
				   (CUS.first_name||' '||CUS.last_name) AS "Customer_name",
					REN.rental_id,
					REN.rental_date
FROM				public.customer CUS
INNER JOIN          public.rental   REN  USING(customer_id)
ORDER BY customer_id, REN.rental_date DESC		
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  6. Create a Procedure that receives a staff ID. If the staff handled more than 1000 rentals – print
--  'High activity'. Otherwise – print 'Low activity'.
CREATE OR REPLACE PROCEDURE pro_activity_stuff (n_staff_id int)
LANGUAGE plpgsql
AS $$
DECLARE n_cnt INT;
BEGIN
		SELECT COUNT(rental_id)
		FROM public.rental
		WHERE staff_id =  n_staff_id
		INTO n_cnt ;

		IF n_cnt > 1000 THEN RAISE NOTICE 'High activity';
		ELSE RAISE NOTICE 'Low activity';
		END IF;
		END;
	$$;
CALL pro_activity_stuff (1)	
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  7. Create a Function that receives a customer ID. If the customer has rentals – return all their
--  rentals sorted by date. If not – return the message 'No rentals found'.
CREATE OR REPLACE FUNCTION fn_customer_rent3(n_customer_id  int)
RETURNS TABLE ( customer_id smallint, rental_id  int ,rental_date  timestamp without time zone )
LANGUAGE plpgsql 
AS $$
BEGIN 
RETURN QUERY
SELECT R.customer_id,
	   R.rental_id ,
	   R.rental_date
FROM public.rental R
WHERE R.customer_id=n_customer_id 
ORDER BY 3 DESC;
IF NOT FOUND THEN RAISE NOTICE 'No rentals found';
END IF ;
END;
$$;
SELECT  fn_customer_rent3( 2)
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  8. Explain the difference between INNER JOIN and LEFT JOIN using the tables film and inventory.
--  Give an example of when you would use each.
"יינר ג'וין מחבר רק ערכים שיש להם מפתח תואם ב2 הטבלאות
לאפט ג'וין יצרף גם ערכים ללא מפתח תואם "


------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  9. Explain the difference between a Primary Key and a Foreign Key in the context of rental and
--  customer. Why is it important to define both?

" פריימירי קיי בקונטקסט  הזה הוא מספר עובד לקוח זה מספר   שלא יכול להיות נאל בטבלת לקוחות
   דוגמא למפתח משני  ה מקשר בין טבלה  אחרת לטבלה זאת ששם הוא מםתח ראשיRENT.customer_id "

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  10. The company DVDNow wants to store: - Real-time rental transactions (payments, rentals). 
-- Historical sales/rental data for BI reports. - Reviews, images, and logs uploaded by customers.
--  Which type of database would you recommend for each need? Briefly explain

"RTD  FOR REAL LIFE TRANSACTION -CONNECTION BETWEEN TABLES 
DATA WEARHOUS FOR HISTORICAL RECORED AND BI - BIG STORGE GOOD FOR DATA MANIPOLITON AND BI
DATA LAKE FOR  REVIEWS -GOOD FOR DIVERSE AND NOT ORGNIZED DATA "

------------------------------------------------------------------------------------------------------------------------------------------------------------------
