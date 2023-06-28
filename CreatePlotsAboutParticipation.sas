* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 6;
* Analyze all participants with plots;


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
