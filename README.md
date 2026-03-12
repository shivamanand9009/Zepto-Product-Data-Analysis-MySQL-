# 🛒 Zepto Product Data Analysis — MySQL Project

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql&logoColor=white)
![Data](https://img.shields.io/badge/Records-3477%20Products-green)
![Categories](https://img.shields.io/badge/Categories-14-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A complete **SQL data analysis project** built on real Zepto grocery product data — covering schema design, CSV-based data loading, and 15 business insight queries.

---

## 📁 Project Structure

```
zepto-sql-analysis/
│
├── zepto_analysis.sql       # Main SQL file (schema + load + queries)
├── zepto_products.csv       # Cleaned & merged product dataset (3,477 rows)
└── README.md                # You are here
```

---

## 🗃️ Dataset

| File | Source | Rows |
|------|--------|------|
| `zepto_v1.xlsx` | Zepto product catalogue v1 | 3,732 |
| `zepto_v2.csv` | Zepto product catalogue v2 | 3,732 |
| `zepto_products.csv` | Merged + deduplicated | **3,477** |

### Columns

| Column | Description |
|--------|-------------|
| `Category` | Product category (14 total) |
| `name` | Product name |
| `mrp` | Maximum Retail Price (in paise) |
| `discountPercent` | Discount percentage offered |
| `discountedSellingPrice` | Final selling price (in paise) |
| `availableQuantity` | Units available in stock |
| `weightInGms` | Product weight in grams |
| `outOfStock` | TRUE / FALSE |
| `quantity` | Pack quantity |

### Categories Covered
`Fruits & Vegetables` · `Dairy, Bread & Batter` · `Beverages` · `Packaged Food` · `Munchies` · `Biscuits` · `Cooking Essentials` · `Meats, Fish & Eggs` · `Health & Hygiene` · `Personal Care` · `Home & Cleaning` · `Ice Cream & Desserts` · `Chocolates & Candies` · `Paan Corner`

---

## 🗄️ Database Schema

```
categories
    category_id (PK)
    name

products
    product_id (PK)
    name
    category_id (FK → categories)
    mrp
    discount_percent
    discounted_price
    available_qty
    weight_gms
    out_of_stock
    quantity
    savings_per_unit  ← Generated column (mrp - discounted_price)
```

---

## 🚀 How to Run

### Prerequisites
- MySQL 8.0+
- MySQL Workbench (recommended)

### Step 1 — Clone the repo
```bash
git clone https://github.com/your-username/zepto-sql-analysis.git
cd zepto-sql-analysis
```

### Step 2 — Find your secure file path
Run this inside MySQL Workbench:
```sql
SHOW VARIABLES LIKE 'secure_file_priv';
```

### Step 3 — Copy the CSV
Copy `zepto_products.csv` into the folder shown in Step 2.

**Windows example:**
```
C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\
```

### Step 4 — Update the path in SQL file
Open `zepto_analysis.sql` and update this line:
```sql
-- Change this:
LOAD DATA INFILE '/var/lib/mysql-files/zepto_products.csv'

-- To your path (Windows example):
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zepto_products.csv'
```
> ⚠️ Always use forward slashes `/` on Windows too

### Step 5 — Run in Workbench
- **File → Open SQL Script** → select `zepto_analysis.sql`
- Hit **Ctrl + Shift + Enter** to run the full script

### Step 6 — Verify
```sql
USE zepto_db;
SELECT COUNT(*) FROM products;    -- expects 3477
SELECT COUNT(*) FROM categories;  -- expects 14
```

---

## 📊 Analysis Queries (15 Total)

| # | Query | Concept Used |
|---|-------|-------------|
| Q1  | Category-wise product & stock count | GROUP BY, SUM |
| Q2  | Top 10 most discounted products | ORDER BY, LIMIT |
| Q3  | Average discount % by category | AVG, GROUP BY |
| Q4  | Out-of-stock rate per category | Conditional aggregation |
| Q5  | Price range buckets (Budget → Luxury) | CASE WHEN |
| Q6  | Best value deals (≥30% off, in stock) | WHERE + ORDER BY |
| Q7  | Heaviest products by weight | ORDER BY weight |
| Q8  | Best price-per-gram ratio | Arithmetic in SELECT |
| Q9  | Total potential savings vs MRP | SUM with available qty |
| Q10 | Discount distribution histogram | FLOOR + GROUP BY |
| Q11 | Fully stocked categories | HAVING |
| Q12 | Flash-sale deals (>50% off) | WHERE filter |
| Q13 | Most stocked category by units | SUM, ORDER BY |
| Q14 | Top 3 discounted per category | RANK() window function |
| Q15 | Executive summary dashboard | Scalar subqueries |

---

## 💡 Sample Query Output

```sql
-- Q3: Average Discount by Category
SELECT c.name, ROUND(AVG(p.discount_percent), 2) AS avg_discount
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY avg_discount DESC;
```

| Category | avg_discount |
|----------|-------------|
| Ice Cream & Desserts | 34.20% |
| Chocolates & Candies | 31.50% |
| Munchies | 28.40% |
| ... | ... |

---

## 🛠️ Tech Stack

- **Database:** MySQL 8.0
- **Tool:** MySQL Workbench
- **Data Format:** CSV + XLSX
- **Key Features:** Window functions, Generated columns, LOAD DATA INFILE

---

## 📌 Key Learnings

- Loading real-world CSV data using `LOAD DATA INFILE`
- Schema normalisation (raw staging table → clean relational tables)
- MySQL generated/computed columns (`savings_per_unit`)
- Window functions — `RANK() OVER (PARTITION BY ...)`
- Conditional aggregation with `SUM(condition)`
- Price-per-gram and value analysis on grocery data

---

## 🙋 Author

**Shivam Anand**
- GitHub: [@shivamanand9009](https://github.com/shivamanand9009)
- LinkedIn: [shivam-anand-649878228](https://linkedin.com/in/shivam-anand-649878228)
- Email: shivamanand9009@gmail.com

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
