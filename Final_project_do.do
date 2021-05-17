*****************************
* Title: GLM Final Project  *
* Data Source: EHSRE Study	*
* Author: Eliza Stone		*
* Last edited: 4/27/2021	*
*****************************

cd "C:/Users/eliza/OneDrive/Documents/EDLF_8310_GLM/Final Project"

use "EHSRE Study.dta", clear
********************************
** Initial Cleaning ***********
*******************************
** Dropping variables not important to research questions **

** dropping variables from 5th grade sample
	drop C5_DATA - T5_SSRS_HY

** dropping variables about depression, health, birth and pregnancy
	drop NODEPRES - PREGNANT
	drop B1P_MAS5 - B2P_CONF
	
** dropping variables about work and social supports by quarter
	drop EVERACT-EDUCQ8
	drop ANYWQ1 - WORKQ8
	
** father data
	drop B2D_TYPE - P2V_ENG2
	
** dropping info on child health, home 
	drop P0_MDCDC - BIRBY24
	
tempfile ehrs_clean1
save `ehrs_clean1'


*******************************
********************************
** DATA EXPLORATION AND CLEANING
************************************
**********************************

** ID is unique by child/respondent
	codebook IDNUM
	
********************************
**** Child assessment variables
*********************************

** variable if completed pre-k assessment
	tab C4PP_DATA //binary 0/1
	
** WJ Applied Problems and Letter-Word Identification
	tab C4WJAPSS //prek
	tab C4WJLWSS //prek
	
	
** pre-k PPVT assessment
	codebook C4PPVT3S
	sum C4PPVT3S
	tab C4PPVT3S  //standard score at pre-k
	tab B3RPPVTS //PPVT standard score at 36 months
	tab C4TVIPS, missing
	sum  C4TVIPS //spanish spoken version

	
** Mental development index assessment
	codebook B1B_MDI //14 months
	codebook B2B_MDI // 24 months
	codebook  B3B_MDI  //36 months
		
****************************************	
**** Childcare quality variables ****
***************************************
** ECER measured at 36 months
	codebook ECER_AVE
	sum ECER_AVE
	tab ECER_AVE
	tab T4ECRTTL //pre-k

** ITER measured at 14 and 24 months
	codebook ITER14
	sum ITER14
	tab ITER14
	tab ITER24
	
**************************************	
****** Caregiver Variables **********
***************************************	
** Parent supportiveness in play activity
	codebook B1V3_SUP //14 month
	tab B1V3_SUP
	codebook B2V3_SUP //24 month
	tab B2V3_SUP
	codebook B3V3_SUP //36 month
	tab B2V3_SUP
	egen supportMean = rowmean(B1V3_SUP B2V3_SUP B3V3_SUP)
	
** Total Hrs worked
	tab TOTHRSW
	
** HOME Observation for Measurement of the Environment:measures the cognitive stimulation and emotional support provided by the parent in the home environment. 
	tab B1P_HOME //14 month
	tab B3P_HOME //36 month HOME score
	tab B2P_HOME //24 month

	
******************************	
******* Covariates ********
*****************************
**ECE random assignment
	tab PROGRAM
	codebook PROGRAM //binary variable for ECE assignment

**child gender
	codebook CSEX
	tab  CSEX // child gender by program assignment
	encode CSEX, generate(CGENDER)
	recode CGENDER 3=. 2=0 1=1 //recode so female is 1 male is 0
	codebook CGENDER
	label define gender3 1 "female" 0 "male"
	label values CGENDER gender3

** Childs age 
	tab CMTHS //age at random assignment	
	tab CHLDAGEG //child age (categorical) at random assignment
	
** Primary caregiver Race
	codebook RACE
	tab RACE 
	
** English as Primary Language
	tab ENGLISH 

** Primary caregiver highest education
	tab HGCG //categorical
	tab HGC26 //highest grade completed at 26
	
** Age of respondent at random assignment
	tab AAGE 

** % of poverty line
	sum POVRATIO 
	tab POV4  //categorical for higher than 100% of poverty line

	
save "ehrs_clean.dta", replace

*************************************	
*********************************
******** Data Cleaning ********
*********************************
************************************
	
use "ehrs_clean.dta",clear
** keep relevant variables for analysis
	keep IDNUM C4PPVT3S B1P_HOME B2P_HOME B3P_HOME ITER14 ITER24 PROGRAM RACE POVRATIO ENGLISH HGCG B4PINCOM AAGE CHLDAGEG CMTHS CGENDER POV4 HGC26 P2V_CC14 P2V_CC24 P2V_CC36 C4PP_DATA C4WJAPSS C4WJLWSS B1V3_SUP B2V3_SUP B3V3_SUP ECER_AVE C4TVIPS
	
** relabel variables for clarity
	label variable ITER24 "Childcare Center Quality Score"
	label variable C4PPVT3S "PPVT Receptive Language Standard Score"
	label variable B3V3_SUP "Parent Supportiveness Score"
	label variable B3P_HOME "HOME Score"
	label variable AAGE "Primary Caregiver Age"
 
 

** global to clean all relevant variables
	global allvars C4PPVT3S B2P_HOME B3P_HOME ITER14 ITER24 RACE POVRATIO ENGLISH HGCG B4PINCOM AAGE CHLDAGEG CMTHS B1P_HOME POV4 HGC26 C4WJAPSS C4WJLWSS P2V_CC14 P2V_CC24 P2V_CC36 B1V3_SUP B2V3_SUP B3V3_SUP ECER_AVE C4TVIPS
	
** replacing missing indicators	
	foreach var in $allvars {
		replace `var' =. if `var' < 0
	}
	

** drop if no PPVT data
	tab C4PP_DATA, missing
	drop if C4PP_DATA == 0

save "ehrs_reduced_clean.dta", replace

*****************************
*** Summary Statistics ******
****************************
	use "ehrs_reduced_clean.dta", clear
	sum $allvars
	
** sum stats of covariates
	sum CMTHS ENGLISH POVRATIO HGC26 AAGE CGENDER
	sum mean_ppvt B3P_HOME ITER24 B3V3_SUP
	asdoc sum C4PPVT3S B3P_HOME ITER14, ///
	save(SumTable.doc) ///
	dec(1)
	
** PPVT score, HOME score, and ITER score by program assignment
	tabstat C4PPVT3S B3P_HOME ITER24 B3V3_SUP, by(PROGRAM) stat(N mean)

** covariates by program
	asdoc tabstat CGENDER CHLDAGEG ENGLISH POVRATIO HGCG AAGE RACE, by(PROGRAM) columns(variables) stat(N mean sd median) ///
	save(Tables3.doc) title(Descriptive Statistics by Program) ///
	dec(1) 

	asdoc tabstat  CGENDER CHLDAGEG ENGLISH POVRATIO HGCG AAGE RACE,  stat(N mean sd median) nototal long col(stat) ///
		save(Tables3.doc) title(Descriptive Statistics by Program) ///
	dec(1) 
	
	bysort PROGRAM: tab CGENDER
	
****************************************
********** Missing Data *************
***************************************
mi set mlong

*variables with missing data
mdesc C4PPVT3S B3P_HOME ITER24 B3V3_SUP	CGENDER ENGLISH POVRATIO HGCG AAGE RACE 

tabmiss C4PPVT3S B3P_HOME ITER24 B3V3_SUP CGENDER ENGLISH POVRATIO HGCG AAGE RACE 

sort PROGRAM ITER24
browse PROGRAM ITER24

**missing data patterns
mvpatterns C4PPVT3S B3P_HOME ITER24 B3V3_SUP CGENDER ENGLISH POVRATIO HGCG AAGE RACE

* Multiple Imputation 

* Phase 1: Imputation

* Register variables to impute, and to leave alone
* These are variables with  missing data that I wish to impute
mi register imputed B3P_HOME ITER24 B3V3_SUP ENGLISH POVRATIO HGCG RACE
* These are variables with complete data that I don't want touched
mi register regular AAGE

* Impute using chained equations: regression for continuous variables (locus); logistic regression for binary (retained, female); ordinal logistic for ordinal variable (math perf) 
* Use SES as an auxillary variable for prediction of missingness
* Create 5 imputed datasets
mi impute chained (regress) B3P_HOME ITER24 B3V3_SUP POVRATIO ///
	(logit) ENGLISH  ///
	(ologit) RACE HGCG = AAGE, add(5)

** check imputed dataset
mi describe

** Phase 2: Analysis
	
** estimate model using imputed values
mi estimate: reg C4PPVT3S B3P_HOME B3V3_SUP i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust

mi estimate: reg C4PPVT3S B3P_HOME B3V3_SUP ITER24 i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust


***************************
****************************
*** Model Specification ****
****************************
*************************

**** Initial Analysis ********

** Dependent variable by program assignment
graph box C4PPVT3S, over(PROGRAM)
	graph export fig2.pdf, replace
* Examine the difference in means between two groups
tabstat C4PPVT3S, stat(n mean sd) by(PROGRAM)

** ITER by program assignment
graph box ITER24, over(PROGRAM)
	graph export fig3.pdf, replace
tabstat ITER24, stat(n mean sd) by(PROGRAM)

** Bivariate analysis 
tabstat C4PPVT3S, by(B3P_HOME)
tabstat C4PPVT3S, by(ITER24)
tabstat C4PPVT3S, by(B3V3_SUP)

** Distributions
histogram B3P_HOME
histogram ITER24
histogram B3V3_SUP


** Additive model 1
reg C4PPVT3S B3P_HOME B3V3_SUP i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
estimates store Add1
margins, at(B3P_HOME=(0(5)35))
marginsplot

margins, at(B3V3_SUP=(0(1)8))
marginsplot

esttab Add1  using "Additive 1", rtf replace se label


** Additive 2
reg C4PPVT3S B3P_HOME B3V3_SUP ITER24 i.PROGRAM i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
estimates store Add2


** Interactive model 
reg C4PPVT3S B3P_HOME B3V3_SUP c.ITER24##PROGRAM  i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust 
estimates store Interactive

margins PROGRAM, at(ITER24=(2 4 6 8))
marginsplot 

** Output results to table
esttab Add1 Add2 Interactive using "MyResults", rtf replace se label


** Run regression, the estesto + estout commands allow you to output your regression in a fun table
eststo, title("Additive Model 1"): reg C4PPVT3S B3P_HOME B3V3_SUP i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
eststo, title("Additive Model 2"): reg C4PPVT3S B3P_HOME B3V3_SUP ITER24 i.PROGRAM i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
eststo, title("Interactive Model"): reg C4PPVT3S B3P_HOME B3V3_SUP c.ITER24##PROGRAM i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
estout, cells(b(star label(Coef.) fmt(a3)) se(label(SE) fmt(2) par))  ///
label legend varlabels(_cons Constant) ///
stats(r2 p rmse N, labels(R-squared "RMSE" "Overall F test" "N. of cases")) 
eststo clear


******************************
*********************************
****** Visualizations ********
**********************************
******************************

** histogram of dependent variable
sum C4PPVT3S
histogram C4PPVT3S
	graph export fig1.pdf, replace
	
** Scatter of PPVT score by HOME score
scatter C4PPVT3S B3P_HOME, msize(tiny) mcolor(gray) xtitle("HOME score") ytitle("PPVT score") ///
	|| lfit C4PPVT3S B3P_HOME, lcolor(red) ///
 legend(lab(1 PPVT Scores) lab(2 Linear Model)) 
graph export explore.pdf, replace

** Scatter of PPVT score by supportiveness score
scatter C4PPVT3S B3V3_SUP, msize(tiny) mcolor(gray) xtitle("Supportiveness score") ytitle("PPVT score") ///
	|| lfit C4PPVT3S B3V3_SUP, lcolor(red) ///
 legend(lab(1 PPVT Scores) lab(2 Linear Model)) 
graph export explore2.pdf, replace



///scatter of childcare quality by program type
twoway (scatter C4PPVT3S ITER24, msym(oh) jitter(3)) ///
       (lfit C4PPVT3S ITER24 if ~PROGRAM)(lfit C4PPVT3S ITER24 if PROGRAM), ///
       legend(order(2 "EHS Program" 3 "Other")) 

	   
** regress data
regress C4PPVT3S B3P_HOME B3V3_SUP ITER24 i.PROGRAM i.CGENDER i.ENGLISH POVRATIO i.HGCG AAGE i.RACE, robust
**margin plots
margins, at(B3P_HOME=(0(5)40))
marginsplot

margins, at(B3V3_SUP=(0(1)8))
marginsplot

margins, at(ITER24=(0(1)8))
marginsplot

margins, at(PROGRAM=(0(1)1))
marginsplot