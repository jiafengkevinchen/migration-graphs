/*** 
Purpose: Replicate Molloy and Smith (2019) basic migration declines
Created: BG 2020-4-14
***/

* CPS variables to read in
local usevars ///
	year			asecwth			age			edu			inctot			incwage ///
	empstat			labforce		sex			race		marst			migrate1 ///
	qmigrat1		 whymove
	
* List of valid migration years in the data
local migyears "1990/1993 1995/2018"

*-------------------------------------------------------------------------------------------------
* Clean demographic variables
*-------------------------------------------------------------------------------------------------

* Drop the few people with negative weights
* Exclude years with faulty migration data
use `usevars' if asecwth>0 & ~inlist(year, 1962, 1963, 1985, 1995) ///
	& ~inrange(year, 1972, 1975) & ~inrange(year, 1977, 1980) ///
	using "${external}/cps_00001", clear
*g rand=runiform()
*keep if rand<0.01

*** Education *** 
* Less than 12 grades, 12 grades of HS/diploma, some college, 4 or more years of college/degree
rename edu tmp
g edu=.

* 1962-1991
replace edu=1 if tmp<=60 & inrange(year, 1962, 1991)
replace edu=2 if inrange(tmp, 72, 73) & inrange(year, 1962, 1991)
replace edu=3 if inrange(tmp, 80, 100) & inrange(year, 1962, 1991)
replace edu=4 if inrange(tmp, 110, 122) & inrange(year, 1962, 1991)

* 1992-2019
replace edu=1 if tmp<=71 & inrange(year, 1992, 2019)
replace edu=2 if tmp==73 & inrange(year, 1992, 2019)
replace edu=3 if inrange(tmp, 81, 92) & inrange(year, 1992, 2019)
replace edu=4 if inrange(tmp, 111, 125) & inrange(year, 1992, 2019)
drop tmp

* Verify by looking for breaks in wages around 1992 (looks pretty good)
*binscatter incwage year if inrange(year, 1980, 2000), discrete linetype(none) by(edu) rd(1991.5)

*** Marital status ***
g married=marst==1
drop marst

*** Sex ***
g male=sex==1
drop sex

*** Race ***
* Do white, black, other so consistent throughout sample
rename race tmp
g race=.

* 1962-1987
replace race=1 if tmp==100 & inrange(year, 1962, 1987)
replace race=2 if tmp==200 & inrange(year, 1962, 1987)
replace race=3 if tmp==700 & inrange(year, 1962, 1987)

* 1988-2002
replace race=1 if tmp==100 & inrange(year, 1988, 2002)
replace race=2 if tmp==200 & inrange(year, 1988, 2002)
replace race=3 if inrange(tmp, 300, 700) & inrange(year, 1988, 2002)

* 2003-2019
replace race=1 if tmp==100 & inrange(year, 2003, 2019)
replace race=2 if tmp==200 & inrange(year, 2003, 2019)
replace race=3 if inrange(tmp, 300, 830) & inrange(year, 2003, 2019)
drop tmp

* Again verify by looking for breaks in variables (seems good--small jump in white around 2000)
*binscatter married year, discrete by(race) rd(1987.5 2002.5) linetype(none)

*** Age ***
* Make ventiles of age
fastxtile age_bin=age, nq(20)

*** Reasons for moving ***
g job_move=inlist(whymove, 4, 5, 6, 7, 8) if whymove!=0 & ~mi(whymove) 
g housing_move=inlist(whymove, 9, 10, 11, 12, 13) if whymove!=0 & ~mi(whymove) 
g family_move=inlist(whymove, 1, 2, 3) if whymove!=0 & ~mi(whymove) 
g other_move=job_move==0 & housing_move==0 & family_move==0 if whymove!=0 & ~mi(whymove) 

*-------------------------------------------------------------------------------------------------
* Build move variables
*-------------------------------------------------------------------------------------------------

* Exclude from sample:
*	Individuals who moved abroad, had "unknown" response, moved but did not report where, and NIU
 
* Any move
g move=migrate1!=1 if ~mi(migrate1) & ~inlist(migrate1, 0, 2, 6, 9)

* Within county move
g move_in_cty=migrate1==3 if ~mi(migrate1) & ~inlist(migrate1, 0, 2, 6, 9) & (mi(qmigrat1) | qmigrat1==0)

* Within state across counties
g move_cty_in_st=migrate1==4 if ~mi(migrate1) & ~inlist(migrate1, 0, 2, 6, 9) & (mi(qmigrat1) | qmigrat1==0)

* Moved across states
g move_st=migrate1==5 if ~mi(migrate1) & ~inlist(migrate1, 0, 2, 6, 9) & (mi(qmigrat1) | qmigrat1==0)

* Moved counties
g move_cty=migrate1==4 | migrate1==5 if ~mi(migrate1) & ~inlist(migrate1, 0, 2, 6, 9) & (mi(qmigrat1) | qmigrat1==0)

* Define a new year variable for year of migration
g move_year=year-1

*-------------------------------------------------------------------------------------------------
* Basic figure on migration
*-------------------------------------------------------------------------------------------------

* Binscatter of move rates
binscatter move move_in_cty move_cty move_st move_year if move_year>=1990 [w=asecwth], discrete linetype(connect) ///
	xscale(range(1990 2018)) xlabel(1990(5)2015) xmtick(##5) xtitle("Year") /// 
	mcolor("${c1}" "${c2}" "${c3}" "${c4}") lcolor("${c1}" "${c2}" "${c3}" "${c4}") ///
	ytitle(Fraction Moving) ylabel(, gmax format(%03.2f)) ymtick(##5) ///
	legend(order(1 "Any move" 2 "Within county" 3 "Across counties" 4 "Across States") row(1) size(*.75)) ///
	title("")
graph export "${output}/mig_all_types_trend.pdf", replace

*-------------------------------------------------------------------------------------------------
* Regression adjusted move rates
*-------------------------------------------------------------------------------------------------

* Generate an indicator for having non-missing values for all variables
* Do 1989 and beyond
g in_samp=1
foreach v in move_cty move_in_cty age_bin edu married race male move_year {
	replace in_samp=0 if mi(`v') | move_year<1989
}

* Create variables to store coefficients
g coef_year=.
foreach s in raw_cty raw_in_cty demo_cty demo_in_cty {
	g b_`s'=.
	g se_`s'=.
}

* Unadjusted version
foreach y in cty in_cty {
	reg move_`y' i.move_year if in_samp==1 [w=asecwth], robust
	foreach i of numlist `migyears' {
		replace b_raw_`y'=_b[`i'.move_year] in `=`i'-1989'
		replace se_raw_`y'=_se[`i'.move_year] in `=`i'-1989'
		replace coef_year=`i' in `=`i'-1989'
	}
}

* All demographic variables
foreach y in cty in_cty {
	areg move_`y' i.edu i.married i.race i.male i.move_year if in_samp==1 [w=asecwth], absorb(age_bin) robust
	foreach i of numlist `migyears' {
		replace b_demo_`y'=_b[`i'.move_year] in `=`i'-1989'
		replace se_demo_`y'=_se[`i'.move_year] in `=`i'-1989'
	}
}

* Recenter coefficients around 1989, gather standard error bars
foreach y in cty in_cty {
	su move_`y' if move_year==1989 & in_samp==1
	foreach s in raw demo {
		replace b_`s'_`y'=b_`s'_`y'+`r(mean)'
		g top_`s'_`y'=b_`s'_`y'+1.96*se_`s'_`y'
		g bot_`s'_`y'=b_`s'_`y'-1.96*se_`s'_`y'
	}
}

* Across county moves
twoway ///
	scatter b_raw_cty coef_year, mcolor("${c1}") || ///
	scatter b_demo_cty coef_year, mcolor("${c2}") || ///
	line top_demo_cty coef_year, lcolor("${c2}") lpattern(shortdash) || ///
	line bot_demo_cty coef_year, lcolor("${c2}") lpattern(shortdash) ///
	xscale(range(1990 2018)) xlabel(1990(5)2015) xmtick(##5) xtitle("Year") /// 
	ytitle(Fraction Moving) ylabel(, format(%03.2f) gmax) ymtick(##5) ///
	legend(order(1 "Raw" 2 "Demographic adj.") row(1)) ///
	title("")
graph export "${output}/mig_cty_adj.pdf", replace

	
	
