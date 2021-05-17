/***********************************************

FILE NAME: Analytic Do-file.do
AUTHOR: Eliza Stone
DATE CREATED: November 15th, 2020
PURPOSE: This do-file performs data prep and analysis in order to build graphs and descriptive statistics.

***********************************************/

clear all
set more off

global drive "C:"

global path "\Users\eliza\OneDrive\Documents\EDLF_5310_DataManagement"

global folder "Final Project"

global clean_data "Clean Data"

global analytic "Analytic Outputs"

cd "$drive/$path/$folder/$analytic"

/****************************************************
*********************data prep*************************
*****************************************************/
use "$drive/$path/$folder/$clean_data/ccd_merge_allyrs", clear
desc

/***creating total that does not count negative numbers**/
	foreach var of varlist kg-g12{
		gen c_`var' = `var' if `var' >= 0
		label variable c_`var' "Count of students in `var'"
	}
	egen total = rowtotal(c_*)
	label variable total "Total enrollment without negative numbers"
	//dropping old variables with negative numbers
	drop kg-g12

/***creating charter as an indicator variable**/
	gen charter_id = "0" if charter_text == "No"
	replace charter_id= "1" if charter_text == "Yes"
	label variable charter_id "Charter school flag"
	destring charter_id, replace

/***creating more intuitive label for charter**/
	replace charter_text = "Charter" if charter_text == "Yes"
	replace charter_text = "Non-Charter" if charter_text == "No"

/***create variable for fall of year of survey**/
	codebook school_year
	gen fall_schyr = "2015" if school_year == "2015-2016"
	replace fall_schyr = "2016" if school_year == "2016-2017"
	replace fall_schyr = "2017" if school_year == "2017-2018"
	codebook fall_schyr
	label variable fall_schyr "Fall of school year survey was conducted"
	//destring for analysis
	destring fall_schyr, replace

/***get percentages & totals of charter schools by year**/
	tab school_year charter_id, row
	by school_year, sort: egen pct = mean(100*(charter_id))
	label variable pct "% of charters by school year"
	//count of all charter schools in a given school year
	by school_year, sort: egen chart_tot = sum(charter_id)  if charter_id == 1
	label variable chart_tot "Total charters schools by year"

/***generate FRPL related variables by school**/
	gen p_totfrl=(100*(totfrl/total))
	label variable p_totfrl "Percent of student body thats Free or Reduced Price lunch eligible"
	
	//creating buckets for % of FRPL students by school
	egen quartfrl = cut(p_totfrl), at(0,25,50,75,110)
	tab quartfrl charter_text, column
	label variable quartfrl "Category of % Free or Reduced Price lunch eligible students"
	
	//labeling groups created by cut
	label define quartile 0 "<25% of school FRL eligible" 25 "25-50% FRL eligible" 50 "50-75% FRL eligible" 75 ">75% of school FRL eligible"
	label value quartfrl quartile

/***generating race percentages by school**/
	foreach var of varlist am as hi hp tr wh bl {
		gen p_`var'=100*`var'/total
		label variable p_`var' "Percent of student body that is `var'"
	}

/***student to teacher ratio**/
	gen stratio = total/teachers
	label variable stratio "Teacher student ratio"
	bysort fall_schyr: egen ncratio = mean(stratio) if charter_id == 0
	bysort fall_schyr: egen cratio = mean(stratio) if charter_id == 1
	label variable ncratio "Student-teacher ratio among Non-Charters"
	label variable cratio "Student-teacher ratio among Charters"
	
save final_merge_file, replace
	 

/****************************************************
****************Descriptive Statistics**************
****************************************************/

cd "$drive/$path/$folder/$analytic/Tables"

/***table for descriptive statistics of all schools in NC**/
asdoc tabstat p_*, by(charter_text) column(stat) stat(N mean sd p25 median p75) ///
	save(Table1.doc) title(Descriptive Statistics by School Type) ///
	dec(1) 
	
/***table for descriptive statistics by school type**/
asdoc tabstat p_*, by(charter_text) column(stat) stat(N mean sd median) ///
	save(Tables2.doc) title(Descriptive Statistics by School Type) ///
	dec(1) 

/**table for enrollment statistics by school type**/
asdoc tabstat total, by(charter_text) column (stat) stat(N mean sd p25 median p75) ///
	save(Tables3.doc) title(Enrollment by School Type) ///
	dec(1) 
	
/**table for student to teacher ratio by school type**/
asdoc tabstat stratio, by(charter_text) column (stat) stat(N mean sd p25 median p75) ///
	save(Tables4.doc) title(Student to Teacher Ratio) ///
	dec(1)
	

/****************************************************
***********************Graphs***********************
****************************************************/
cd "$drive/$path/$folder/$analytic/Graphs" 

/***line graph of charter growth over years**/
	help graph twoway
	twoway connected chart_tot fall_schyr, msize(small) xlabel(2015(1)2017) ylabel(150(5)180) ///
	title("Charter School Growth in NC") xtitle("School year") ysca(titlegap(.25cm)) /// 
	xsca(titlegap(.25cm)) ytitle(Charter School Count)
	graph save charter_growth_line, replace
	graph export charter_growth_line.png, replace


/***demographic pie chart**/
	help graph pie
	graph pie am as hi hp tr wh bl, sort(tr) pie(1,color(navy)) pie(2,color(ltblue)) ///
	pie(3,color(ltkhaki)) pie(4,color(dknavy)) pie(6,color(forest_green)) plabel(_all percent, format(%9.2g) ///
	gap(2rs) color(white) size(vsmall)) legend(size(vsmall)) ///
	by(charter_text,  title("Demographics of Charter and Traditional Public Schools", size(medium)) note (""))
	graph save demographic_pie, replace
	graph export demographic_pie.png, replace


/***frpl quintile chart**/
	//installing catplot
	ssc inst catplot
	catplot quartfrl charter_text, percent(charter_text) stack asyvars bar(1, blcolor(gs13) bfcolor(dknavy)) ///
	bar(2, blcolor(gs13) bfcolor(ltblue)) bar(3, blcolor(gs13) bfcolor(dimgray)) ///
	bar(4, blcolor(gs13) bfcolor(lavender)) legend(size(small)) ///
	title("Percentage of Free & Reduced Price Lunch by School Type", size(medium))  
	graph save catplot_frpl, replace
	graph export catplot_frpl.png, replace

	tab quartfrl charter_text, col
	
/***bar chart for % FRPL**/
	collapse (mean) p_totfrl, by(fall_schyr charter_text)
	save charter_frl, replace
	use charter_frl
	graph bar p_totfrl, over(charter_text) over(fall_schyr) asyvars bar(2, color(lavender)) ///
	ytitle("% of FRPL eligible students", size(small)) ylabel(0(10)80) ysca(titlegap(.5cm)) ///
	title("Percentage of students eligible for Free or Reduced Price Lunch by School Type", size(medsmall)) 
	graph save p_totfrl_bar, replace
	graph export p_totfrl_bar.png, replace
	
/***state map **/
//installing mapping 
ssc install spmap
ssc install shp2dta


//converting shape file for work with data
shp2dta using nc, database(usdb) coordinates(uscoord) genid(id) replace

//describing new shp data file and renaming to work for merge
use usdb, clear
desc
codebook NAME
rename NAME county
save usdb2, replace

//pulling in latest year of data
use "$drive/$path/$folder/$clean_data/ccd_merge_17", clear
tab county charter_text
	gen charter_id = "0" if charter_text == "No"
	replace charter_id= "1" if charter_text == "Yes"
	label variable charter_id "Charter school flag"
	destring charter_id, replace
//creating county as a unique observation
collapse (sum) charter_id, by (county)
merge 1:1 county using usdb2
drop _merge

//buidling map of NC 
spmap charter_id using uscoord, id(id) fcolor(Blues) title("Charter schools by County") ///
legend(size(medium)) clmethod(custom) clbreaks(0 .01 1 2 5 10 20 30) 
help spmap
graph save nc_map, replace
graph export nc_map.jpg, replace

	