import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+pymysql://root:@localhost/olist_project"
)

query = """
SELECT
    c.customer_unique_id,
    ROUND(SUM(oi.price),2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
"""

df = pd.read_sql(query, engine)

print(df.head())


# Understand the Data

print(df["total_spent"].describe())


def customer_segment(amount):

    if amount >= 154:
        return "High Value"

    elif amount >= 90:
        return "Medium Value"

    else:
        return "Low Value"
    

df["segment"] = df["total_spent"].apply(customer_segment)

# Check Segment Counts

print(df["segment"].value_counts())

# Revenue by Segment

segment_summary = df.groupby("segment")["total_spent"].sum()

print(segment_summary)

df.to_csv(
    "customer_segments.csv",
    index=False
)

print(df["segment"].value_counts())


