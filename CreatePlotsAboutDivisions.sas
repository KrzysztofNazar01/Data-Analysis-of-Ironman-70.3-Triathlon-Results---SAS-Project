* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 6;
* Analyze all participants and the division with plots;

/* Analyze all participants by the divisions - new skill: macro (I didn't want to repeat code for both genders) */
%macro create_box_plot_by_division(dataset, gender);
    /* Create a new dataset with only specified gender observations */
    data &dataset._&gender.;
        set &dataset.;
        where Gender = "&gender.";
    run;

    /* Sort the dataset by Division to ensure correct order in the plot */
    proc sort data=&dataset._&gender.;
        by OverallTime;
    run;

    /* Create the box plot */
    proc sgplot data=&dataset._&gender.;
        vbox OverallTime / category=Division;
        xaxis label='Division' grid;
        yaxis label='Overall Time' grid;
        title "Overall Time of &gender. Participants by Division (gender and age group)";
    run;
%mend;


%create_box_plot_by_division(results_all, Male);
%create_box_plot_by_division(results_all, Fema);

