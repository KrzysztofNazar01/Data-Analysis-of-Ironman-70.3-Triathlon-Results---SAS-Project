* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 2;
* Create Maps;


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


















