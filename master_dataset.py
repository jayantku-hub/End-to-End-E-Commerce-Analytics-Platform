import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+pymysql://root:@localhost/olist_project"
)

products = pd.read_sql(
    "SELECT * FROM products",
    engine
)

print(products.head())

print("Rows and Columns")
print(products.shape)

print("\nData Types")
print(products.dtypes)

print("\nMissing Values")
print(products.isnull().sum())

print("\nDuplicate Rows")
print(products.duplicated().sum())


# Create Reusable Function

def data_quality_report(df, table_name):

    print("\n" + "="*50)
    print(f"TABLE : {table_name}")
    print("="*50)

    print("Shape :", df.shape)

    print("\nMissing Values")
    print(df.isnull().sum())

    print("\nDuplicate Rows")
    print(df.duplicated().sum())

    print("\nData Types")
    print(df.dtypes)


customers = pd.read_sql(
    "SELECT * FROM customers",
    engine
)

orders = pd.read_sql(
    "SELECT * FROM orders",
    engine
)

products = pd.read_sql(
    "SELECT * FROM products",
    engine
)

data_quality_report(customers, "customers")
data_quality_report(orders, "orders")
data_quality_report(products, "products")    


summary = []

tables = {
    "customers": customers,
    "orders": orders,
    "products": products
}

for name, df in tables.items():

    summary.append({
        "Table": name,
        "Rows": df.shape[0],
        "Columns": df.shape[1],
        "Null Values": df.isnull().sum().sum(),
        "Duplicate Rows": df.duplicated().sum()
    })

report = pd.DataFrame(summary)

print(report)


report.to_excel(
    "data_quality_report.xlsx",
    index=False
)

print("Report Saved Successfully")