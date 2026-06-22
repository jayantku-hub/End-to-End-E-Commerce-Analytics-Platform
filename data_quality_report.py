import pandas as pd
from sqlalchemy import create_engine

# ==========================================

# DATABASE CONNECTION

# ==========================================

engine = create_engine(
"mysql+pymysql://root:@localhost/olist_project"
)

# ==========================================

# EXTRACT DATA

# ==========================================

query = """
SELECT
c.customer_unique_id,
o.order_id,
o.order_purchase_timestamp,
oi.price
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
"""

df = pd.read_sql(query, engine)

print("Data Loaded Successfully")
print(df.head())

# ==========================================

# CONVERT DATE COLUMN

# ==========================================

df["order_purchase_timestamp"] = pd.to_datetime(
df["order_purchase_timestamp"]
)

# ==========================================

# REFERENCE DATE

# ==========================================

reference_date = df["order_purchase_timestamp"].max()

print("\nReference Date:")
print(reference_date)

# ==========================================

# CREATE RFM TABLE

# ==========================================

rfm = df.groupby(
"customer_unique_id"
).agg(
{
"order_purchase_timestamp": "max",
"order_id": "nunique",
"price": "sum"
}
).reset_index()

# ==========================================

# RENAME COLUMNS

# ==========================================

rfm.columns = [
"customer_id",
"last_purchase_date",
"frequency",
"monetary"
]

# ==========================================

# CALCULATE RECENCY

# ==========================================

rfm["recency"] = (
reference_date -
rfm["last_purchase_date"]
).dt.days

# ==========================================

# CREATE RFM SCORES

# ==========================================

rfm["R_score"] = pd.qcut(
rfm["recency"],
5,
labels=[5,4,3,2,1]
)

rfm["F_score"] = pd.qcut(
rfm["frequency"].rank(method="first"),
5,
labels=[1,2,3,4,5]
)

rfm["M_score"] = pd.qcut(
rfm["monetary"],
5,
labels=[1,2,3,4,5]
)

# ==========================================

# CONVERT TO INTEGER

# ==========================================

rfm["R_score"] = rfm["R_score"].astype(int)
rfm["F_score"] = rfm["F_score"].astype(int)
rfm["M_score"] = rfm["M_score"].astype(int)

# ==========================================

# RFM SCORE

# ==========================================

rfm["RFM_Score"] = (
rfm["R_score"].astype(str)
+ rfm["F_score"].astype(str)
+ rfm["M_score"].astype(str)
)

# ==========================================

# RFM TOTAL

# ==========================================

rfm["RFM_Total"] = (
rfm["R_score"]
+ rfm["F_score"]
+ rfm["M_score"]
)

# ==========================================

# CUSTOMER SEGMENTATION

# ==========================================

def segment_customer(row):

    score = row["RFM_Total"]

    if score >= 13:
        return "Champions"

    elif score >= 10:
        return "Loyal Customers"

    elif score >= 7:
        return "Potential Loyalists"

    elif score >= 4:
        return "Need Attention"

    else:
        return "At Risk"


rfm["segment"] = rfm.apply(
segment_customer,
axis=1
)

# ==========================================

# SEGMENT SUMMARY

# ==========================================

print("\nCustomer Segment Counts")
print(
rfm["segment"]
.value_counts()
)

print("\nRevenue By Segment")
print(
rfm.groupby("segment")
.agg({
"customer_id":"count",
"monetary":"sum"
})
.sort_values(
by="monetary",
ascending=False
)
)

# ==========================================

# TOP 10 CUSTOMERS

# ==========================================

print("\nTop 10 Customers")

print(
rfm[
[
"customer_id",
"frequency",
"monetary",
"segment"
]
]
.sort_values(
by="monetary",
ascending=False
)
.head(10)
)

# ==========================================

# EXPORT CSV

# ==========================================

rfm.to_csv(
"rfm_analysis2.csv",
index=False
)

print("\nRFM Analysis File Created Successfully")

# ==========================================

# FINAL OUTPUT

# ==========================================

print("\nColumns Available")

print(
rfm.columns.tolist()
)

print("\nSample Data")

print(
rfm.head()
)
