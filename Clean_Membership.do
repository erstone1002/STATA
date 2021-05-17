/***********************************************

FILE NAME: Create Membership Do-file.do
AUTHOR: Eliza Stone
DATE CREATED: October 24, 2020
PURPOSE: This do-file creates a year over year clean dataset for the NCES CCD membership file.

***********************************************/
capture log close
log using "\Users\eliza\OneDrive\Documents\EDLF_5310_DataManagement\Final Project\Do-files\Create_Membership", replace

clear all
set more off

global drive "C:"

global path "\Users\eliza\OneDrive\Documents\EDLF_5310_DataManagement"

global folder "Final Project"

global raw_data "Raw Data"

global clean_data "Clean Data"

cd "$drive/$path/$folder/$raw_data"


/*********************************************
****************2015-16**********************/

import delimited using "ccd_member_15.csv",clear
save "ccd_member_15_raw", replace
keep if statename == "NORTH CAROLINA"

//drop variables not needed for join
drop fipst survyear stabr statename seaname leaid st_leaid lea_name schid st_schid member
browse

//identify and drop adult ed and ungraded variables
codebook *ug* *ae*
drop *ug* *ae* g13

//making sure this only removes pre-K, K, grade 1,2,3,4,5 variables
drop *pk*

//dropping race-grade-gender totals
drop amkgm - tr13f total

//dropping race-gender totals
drop amalm amalf asalm asalf hialm hialf blalm blalf whalm whalf hpalm hpalf tralm tralf

//labeling grade and race variables
label var kg "Kindergarten students"
label var g01 "Grade 1 students"
label var g02 "Grade 2 students"
label var g03 "Grade 3 students"
label var g04 "Grade 4 students"
label var g05 "Grade 5 students"
label var g06 "Grade 6 students"
label var g07 "Grade 7 students"
label var g08 "Grade 8 students"
label var g09 "Grade 9 students"
label var g10 "Grade 10 students"
label var g11 "Grade 11 students"
label var g12 "Grade 12 students"

label var as "All Students - Asian"
label var hi "All Students - Hispanic"
label var am "All Students - American Indian/Alaska Native"
label var bl "All Students - Black"
label var wh "All Students - White"
label var hp "All Students - Hawaiian Native/Pacific Islander"
label var tr "All Students - Two or More Races"


save "$drive/$path/$folder/$clean_data/ccd_member_15_clean", replace


/***************************************************
****************2016-17 & 2017-18******************/
foreach yr in 16 17 {	
	import delimited using "ccd_member_`yr'.csv", clear
	save "ccd_member_`yr'_raw", replace
	keep if statename == "NORTH CAROLINA" 

	//dropping variables not relevant for merge
	drop fipst statename st state_agency_no union st_leaid leaid schid st_schid total_indicator dms_flag schid
	order ncessch, first
	sort ncessch sch_name grade race_ethnicity sex 
	
//keeping grades of interest for analysis
	drop if grade == "Pre-Kindergarten"
	drop if grade == "Grade 13"
	
	//collapse sex
	collapse (sum) student_count, by (ncessch school_year sch_name grade race_ethnicity)
	
	//in order to reshape have to rename to abbreviations
	codebook race_ethnicity
	replace race_ethnicity = "tot" if race_ethnicity == "No Category Codes"
	replace race_ethnicity = "." if race_ethnicity == "Not Specified"
	replace race_ethnicity = "am" if race_ethnicity == "American Indian or Alaska Native"
	replace race_ethnicity = "as" if race_ethnicity == "Asian"
	replace race_ethnicity = "bl" if race_ethnicity == "Black or African American"
	replace race_ethnicity = "hi" if race_ethnicity == "Hispanic/Latino"
	replace race_ethnicity = "hp" if race_ethnicity == "Native Hawaiian or Other Pacific Islander"
	replace race_ethnicity = "tr" if race_ethnicity == "Two or more races"
	replace race_ethnicity = "wh" if race_ethnicity == "White"
	drop if race_ethnicity == "."	
		
	codebook grade
	replace grade = "tot" if grade == "No Category Codes"
	replace grade = "." if grade == "Not Specified"
	replace grade = "kg" if grade == "Kindergarten"
	replace grade = "01" if grade == "Grade 1"
	replace grade = "02" if grade == "Grade 2"
	replace grade = "03" if grade == "Grade 3"
	replace grade = "04" if grade == "Grade 4"
	replace grade = "05" if grade == "Grade 5"
	replace grade = "06" if grade == "Grade 6"
	replace grade = "07" if grade == "Grade 7"
	replace grade = "08" if grade == "Grade 8"
	replace grade = "09" if grade == "Grade 9"
	replace grade = "10" if grade == "Grade 10"
	replace grade = "11" if grade == "Grade 11"
	replace grade = "12" if grade == "Grade 12"
	drop if grade == "."


	//these totals create weird totals in the rows - will create total columsn later
	drop if race_ethnicity == "tot"

	rename student_count cnt
	egen graderace = concat(grade race_ethnicity)
	drop grade race_ethnicity
	
	//reshape wide
	reshape wide cnt, i(ncessch school_year sch_name) j(graderace) string

	//create row totals by grade and race
	egen kg = rowtotal(*kg*)
	egen g01 = rowtotal(*01*)
	egen g02 = rowtotal(*02*)
	egen g03 = rowtotal(*03*)
	egen g04 = rowtotal(*04*)
	egen g05 = rowtotal(*05*)
	egen g06 = rowtotal(*06*)
	egen g07 = rowtotal(*07*)
	egen g08 = rowtotal(*08*)
	egen g09 = rowtotal(*09*)
	egen g10 = rowtotal(*10*)
	egen g11 = rowtotal(*11*)
	egen g12 = rowtotal(*12*)
	
	egen am = rowtotal(*am)
	egen as = rowtotal(*as)
	egen bl = rowtotal(*bl)
	egen hi = rowtotal(*hi)
	egen hp = rowtotal(*hp)
	egen tr = rowtotal(*tr)
	egen wh = rowtotal(*wh)
	
	//dropping race-grade-gender totals
	drop cnt01am - cnttotwh
	
	//labeling grade and race variables
	label var g06 "Grade 6 students"
	label var g07 "Grade 7 students"
	label var g08 "Grade 8 students"
	label var g09 "Grade 9 students"
	label var g10 "Grade 10 students"
	label var g11 "Grade 11 students"
	label var g12 "Grade 12 students"

	label var as "All Students - Asian"
	label var hi "All Students - Hispanic"
	label var am "All Students - American Indian/Alaska Native"
	label var bl "All Students - Black"
	label var wh "All Students - White"
	label var hp "All Students - Hawaiian Native/Pacific Islander"
	label var tr "All Students - Two or More Races"
		
	save "$drive/$path/$folder/$clean_data/ccd_member_`yr'_clean", replace
}

* Convert log file to a PDF file.
translate Create_Membership.smcl Create_Membership.pdf

translate Clean_Membership.do Clean_Membership.pdf, translator(txt2pdf)