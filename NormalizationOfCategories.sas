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
  					   TransitionTime);

proc print data=results_times (obs=10);


/* Previous version - I had to copy this code and adjust it manually for each Time variable */
/* Normalize the time variable by dividing it by the median */
/* data results_times; */
/*     set results_times; */
/*     if _n_ = 1 then set median_times;  */
/*      */
/*     Convert time variables to seconds */
/*     BikeTime_sec = input(put(BikeTime, time.), time8.); */
/*     Median_Time_sec = input(put(Median_Time, time.), time8.); */
/*      */
/*     Calculate normalized value */
/*     BikeTimeNorm = BikeTime_sec / Median_Time_sec; */
/*  */
/*     drop Median_Time_sec BikeTime_sec Median_Time; */
/* run; */
/*  */




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

        drop Median_Time_sec &time_variable._sec Median_Time _TYPE_ _FREQ_;
    run;
%mend;

%normalize_time(results_times, OverallTime);
run;
%normalize_time(results_times, SwimTime);
run;
%normalize_time(results_times, BikeTime);
run;
%normalize_time(results_times, RunTime);
run;
%normalize_time(results_times, TransitionTime);
run;

proc print data=results_times (obs=10);










