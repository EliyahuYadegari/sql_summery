
````markdown
# SQL – סיכום למבחן

סיכום זה מכסה את הפקודות החשובות ביותר ב-SQL, עם דגש על **DDL, DML**, יצירת ומחיקת טבלאות.

---

## 1️⃣ סוגי פקודות SQL

### **1. DDL – Data Definition Language**
פקודות שמגדירות ומנהלות את מבנה בסיס הנתונים (טבלאות, אינדקסים וכו').

| פקודה | מה היא עושה |
|--------|--------------|
| `CREATE TABLE` | יוצרת טבלה חדשה |
| `ALTER TABLE`  | משנה מבנה של טבלה קיימת |
| `DROP TABLE`   | מוחקת טבלה מהמסד |
| `TRUNCATE TABLE` | מוחקת את כל הנתונים בטבלה בלי למחוק את הטבלה עצמה |
| `CREATE INDEX` | יוצר אינדקס לשיפור ביצועים |

**דוגמה ליצירת טבלה:**
```sql
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT,
    grade CHAR(1)
);
````

**שינוי טבלה – הוספת עמודה:**

```sql
ALTER TABLE Students
ADD COLUMN email VARCHAR(100);
```

**מחיקת טבלה:**

```sql
DROP TABLE Students;
```

**ניקוי כל הנתונים בטבלה (בלי למחוק את הטבלה):**

```sql
TRUNCATE TABLE Students;
```

---

### **2. DML – Data Manipulation Language**

פקודות שמנהלות את הנתונים בתוך הטבלאות.

| פקודה         | מה היא עושה        |
| ------------- | ------------------ |
| `INSERT INTO` | מכניס שורות חדשות  |
| `UPDATE`      | משנה נתונים קיימים |
| `DELETE`      | מוחק נתונים קיימים |
| `SELECT`      | שולף נתונים        |

**דוגמאות שימוש:**

* **הכנסת שורה חדשה:**

```sql
INSERT INTO Students (student_id, name, age, grade)
VALUES (1, 'Eliyahu', 22, 'A');
```

* **עדכון נתון:**

```sql
UPDATE Students
SET grade = 'B'
WHERE student_id = 1;
```

* **מחיקת שורה:**

```sql
DELETE FROM Students
WHERE student_id = 1;
```

* **שאילתת SELECT:**

```sql
SELECT name, grade
FROM Students
WHERE age > 20;
```

---

## 2️⃣ מפתחות וקשרים בטבלאות

* **Primary Key (PK)** – מזהה ייחודי לכל שורה בטבלה.
* **Foreign Key (FK)** – מחבר בין שתי טבלאות ומצביע על PK בטבלה אחרת.

### סוגי קשרים בין טבלאות:

* **1:1** – שורה אחת בטבלה אחת מתאימה לשורה אחת בטבלה אחרת.
* **1:N** – שורה אחת בטבלה אחת יכולה להיות קשורה להרבה שורות בטבלה אחרת.
* **M:N** – קשר הרבה-לרבה, דורש טבלה ביניים.

---

## 3️⃣ דגשים חשובים

1. **DDL משנה מבנה**, לא את הנתונים עצמם.
2. **DML מנהל נתונים**, לא את מבנה הטבלה.
3. תמיד להשתמש ב-`WHERE` ב-`UPDATE` ו-`DELETE` כדי למנוע שינוי/מחיקה של כל הנתונים.
4. `CREATE TABLE` – תמיד מגדירים סוגי עמודות ויכולות כמו `PRIMARY KEY`, `NOT NULL`.
5. `INSERT INTO` – חייב להתאים לעמודות שהוגדרו בטבלה.


