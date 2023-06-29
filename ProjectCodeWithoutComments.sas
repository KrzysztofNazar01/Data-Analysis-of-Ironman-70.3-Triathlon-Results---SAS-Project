proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2019_results_1.csv'
	dbms=csv out=results_2019 replace;
	delimiter=',';
	getnames=yes;
	
data results_2019_formatted;
	set results_2019(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2019;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2018_results_1.csv'
	dbms=csv out=results_2018 replace;
	delimiter=',';
	getnames=yes;

data results_2018_formatted;
	set results_2018(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2018;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/Ironman_703_2017_results_1.csv'
	dbms=csv out=results_2017 replace;
	delimiter=',';
	getnames=yes;
	
data results_2017_formatted;
	set results_2017(drop=name bib);
	where 'Finish status'n = "Finisher";
	EventYear=2017;
run;


proc sql;
    create table results_all as
        select * from results_2017_formatted
        union all
        select * from results_2018_formatted
        union all
        select * from results_2019_formatted;
    alter table results_all
        drop 'Finish status'n;
quit;


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
	Division = tranwrd(Division, '"', ''); 
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


data results_all;
    set results_all;
    if missing(SwimTime) or missing(BikeTime) or missing(RunTime) then delete;
run;




data results_all;
    set results_all;
 	AllCategoriesTime = SwimTime + BikeTime + RunTime;
    TransitionTime = intck("second", allCategoriesTime, OverallTime);
	label TransitionTime='Transition Time (H:MM:SS)';
    format
    	OverallTime SwimTime BikeTime RunTime TransitionTime AllCategoriesTime TIME10.
    	OverallRank SwimRank BikeRank RunRank TransitionRank DivisionRank Number6. ; 
run;


proc rank data=results_all out=results_all;
	var TransitionTime;
	ranks TransitionRank;
	label TransitionRank='Transition Rank';
	format TransitionRank BEST12.;
	
proc print data=results_all (obs=10) label;

proc contents data=results_all;




proc means data=results_all noprint;
    class EventYear Gender;
    output out=participant_count_by_year_means(drop=_type_ _freq_) n=ParticipantCount;
run;


data plot_pax_by_year_gender;
	set participant_count_by_year_means;
	where EventYear ne .;
run;


proc sgplot data=plot_pax_by_year_gender;
    title 'Number of Participants by Year and Gender';
    vbar EventYear / response=ParticipantCount group=Gender
                     groupdisplay=stack  barwidth=0.4 datalabel datalabelattrs=(size=11) seglabel seglabelattrs=(size=10); 
    keylegend;
    xaxis label='Event Year';
    yaxis label='Number of Participants' grid;
run;




proc sql;
	create table paxes_by_country as
	select Country, count(*) as NumOfParticipants
	from results_all
	group by Country;
quit;

data paxes_by_country;
	set paxes_by_country;
	label NumOfParticipants='Number of participants';
	format NumOfParticipants number5.;

data worldmap;
	set mapsgfk.world; 
	Country = idname;
	
proc gmap data=paxes_by_country map=worldmap all;
	id Country;
	choro NumOfParticipants / levels=5 legend=NumOfParticipants;
	title 'Number of participants by country';
run;


proc sort data = paxes_by_country;
  	by descending NumOfParticipants; 
run;
proc print data=paxes_by_country (obs=10) label;
Title 'Number of participants by country - top 10';



proc sort data=results_all;
    by Country;
run;


data best_results_by_country;
  set results_all(keep=Country OverallRank); 
  where OverallRank <= 100; 
  by Country;
  
  if first.Country then NumOfBestParticipants = 0; 
  NumOfBestParticipants + 1;
  
  if last.Country then output;
  drop OverallRank;
run;

data best_results_by_country;
	set best_results_by_country;
	label NumOfBestParticipants='Number of best participants';
	format NumOfBestParticipants number5.;
	
data worldmap;
	set mapsgfk.world; 
	Country = idname;

proc gmap data=best_results_by_country map=worldmap all;
	id Country;
	choro NumOfBestParticipants / levels=5 legend=NumOfBestParticipants; 
	title 'Number of best participants by country';
run;


proc sort data = best_results_by_country;
  	by descending NumOfBestParticipants; 
run;
proc print data=best_results_by_country (obs=10) label;
Title 'Number of best participants by country - top 10';





proc sql;
	create table results_paxes_by_country as
	select bp.country, p.NumOfParticipants, bp.NumOfBestParticipants
	from paxes_by_country as p right join
		best_results_by_country as bp
	on p.country = bp.country
	order by country;
quit;

data results_paxes_by_country;
	set results_paxes_by_country;
	paxes_diff = NumOfParticipants - NumOfBestParticipants;
	ParticipantsProp = NumOfBestParticipants/NumOfParticipants;
	label Country='Country Name'
      NumOfParticipants='Number of participants'
      NumOfBestParticipants='Number of best participants'
      paxes_diff='Difference between all participants and best participants'
      ParticipantsProp='Proprtion of best participants to all participants';
	format ParticipantsProp percent10.2;
	
proc sort data = results_paxes_by_country;
  	by descending paxes_diff; 
run;

proc print data=results_paxes_by_country (obs=20) label;
	var Country NumOfParticipants NumOfBestParticipants paxes_diff;
	title 'Participants and Best Participants by country sorted by the difference - top 20';

proc sort data = results_paxes_by_country;
  	by descending ParticipantsProp; 
run;

proc print data=results_paxes_by_country (obs=20) label;
	var Country NumOfParticipants NumOfBestParticipants ParticipantsProp;
	title 'Participants and Best Participants by country sorted by the proportion - top 20';


proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_NY.GDP.MKTP.CD_DS2_en_excel_v2_5551619_edited.xls'
	dbms=xls out=countr_gdp replace;
	range='Data$A4:BN270';


data countr_gdp_formatted;
	set countr_gdp(
		keep = 'Country Name'n '2019'n
		rename=('Country Name'n=CountryName '2019'n=GDP2019)
		);
	label
		CountryName='Country Name'
		GDP2019='GDP in 2019';
	format GDP2019 DOLLAR30.2;
run;

proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_SP.POP.TOTL_DS2_en_excel_v2_5551740_edited.xls'
	dbms=xls out=countr_pop replace;
	range='Data$A4:BN270';

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
		GDP2019='GDP in 2019'
		POP2019='Population in 2019'		
		GDPPC2019='GDP per capita in 2019'
		;	
    format GDPPC2019 DOLLAR30.2;
run;

proc sort data=CountriesGDPPOP;
	by descending GDPPC2019;
run;

proc print data=CountriesGDPPOP (obs=10) label;
	title 'Gross Domestic Product and Population of Countries in 2019 sorted by Gross Domestic Product per capita';
run;

proc sort data=results_paxes_by_country;
	by descending NumOfParticipants;
run;



proc sql;
    create table CountriesGDPPOPmerged as
    select a.CountryName, a.GDP2019, a.GDPPC2019, b.NumOfParticipants, b.NumOfBestParticipants, b.ParticipantsProp
    from CountriesGDPPOP as a
    right join results_paxes_by_country as b
    on a.CountryName = b.Country;
quit;


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

%macro create_box_plot_by_division(dataset, gender);

    data &dataset._&gender.;
        set &dataset.;
        where Gender = "&gender.";
    run;


    proc sort data=&dataset._&gender.;
        by OverallTime;
    run;


    proc sgplot data=&dataset._&gender.;
        vbox OverallTime / category=Division;
        xaxis label='Division' grid;
        yaxis label='Overall Time' grid;
        title "Overall Time of &gender. Participants by Division (gender and age group)";
    run;
%mend;

%create_box_plot_by_division(results_all, Male);
%create_box_plot_by_division(results_all, Fema);

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
   Overall_Time_Group = floor(Overalltime / 3600); 
run;

title "Distribution of Overall Time of All Participants - intervals of 60 minutes";
proc sgplot data = grouped_data;
    vbar Overall_Time_Group / group = Gender groupdisplay = cluster;
run;



proc sgplot data=results_all;
	scatter x=transitionTime y=OverallTime / group=Gender; 

	title 'Transition Time vs Overall Time by Gender';
	XAXIS grid label='Transition Time (H:MM)';
	YAXIS grid label='Overall Time (H:MM)';


proc sgplot data=results_all;
	scatter x=transitionRank y=OverallRank / group=Gender; 
	title 'Transition Rank vs Overall Rank by Gender';
	XAXIS grid label='Transition Rank';
	YAXIS grid label='Overall Rank';


proc sgplot data=results_all;
    scatter x=SwimRank y=OverallRank / group=Gender;
    title 'Swim Rank vs Overall Rank by Gender';
	XAXIS grid label='Swim Rank';
	YAXIS grid label='Overall Rank';
run;



proc sgplot data=results_all;
	scatter x=BikeRank y=OverallRank / group=Gender;
	title 'Bike Rank vs Overall Rank by Gender';
	XAXIS grid label='Bike Rank';
	YAXIS grid label='Overall Rank';
	

proc sgplot data=results_all;
	scatter x=RunRank y=OverallRank / group=Gender;
	title 'Run Rank vs Overall Rank by Gender';
	XAXIS grid label='Run Rank';
	YAXIS grid label='Overall Rank';


data results_ranks_corr;
	set results_all(keep=OverallRank
  					   SwimRank
  					   BikeRank
  					   RunRank 
  					   TransitionRank
  					   Gender);


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

data results_times;
  set results_all(keep=OverallTime
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
    proc summary data=&data.;
        output out=median_times median(&time_variable.)=Median_Time;
    run;

    data &data.;
        set &data.;
        if _n_ = 1 then set median_times; 
        
        &time_variable._sec = input(put(&time_variable., time.), time8.);
        Median_Time_sec = input(put(Median_Time, time.), time8.);
        
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
	ranks OverallTimeNormRank;
	label OverallTimeNormRank='Overall Time Normalized Rank';

proc sgplot data=results_times_rank;
	scatter x=SwimRank y=OverallTimeNormRank / group=Gender;
	title 'Swim Rank vs Overall Time Normalized Rank by Gender';
	
proc sgplot data=results_times_rank;
	scatter x=BikeRank y=OverallTimeNormRank / group=Gender;
	title 'Bike Rank vs Overall Time Normalized Rank by Gender';

proc sgplot data=results_times_rank;
	scatter x=RunRank y=OverallTimeNormRank / group=Gender;
	title 'Run Rank vs Overall Time Normalized Rank by Gender';

proc corr data=results_times_rank plots=matrix(histogram); 
	var OverallTimeNormRank
	  	SwimRank
	  	BikeRank
	  	RunRank;
run;

