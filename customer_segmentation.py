import pandas as pd
from sqlalchemy import create_engine

# engine = create_engine(
#     "mysql+pymysql://root:YOUR_PASSWORD@localhost/olist_project"
# )

engine = create_engine(
    "mysql+pymysql://root:@localhost/olist_project"
)
query = """
select 
		c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        price
from customers c
join orders o   
on c.customer_id = o.customer_id  
join order_items oi
on oi.order_id = o.order_id;
    
"""

df = pd.read_sql(query, engine)

# print(df)

print(df.shape)
print (df.info())
print(df.isnull().sum())
print(df.describe())


# Total Revenue
print("Total Revenue",df["price"].sum())

# Average order Value
print("Avgerage order value",df["price"].mean())

#Top 10 customer

top_customer = (
    df.groupby("customer_unique_id")["price"]
                 .sum()
                 .sort_values["price"]
                 .head(10)
                 )

print(top_customer)