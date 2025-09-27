# 📘 סיכום SQL – דוגמאות, אסטרטגיות, וטיפים

---

## 🔍 Overlook – הצצה לטבלאות

```sql
SELECT * FROM public.categories
SELECT * FROM public.customers
SELECT * FROM public.employees
SELECT * FROM public.order_details
SELECT * FROM public.orders
SELECT * FROM public.products
SELECT * FROM public.shippers
SELECT * FROM public.suppliers
SELECT * FROM public.us_states
```

📌 **למה זה מועיל?**
פשוט – נותן לנו לראות את מבנה הטבלאות והמידע שיש בהן. שלב ראשון לפני כל שאלה זה להבין מה הנתונים.

---

## 🔗 String Concatenation

```sql
(EMP.first_name || ' ' || EMP.last_name) AS "Employes_name"
```

📌 **למה זה מועיל?**
מאפשר לאחד שדות טקסטיים (כמו שם פרטי + משפחה) לעמודה אחת קריאה וברורה.

---

## 🔗 Joins שימושיים

### 1. מוצרים להזמנות

```sql
FROM orders ORD
INNER JOIN order_details USING (order_id)
INNER JOIN products PRO USING (product_id)
```

📌 **מועיל**: מציג את ההזמנות עם המוצרים שהוזמנו.

---

### 2. מוצרים, הזמנות, ספקים וקטגוריות

```sql
FROM products PRO
LEFT JOIN order_details USING (product_id)
LEFT JOIN orders ORD USING (order_id)
LEFT JOIN suppliers SUP USING (supplier_id)
LEFT JOIN categories CAT USING (category_id)
```

📌 **מועיל**: נותן תמונה רחבה – מוצר, מי הספק, לאיזה קטגוריה שייך, ואילו הזמנות קשורות אליו.

---

### 3. מוצרים לקטגוריות

```sql
FROM products PRO
LEFT JOIN categories CAT USING (category_id)
```

📌 **מועיל**: מאפשר להבין אילו מוצרים משויכים לכל קטגוריה.

---

### 4. לקוחות להזמנות

```sql
FROM customers CUS
INNER JOIN orders ORD USING (customer_id)
```

📌 **מועיל**: קשר ישיר – מי הלקוחות ומה ההזמנות שלהם.

---

## 🧩 אסטרטגיות לפתרון שאלות

### ❓ מציאת מוצרים שמעולם לא הוזמנו ויקרים מהממוצע

📌 **מה לומדים?**
איך משלבים **Join** + **סינון עם Subquery** + תנאי `IS NULL` כדי למצוא פריטים שלא קיימים בטבלאות אחרות.

---

### ❓ ההזמנה האחרונה של כל לקוח

* **דרך 1:** `DISTINCT ON` + `ORDER BY`
* **דרך 2:** שימוש ב־`CTE` עם פונקציית חלון `ROW_NUMBER()`

📌 **מה לומדים?**
שתי טכניקות למציאת "האחרון/ראשון" לכל קבוצה – או בעזרת `DISTINCT ON` או בעזרת פונקציות חלון.

---

### ❓ פרוצדורה שבודקת פעילות עובד

```sql
CREATE OR REPLACE PROCEDURE pro_activity_stuff (n_staff_id int)
```

📌 **מה לומדים?**
איך להגדיר פרוצדורה ב־Postgres, להצהיר משתנה, לשמור לתוכו ערך מ־`SELECT`, ולעשות בדיקות תנאי.

---

### ❓ פונקציה שמחזירה את כל ההשכרות של לקוח

```sql
CREATE OR REPLACE FUNCTION fn_customer_rent3(n_customer_id int)
```

📌 **מה לומדים?**
איך ליצור פונקציה שמחזירה טבלה שלמה (`RETURNS TABLE`) עם מיון + טיפול במקרה שאין תוצאות (`IF NOT FOUND`).

---

### ❓ עובדים עם יותר מהממוצע הכללי

📌 **מה לומדים?**
שימוש ב־`CTE` כדי לחשב לכל עובד כמה עסקאות היו לו, ואז שימוש בפונקציות חלון (`RANK`) להשוואה מול אחרים.

---

### ❓ קטגוריות סרטים – ממוצע, הארוך והקצר ביותר

📌 **מה לומדים?**
איך להשתמש ב־Window Functions (`COUNT`, `AVG`, `RANK`) כדי לקבל נתונים מפורטים ברמת הקטגוריה, כולל כאלה שאין להן סרטים (באמצעות `LEFT JOIN`).

---

## 🧠 חלק תאורטי

### Primary Key vs Foreign Key

📌 **למה זה מועיל?**
מסביר את עקרונות המפתחות בדאטהבייס:

* PK מבטיח ייחודיות.
* FK שומר על קשרים בין טבלאות.
  זהו הבסיס לאמינות ושלמות הנתונים.

---

### סוגי בסיסי נתונים – סיכום

📌 **למה זה מועיל?**
מבינים מתי נכון להשתמש ב־Warehouse, Data Lake, RDB, או NoSQL, לפי הצורך (אנליטיקה, Big Data, אפליקציות טרנזקציוניות, סקייל).

---

## 💡 טיפים אחרונים

1. **SUM vs COUNT** –

   * `SUM`: מחשב סכום.
   * `COUNT`: סופר מופעים.
     📌 **מועיל**: להבין ההבדל בין סכימה לכמות.

2. **HAVING vs WHERE** –

   * `WHERE`: לפני אגרגציה.
   * `HAVING`: אחרי אגרגציה.
     📌 **מועיל**: לדעת באיזה שלב להשתמש בסינון.

3. **GROUP BY** –
   חובה כשיש גם עמודות רגילות וגם אגרגציות.
   📌 **מועיל**: כלי יסודי להבנה של איך מאגדים נתונים בקבוצות.
