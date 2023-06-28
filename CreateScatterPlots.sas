* Krzysztof Nazar 27/06/2023;
* OTH ZADA Project Part 4;
* Create Scatter Plots;

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
  					   transitionTime
  					   Gender);

proc rank data=results_ranks_corr out=results_ranks_corr_all;
	var transitionTime;
	ranks TransitionRank; * new variable that holds the order of sotring;

/* Look at the first column --> correlation between the Overall Rank and other ranks
Results - the highest correlations with the overall rank:
 - bike rank 0.95989
 - run rank 0.92900
 - swim rank 0.74933
 - transition rank 0.64531
*/
proc corr data=results_ranks_corr_all plots=matrix(histogram); 
var OverallRank
	SwimRank
	BikeRank
	RunRank 
	TransitionRank
	 ;
run;

proc sgscatter data=results_ranks_corr_all; 
matrix OverallRank
  		SwimRank
  		BikeRank 
  		RunRank 
  		TransitionRank
  		/ group=gender diagonal=(histogram kernel);
run;



























