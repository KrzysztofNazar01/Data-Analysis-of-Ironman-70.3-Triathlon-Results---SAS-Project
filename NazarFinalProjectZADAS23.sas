* Krzysztof Nazar 28/06/2023;
* OTH ZADA Project Full Code;
* Wordcount:______; * TODO: count the words in code (including comments);

/* LOAD DATA - Load data containing results of Ironman in 2017, 2018 and 2019 */
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2019_results_0.csv'
	dbms=csv out=results_2019 replace;
	delimiter=',';
	getnames=yes;
	
data results_2019_formatted;
	set results_2019(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2019;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2018_results_0.csv'
	dbms=csv out=results_2018 replace;
	delimiter=',';
	getnames=yes;

data results_2018_formatted;
	set results_2018(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2018;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2017_results_0.csv'
	dbms=csv out=results_2017 replace;
	delimiter=',';
	getnames=yes;
	
data results_2017_formatted;
	set results_2017(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2017;
run;

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

* Rename columns and format time variables;
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
	format OverallTime SwimTime BikeRank RunTime TIME10.; 
run;

/* Delete a row if there is a missing value (".") in SwimTime, BikeTime or RunTime column */
data results_all;
    set results_all;
    if missing(SwimTime) or missing(BikeTime) or missing(RunTime) then delete;
run;

proc print data=results_all (obs=10);

* Calculate transition times;
data results_all;
    set results_all;
 	AllCategoriesTime = SwimTime + BikeTime + RunTime;
    TransitionTime = intck("second", allCategoriesTime, OverallTime);
    format OverallTime SwimTime BikeTime RunTime transitionTime allCategoriesTime TIME10.; 
run;

* Calculate transition time rank;
proc rank data=results_all out=results_all;
	var TransitionTime;
	ranks TransitionRank;
	label TransitionRank='TransitionRank';

proc print data=results_all (obs=10);

proc contents data=results_all;


/* ANALYSIS - Analyze participants by year and gender */

proc means data=results_all noprint;
    class EventYear Gender;
    output out=participant_count_by_year_means(drop=_type_ _freq_) n=ParticipantCount;
run;

* Exclude unneeded values;
data plot_pax_by_year_gender;
	set participant_count_by_year_means;
	where EventYear ne .;
	format EventYear number4.;
run;

* Plot Number of Participants by Year and Gender;
proc sgplot data=plot_pax_by_year_gender;
    title 'Number of Participants by Year and Gender';
    vbar EventYear / response=ParticipantCount group=Gender
                     groupdisplay=stack /*groupdisplay=cluster*/ barwidth=0.4 datalabel datalabelattrs=(size=10) seglabel; 
    keylegend;
    xaxis label='Event Year';
    yaxis label='Number of Participants' grid;
run;


/* ANALYSIS - COUNTRIES AND MAPS */


* Count number of participants from each country;
PROC SQL;
	CREATE TABLE paxes_by_country AS
	SELECT Country, COUNT(*) AS Number_of_paxes
	FROM results_all
	GROUP BY Country;
QUIT;

data worldmap;
	set mapsgfk.world; /* Template import */
	Country = idname;

proc gmap data=paxes_by_country map=worldmap all;
	id Country;
	choro Number_of_paxes / levels=4; /* Prepare a 2-dimensional map, levels -> number of colors */
	title 'Number of participants by country';
run;

* Show the results as table;
proc sort data = paxes_by_country;
  	by descending number_of_paxes; 
run;
proc print data=paxes_by_country (obs=20);
Title 'Number of participants by country - top 20';


* Sort the data by country - needed for the next step;
proc sort data=results_all;
    by Country;
run;

* Count number of best participants from each country;
data best_results_by_country;
  set results_all(keep=Country OverallRank); 
  where OverallRank <= 100; /* Filter only the top ten results */
  by Country;
  
  if first.Country then number_of_best_paxes = 0; /* Initialize count for each country */
  number_of_best_paxes + 1; /* Increment count for each person in the top ten */
  
  if last.Country then output; /* Output the count for each country */
  drop OverallRank;
run;

data worldmap;
	set mapsgfk.world; /* Template import */
	Country = idname;

proc gmap data=best_results_by_country map=worldmap all;
	id Country;
	choro number_of_best_paxes / levels=4; /* Prepare a 2-dimensional map, levels -> number of colors */
	title 'Number of best participants by country';
run;

* Show the results as table;
proc sort data = best_results_by_country;
  	by descending number_of_best_paxes; 
run;
proc print data=best_results_by_country (obs=20);
Title 'Number of best participants by country - top 20';



/* Which country has the best proportion of all paxes and the best paxes? */

* Store Participants and Best Participants by country in one dataset;
proc sql;
	create table results_paxes_by_country as
	select bp.country, p.number_of_paxes, bp.number_of_best_paxes
	from paxes_by_country as p right join
		best_results_by_country as bp
	on p.country = bp.country
	order by country;
quit;

* Calculate the difference and proportion of paxes;
data results_paxes_by_country;
	set results_paxes_by_country;
	paxes_diff = number_of_paxes - number_of_best_paxes;
	paxes_prop = number_of_best_paxes/number_of_paxes;
	label Country='Country Name'
      Number_of_paxes='Number of participants'
      Number_of_best_paxes='Number of best participants'
      paxes_diff='Difference between all participants and best participants'
      paxes_prop='Proprtion of best participants to all participants';
	format paxes_prop percent10.2;
	
proc sort data = results_paxes_by_country;
  	by descending paxes_diff; 
run;
proc print data=results_paxes_by_country (obs=20) label;
var Country Number_of_paxes number_of_best_paxes paxes_diff;

Title 'Participants and Best Participants by country sorted by the difference - top 20';

proc sort data = results_paxes_by_country;
  	by descending paxes_prop; 
run;
proc print data=results_paxes_by_country (obs=20) label;
var Country Number_of_paxes number_of_best_paxes paxes_prop;
Title 'Participants and Best Participants by country sorted by the proportion - top 20';


/* ANALYSIS - BAR PLOTS */
proc gchart data=results_all;
	hbar Overalltime / group=Gender;
	where Gender = 'Fema';
	title 'Distribution of Overall Time of Female Participant';
run;

proc gchart data=results_all;
	hbar Overalltime / group=Gender;
	where Gender = 'Male';
	title 'Distribution of Overall Time of Male Participant';
run;

data grouped_data;
   set results_all(keep=Gender Overalltime);
   Overall_Time_Group = floor(Overalltime / 3600); /* Group by 60 minutes interval */
run;

title "Distribution of Overall Time of All Participants - intervals of 60 minutes";
proc sgplot data = grouped_data;
    vbar Overall_Time_Group / group = Gender groupdisplay = cluster;
run;


/* ANALYSIS - SCATTER PLOTS */
* Scatterplot - Transition Time vs Overall Time by Gender;
proc sgplot data=results_all;
	scatter x=transitionTime y=Overalltime / group=Gender; * markers without filling;
/* 	scatter x=transitionTime y=Overalltime / group=Gender markerattrs=(symbol=circlefilled); * markers with filling; */
	title 'Transition Time vs Overall Time by Gender';

* Scatterplot - Swim Rank vs Overall Rank by Gender;
proc sgplot data=results_all;
	scatter x=SwimRank y=OverallRank / group=Gender;
	title 'Swim Rank vs Overall Rank by Gender';

* Scatterplot - Bike Rank vs Overall Rank by Gender;
proc sgplot data=results_all;
	scatter x=BikeRank y=OverallRank / group=Gender;
	title 'Bike Rank vs Overall Rank by Gender';

* Scatterplot - Run Rank vs Overall Rank by Gender;
proc sgplot data=results_all;
	scatter x=RunRank y=OverallRank / group=Gender;
	title 'Run Rank vs Overall Rank by Gender';


/*  Correlation between ranks */

* calculate rank of transition time;
data results_ranks_corr;
	set results_all(keep=OverallRank
  					   SwimRank
  					   BikeRank
  					   RunRank 
  					   TransitionRank
  					   Gender);

/* Look at the first column --> correlation between the Overall Rank and other ranks
Results - the highest correlations with the overall rank:
 - bike rank 0.95989
 - run rank 0.92900
 - swim rank 0.74933
 - transition rank 0.64531
*/
proc corr data=results_ranks_corr plots=matrix(histogram); 
var OverallRank
	SwimRank
	BikeRank
	RunRank 
	TransitionRank
	 ;
run;

proc sgscatter data=results_ranks_corr; 
matrix OverallRank
  		SwimRank
  		BikeRank 
  		RunRank 
  		TransitionRank
  		/ group=gender diagonal=(histogram kernel);
run;


