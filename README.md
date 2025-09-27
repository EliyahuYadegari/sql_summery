# 📘 סיכום SQL – Procedures, Functions, Triggers, Views, Window Functions, CTE

---

## 1. Procedure

🔹 קוד שמבצע פעולות (יכול להחזיר או לא להחזיר ערך).
🔹 יכול להכיל לוגיקה מורכבת, תנאים, לולאות, Insert/Update/Delete/Select.

**סינטקס:**

```sql
CREATE OR REPLACE PROCEDURE proc_name(param1 TYPE, param2 TYPE)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL statements
END;
$$;
```

**דוגמאות:**

```sql
-- Insert
CREATE OR REPLACE PROCEDURE add_customer(p_name TEXT, p_city TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO customers(name, city) VALUES(p_name, p_city);
END;
$$;

-- Update
CREATE OR REPLACE PROCEDURE update_city(p_id INT, p_city TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE customers SET city = p_city WHERE customer_id = p_id;
END;
$$;

-- Delete
CREATE OR REPLACE PROCEDURE delete_customer(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM customers WHERE customer_id = p_id;
END;
$$;

-- Select
CREATE OR REPLACE PROCEDURE show_customers()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Customer list:';
    PERFORM * FROM customers;
END;
$$;
```

---

## 2. Function

🔹 מחזירה ערך יחיד או טבלה.
🔹 שימוש עיקרי: חישובים והחזרת תוצאה.

**סינטקס:**

```sql
CREATE OR REPLACE FUNCTION func_name(param TYPE)
RETURNS return_type
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN ...;
END;
$$;
```

**דוגמא:**


```sql
-- For example
-- חישוב ממוצע הזמנות ללקוח
CREATE OR REPLACE FUNCTION avg_order_amount(cust_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE v_avg NUMERIC;
BEGIN
    SELECT AVG(amount) INTO v_avg
    FROM orders WHERE customer_id = cust_id;
    RETURN v_avg;
END;
$$;
```

---

## 3. Trigger

🔹 מופעל אוטומטית בעקבות אירוע בטבלה (INSERT/UPDATE/DELETE).
🔹 מתאים ללוגים, בדיקות תנאים, שמירה על עקביות.

**סינטקס:**

```sql
CREATE OR REPLACE FUNCTION trigger_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Action
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_name
AFTER INSERT OR UPDATE OR DELETE ON table_name
FOR EACH ROW
EXECUTE FUNCTION trigger_func();
```

**דוגמאות:**

```sql
-- For example
-- לוג על עדכון
CREATE OR REPLACE FUNCTION log_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO logs(table_name, action_time)
    VALUES('customers', NOW());
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_update
AFTER UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION log_update();

-- בדיקת תנאים לפני Insert
CREATE OR REPLACE FUNCTION check_salary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.salary < 0 THEN
        RAISE EXCEPTION 'Salary cannot be negative';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_salary
BEFORE INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION check_salary();
```

---

## 4. View

🔹 שאילתה שמורה שמחזירה תוצאה כמו טבלה.
🔹 שימושי לקריאות קוד ושימוש חוזר.

**סינטקס:**

```sql
CREATE OR REPLACE VIEW view_name AS
SELECT ...
FROM ...
WHERE ...;
```

**דוגמאות:**

```sql
-- For example
-- לקוחות מתל אביב
CREATE OR REPLACE VIEW tel_aviv_customers AS
SELECT customer_id, name
FROM customers
WHERE city = 'Tel Aviv';

-- הכנסות פר קטגוריה
CREATE OR REPLACE VIEW revenue_per_category AS
SELECT c.category_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p USING(product_id)
JOIN categories c USING(category_id)
GROUP BY c.category_name;
```

---

## 5. Window Functions

🔹 מבצעות חישובים על "חלון" של שורות בלי לאבד את הפירוט.
🔹 שימוש עיקרי: דירוגים, מצטברים, גישה לשורות קודמות/באות.

**סינטקס כללי:**

```sql
function() OVER (
    PARTITION BY col
    ORDER BY col
)
```

### סוגים עיקריים:

1. **ROW_NUMBER()** – מספר רץ לכל שורה.

```sql
SELECT product_name,
       ROW_NUMBER() OVER(ORDER BY price DESC) AS row_num
FROM products;
```

2. **RANK()** – דירוג עם דילוגים בשוויון.
3. **DENSE_RANK()** – דירוג בלי דילוגים.

```sql
SELECT product_name, price,
       RANK() OVER(ORDER BY price DESC) AS rnk,
       DENSE_RANK() OVER(ORDER BY price DESC) AS dense_rnk
FROM products;
```

4. **LAG() / LEAD()** – גישה לערך מהשורה הקודמת/הבאה.

```sql
SELECT order_id, amount,
       LAG(amount) OVER(ORDER BY order_date) AS prev_order,
       LEAD(amount) OVER(ORDER BY order_date) AS next_order
FROM orders;
```

5. **NTILE(n)** – חלוקה ל־n קבוצות שוות.

```sql
SELECT product_name, price,
       NTILE(4) OVER(ORDER BY price) AS quartile
FROM products;
```

---

## 6. CTE (Common Table Expression)

🔹 "טבלה זמנית" בתוך שאילתה, משפרת קריאות ושימוש חוזר.

**סינטקס:**

```sql
WITH cte_name AS (
    SELECT ...
    FROM ...
)
SELECT *
FROM cte_name;
```

**דוגמאות:**

```sql
-- For example
-- לקוחות מתל אביב
WITH tel_aviv_customers AS (
    SELECT * FROM customers WHERE city = 'Tel Aviv'
)
SELECT * FROM tel_aviv_customers;

-- שני המוצרים הזולים ביותר בכל קטגוריה
WITH ranked_products AS (
    SELECT category_id, product_name, unit_price,
           ROW_NUMBER() OVER(PARTITION BY category_id ORDER BY unit_price ASC) AS rn
    FROM products
)
SELECT * FROM ranked_products WHERE rn <= 2;
```

---

## 7. טבלת השוואה

| כלי             | מחזיר ערך?      | שינוי נתונים? | מופעל ע"י      | שימוש עיקרי                      |
| --------------- | --------------- | ------------- | -------------- | -------------------------------- |
| **Procedure**   | לא חובה         | כן            | קריאה ישירה    | פעולות CRUD מורכבות              |
| **Function**    | כן              | לא            | קריאה ישירה    | חישובים והחזרת ערך               |
| **Trigger**     | לא              | כן/לא         | אירוע בטבלה    | לוגים, בדיקות תנאים              |
| **View**        | כן (טבלה)       | לא            | קריאה כמו טבלה | קריאות קוד, שאילתה שמורה         |
| **Window Func** | כן              | לא            | חלק מ־SELECT   | דירוגים, מצטברים, גישה בין שורות |
| **CTE**         | כן (טבלה זמנית) | לא            | חלק מ־SELECT   | ארגון קוד, שימוש חוזר            |
