* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 3;
* Create Bar Plots;

proc gchart data=results_all;
	vbar Overalltime / group=Gender;
	where Gender = 'Fema';
	title 'Distribution of Overall Time of Female Participant';
run;

proc gchart data=results_all;
	vbar Overalltime / group=Gender;
	where Gender = 'Male';
	title 'Distribution of Overall Time of Male Participant';
run;

/* proc means data=results_all maxdec=2 mean stddev min max; */
/* class Gender; */
/* var Overalltime SwimTime BikeTime RunTime; */
/* Title 'Statistics of Times of Participants'; */
/* output out=mean_times mean=MeanTime; */
/* run; */
/*  */
/* Calcualte difference between the mean times */
/* data mean_times; */
/*    set mean_times; */
/*    if Gender = "Male" then Male_Mean_Time = MeanTime; */
/*    else if Gender = "Fema" then Female_Mean_Time = MeanTime; */
/*  */
/* run; */
/*  */
/* proc print data=mean_times; */


/* Plot Male and Female together */
data grouped_data;
   set results_all(keep=Gender Overalltime);
   Overall_Time_Group = floor(Overalltime / 3600); /* Group by 60 minutes interval */
run;

title "Distribution of Overall Time of All Participants - intervals of 60 minutes";
proc sgplot data = grouped_data;
    vbar Overall_Time_Group / group = Gender groupdisplay = cluster;
run;


/* Calcualte differences in mean times */
/* QUESTION: HOW TO CALCULATE THE DIFFERENCE BETWEEN GENDERS? */
proc means data=results_all mean noobs;
  var Overalltime SwimTime BikeTime RunTime;
  class Gender;
  output out=mean_times;
run;

proc print data=mean_times;


/* ---- CODE BELOW DOES NOT WORK --- */
data mean_values;
  set mean_times;
  where _STAT_ = 'MEAN';
  if Gender = 'Fema' then do;
    Mean_Overall_Fema = Overalltime;
    Mean_Swim_Fema = SwimTime;
    Mean_Bike_Fema = BikeTime;
    Mean_Run_Fema = RunTime;
  end;
  else if Gender = 'Male' then do;
    Mean_Overall_Male = Overalltime;
    Mean_Swim_Male = SwimTime;
    Mean_Bike_Male = BikeTime;
    Mean_Run_Male = RunTime;
  end;
  Gender_Diff_Overall = intck("second", Mean_Overall_Male, Mean_Overall_Fema);
  drop Gender _STAT_  _TYPE_	_FREQ_ Overalltime SwimTime BikeTime RunTime;
  format Mean_Overall_Fema Mean_Swim_Fema Mean_Bike_Fema Mean_Run_Fema
  		 Mean_Overall_Male Mean_Swim_Male Mean_Bike_Male Mean_Run_Male Time10.;

run;

/* Viewing the mean values for each gender */
proc print data=mean_values;
run;


/* Calculating the difference between genders */
data gender_time_difference;
  set mean_values;
  Gender_Diff_Overall = intck("second", Mean_Overall_Male, Mean_Overall_Fema);
/* 	Gender_Diff_Swim = Mean_Swim_Male - Mean_Swim_Fema; */
/* 	Gender_Diff_Bike = Mean_Bike_Male - Mean_Bike_Fema; */
/* 	Gender_Diff_Run = Mean_Run_Male - Mean_Run_Fema; */
format Gender_Diff_Overall Time10.;
run;

/* Viewing the results */
proc print data=gender_time_difference;
run;
