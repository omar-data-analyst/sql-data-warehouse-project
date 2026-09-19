# 📊 Data Warehouse Pipeline By SQL

<img width="1376" height="768" alt="Gemini_Generated_Image_3aadla3aadla3aad" src="https://github.com/user-attachments/assets/f02d4d31-2720-4432-a5a1-3fd99a15fc11" />

---

## 📌 Project Overview
This project demonstrates the design and implementation of an End-to-End Data Warehouse using **SQL** following the **Medallion Architecture (Bronze, Silver, Gold)**. 

The pipeline ingests raw data from multiple source systems (**CRM** and **ERP**), cleanses and transforms it, and loads it into a dimensional **Star Schema** optimized for analytical querying and reporting.

---

## 🏗️ Architecture & Data Flow

The data flows through three distinct layers, processing data from CRM and ERP sources into business-ready analytical structures:

<img width="1025" height="573" alt="Data Flow Diagram" src="https://github.com/user-attachments/assets/4b9a5df2-516e-4348-9105-4c99cdefc817" />


### Data Processing Layers:
1. **Source Systems (Data Resources):**
   * **CRM System:** `crm_cust_info`, `crm_prd_info`, `crm_sales_details`
   * **ERP System:** `erp_CUST_AZ12`, `erp_LOC_A101`, `erp_PX_CAT_G1V2`
2. **Bronze Layer (Raw Ingestion):**
   * Stores raw, unmodified data ingested directly from CRM and ERP sources via SQL load scripts.
3. **Silver Layer (Cleansing & Standardization):**
   * Applies data cleansing, handles null values, standardizes data types, and aligns schemas.
4. **Gold Layer (Dimensional Data Model):**
   * Integrates Silver tables into a Star Schema (`dim_customers`, `dim_products`, `fact_sales`) ready for BI dashboards and reporting.

---

## 📐 Gold Layer Data Model (Star Schema)

The final analytics layer is structured as a **Star Schema** to optimize query performance and simplify analytics:

<img width="776" height="713" alt="Data_Model of Gold Layer" src="https://github.com/user-attachments/assets/f1d4181a-7cfa-4b21-abd3-6e5e3ceda603" />


### Entities & Relationships:
* **`dim_customers`**: Consolidated customer dimension built from CRM customer info and ERP location/demographics data.
* **`dim_products`**: Product dimension integrating product info and ERP category mappings.
* **`fact_sales`**: Fact table recording transactions with keys linking to dimensions. Calculated metrics include `sales_amount = price * quantity`.

---

## 📁 Repository Structure

```text
├── docs/
│   ├── assets/
│   │   └── header_banner.png
│   └── diagrams/
│       ├── data_flow.png
│       ├── data_flow.drawio
│       ├── data_model.png
│       └── data_model.drawio
├── scripts/
│   ├── bronze/
│   │   └── ddl_bronze.sql
│   ├── silver/
│   │   └── proc_load_silver.sql
│   └── gold/
│       └── ddl_gold.sql
└── README.md
