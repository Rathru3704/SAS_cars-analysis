/**********************************************************************
* Project: US Cars Market Analysis
* Author: Arthur
* Purpose: Showcase proficiency in SAS Data Step, PROC, ODS, data cleaning, statistical analysis, visualization, and reporting
***********************************************************************/

/***Load SASHELP.CARS dataset ***/
data cars;
    set sashelp.cars;
run;

/*** Explore dataset structure (output table in Results tab) ***/
/* Show column names, types, number of observations (i.e., rows) */
proc contents data=cars; 
run;
/* Print first 10 rows to understand data */
proc print data=cars(obs=10); 
run;

/*** Summary statistics for key variables ***/
proc means data=cars n mean median std min max;
	/* Numeric variables to analyze */
	/* Add suffix "n" to Weight variable name to avoid conflict with SAS reserved keywords */
	var Horsepower MPG_City MPG_Highway 'Weight'n; 
run;

/*** Frequency counts by categorical variables ***/
proc freq data=cars;
	/* Count observations per category */
	tables Type Origin Make;
run;

/*** Data cleaning and filtering (US cars) ***/
data us_cars;
	set cars;
	/* Keep US cars with horsepower > 200 */
	if Origin='USA' and Horsepower > 200;
run;

/*** Create Power_to_Weight and Efficiency_Rating derived variables (US cars) ***/
data us_cars;
	set us_cars;
	/* Horsepower to weight ratio */
	Power_to_Weight = Horsepower / Weight;
	/* Average fuel efficiency */
	Efficiency_Rating = (MPG_City + MPG_Highway)/2;
run;

/*** Categorize cars by horsepower tiers ***/
data us_cars;
	set us_cars;
	if Horsepower >= 400 then HP_Tier='High';
		else if Horsepower >= 300 then HP_Tier='Medium';
		else HP_Tier='Low';
	/*
	if condition then do;
		multiple statements
		...
		...
	*/
run;

/*** Compare US vs Non-US cars using t-test ***/
data cars_ttest;
	set cars;
	/* Create a binary variable: US vs Non-US */
	/* The PROC step cannot contain DATA step statements (if...then, set).*/
    if Origin = 'USA' then Origin_US = 'USA';
    else Origin_US = 'Non-USA';
run;

proc ttest data=cars_ttest;
	/* Group variable */
	/* The CLASS variable should only have two levels. */
	class Origin_US;
	/* Variables to test */
	var Horsepower Weight;
run;

/*** Correlation analysis (US cars) ***/
proc corr data=us_cars plots=matrix(histogram nvar=6);
	/* Variables for correlation */
	var Horsepower Weight MPG_City MPG_Highway Power_to_Weight;
run;

/*** Aggregated summary using PROC SQL (US cars) ***/
proc sql;
	create table car_summary as
	select Type,
		count(*) as Num_Cars,
		mean(Horsepower) as Avg_HP,
		mean(Weight) as Avg_Weight,
		mean(Efficiency_Rating) as Avg_Efficiency
	from us_cars
	group by Type;
quit;
/* SQL statement order (syntax)
SELECT ...
FROM ...
WHERE ... (Filter rows before grouping)
GROUP BY ...
HAVING ... (Filter groups after GROUP BY)
ORDER BY ...

Cooking analogy (logical execution order)
	1. FROM   → buy ingredients
	2. WHERE  → remove bad ones
	3. GROUP BY → sort into baskets
	4. HAVING → keep only good baskets
	5. SELECT → cook the dishes
	6. ORDER BY → plate nicely
*/

/*** Select top 5 cars by Power_to_Weight (US cars) ***/
/* outobs means OUTPUT OBSERVATIONS */
proc sql;
	title "Top 5 US Cars by Power-to-Weight Ratio";
	select Make, Model, Horsepower, Weight, Power_to_Weight
	from us_cars
	order by Power_to_Weight desc;
quit;

/*** Visualization using SGPLOT ***/
/* ODS (Output Delivery System) */
/* ods graphics on, enable automatic statistical graphics in SAS output */
ods graphics on;

/* Boxplot of Horsepower by Car Type (US cars) */
/* sgplot (Statistical Graphics Plot) */
proc sgplot data=us_cars;
	/* vbox (Vertical Box Plot) */
	/* vbox variable / category=group-var options; */
	vbox Horsepower / category=Type;
	title "Horsepower Distribution by Car Type";
run;

/* Scatter plot: Weight vs Horsepower by Type (US cars) */
proc sgplot data=us_cars;
	scatter x=Weight y=Horsepower / group=Type; 
	title "Weight vs Horsepower by Car Type";
run;

/* Histogram of Power to Weight ratio */
proc sgplot data=us_cars;
	histogram Power_to_Weight;
	/* Overlay a smooth probability density curve on top of the histogram */
	density Power_to_Weight;
	title "Distribution of Power to Weight Ratio";
run;

/* disable ODS Graphics to prevent further graph output */
ods graphics off;

/*** Create a report with PROC REPORT ***/
/* nowd: run in windowless mode (no interactive report window) */
proc report data=car_summary nowd;
    column Type Num_Cars Avg_HP Avg_Weight Avg_Efficiency;
	/* define: Control how each column is displayed */
	/* rows grouped by Type */
    define Type / group 'Car Type';
	/* Num_Cars / analysis: Calculate summary statistic (default = sum) */
    define Num_Cars / analysis 'Number of Cars';
    /* format=8.1 → total width 8, 1 decimal place */
    define Avg_HP / analysis format=8.1 'Average Horsepower';
    define Avg_Weight / analysis format=8.0 'Average Weight';
    define Avg_Efficiency / analysis format=5.1 'Avg Fuel Efficiency';
    title "Summary Report by Car Type";
run;

/*** Export HTML, and PDF reports ***/
ods html file="cars_report.html" style=statistical path="~/sasuser.v94";
/* style=journal is a built-in SAS style that produces a clean, publication-ready look */
ods pdf file="/home/u64319515/sasuser.v94/cars_report.pdf" style=journal;

title "US Cars Market Analysis Report";

/* Print summary table */
proc print data=car_summary;
    title "Summary Statistics by Car Type";
run;

/* Print top 10 cars by Power_to_Weight */
proc sort data=us_cars out=top10_cars;
    by descending Power_to_Weight;
run;

proc print data=top10_cars(obs=10);
    title "Top 10 US Cars by Power-to-Weight Ratio";
run;

ods html close;
ods pdf close;