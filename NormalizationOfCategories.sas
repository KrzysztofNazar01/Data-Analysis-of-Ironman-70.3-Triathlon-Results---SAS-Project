* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 5;
* Normalize the data;
* normalize the times of each segment by dividing it
  by the median time of each segment and then plot the data;

* create temp dataset;
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
    /* Calculate the median of the time variable */
    proc summary data=&data.;
        output out=median_times median(&time_variable.)=Median_Time;
    run;

    /* Normalize the time variable by dividing it by the median */
    data &data.;
        set &data.;
        if _n_ = 1 then set median_times; 
        
        /* Convert time variables to seconds */
        &time_variable._sec = input(put(&time_variable., time.), time8.);
        Median_Time_sec = input(put(Median_Time, time.), time8.);
        
        /* Calculate normalized value */
        &time_variable.Norm = &time_variable._sec / Median_Time_sec;

/*         drop Median_Time_sec &time_variable._sec Median_Time _TYPE_ _FREQ_; */
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

proc rank data=results_times out=results_times_rank;
	var OverallTimeNorm;
	ranks OverallTimeNormRank; * new variable that holds the order of sotring;
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

/*
The Correlation results prove that the distances of activities are disproportional.
The race favours bikers(0.93841) & runners(0.90823) over swimmers (0.72679).
*/
proc corr data=results_times_rank plots=matrix(histogram); 
	var OverallTimeNormRank
	  	SwimRank
	  	BikeRank
	  	RunRank;
run;








