* Krzysztof Nazar 28/06/2023;
* OTH ZADA Project Full Code;
* Wordcount:___; * TODO: count the words in code (including comments);
/*
Number of words with comments: 1998
Number of words without comments: 1253
*/

/* LOAD DATA - Load data containing results of Ironman in 2017, 2018 and 2019 */
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_results_2017.csv'
	dbms=csv out=results_2017 replace;
	delimiter=',';
	getnames=yes;
	
data results_2017_formatted;
	set results_2017(drop=name bib);
/* 	where 'Finish status'n = "Finisher"; */
	EventYear=2017;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_results_2018.csv'
	dbms=csv out=results_2018 replace;
	delimiter=',';
	getnames=yes;

data results_2018_formatted;
	set results_2018(drop=name bib);
/* 	where 'Finish status'n = "Finisher"; */
	EventYear=2018;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_results_2019.csv'
	dbms=csv out=results_2019 replace;
	delimiter=',';
	getnames=yes;
	
data results_2019_formatted;
	set results_2019(drop=name bib);
/* 	where 'Finish status'n = "Finisher"; */
	EventYear=2019;
run;

/* Create the results master datasets - using a new command "union all" and "alter table" */
proc sql;
    create table results_all as
        select * from results_2017_formatted
        union all
        select * from results_2018_formatted
        union all
        select * from results_2019_formatted;
quit;

data results_finishers(drop='Finish status'n);
    set results_all(where=('Finish status'n = "Finisher"));
run;


* Rename columns and format time variables;
data results_finishers;
    set results_finishers(rename=(
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
	Division = tranwrd(Division, '"', ''); * remove the quotes from imported values;
	format
		OverallTime SwimTime BikeTime RunTime TIME10.
		EventYear number4.; 
	label 
		DivisionRank='Division Rank'
		OverallTime='Overall Time (H:MM:SS)'
	    OverallRank='Overall Rank'
	    SwimTime='Swim Time (H:MM:SS)'
	    SwimRank='Swim Rank'
	    BikeTime='Bike Time (H:MM:SS)'
	    BikeRank='Bike Rank'
	    RunTime='Run Time (H:MM:SS)'
	    RunRank='Run Rank';
run;

/* Delete a row if there is a missing value (".") in SwimTime, BikeTime or RunTime column */
data results_finishers;
    set results_finishers;
    if missing(SwimTime) or missing(BikeTime) or missing(RunTime) then delete;
run;

/* proc print data=results_finishers (obs=10) label; */

* Calculate transition times;
data results_finishers;
    set results_finishers;
 	AllCategoriesTime = SwimTime + BikeTime + RunTime;
    TransitionTime = intck("second", allCategoriesTime, OverallTime);
	label TransitionTime='Transition Time (H:MM:SS)';
    format
    	OverallTime SwimTime BikeTime RunTime TransitionTime AllCategoriesTime TIME10.
    	OverallRank SwimRank BikeRank RunRank TransitionRank DivisionRank Number6. ; 
run;

* Calculate transition time rank;
proc rank data=results_finishers out=results_finishers;
	var TransitionTime;
	ranks TransitionRank;
	label TransitionRank='Transition Rank';
	format TransitionRank BEST12.;
	
proc print data=results_finishers (obs=10) label;

proc contents data=results_finishers;


/* ANALYSIS - Analyze participants by year and gender */

proc means data=results_finishers noprint;
    class EventYear Gender;
    output out=participant_count_by_year_means(drop=_type_ _freq_) n=ParticipantCount;
run;

* Exclude unneeded values;
data plot_pax_by_year_gender;
	set participant_count_by_year_means;
	where EventYear ne .;
run;

proc print data=plot_pax_by_year_gender;

* Plot Number of Participants by Year and Gender;
proc sgplot data=plot_pax_by_year_gender;
    title 'Number of participants by event year and gender';
    styleattrs datacolors=("#d15b5b" "#6f7fb3");
    vbar EventYear / response=ParticipantCount group=Gender
                     groupdisplay=stack /*groupdisplay=cluster*/ barwidth=0.4 datalabel datalabelattrs=(size=11) seglabel seglabelattrs=(size=10); 
    legenditem type=marker name="F" / label="Female" markerattrs=(symbol=squarefilled color="#d15b5b" size=9);
    legenditem type=marker name="M" / label="Male" markerattrs=(symbol=squarefilled color="#6f7fb3" size=9);    
    xaxis label='Event year';
    yaxis label='Number of participants' grid ;
    keylegend "M" "F" / title="Gender";
run;


/* ANALYSIS - COUNTRIES AND MAPS */
* Count number of participants from each country;
proc sql;
	create table paxes_by_country as
	select Country, count(*) as NumOfParticipants
	from results_finishers
	group by Country;
quit;

data paxes_by_country;
	set paxes_by_country;
	label NumOfParticipants='Number of participants';
	format NumOfParticipants number5.;

data worldmap;
	set mapsgfk.world; * Template import;
	Country = idname;
	
proc gmap data=paxes_by_country map=worldmap all;
	id Country;
	choro NumOfParticipants / levels=5 legend=NumOfParticipants;
	title 'Number of participants by country';
run;

* Show the results as table;
proc sort data = paxes_by_country;
  	by descending NumOfParticipants; 
run;
proc print data=paxes_by_country (obs=10) label;
Title 'Number of participants by country - top 10';


* Sort the data by country - needed for the next step;
proc sort data=results_finishers;
    by Country;
run;

* Count number of best participants from each country;
data best_results_by_country;
  set results_finishers(keep=Country OverallRank); 
  where OverallRank <= 100; /* Filter only the top ten results */
  by Country;
  
  if first.Country then NumOfBestParticipants = 0; /* Initialize count for each country */
  NumOfBestParticipants + 1; /* Increment count for each person in the top ten */
  
  if last.Country then output; /* Output the count for each country */
  drop OverallRank;
run;

data best_results_by_country;
	set best_results_by_country;
	label NumOfBestParticipants='Number of best participants';
	format NumOfBestParticipants number5.;
	
data worldmap;
	set mapsgfk.world; * Template import;
	Country = idname;

proc gmap data=best_results_by_country map=worldmap all;
	id Country;
	choro NumOfBestParticipants / levels=5 legend=NumOfBestParticipants; /* Prepare a 2-dimensional map, levels -> number of colors */
	title 'Number of best participants by country';
run;

* Show the results as table;
proc sort data = best_results_by_country;
  	by descending NumOfBestParticipants; 
run;
proc print data=best_results_by_country (obs=10) label;
Title 'Number of best participants by country - top 10';


/* Which country has the best proportion of all paxes and the best paxes? */

* Store Participants and Best Participants by country in one dataset;
proc sql;
	create table results_paxes_by_country as
	select bp.country, p.NumOfParticipants, bp.NumOfBestParticipants
	from paxes_by_country as p right join
		best_results_by_country as bp
	on p.country = bp.country
	order by country;
quit;

* Calculate the difference and proportion of paxes;
data results_paxes_by_country;
	set results_paxes_by_country;
	paxes_diff = NumOfParticipants - NumOfBestParticipants;
	ParticipantsProp = NumOfBestParticipants/NumOfParticipants;
	label Country='Country Name'
      NumOfParticipants='Number of participants'
      NumOfBestParticipants='Number of best participants'
      paxes_diff='Difference between all participants and best participants'
      ParticipantsProp='Proportion of best participants to all participants';
	format ParticipantsProp percent10.2;
	
proc sort data = results_paxes_by_country;
  	by descending paxes_diff; 
run;

proc print data=results_paxes_by_country (obs=10) label;
	var Country NumOfParticipants NumOfBestParticipants paxes_diff;
	title 'Participants and Best Participants by country sorted by the difference - top 10';

proc sort data = results_paxes_by_country;
  	by descending NumOfParticipants; 
run;

proc print data=results_paxes_by_country (obs=10) label;
	var Country NumOfParticipants NumOfBestParticipants ParticipantsProp;
	title 'Participants and Best Participants by country sorted by the proportion - top 10';

/* ANALYSIS - PEARSON CORRELATION (Analyse correlation between GDP, GDP per capita and number of participants) */
* Import Gross Domestic Product of countries dataset;
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_NY.GDP.MKTP.CD_DS2_en_excel_v2_5607200.xls'
	dbms=xls out=countr_gdp replace;
	range='Data$A4:BN270';

* Keep and format only valuable columns;
data countr_gdp_formatted;
	set countr_gdp(
		keep = 'Country Name'n '2019'n
		rename=('Country Name'n=CountryName '2019'n=GDP2019)
		);
	label
		CountryName='Country Name'
		GDP2019='GDP in 2019';
	format GDP2019 DOLLAR30.;
run;
 
/* proc contents data=countr_gdp_formatted; */
/* proc print data=countr_gdp_formatted (obs=10) label; */
/* 	title 'Gross Domestic Product of Countries in 2019'; */
/* run; */

* Import Population of countries dataset;
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_SP.POP.TOTL_DS2_en_excel_v2_5607126.xls'
	dbms=xls out=countr_pop replace;
	range='Data$A4:BN270';

* Keep and format only valuable columns;
data countr_pop_formatted;
	set countr_pop(
		keep = 'Country Name'n '2019'n
		rename=('Country Name'n=CountryName '2019'n=POP2019)
		);
	label
		CountryName='Country Name'
		POP2019='Population in 2019';	
	format POP2019 15.;
run;
 
/* proc print data=countr_pop_formatted (obs=10) label; */
/* 	title 'Population of Countries in 2019'; */
/* run; */

* Merge Countries GDP and Population datasets;
proc sql;
    create table CountriesGDPPOP as
    select a.CountryName, a.GDP2019, b.POP2019
    from countr_gdp_formatted as a
    right join countr_pop_formatted as b
    on a.CountryName = b.CountryName;
quit;

data CountriesGDPPOP;
    set CountriesGDPPOP;
    GDPPC2019 = GDP2019 / POP2019;
	label
		CountryName='Country Name'
		GDP2019='GDP in 2019 (USD)'
		POP2019='Population in 2019'		
		GDPPC2019='GDP per capita in 2019 (USD)'
		;	
    format GDPPC2019 DOLLAR30.;
run;

proc sort data=CountriesGDPPOP;
	by descending GDPPC2019;
run;

proc print data=CountriesGDPPOP (obs=10) label;
	title 'Gross Domestic Product and Population of Countries in 2019 sorted by Gross Domestic Product per capita';
run;

* Analyze correlation between GDP values and the number of participants;
proc sort data=results_paxes_by_country;
	by descending NumOfParticipants;
run;

/* proc print data=results_paxes_by_country (obs=10) label; */
/* 	var Country NumOfParticipants NumOfBestParticipants ParticipantsProp; */
/* 	title 'Results of participants and best participants by country sorted by number of participants'; */
/* run; */

* Merge the GDP and population dataset with Participant dataset;
proc sql;
    create table CountriesGDPPOPmerged as
    select a.CountryName, a.GDP2019, a.GDPPC2019, b.NumOfParticipants, b.NumOfBestParticipants, b.ParticipantsProp
    from CountriesGDPPOP as a
    right join results_paxes_by_country as b
    on a.CountryName = b.Country;
quit;

* Delete rows with missing values;
data CountriesGDPPOPmerged;
    set CountriesGDPPOPmerged;
    if missing(CountryName) then delete;
run;

proc sort data=CountriesGDPPOPmerged;
 	by descending NumOfParticipants; 
run;

proc print data=CountriesGDPPOPmerged (obs=10) label;
	var CountryName GDP2019 GDPPC2019 NumOfParticipants NumOfBestParticipants ParticipantsProp;
	title 'GDP, population, and number of participants by country sorted by number of participants';
run;

proc corr data=CountriesGDPPOPmerged plots=matrix(histogram); 
	var GDP2019	GDPPC2019 NumOfParticipants NumOfBestParticipants ParticipantsProp;
	title 'Correlation results between GDP, GDP per capita and number of participants';
run;

/* ANALYSIS - BOX PLOTS (Analyze all participants by the divisions) */
* New skill: macro (The code is not repeated for both genders);
%macro create_box_plot_by_division(dataset, gender);
    * Create a new dataset with only specified gender observations;
    data &dataset._&gender.;
        set &dataset.;
        where Gender = "&gender.";
    run;

    * Sort the dataset by Division to ensure correct order in the plot;
    proc sort data=&dataset._&gender.;
        by OverallTime;
    run;

    * Create the box plot;
    proc sgplot data=&dataset._&gender.;
        vbox OverallTime / category=Division;
        xaxis label='Division' grid;
        yaxis label='Overall Time (H:MM)' grid;
        
        * if else docs: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/mcrolref/n18fij8dqsue9pn1lp8436e5mvb7.htm;
        %if &gender = Fema %then %do;
        	title "Overall Time of Female Participants by Division (gender and age group)";
    	%end;
    	%else %do;
        	title "Overall Time of Male Participants by Division (gender and age group)";
    	%end;
   run;
%mend;

%create_box_plot_by_division(results_finishers, Male);
%create_box_plot_by_division(results_finishers, Fema);

/* ANALYSIS - BAR PLOTS */
proc gchart data=results_finishers;
	hbar Overalltime / group=Gender;
	where Gender = 'Fema';
	title 'Distribution of Overall Time of Female Participant';
run;

proc gchart data=results_finishers;
	hbar Overalltime / group=Gender;
	where Gender = 'Male';
	title 'Distribution of Overall Time of Male Participant';
run;

data grouped_data;
   set results_finishers(keep=Gender Overalltime);
   Overall_Time_Group = floor(Overalltime / 3600); /* Group by 60 minutes interval */
run;

title "Distribution of Overall Time of All Participants - intervals of 60 minutes";
proc sgplot data = grouped_data;
    vbar Overall_Time_Group / group = Gender groupdisplay = cluster;
    xaxis label='Overall Time (Hours)';
    yaxis label='Number of Participants';
run;

/* ANALYSIS - SCATTER PLOTS */

* Scatterplot - Transition Time vs Overall Time by Gender;
proc sgplot data=results_finishers;
	scatter x=transitionTime y=OverallTime / group=Gender; * markers without filling;
/* 	scatter x=transitionTime y=Overalltime / group=Gender markerattrs=(symbol=circlefilled); * markers with filling; */
	title 'Transition Time vs Overall Time by Gender';
	XAXIS grid label='Transition Time (H:MM)';
	YAXIS grid label='Overall Time (H:MM)';

* Scatterplot - Transition Rank vs Overall Time by Gender;
proc sgplot data=results_finishers;
	scatter x=transitionRank y=OverallRank / group=Gender; * markers without filling;
	title 'Transition Rank vs Overall Rank by Gender';
	XAXIS grid label='Transition Rank';
	YAXIS grid label='Overall Rank';

* Scatterplot - Swim Rank vs Overall Rank by Gender;
proc sgplot data=results_finishers;
    scatter x=SwimRank y=OverallRank / group=Gender;
    title 'Swim Rank vs Overall Rank by Gender';
	XAXIS grid label='Swim Rank';
	YAXIS grid label='Overall Rank';
run;


* Scatterplot - Bike Rank vs Overall Rank by Gender;
proc sgplot data=results_finishers;
	scatter x=BikeRank y=OverallRank / group=Gender;
	title 'Bike Rank vs Overall Rank by Gender';
	XAXIS grid label='Bike Rank';
	YAXIS grid label='Overall Rank';
	
* Scatterplot - Run Rank vs Overall Rank by Gender;
proc sgplot data=results_finishers;
	scatter x=RunRank y=OverallRank / group=Gender;
	title 'Run Rank vs Overall Rank by Gender';
	XAXIS grid label='Run Rank';
	YAXIS grid label='Overall Rank';

/* Correlation between the final score (Overall rank) and scores in three categories (SwimRank, BikeRank, RunRank) */

* Calculate rank of transition time;
data results_ranks_corr;
	set results_finishers(keep=OverallRank
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

/* ANALYSIS - normalization of times */
* normalize the times of each category
  by dividing it by the median time of each category;

data results_times;
  set results_finishers(keep=OverallTime
  					   SwimTime
  					   BikeTime
  					   RunTime 
  					   OverallRank
  					   SwimRank
  					   BikeRank 
  					   RunRank 
  					   Gender);

proc print data=results_times (obs=10) label;

%macro normalize_time(data, time_variable);
    /* Calculate the median of the time variable */
    proc summary data=&data.;
        output out=median_times median(&time_variable.)=Median_Time;
    run;

    /* Normalize the time variable by dividing it by the median value */
    data &data.;
        set &data.;
        if _n_ = 1 then set median_times; 
        
        /* Convert time variables to seconds */
        &time_variable._sec = input(put(&time_variable., time.), time8.);
        Median_Time_sec = input(put(Median_Time, time.), time8.);
        
        /* Calculate normalized value */
        &time_variable.Norm = &time_variable._sec / Median_Time_sec;

        drop Median_Time_sec &time_variable._sec Median_Time _TYPE_ _FREQ_;
    run;
%mend;

%normalize_time(results_times, SwimTime);
run;
%normalize_time(results_times, BikeTime);
run;
%normalize_time(results_times, RunTime);
run;

proc print data=results_times (obs=10) label;

data results_times;
set results_times;
	OverallTimeNorm = SwimTimeNorm + BikeTimeNorm + RunTimeNorm;
	drop SwimTimeNorm BikeTimeNorm RunTimeNorm;

proc rank data=results_times out=results_times_rank;
	var OverallTimeNorm;
	ranks OverallTimeNormRank; * new variable that holds the order of sotring;
	label OverallTimeNormRank='Overall Time Normalized Rank';

proc sgplot data=results_times_rank;
	scatter x=SwimRank y=OverallTimeNormRank / group=Gender;
	title 'Swim Rank vs Overall Time Normalized Rank by Gender';
	xaxis grid;
	yaxis grid;
	
proc sgplot data=results_times_rank;
	scatter x=BikeRank y=OverallTimeNormRank / group=Gender;
	title 'Bike Rank vs Overall Time Normalized Rank by Gender';
	xaxis grid;
	yaxis grid;
	
proc sgplot data=results_times_rank;
	scatter x=RunRank y=OverallTimeNormRank / group=Gender;
	title 'Run Rank vs Overall Time Normalized Rank by Gender';
	xaxis grid;
	yaxis grid;

/*
The Correlation results prove that the distances of activities are disproportional.
The race slightly favours bikers(0.87575) & runners(0.87216) over swimmers (0.82035).
*/
proc corr data=results_times_rank plots=matrix(histogram); 
	var OverallTimeNormRank
	  	SwimRank
	  	BikeRank
	  	RunRank;
run;

