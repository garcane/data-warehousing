USE DW_Superstore_Code
GO
--
-- Make sure all the tables contain correct number of records:
--
SELECT COUNT(*) FROM SuperstoreStaging -- must be 9994
SELECT COUNT(*) FROM dimCustomer       -- must be 794
SELECT COUNT(*) FROM dimProduct        -- must be 1894
SELECT COUNT(*) FROM dimShipMode       -- must be 4
SELECT COUNT(*) FROM dimGeog           -- must be 632
SELECT COUNT(*) FROM dimDate           -- must be 1461 
SELECT COUNT(*) FROM FACTOrderItem     -- must be 9994



TASK 1
	Write a query that returns total quantity of products sold, and total sales amount,
	summarised by customer name, region, state, city and quarter
	Solve the task using two different appraches:
	a)	Retrieving from DW (table FACTS and dim table(s) if needed)
	b)	Retrieving from SuperstoreStaging table ONLY
	Save Query 1a as Cube1

	


TASK 2
	Write a query that returns total quantity of products sold, and total sales amount,
	summarised by week, product category, customer segment and region
	Hint: you are expected to get 3856 records
	Solve the task using two different appraches:
	a)	Retrieving from DW (table FACTS and dim table(s) if needed)
	b)	Retrieving from SuperstoreStaging table ONLY
	Save Query 2a as Cube2




TASK 3
	Write a query that returns total quantity of products sold, and total sales amount,
	summarised by product categories across all the years
	Hint: you are expected to get 12 records
	Solve the task using three different approaches:
	a)	Retrieving from DW (table FACTS and dim table(s) if needed)
	b)	Retrieving from SuperstoreStaging table ONLY
	c)	Retrieving from the previous cube(s) only
	Compare results of all three queries 3a, 3b, 3c (they must match of course)
	Save Query 3с as Cube3

	


	So, you are expected to produce 7 queries (or as many as you can),
	and 3 of those would be saved as views (named Cube1, Cube2, Cube3)
