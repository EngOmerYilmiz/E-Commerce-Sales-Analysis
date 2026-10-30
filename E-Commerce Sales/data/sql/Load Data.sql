  PART 2: LOAD THE CSV FILES
  - Change the folder path. The SQL Server SERVICE must be able to read it.
  - If a load fails, use the wizard instead: right-click e_commerce ->
    Tasks -> Import Flat File (map to the existing table).
  - If dates are dd/mm/yyyy, run:  SET DATEFORMAT dmy;  before the load.
  - If rate columns contain '%' symbols, import dataset_statistics via the wizard
    and convert the columns manually.
==============================================================================*/
BULK INSERT  customer_master
FROM 'C:\EcommerceProject\customer_master.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  product_catalog
FROM 'C:\EcommerceProject\product_catalog.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  ecommerce_sales_customer
FROM 'C:\EcommerceProject\ecommerce_sales_customer.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  order_items
FROM 'C:\EcommerceProject\order_items.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  dataset_statistics
FROM 'C:\EcommerceProject\dataset_statistics.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);
GO
