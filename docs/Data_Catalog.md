# 📚 Sales Data Mart - Data Catalog

Welcome to the Data Catalog for the **Sales Data Mart (Gold Layer)**. This document provides a comprehensive view of the Data Warehouse architecture, table schemas, data lineage, business rules, and field-level definitions to facilitate analytics, reporting, and data governance.

---

## 📐 Data Architecture Overview

The Sales Data Mart follows a **Star Schema** modeling approach within the `gold` schema layer. It consists of a central Fact Table surrounding two primary Dimension Tables.

<img width="776" height="713" alt="Data_Model of Gold LAyer" src="https://github.com/user-attachments/assets/bf5a78c7-6006-40a6-b8d6-a3372220a0af" />

---

## 📊 Entity Relationship & Grain Summary

| Table Name | Entity Type | Primary Key (PK) | Foreign Keys (FK) | Granularity / Grain |
| :--- | :--- | :--- | :--- | :--- |
| `gold.dim_customers` | Dimension | `customer_key` | None | One row per unique customer |
| `gold.dim_products` | Dimension | `product_key` | None | One row per unique product variant |
| `gold.fact_sales` | Fact | Composite / Implicit | `customer_key`, `product_key` | One row per order line item |

---

## 📋 Detailed Table Specifications

### 1. Table: `gold.dim_customers`

* **Description:** Contains master information about individual customers, including demographics, contact metadata, and geographical attributes.
* **Type:** Dimension Table (SCD Type 1)

| Column Name | Data Type | Key Type | Nullable | Description / Business Rules | Example Value |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `customer_key` | `INT` / `BIGINT` | **PK** | No | Surrogate key assigned to uniquely identify a customer record in Gold layer. | `1` |
| `customer_id` | `INT` | Natural | No | Business key from source system (CRM/ERP). | `11000` |
| `customer_number` | `VARCHAR(20)` | Business | No | Human-readable customer identification code. | `AW00011000` |
| `first_name` | `VARCHAR(50)` | - | Yes | Customer's given first name. | `Jon` |
| `last_name` | `VARCHAR(50)` | - | Yes | Customer's family name / surname. | `Yang` |
| `marital_status` | `VARCHAR(20)` | - | Yes | Marital status (`Married`, `Single`). | `Married` |
| `gender` | `VARCHAR(10)` | - | Yes | Gender classification (`Male`, `Female`). | `Male` |
| `birthdate` | `DATE` | - | Yes | Customer date of birth (`YYYY-MM-DD`). Used for age segmentation. | `1971-10-06` |
| `country` | `VARCHAR(50)` | - | Yes | Customer primary country of residence (`Australia`, `United States`, `Canada`). | `Australia` |
| `create_date` | `DATE` | Meta | No | Record load timestamp / effective creation date in Data Warehouse. | `2025-10-06` |

---

### 2. Table: `gold.dim_products`

* **Description:** Master catalog of products, categories, subcategories, cost structures, and product categorization lines.
* **Type:** Dimension Table (SCD Type 1)

| Column Name | Data Type | Key Type | Nullable | Description / Business Rules | Example Value |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `product_key` | `INT` / `BIGINT` | **PK** | No | Surrogate key assigned to uniquely identify a product record in Gold layer. | `1` |
| `product_id` | `VARCHAR(30)` | Natural | No | Natural code identifier from inventory system. | `BK_M82B_38` |
| `product_number` | `VARCHAR(50)` | Business | No | Full descriptive product display name with specifications. | `Mountain-100 Black- 38` |
| `category_id` | `VARCHAR(10)` | - | Yes | Internal category identifier code. | `BI_MB` |
| `category` | `VARCHAR(50)` | - | Yes | High-level product category (`Bikes`, `Accessories`, `Clothing`). | `Bikes` |
| `subcategory` | `VARCHAR(50)` | - | Yes | Specific product line grouping (`Mountain Bikes`, `Bottles and Cages`). | `Mountain Bikes` |
| `maintenance` | `VARCHAR(5)` | - | Yes | Indicates if maintenance service applies (`Yes`, `No`). | `Yes` |
| `cost` | `DECIMAL(10,2)` | - | No | Standard unit cost of the product. | `1898.00` |
| `product_line` | `VARCHAR(30)` | - | Yes | Target segment / line classification (`Mountain`, `Road`, `Touring`, `Other Sales`). | `Mountain` |
| `start_date` | `DATE` | Meta | No | Effective release/start date of product variant in catalog. | `2011-07-01` |

---

### 3. Table: `gold.fact_sales`

* **Description:** Transactional fact table capturing sales transactions, quantities, prices, and date dimensions for sales analytical measures.
* **Type:** Fact Table (Transactional)

| Column Name | Data Type | Key Type | Nullable | Description / Business Rules | Formula / Measure Type |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `order_number` | `VARCHAR(30)` | Business Key | No | Sales order transaction number. | Transaction Identifier |
| `product_key` | `INT` / `BIGINT` | **FK1** | No | References `gold.dim_products(product_key)`. | Foreign Key |
| `customer_key` | `INT` / `BIGINT` | **FK2** | No | References `gold.dim_customers(customer_key)`. | Foreign Key |
| `order_date` | `DATE` | Time FK | No | Date on which the transaction was placed. | Transaction Date |
| `shipping_date` | `DATE` | Time FK | Yes | Date on which order was fulfilled and shipped. | Logistics Milestone |
| `due_date` | `DATE` | Time FK | Yes | Date on which payment/fulfillment is due. | Financial Milestone |
| `sales_amount` | `DECIMAL(12,2)` | Measure | No | Total calculated revenue for line item. | **Formula:** `quantity * price` |
| `quantity` | `INT` | Measure | No | Number of units purchased in order line. | Additive Measure (`SUM`) |
| `price` | `DECIMAL(10,2)` | Measure | No | Unit selling price of product at transaction time. | Non-additive (`AVG` / `MIN` / `MAX`) |

---

## 📐 Calculated Measures & KPI Rules

```sql
-- Core Revenue Metric Calculation
Sales Amount = Quantity * Unit Price

-- Profitability Calculation
Total Cost = Quantity * Dim_Products.cost
Gross Profit = Sales Amount - Total Cost
Profit Margin % = (Gross Profit / Sales Amount) * 100
```

## 🔒 Data Quality & Validation Rules
1- Referential Integrity: Every customer_key and product_key in gold.fact_sales MUST map to an existing surrogate key in gold.dim_customers and gold.dim_products. Unknown/missing keys must map to a default surrogate key (e.g., -1 = N/A).

2- Numeric Constraints: quantity must be greater than 0 (quantity > 0).

3- Date Consistency: shipping_date >= order_date.

4- Uniqueness: customer_key in dim_customers and product_key in dim_products must be UNIQUE Primary Keys.

