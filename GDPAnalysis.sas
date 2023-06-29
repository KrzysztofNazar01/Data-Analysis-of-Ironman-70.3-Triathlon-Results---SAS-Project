* Import Gross Domestic Product of countries dataset;
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_NY.GDP.MKTP.CD_DS2_en_excel_v2_5551619_edited.xls'
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
		GDP2019='GDP in 2019'
		;
	format GDP2019 DOLLAR30.2;
run;
 
/* proc contents data=countr_gdp_formatted; */
proc print data=countr_gdp_formatted (obs=10) label;
	title 'Gross Domestic Product of Countries in 2019';
run;

* Import Population of countries dataset;
proc import datafile='/home/u63345464/sasuser.v94/Project/Data/API_SP.POP.TOTL_DS2_en_excel_v2_5551740_edited.xls'
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
		POP2019='Population in 2019'
		;	
	format POP2019 15.;
run;
 
proc print data=countr_pop_formatted (obs=10) label;
	title 'Population of Countries in 2019';
run;

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

* Analyze correlation between GDP values and the number of participants;
proc sort data=results_paxes_by_country;
	by descending NumOfParticipants;
run;

proc print data=results_paxes_by_country (obs=10) label;
	var Country NumOfParticipants NumOfBestParticipants paxes_prop;
	title 'Results of participants and best participants by country sorted by number of participants';
run;

* Merge the GDP and population dataset with Participant dataset;
proc sql;
    create table CountriesGDPPOPmerged as
    select a.CountryName, a.GDP2019, a.GDPPC2019, b.NumOfParticipants, b.NumOfBestParticipants, b.paxes_prop
    from CountriesGDPPOP as a
    right join results_paxes_by_country as b
    on a.CountryName = b.Country;
quit;

* Delete rows with missing values;
data CountriesGDPPOPmerged;
    set CountriesGDPPOPmerged;
    if missing(CountryName) then delete;
run;

proc print data=CountriesGDPPOPmerged (obs=10) label;
	var CountryName GDP2019 GDPPC2019 NumOfParticipants NumOfBestParticipants paxes_prop;
	title 'GDP, population, and number of participants by country';
run;

proc corr data=CountriesGDPPOPmerged plots=matrix(histogram); 
	var GDP2019	GDPPC2019 NumOfParticipants NumOfBestParticipants;
	title 'Correlation results between GDP, GDP per capita and number of participants';
run;


