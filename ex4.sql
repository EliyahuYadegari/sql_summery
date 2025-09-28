/*==================================================
1) Create table: film_audit (history of rental_rate changes)
Fields: audit_id (auto-increment PK), film_id, old_rate, new_rate, changed_at (DEFAULT now)
==================================================*/
CREATE TABLE IF NOT EXISTS public.film_audit (
  audit_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK אוטומטי מודרני
  film_id     INTEGER NOT NULL REFERENCES public.film(film_id) ON DELETE CASCADE,
  old_rate    NUMERIC(4,2) NOT NULL CHECK (old_rate >= 0),
  new_rate    NUMERIC(4,2) NOT NULL CHECK (new_rate >= 0),
  changed_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

/*==================================================
2) Update film: increase rental_rate by +0.5 for all films in category "Action"
==================================================*/
 UPDATE public.film AS f
SET    rental_rate = f.rental_rate + 0.5
FROM   public.film_category AS fc
JOIN   public.category       AS c  USING (category_id)
WHERE  fc.film_id = f.film_id
AND    c.name = 'Action';


/*==================================================
3) Trigger: on UPDATE of film.rental_rate insert row into film_audit with old/new values
(only when the value actually changes)
==================================================*/
-- TODO: write your CREATE FUNCTION (trigger) + CREATE TRIGGER here

CREATE OR REPLACE FUNCTION public.fn_film_rental_rate_audit() -- יצירה או החלפה של פונקציית טריגר. הפונקציה תחזיר אובייקט מסוג TRIGGER
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
-- התחלת גוף הפונקציה
BEGIN
  -- התנאי המרכזי: בודק אם הערך החדש (NEW) שונה מהערך הישן (OLD).
  --אולד וניו זה מילים שמורות מיוחדת  כשמדברים על טריגרים ב SQL
  -- השימוש ב-IS DISTINCT FROM הוא הדרך הנכונה והבטוחה להשוות ערכים ב-PostgreSQL,
  -- מכיוון שהוא מטפל נכון במקרה שאחד הערכים (או שניהם) הוא NULL.
  -- לדוגמה, NULL <> NULL מחזיר NULL, אך NULL IS NOT DISTINCT FROM NULL מחזיר TRUE.
  IF NEW.rental_rate IS DISTINCT FROM OLD.rental_rate THEN
    -- אם הערך אכן השתנה, הוסף שורה לטבלת הביקורת
    INSERT INTO public.film_audit(film_id, old_rental_rate, new_rental_rate, change_date)
    -- OLD ו-NEW הם רשומות מיוחדות המכילות את נתוני השורה לפני ואחרי השינוי
    VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate, NOW());
  END IF;

  -- בפונקציית טריגר מסוג AFTER, הערך המוחזר אינו משפיע על הפעולה,
  -- אך נהוג להחזיר את הרשומה החדשה (NEW).
  -- בפונקציית טריגר מסוג BEFORE, החזרת NEW מאשרת את המשך הפעולה.
  RETURN NEW;
-- סיום גוף הפונקציה
END;
$$;


-- מוחק את הטריגר הקיים (אם ישנו) לפני יצירת החדש.
-- זוהי פרקטיקה טובה לפיתוח כדי למנוע שגיאות בהרצה חוזרת של הסקריפט.
DROP TRIGGER IF EXISTS film_rental_rate_update_audit ON public.film;

-- יצירת הטריגר
CREATE TRIGGER film_rental_rate_update_audit
-- הגדרת התזמון: הטריגר יפעל "אחרי" שהעדכון בוצע בהצלחה
-- ורק אם העמודה "rental_rate" נכללה בפקודת ה-UPDATE.
-- זוהי אופטימיזציה שמונעת הרצה מיותרת של הטריגר אם עדכנו עמודה אחרת.
AFTER UPDATE OF rental_rate ON public.film
-- הגדרת רמת הפעולה: הטריגר יפעל פעם אחת "עבור כל שורה" שמושפעת מהעדכון.
-- זה הכרחי כדי שנוכל להשוות את הערכים הישנים והחדשים של כל שורה בנפרד.
FOR EACH ROW
-- הפעולה שיש לבצע: הפעלת פונקציית הטריגר שיצרנו בשלב הקודם.
EXECUTE FUNCTION public.fn_film_rental_rate_audit(); 

/*==================================================
4) Top 2 customers per city by number of rentals
Return: customer_name, city, number_of_rentals, rank_in_city
==================================================*/
 WITH rentals_per_customer AS (
  SELECT 
      c.customer_id,
      (c.first_name || ' ' || c.last_name) AS customer_name,
      ci.city,
      COUNT(r.rental_id) AS number_of_rentals
  FROM public.customer c
  JOIN public.rental  r  USING (customer_id)
  JOIN public.address a  USING (address_id)
  JOIN public.city    ci USING (city_id)
  GROUP BY c.customer_id, customer_name, ci.city
),
ranked AS (
  SELECT
      customer_name,
      city,
      number_of_rentals,
      ROW_NUMBER() OVER (
        PARTITION BY city 
        ORDER BY number_of_rentals DESC, customer_name, customer_id
      ) AS rn
  FROM rentals_per_customer
)
SELECT customer_name, city, number_of_rentals, rn AS rank_in_city
FROM ranked
WHERE rn <= 2
ORDER BY city, rn, customer_name;
 
/*==================================================
5) For each category: films count, avg rental_rate,
   longest film (title + length), shortest film (title + length)
==================================================*/
WITH CTE AS 
(SELECT  CAT.name,
 		 COUNT(F.film_id)OVER (PARTITION BY  CAT.name) AS CNT,
		 AVG(F.rental_rate)OVER(PARTITION BY CAT.name)AS AVRG,
		 F.title,
		 F.length,
		 RANK()OVER(PARTITION BY CAT.name ORDER BY  F.length DESC) AS LONGEST,
		 RANK()OVER(PARTITION BY CAT.name ORDER BY  F.length ASC) AS SHORTEST
FROM category CAT
LEFT JOIN film_category FC
USING(category_id)
LEFT JOIN film F
USING(film_id)
)
SELECT * FROM CTE
WHERE LONGEST<=2 OR SHORTEST <= 2
/*==================================================
6) Customers whose total payments > overall average total payments
Return: customer_name, total_payments, diff_from_overall_avg
==================================================*/
WITH CTE1 AS (
SELECT (c.first_name || ' ' || c.last_name) AS customer_name,
 		 SUM(P.amount) AS total_payments
 FROM public.payment P
 INNER JOIN public.customer C USING (customer_id)
 GROUP BY 1 
			),
 CTE2 AS (			
SELECT customer_name,
		total_payments,
		(SELECT AVG(total_payments) FROM CTE1 )  AS TOTAL_AVG
FROM CTE1
 )
 SELECT * 
 FROM CTE2 
 WHERE total_payments > TOTAL_AVG
/*==================================================
7) Stores with > 200 customers
Also return, per such store, the top customer by total payments (name + amount)
==================================================*/
 SELECT DISTINCT ON (q.store_id)
  q.store_id,
  q.customer_count,
  p.customer_name  AS top_customer_name,
  p.total_paid     AS top_customer_total_paid
FROM qualified_stores q
JOIN payments_per_customer p USING (store_id)
ORDER BY q.store_id, p.total_paid DESC, p.customer_name, p.customer_id;
--OR
WITH customers_per_store AS (
  SELECT store_id, COUNT(*) AS customer_count
  FROM public.customer
  GROUP BY store_id
),
qualified_stores AS (
  SELECT store_id, customer_count
  FROM customers_per_store
  WHERE customer_count > 200
),
payments_per_customer AS (
  SELECT 
      c.store_id,
      c.customer_id,
      (c.first_name || ' ' || c.last_name) AS customer_name,
      COALESCE(SUM(p.amount), 0) AS total_paid
  FROM public.customer AS c
  LEFT JOIN public.payment  AS p USING (customer_id)
  GROUP BY c.store_id, c.customer_id, customer_name
),
ranked AS (
  SELECT 
      q.store_id,
      q.customer_count,
      p.customer_name,
      p.total_paid,
      ROW_NUMBER() OVER (
        PARTITION BY q.store_id 
        ORDER BY p.total_paid DESC, p.customer_name, p.customer_id
      ) AS rn
  FROM qualified_stores AS q
  JOIN payments_per_customer AS p USING (store_id)
)
SELECT 
  store_id,
  customer_count,
  customer_name  AS top_customer_name,
  total_paid     AS top_customer_total_paid
FROM ranked
WHERE rn = 1
ORDER BY store_id;

