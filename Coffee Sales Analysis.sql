/* 	Author : Muhammad Raihan Dhaifullah
           : MSc Business Analytics 2026
           : Nanyang Technological University
*/   

/*1. How many product categories are there? For each product category, show the number of records.*/
SELECT 
	product_category, count(order_date) as count_no #to show the product_category and the count of it
FROM baristacoffeesalestbl 
GROUP BY product_category;

#The output shows 7 types of product category and the number of record in 'count_no' column

/*2*/
SELECT DISTINCT 
	customer_gender, loyalty_member, 
	COUNT(*) OVER (PARTITION BY customer_gender, loyalty_member) as records1, #make a column where it count for every row in the partition of customer_gender and loyalty_member only
	is_repeat_customer, 
	COUNT(*) OVER (PARTITION BY customer_gender, loyalty_member, is_repeat_customer) as records2 #make a column where it count for every row in the partition of customer_gender, loyalty_member and is_repeat_cutomer
FROM baristacoffeesalestbl 
ORDER BY customer_gender, is_repeat_customer DESC; #order to sort the column by customer_gender first, and then order is_repeat_customer with Descending order

# The output shows the count records within each unique combination of gender and loyalty status, and the cound of records within each unique combination of gender, loyalty status and repeating customer

/*3*/
/*A*/
SELECT 
	product_category, customer_discovery_source, 
    SUM(ROUND(convert(total_amount, decimal),0)) as sum_amt #sum for summarizing the total_amount, and converting the 'total_amount' to decimal type
FROM baristacoffeesalestbl
GROUP BY product_category, customer_discovery_source
ORDER BY product_category; #order to sort the column product_category. 

# the output shows the sum of amount based on the product_category and the customer discovery source

/*B*/
SELECT 
	product_category, customer_discovery_source, 
	SUM(total_amount) #sum for summarizing the total_amount
FROM baristacoffeesalestbl
GROUP BY product_category, customer_discovery_source #Grouping so the total_amount is aggregated by the group product_category and customer_discovery_source
ORDER BY product_category; #order to sort the column product_category

# The output is the same as before, but this time it is not rounded

/*4*/
SELECT
	IF(time_of_day_morning = 'True', 'morning', 
		IF(time_of_day_afternoon = 'True', 'afternoon', 'evening')) as time_of_day, #make a column where it depends on the time of day column with 'True' value
	IF(gender_male = 'True', 'male', 'female') as gender, #make a column where it depends on the gender whether it male or female
	FORMAT(AVG(ROUND(focus_level)),4) as avg_focus_level, FORMAT(AVG(ROUND(sleep_quality)),4) as avg_sleep_quality #make a column where it average from focus_level and also sleep_quality
FROM caffeine_intake_tracker
WHERE beverage_coffee = 'True' #filter the data so it only use where beverage_coffee is True
GROUP BY time_of_day, gender
ORDER BY CASE time_of_day #ORDER BY CASE to order as I want, in this case I want morning to be the first, afternoon, and then evening in the last.
	WHEN 'morning' THEN 1
	WHEN 'afternoon' THEN 2
	WHEN 'evening' THEN 3
	END, gender;
    
# The output is to find the average focus level and average sleep quality between each gender and each time the coffee is consumed

/*5*/
SELECT *
FROM list_coffee_shops_in_kota_bogor
WHERE url_id IN (
	SELECT url_id
	FROM list_coffee_shops_in_kota_bogor
	GROUP BY url_id 
	HAVING COUNT(*) >1) #this subquery used to find duplicate value in the 'url_id' column
ORDER BY url_id;

# The output listed all the duplicated value. 

/*6*/
SELECT
	CASE
		WHEN CAST(SUBSTRING(datetime, 1, 2) AS DECIMAL (8,2)) < 12 THEN "Before 12" #SUBSTRING function to find the first (1) character, and take two character (2) after the first char
        WHEN CAST(SUBSTRING(datetime, 1, 2) AS DECIMAL (8,2)) < 24 THEN "After 12" # Cast(X, AS UNSIGNED) function to make that X (the substring) to be a number type
        END AS period, ROUND(SUM(money),2) as amt
FROM coffeesales
WHERE CAST(SUBSTRING(datetime, 1, 2) AS UNSIGNED) BETWEEN 0 and 23 #since the data have hours like 48, which I think is an error, filter it so we only use hours between 0 - 23
GROUP BY period
ORDER by period DESC;

#The output is to find the total amount of money where it is groupped by the time, before 12 PM and after 12 PM

/*7*/
SELECT
	CASE
		WHEN pH LIKE "0%" THEN "0 to 1"
        WHEN pH LIKE "1%" THEN "1 to 2"
        WHEN pH LIKE "2%" THEN "2 to 3"
        WHEN pH LIKE "3%" THEN "3 to 4"
        WHEN pH LIKE "4%" THEN "4 to 5"
        WHEN pH LIKE "5%" THEN "5 to 6"
        WHEN pH LIKE "6%" THEN "6 to 7"
        ELSE "Invalid pH"
        END as pH_range, #create a column ph_range where the data depends on 'pH' value.
	ROUND(AVG(Liking),2) AS avgLiking, ROUND(AVG(FlavorIntensity),2) AS avgFlavorIntensity, 
	ROUND(AVG(Acidity),2) AS avgAcidity, ROUND(AVG(Mouthfeel),2) AS avgMouthfeel
FROM consumerpreference
GROUP BY pH_range
ORDER BY ph_range;

# The output is to find the pH ranges based on the first digit of the pH values and calculates average metrics for each range

/*8*/
SELECT trans_month, store_id, store_location, location_name, avg_agtron, trans_amt, total_money
FROM (
    SELECT
        (UPPER(DATE_FORMAT(STR_TO_DATE(c.`date`, '%d/%m/%Y'), '%b'))) AS trans_month, #Extract date from format dd/mm/yyyy, output is the initial month
		EXTRACT(MONTH FROM STR_TO_DATE(c.date, '%d/%m/%y')) AS month_no, #Convert trans_month to number for sorting
        b.store_id,
        MIN(b.store_location) AS store_location, #to avoid grouping, because the total_sales value would be different
        l.location_name,
        c.shopID,
        CAST(AVG(t.agtron) AS DECIMAL (18,6)) AS avg_agtron, 
        COUNT(*) AS trans_amt,
        ROUND(SUM(c.money),2) AS total_money,
        ROW_NUMBER() OVER (
			PARTITION BY (UPPER(DATE_FORMAT(STR_TO_DATE(c.`date`, '%d/%m/%Y'), '%b'))) 
            ORDER BY ROUND(SUM(c.money),2) DESC) as rn # OVER() to make a column where it ranked each row based on money for every month
    FROM coffeesales c
    JOIN `top-rated-coffee`t ON t.ID = c.coffeeID
    JOIN list_coffee_shops_in_kota_bogor l ON l.`no` = c.shopID
    JOIN baristacoffeesalestbl b ON SUBSTRING(b.customer_id, 6,8) = c.customer_id
    GROUP BY trans_month, month_no, b.store_id, c.shopID, l.location_name
    ORDER BY month_no, rn
) AS subquery
WHERE rn <= 3;

# The output is find the finds the top 3 highest-grossing coffee shops by total sales for each month.
