use Supermarket2;
select* from Calendar;
select* from Products;
select* from Regions;
select* from Transactions;
select* from Returns;
select* from Stores;


--Duplicates?

select count(distinct customer_acct_num) as distinct_count,
		count(*) as count
from ..Customers;

select count(distinct product_name) as distinct_count,
		count(*) as count
from Products;

select count(distinct store_name) as distinct_count,
		count(*) as count
from Stores;

-- region_id from Regions dimension table vs region_id from Stores dimension table: 
-- there are many unreferenced region_id --> we only want those from Stores table
select* from Regions;
select* from Stores;

create view region as(
select
	Regions.region_id ,Regions.sales_district, Regions.sales_region
from Stores
join Regions
	on Stores.region_id=Regions.region_id)

select* into Regions2 from region;
select* from Stores order by region_id;
select* from Regions2;

-- We see there is a duplicate in region_id 25 from Regions table
with region_id_duplicate as(
	select*, ROW_NUMBER() over(partition by region_id order by region_id) as row_num
	from Regions2
)
delete from region_id_duplicate where row_num > 1;
select* from Regions2; -- no more duplicates

-- Customers table
-- 1. Interesting questions:
	-- a. Is there a relationship between the number of children each family has and the type of product they buy?
	-- b. Do members with a Golden or Silver member card buy more and which products do they buy?
	-- c. What type of products do people with high, medium or low income buy?

-- Let's unify all transactions into one table
create view unify_transactions as(
	select* from Transactions_1997
	union all
	select* from Transactions_1998
)
select* into Transactions from unify_transactions;
select* from Transactions;



-- We won't need the product sku, if it is recyclable or low fat. However we could answer some cool stuff like 'If a product is recyclable, does it get more sales?'
alter table Products drop column product_sku, product_weight, recyclable, low_fat;
select* from Products;

-- We do not have a primary key in the Returns table so we must generate one
alter table Returns add  return_id int identity(1,1);
alter table Returns add primary key(return_id);
select* from Returns;
-- Same with Transactions
alter table Transactions add  trans_id int identity(1,1);
alter table Transactions add primary key(trans_id);
select* from Transactions;

-- Total transactions by product brand
create view transactions_by_product_brand as (
	select Products.product_brand, count(Transactions.trans_id) as total_transactions
	from Transactions
	left join Products
		on Products.product_id=Transactions.product_id
	group by Products.product_brand
)

select* from transactions_by_product_brand order by total_transactions desc;

-- Total profit by product brand
select* from Transactions;
select* from Products;

create view profit_by_product_brand as (
	select Products.product_brand, SUM(Transactions.quantity*(Products.product_retail_price-Products.product_cost)) as total_profit
	from Transactions
	left join Products
		on Products.product_id=Transactions.product_id
	group by Products.product_brand
)
select* from profit_by_product_brand order by total_profit desc;

-- Return rate by product_brand
select* from Returns;
select* from Products;
select* from Transactions;

create view returns_by_product_brand as (
	select id int, Products.product_brand, ((SUM(Returns.quantity))/(SUM(Transactions.quantity)))*100 as return_rate
	from Transactions
	left join Returns
		on Returns.product_id=Transactions.product_id
	left join Products
		on Products.product_id=Transactions.product_id
	group by Products.product_brand
)

