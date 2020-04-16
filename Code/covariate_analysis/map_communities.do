/***
Purpose: Covariate analysis
Created: BG 2020-4-14
***/

*-------------------------------------------------------------------------------------------------
* Maps
*-------------------------------------------------------------------------------------------------

* Read in the community assignments
import delimited "${input}/group_labels_seed=2138.csv", clear varnames(nonames) rowrange(2:)
rename v1 county

* Keep primary community detection specifications
rename (v2 v12 v22 v32 v42) (q_1990 q_1995 q_2000 q_2005 q_2010)
rename (v7 v17 v27 v37 v47) (p_1990 p_1995 p_2000 p_2005 p_2010)
keep county q* p*

* Remake community IDs such that they are ordered ascending by count
ds county, not
global comm_vars `r(varlist)'
quietly foreach x of global comm_vars {
	preserve
	
	* Keep only counties that received a community assignment under definition x
	drop if mi(`x')
	
	* Count number of counties in each community
	egen total=count(county), by(`x')
	
	* Keep 1 observation per community and reassign IDs based on frequencies
	bysort `x': keep if _n==1
	gsort -total
	g bin=_n
	
	* Re-assign all communities not in the top 5 together
	replace bin=6 if bin>5
	
	keep `x' bin
	tempfile holder
	save `holder'
	restore 
	
	* Merge new community IDs on to original data set
	merge m:1 `x' using `holder', nogen
	drop `x'
	rename bin `x'
}
compress
/*
* Combine all places no
foreach j in q p {
	forvalues i=1990(5)2010 {
		maptile `j'_`i', geo(county2000) cutpoints(`j'_`i') fcolor(Accent) ///
		twopt(legend(off) ///
		title("`i'-`=`i'+5'", size(*.7)) name(`j'_`i', replace))
	}
	ds `j'*
	graph combine `r(varlist)', cols(1)
	graph export "${output}/mig_maps_`j'.png", replace width(4000) 

}
*/

*-------------------------------------------------------------------------------------------------
* Distribution of community assignments
*-------------------------------------------------------------------------------------------------

hist q_1990, freq ///
	fcolor("scheme p1") lcolor("scheme p1") ///
	xtitle("Community") ///
	ytitle("Number of Counties") ylabel(0(200)800) 
graph export "${output}/q_1990_counts.pdf", replace

hist q_2010, freq ///
	fcolor("scheme p1") lcolor("scheme p1") ///
	xtitle("Community") ///
	ytitle("Number of Counties") ylabel(0(200)800) 
graph export "${output}/q_2010_counts.pdf", replace

hist p_1990, freq ///
	fcolor("scheme p2") lcolor("scheme p2") ///
	xtitle("Community") ///
	ytitle("Number of Counties") ylabel(0(200)800) 
graph export "${output}/p_1990_counts.pdf", replace

hist p_2010, freq ///
	fcolor("scheme p2") lcolor("scheme p2") ///
	xtitle("Community") ///
	ytitle("Number of Counties") ylabel(0(200)800) 
graph export "${output}/p_2010_counts.pdf", replace

*-------------------------------------------------------------------------------------------------
* Covariate analysis
*-------------------------------------------------------------------------------------------------

* Build identifier for data linkage
rename county fips
tostring fips, replace format(%05.0f)
g state=substr(fips, 1, 2)
g county=substr(fips, 3, 3)
destring state county, replace

* Merge on covariates
merge 1:1 state county using "${external}/cty_covariates", keep(1 3) nogen

* Build a list of covariates to use
global covars ///
	emp2000 frac_coll_plus2000 hhinc_mean2000 mail_return_rate2010 mean_commutetime2000 ///
	poor_share2000 popdensity2000 share_black2000 share_white2000 singleparent_share2000
	
* Store R-squared from reg of covariates on community bins
quietly foreach y of global covars {
	foreach x of global comm_vars {
		areg `y', absorb(`x')
		local `y'_`x'=`e(r2)'
	}
}	
	
* Build an empty data set with the results
local tot_vars : word count $covars
local tot_comm : word count ${comm_vars} 

clear
set obs `tot_vars'
g x=""
forvalues i=1/`tot_vars'{
	local tmp : word `i' of $covars
	replace x="`tmp'" in `i'
}

expand `tot_comm'
g comm=""
forvalues i=1/`tot_comm' {
	local tmp : word `i' of ${comm_vars} 
	bysort x: replace comm="`tmp'" if _n==`i'
}

* Populate the R-2s
g r2=.
foreach y of global covars {
	foreach x of global comm_vars {
		replace r2=``y'_`x'' if x=="`y'" & comm=="`x'"
	}
}	
	
* Type of bin (quantity or percentage)
g type=substr(comm, 1, 1)

graph bar (asis) r2 if type=="q", ///
	over(comm, relabel(1 "1990-1995" 2 " " 3 " "  4 " "  5 "2010-2015") ///
		gap(*.1) sort(x) label(angle(vertical) labsize(*.6))) ///
		over(x, relabel(1 "Employment" 2 "College" 3 "Income" 4 "Census Return" 5 "Commute" ///
		6 "Poverty" 7 "Pop. Density" 8 "Share Black" 9 "Share White" 10 "Single Parent") ///
		sort(x) gap(*3) label(labsize(*.6))) ///
		ytitle("R-Squared") ylabel(0(0.03).15, gmax format(%03.2f)) ///
		bar(1, lcolor("scheme p1") fcolor("scheme p1"))
graph export "${output}/q_covars.pdf", replace 
 
		
graph bar (asis) r2 if type=="p", ///
	over(comm, relabel(1 "1990-1995" 2 " " 3 " "  4 " "  5 "2010-2015") ///
		gap(*.1) sort(x) label(angle(vertical) labsize(*.6))) ///
		over(x, relabel(1 "Employment" 2 "College" 3 "Income" 4 "Census Return" 5 "Commute" ///
		6 "Poverty" 7 "Pop. Density" 8 "Share Black" 9 "Share White" 10 "Single Parent") ///
		sort(x) gap(*3) label(labsize(*.6))) ///
		ytitle("R-Squared") ylabel(0(0.03).15, gmax format(%03.2f)) ///
		bar(1, lcolor("scheme p2") fcolor("scheme p2"))
graph export "${output}/p_covars.pdf", replace

