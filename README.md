# Extract Data From MySQL

import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+pymysql://root:@localhost/olist_project"
)

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

print(df.head())



# Calculate Customer Revenue

customer_revenue = (
    df.groupby("customer_unique_id")["price"]
      .sum()
      .reset_index()
)

customer_revenue.rename(
    columns={"price":"total_spent"},
    inplace=True
)

print(customer_revenue.head())


# Create Customer Segments

def customer_segment(amount):

    if amount >= 154:
        return "High Value"

    elif amount >= 90:
        return "Medium Value"

    else:
        return "Low Value"


customer_revenue["segment"] = (
    customer_revenue["total_spent"]
    .apply(customer_segment)
)

# Merge Segment Back


master_df = pd.merge(
    df,
    customer_revenue[
        [
            "customer_unique_id",
            "segment"
        ]
    ],
    on="customer_unique_id",
    how="left"
)

print(master_df.head())


master_df.to_csv(
    "master_sales_dataset.csv",
    index=False
)

print("Master Dataset Created")