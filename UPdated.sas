libname k 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED';
PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\ec90 data.csv'
 out = k.transaction
 dbms = csv
 replace;
run;

proc print data= k.transaction(obs=100);
run;
PROC CONTENTS DATA=k.transaction;
RUN;
proc sort data=k.transaction;
   by CUSTOMERID;
run;

PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\transactionhistoryforcurrentcustomers.csv'
 out = k.transaction_history
 dbms = csv
 replace;
run;

proc print data= k.transaction_history(obs=10);
run;
PROC CONTENTS DATA=k.transaction_history;
RUN;
proc sort data=k.transaction_history;
   by CUSTOMERID;
run;



/*********************************************************************************************************/
/*PROC SQL JOIN*/
proc sql;
create table k.MergedRecords as	
  select * from k.transaction_history a inner join k.transaction b
   on a.CustomerID = b.CustomerID; quit;
/*ADDING COLUMNS BASED ON DATE*/
/*ORDERDATE*/
data k.MergedRecords;
set k.MergedRecords;
Date = datepart(OrderDate);
format Date date9.;
run;

proc print data = k.MergedRecords;run;
quit;

proc export 
  data=k.MergedRecords 
  dbms=xlsx 
  outfile="C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\MERGERES.xlsx" 
  replace;
run;

/*ORDERDATE MONTH*/
data k.MergedRecords;
set k.MergedRecords;
Month = intnx('month', Date, 0);
format Month monname3.;
run;

proc print data = k.MergedRecords(obs=100);run;


/*ORDERDATE YEAR*/
data k.MergedRecords;
set k.MergedRecords;
Year = year(Date);
run;

proc print data = k.MergedRecords;run;
/*********************************************************************************************************/
/*TOTAL OBASERVATIONS*/

proc contents data=k.MergedRecords varnum;
run;

%macro totobs(mydata);
    %let mydataID=%sysfunc(OPEN(&mydata.,IN));
    %let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
    %let RC=%sysfunc(CLOSE(&mydataID));
    &NOBS
%mend;
%put %totobs(k.MergedRecords);

/*MISSING VALUES*/
data k.missing_values;
set k.MergedRecords (keep= _numeric_);
cnt_missing_numeric = nmiss(of Price);	
run;
proc print data= k.missing_values;
run;

proc freq data=k.MergedRecords;
run;
proc means data=one NMISS N; run;

proc freq data=k.MergedRecords;
table Category /missing;
run;



/*********************************************************************************************************************************************/

/*UNIVARIATE ANALYSIS*/
/*PRICE*/
PROC UNIVARIATE Data=k.transaction_history;
 VAR Price;
TITLE2 " HISTOGRAM for Price in PROC UNIVARIATE";
HISTOGRAM / NORMAL (COLOR=RED W=5) NROWS=2;
RUN; 
/*SOURCE*/
proc freq data = k.MergedRecords;
tables Source;
run;
PROC SGPLOT DATA=k.MergedRecords ;
 VBAR Source / GROUP=Source
 DATALABEL
 FILL
 GROUPDISPLAY=Cluster ;
RUN ;
/*CONCLUSION : Top 3  sources Regular, Web, IVR*/

/*CATTEGORY*/
proc freq data = k.MergedRecords;
tables Category;
run;

/*TEST OF INDEPENDENCY*/
proc anova data = k.MergedRecords;
class Source;
model Price = Source;
run;
proc anova data = k.MergedRecords;
class Category;
model Price = Category;
run;

TITLE 'VBAR Chart with SGPLOT' ;
PROC SGPLOT DATA=k.MergedRecords ;
 VBAR Category / GROUP=Category
 DATALABEL
 FILL
 GROUPDISPLAY=Cluster ;
RUN ;
/*CONCLUSION : Categories C, F, K are the top 3 categories */


%include "C:\Users\praka\OneDrive\Desktop\METRO\SAS\ADVANCE_SAS\PROJECT\KRUTIKA_PROJECT\univariate_analysis.sas";
%UNI_ANALYSIS_NUM(k.MergedRecords,Price)
%UNI_ANALYSIS_NUM(k.MergedRecords,Quantity)
%UNI_ANALYSIS_CAT_FORMAT(k.transaction_history,Category)
%UNI_ANALYSIS_CAT_FORMAT(k.transaction_history,Source)
%UNI_ANALYSIS_CAT_FORMAT(k.transaction,Source)
%UNI_ANALYSIS_CAT_FORMAT(k.data2,Month)
%UNI_ANALYSIS_CAT_FORMAT(k.data3,Year)

TITLE ‘Vertical Bar Chart for Category’ ;
PROC SGPLOT DATA=k.MergedRecords ;
 VBAR Category / GROUP=Category ;
RUN ;
TITLE ‘Vertical Bar Chart for Source ;
PROC SGPLOT DATA=k.MergedRecords ;
 VBAR Source / GROUP=Source ;
RUN ;

/*BIVARIATE PLOTS*/
/*TOP 10 CUSTOMERID WITH HIGHEST SALES */
PROC SQL outobs=10;
create table k.Sales_CustomerID as
SELECT CustomerID, SUM(Price) AS SALES
FROM k.transaction_history
group by CustomerID
ORDER BY  SALES DESC;;
QUIT;
TITLE 'TOP 10 CUSTOMERS WITH HIGHEST RECORDS';
proc sgplot data=k.Sales_CustomerID ;
 hbar CustomerID / response= Sales 
 GROUP=CustomerID
 dataskin=gloss datalabel
 categoryorder=respdesc nostatlabel;
 xaxis grid display=(nolabel);
 yaxis grid discreteorder=data display=(nolabel);
 run;

 /*TOP 10 PROVINCE WITH HIGHEST SALES*/
 PROC SQL outobs=10;
create table k.Sales_Province as
SELECT Prov, SUM(Price) AS SALES
FROM k.MergedRecords
group by Prov
ORDER BY  SALES DESC;;
QUIT;
title'TOP 10 PROVINCE WITH HIGHEST SALES';
proc sgplot data=k.Sales_Province ;
 hbar Prov / response= Sales
 dataskin=matt datalabel
 baselineattrs=(thickness=0)
 fillattrs=(color= 'green');
 xaxis grid display=(nolabel);
 yaxis grid discreteorder=data display=(nolabel);
 run;
/*TOTAL SALES BY YEAR, MONTH AND SOURCE*/
 title 'TOTAL SALES BY YEAR (2007), MONTH AND SOURCE ';
proc sgplot data=k.MergedRecords(where=(year=2007))noborder;
  format Price dollar8.0;
  hbar Month / response=Price stat=sum
           group=Source seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/*CONCLUSION : SALES ARE HIGH FROM MAY TO DECEMBER, HIGHEST SALES IN MONTH AUGUST */

title 'TOTAL SALES BY YEAR (2008), MONTH AND SOURCE ';

proc sgplot data=k.MergedRecords(where=(year=2008))noborder;
  format Price dollar8.0;
  hbar Month / response=Price stat=sum
           group=Source seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/*CONCLUSION : SALES ARE HIGH FROM JAN TO APRIL, HIGHEST SALES IN MONTH MARCH */


/*TOTAL SALES BY YEAR, MONTH AND CATEGORY */
 title 'Sales by Type and Quarter for 2007';
proc sgplot data=k.MergedRecords(where=(year=2007))noborder;
  format Price dollar8.0;
  hbar Month / response=Price stat=sum
           group=Category seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/*CONCLUSION : CATEGORY J,E,B HAS HIGHEST SALES FROM MAY TO DECEMBER*/

 title 'Sales by Type and Quarter for 2008';
proc sgplot data=k.MergedRecords(where=(year=2008))noborder;
  format Price dollar8.0;
  hbar Month / response=Price stat=sum
           group=Category seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/*CONCLUSION : CATEGORY B,c HAS HIGHEST SALES FROM JAN TO FEBRUARY*/

/*TOTAL SALES BY YEAR SOURCE CATEGORY*/
 title 'Sales by Type and Quarter for 2007';
proc sgplot data=k.MergedRecords(where=(year=2007))noborder;
  format Price dollar8.0;
  vbar Category / response=Price stat=sum
           group=Source seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;

/*TOTAL SALES BY YEAR SOURCE CATEGORY*/
 title 'Sales by Type and Quarter for 2008';
proc sgplot data=k.MergedRecords(where=(year=2008))noborder;
  format Price dollar8.0;
  vbar Category / response=Price stat=sum
           group=Source seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/*TOTAL SALES BY YEAR SOURCE*/
title 'Sales by Type and Year';
proc sgplot data=k.MergedRecords noborder;
  vbar Source / response=Price
          group=Year groupdisplay=cluster
         dataskin=pressed
         baselineattrs=(thickness=0);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline) grid;
run;

/*TOTAL SALES PROVINCE CATEGORY SOURCE*/
title 'PROVINCE CATEGORY SOURCE';
proc sgplot data=k.MergedRecords noborder;
  format actual dollar8.0;
  hbar Prov / response=Price stat=sum
           group=Category seglabel datalabel
          baselineattrs=(thickness=0)
          outlineattrs=(color=cx3f3f3f);
  xaxis display=(nolabel noline noticks);
  yaxis display=(noline noticks) grid;
run;
/****************************************************************************/

/*MODELLING*/

data k.var_mlr;
set k.transaction_history; 
drop OrderDate;
run;

 %macro label_encode(dataset,var);
   proc sql noprint;
     select distinct(&var)
     into:val1-
     from &dataset;
 select count(distinct(&var))  into:mx from &dataset;
 quit;
 data k.encode_itemdesc;
     set &dataset;
   %do i=1 %to &mx;
     if &var="&&&val&i" then encode_itemdesc=&i;
   %end;
   run;
 %mend;

/* define a macro to create dummy variables */
 %label_encode(k.var_mlr,Category)
 %label_encode(k.encode_category,CustomerID)
 %label_encode(k.encode_customerid,ItemCode)
 %label_encode(k.encode_itemcode,Source)


  proc print data=k.encode_category(obs=100);
   proc print data=k.encode_customerid(obs=100);
    proc print data=k.encode_itemcode(obs=100);

data k.labelencodeddata;
set  k.encode_itemcode;
drop CustomerID ItemCode Source ItemDescription Category;
run;
proc print data=k.labelencodeddata(obs=10);

/*Model */
proc sgscatter;
matrix price Quantity encode_category encode_customerid encode_itemcode;
run;

proc sgscatter data=k.labelencodeddata;
  title " Dependent & Independent Variable";
  compare y=(price)
          x=(Quantity encode_category encode_customerid encode_itemcode)
          / reg ellipse=(type=mean) spacing=4;
run;
title;

proc reg data=k.labelencodeddata;
   model price = Quantity encode_category encode_customerid encode_itemcode;
run;


/*MODELLING ON MERGED DATA*/
PROC  PRINT DATA = k.MERGEDRECORDS;
data k.variables_reg;
set k.MergedRecords; 
drop OrderDate ItemDescription Date PostalCode encode_customerid ;
run;
PROC  PRINT DATA = k.variables_reg(OBS=100);

 %macro label_encode(dataset,var);
   proc sql noprint;
     select distinct(&var)
     into:val1-
     from &dataset;
 select count(distinct(&var))  into:mx from &dataset;
 quit;
 data k.encode_ordernumber;
     set &dataset;
   %do i=1 %to &mx;
     if &var="&&&val&i" then encode_ordernumber=&i;
   %end;
   run;
 %mend


/* Label encoding variables */
 %label_encode(k.variables_reg,CustomerID);
 %label_encode(k.encode_customerid,ItemCode);
 %label_encode(k.encode_itemcode,Category);
 %label_encode(k.encode_category,Source);
 %label_encode(k.encode_source,City);
 %label_encode(k.encode_city,Prov);
 %label_encode(k.encode_prov,OrderFirstTime);
 %label_encode(k.encode_orderfirsttime,OrderNumber);
 %label_encode(k.encode_ordernumber,Year);



proc print data=k.encode_ordernumber(obs=100);


data k.labelencodeddata1;
set  k.encode_ordernumber;
drop CustomerID OrderNumber ItemCode Source ItemDescription Category City Prov ItemCode Month Year;
run;
proc print data=k.labelencodeddata1(obs=10);

proc sgscatter;
matrix Price Quantity encode_category encode_customerid encode_city encode_prov encode_itemcode ;
run;

proc sgscatter data=k.labelencodeddata1;
  title " Dependent & Independent Variable";
  compare y=(Price)
          x=(Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov encode_orderfirsttime)
          / reg ellipse=(type=mean) spacing=4;
run;
title;


proc reg data = k.labelencodeddata1;
  model Price = Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov encode_orderfirsttime encode_ordernumber/ selection = forward slentry = 0.99;
run;
quit;
/*TRAIN TEST SPLIT*/

proc surveyselect data=k.labelencodeddata1 out=split_train_test method=srs samprate=0.70

         outall seed=12345 noprint;

  samplingunit encode_customerid;

run;

/*MODEL ON TRAIN DATA*/

libname k 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED';

PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\train_data_.csv'
 out = k.train_
 dbms = csv
 replace;
run;
proc print data= k.train_(obs=10);
run;

PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\test_data_ - Copy.csv'
 out = k.test_
 dbms = csv
 replace;
run;
proc print data= k.test_(obs=10);
run;
/*Training the data*/
proc reg data = k.train_ noprint outest=estimates;
model Price = Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov encode_orderfirsttime;
run;

/*Predicted score values*/
proc score data = k.test_ score=estimates
out=scored type=parms;
var Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov;
run;
PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\test_data_.csv'
 out = k.testtarget
 dbms = csv
 replace;
run;
proc reg data=k.testtarget;
model Price=Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov / stb clb;
output out=stdres p= predict r = resid;
run;
/*Correlation between y and x variables*/
PROC CORR DATA = k.labelencodeddata1  PLOTS= MATRIX(HISTOGRAM);
 VAR Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov;
 WITH Price;
RUN;

PROC CORR DATA = k.labelencodeddata1  PLOTS= MATRIX(HISTOGRAM);
 VAR Quantity encode_category encode_customerid encode_itemcode encode_city encode_prov encode_orderfirsttime encode_ordernumber ;
 WITH Price;
RUN;


/************************************************************************************************************/

/*GLM SELECT*/
PROC GLMSELECT data=k.variables_reg;
class CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year;
model  Price = Quantity CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year
/ selection=stepwise select=SL showpvalues stats=all STB;
run;

PROC GLMSELECT data=k.variables_reg;
class CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year;
model  Price = Quantity CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year
/ selection=forward(stop=none);
run;

/*TRAIN TEST*/
/*TRAIN TEST SPLIT*/

proc surveyselect data=k.variables_reg out=split_train_test method=srs samprate=0.70

         outall seed=12345 noprint;

  samplingunit CustomerID;

run;

libname k 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED';

PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\traindata_glmselect.csv'
 out = k.traindata
 dbms = csv
 replace;
run;
proc print data= k.traindata(obs=10);
run;

PROC IMPORT DATAFILE = 'C:\Users\praka\OneDrive\Desktop\METRO\KRUTIKA_SAS_PROJECT\UPDATED\testdata_glmselect.csv'
 out = k.testdata
 dbms = csv
 replace;
run;
proc print data= k.testdata(obs=10);
run;

PROC GLMSELECT data=k.traindata;
class CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year;
model  Price = Quantity CustomerID ItemCode Source Category OrderNumber City Prov OrderFirstTime Month Year
/ selection=forward(stop=none);
run;

