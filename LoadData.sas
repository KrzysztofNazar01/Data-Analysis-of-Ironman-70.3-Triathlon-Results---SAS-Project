* Krzysztof Nazar 26/06/2023;
* OTH ZADA Project Part 1;
* Load data from files;

* Import Gross Domestic Product of countries dataset;
/* proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_NY.GDP.MKTP.CD_DS2_en_excel_v2_5551619_edited.xls' */
/* 	dbms=xls out=countr_gdp replace; */
/* 	range='Data$A4:BN270'; */

/* * Keep and format only valuable columns; */
/* data countr_gdp_formatted; */
/* 	set countr_gdp (keep = 'Country Name'n 'Country Code'n '2017'n '2018'n '2019'n); */
/* 	format '2017'n '2018'n '2019'n DOLLAR20.2; */
/* run; */
/*   */
/* proc contents data=countr_gdp_formatted; */
/* proc print data=countr_gdp_formatted; */
/* 	title 'Output Dataset: countr_gdp_formatted'; */
/* run; */

* Import Population of countries dataset;
/* proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_SP.POP.TOTL_DS2_en_excel_v2_5551740_edited.xls' */
/* 	dbms=xls out=countr_pop replace; */
/* 	range='Data$A4:BN270'; */

/* * Keep and format only valuable columns; */
/* data countr_pop_formatted; */
/* 	set countr_pop (keep = 'Country Name'n 'Country Code'n '2017'n '2018'n '2019'n); */
/* 	format '2017'n '2018'n '2019'n 12.; */
/* run; */
/*   */
/* proc contents data=countr_pop_formatted; */
/* proc print data=countr_pop_formatted; */
/* 	title 'Output Dataset: countr_pop_formatted'; */
/* run; */

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2019_results_0.csv'
	dbms=csv out=results_2019 replace;
	delimiter=',';
	getnames=yes;
	
* Keep and format only valuable columns;
data results_2019_formatted;
	set results_2019(drop=name bib);
	where 'Finish status'n = "Finisher";
run;

/* proc contents data=results_2019; */
/* proc print data=results_2019; */
/* 	title 'Output Dataset: results_2019'; */
/* run; */

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2018_results_0.csv'
	dbms=csv out=results_2018 replace;
	delimiter=',';
	getnames=yes;
* Keep and format only valuable columns;
data results_2018_formatted;
	set results_2018(drop=name bib);
	where 'Finish status'n = "Finisher";
run;
/* proc contents data=results_2018; */
/* proc print data=results_2018; */
/* 	title 'Output Dataset: results_2018'; */
/* run; */

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2017_results_0.csv'
	dbms=csv out=results_2017 replace;
	delimiter=',';
	getnames=yes;
	
* Keep and format only valuable columns;
data results_2017_formatted;
	set results_2017(drop=name bib);
	where 'Finish status'n = "Finisher";
run;

/* proc contents data=results_2017; */
/* proc print data=results_2017; */
/* 	title 'Output Dataset: results_2017'; */
/* run; */

/* Create the results master datasets - using a new command "union all and alter table"*/
PROC SQL;
	CREATE TABLE results_all AS
		SELECT * FROM results_2017_formatted
		UNION ALL
		SELECT * FROM results_2018_formatted
		UNION ALL
		SELECT * FROM results_2019_formatted;
		ALTER TABLE results_all
		DROP 'Finish status'n;
QUIT;

/* Rename the column Overall Time to OverallTime */
data results_all;
    set results_all(rename=(
    'Division Rank'n=DivisionRank
    'Overall Time'n=OverallTime
    'Overall Rank'n=OverallRank
    'Swim Time'n=SwimTime
    'Swim Rank'n=SwimRank
    'Bike Time'n=BikeTime
    'Bike Rank'n=BikeRank
    'Run Time'n=RunTime
    'Run Rank'n=RunRank
    ));
run;

proc print data=results_all (obs=10);

/* Format time variables */
data results_all;
	set results_all;
	format OverallTime SwimTime BikeRank RunTime TIME10.; 
run;

/* Calculate transition times */
data results_all;
    set results_all;
 	allCategoriesTime = SwimTime + BikeRank + RunTime;
    TransitionTime = intck("second", allCategoriesTime, OverallTime);
/* TODO: IDK if this formatting is okay?   */
    format OverallTime SwimTime BikeTime RunTime transitionTime allCategoriesTime TIME10.; 
run;

proc contents data=results_all;
/* proc print data=results_all; */
/* 	title 'Output Dataset: results_all'; */
/* run; */


