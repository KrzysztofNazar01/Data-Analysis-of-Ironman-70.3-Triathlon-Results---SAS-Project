* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 2;
* Create Maps;

/* Define a macro function */
%macro count_paxes_by_country(dataset);
	/* Create a table to store the results */
	PROC SQL;
		CREATE TABLE paxes_by_country AS
		SELECT Country, COUNT(*) AS Number_of_paxes
		FROM &dataset
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
%mend;


%macro count_best_paxes_by_country(dataset);
	proc sort data=&dataset; 
	  by Country;
	run;
	
	
	data best_results_by_country;
	  set &dataset; 
	  where OverallRank <= 100; /* Filter only the top ten results */
	  by Country;
	  
	  if first.Country then number_of_paxes = 0; /* Initialize count for each country */
	  number_of_paxes + 1; /* Increment count for each person in the top ten */
	  
	  if last.Country then output; /* Output the count for each country */
	run;
	
	
	data worldmap;
		set mapsgfk.world; /* Template import */
		Country = idname;
	
	proc gmap data=best_results_by_country map=worldmap all;
		id Country;
		choro number_of_paxes / levels=4; /* Prepare a 2-dimensional map, levels -> number of colors */
		title 'Number of best participants by country';
	run;
%mend;

/* Call the macro functions */
%count_paxes_by_country(results_all);
%count_best_paxes_by_country(results_all);












