create database cosmetic;

show variables like "secure_file_priv";

select * from cosmetics_sales_data limit 10;

select
	country,
    count(*) as Kota
from cosmetics_sales_data
group by Country
order by Kota DESC 
limit 10;

select
	country,
    sum(`amount ($)`) as Revenue
from cosmetics_sales_data
group by country
order by Revenue DESC
limit 10;

select 
	`sales person`,
    sum(`amount ($)`) as Revenue
from cosmetics_sales_data
group by `sales person`
order by Revenue DESC;

select 
	product,
    sum(`Boxes Shipped`) as Total_Terjual
from cosmetics_sales_data
group by product
order by Total_Terjual DESC;

select
	product,
    sum(`boxes shipped`) as Pengiriman,
    sum(`amount ($)`) as Revenue
from cosmetics_sales_data
group by product
order by Revenue DESC;

select
	sum(`amount ($)`) as Total_Revenue,
    sum(`boxes shipped`) as Total_Pengiriman,
    round(sum(`amount ($)`) / sum(`boxes shipped`), 2) as Average_Price_per_Box,
    count(distinct country) as Actice_Markets,
    count(distinct product) as Total_Product_lines
from cosmetics_sales_data;

select
	country,
    sum(`amount ($)`) as Country_Revenue,
    sum(`boxes shipped`) as Country_Boxes_Sold,
    round((sum(`amount ($)`) / (select sum(`amount ($)`) from cosmetics_sales_data)) *100,2) as Revenue_Countribution_Percentage
    from cosmetics_sales_data
    group by country
    order by Country_Revenue DESC;

select
	product,
    sum(`amount ($)`) as Revenue,
    sum(`boxes shipped`) as Sold,
    round(avg(`amount ($)`), 2) as Average_Transaction_Value
from cosmetics_sales_data
group by Product
order by Revenue DESC;

select
	`sales person`,
    count(*) as Total_Transaction,
    sum(`boxes shipped`) as Total_Box_Shipped,
    sum(`amount ($)`) as Total_Revenue,
    round(sum(`amount ($)`) / sum(`boxes shipped`), 2) as Revenue_per_Box
from cosmetics_sales_data
group by `sales person`
order by Total_Revenue DESC;

SELECT 
    Product,
    SUM(`Boxes Shipped`) AS Total_Volume_Box,
    SUM(`Amount ($)`) AS Total_Revenue,
    -- Metrik Kunci Operasional: Berapa dolar yang dihasilkan dari SETIAP 1 BOX yang dikirim
    ROUND(SUM(`Amount ($)`) / SUM(`Boxes Shipped`), 2) AS Value_Density_Per_Box
FROM cosmetics_sales_data
GROUP BY Product
ORDER BY Value_Density_Per_Box DESC;

create or replace view Master_Cosmetics_Data as 
select
	`sales Person`,
    Country,
    Product,
    str_to_date(`date`, '%Y-%m-%d') as order_date,
    year(str_to_date(`date`, '%Y-%m-%d')) as order_year,
    monthname(str_to_date(`date`, '%Y-%m-%d')) as order_month,
    month(str_to_date(`date`, '%Y-%m-%d')) as month_number,
    `Boxes shipped` as boxes_shipped,
    `amount ($)` as Revenue,
    1 as Transaction_Count
from cosmetics_sales_data
where `sales person` is not null and `sales person` !='';

select * from Master_Cosmetics_Data;

-- 1. Hapus prosedur lama jika ada agar tidak bentrok
DROP PROCEDURE IF EXISTS sp_sync_cosmetics_data;

DELIMITER //

-- 2. Buat Prosedur Otomatisasi Baru
CREATE PROCEDURE sp_sync_cosmetics_data()
BEGIN
    -- Matikan safe updates agar bisa melakukan pembersihan massal
    SET sql_safe_updates = 0;

    -- TAHAP 1: DATA CLEANING (Pembersihan Otomatis)
    -- Menghapus baris yang kosong atau tidak sengaja ter-import (Clean up nulls)
    DELETE FROM cosmetics_sales_data 
    WHERE `Sales Person` IS NULL 
       OR `Sales Person` = '' 
       OR `Amount ($)` IS NULL;

    -- Merapikan spasi berlebih di ujung teks agar grup data di Power BI tidak pecah
    UPDATE cosmetics_sales_data
    SET 
        `Sales Person` = TRIM(`Sales Person`),
        Country = TRIM(Country),
        Product = TRIM(Product);

    -- Hidupkan kembali safe updates demi keamanan database
    SET sql_safe_updates = 1;


    -- TAHAP 2: VALIDASI DATA (Laporan Langsung)
    -- Menampilkan jumlah baris saat ini setelah dibersihkan
    SELECT COUNT(*) AS total_clean_rows_in_database FROM cosmetics_sales_data;


    -- TAHAP 3: ANALISIS RINGKAS OPERASIONAL (Quick Insight)
    -- Otomatis memunculkan performa penjualan terbaru setelah data masuk
    SELECT 
        Country,
        SUM(`Amount ($)`) AS total_revenue,
        SUM(`Boxes Shipped`) AS total_boxes_shipped
    FROM cosmetics_sales_data
    GROUP BY Country
    ORDER BY total_revenue DESC;

    -- Pesan penutup penanda sukses
    SELECT 'SUCCESS: Cosmetics Data Pipeline Refreshed! Open Power BI and click Refresh.' AS Automation_Status;

END //

DELIMITER ;