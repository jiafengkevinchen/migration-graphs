clear all
set more off

// enter your path to directory with data folder
local directory = "/Users/malekseev/Migration"
cd "`directory'"


****************************************************************************
/* STANDARDIZE VARIABLE VALUES */
****************************************************************************


loc type1 = "inflow"
loc base1 = "to"
loc flow1 = "from"

loc type2 = "outflow"
loc base2 = "from"
loc flow2 = "to"


forval i = 1/2 {
	use "./DataOutput/01_prepare_data/`type`i''_varnames", clear

	// state names
	replace st_base_name = upper(st_base_name)
	replace st_flow_name = upper(st_flow_name)

	// county base names
	loc a "base flow"
	foreach j of local a {
		gen temp1 = strpos(cty_`j'_name, " Tot") - 1
		gen temp2 = strpos(cty_`j'_name, " (Tot") - 1
		gen temp3 = strpos(cty_`j'_name, " Coun") - 1
		replace cty_`j'_name = substr(cty_`j'_name, 1, temp1) if temp1 > 0
		replace cty_`j'_name = substr(cty_`j'_name, 1, temp2) if temp2 > 0
		replace cty_`j'_name = substr(cty_`j'_name, 1, temp3) if temp3 > 0
		drop temp*
	}

	// copy codes for non-migration
	replace st_flow = st_base if nonmigr == 1
	replace cty_flow = cty_base if nonmigr == 1
	replace st_flow_name = st_base_name if nonmigr == 1 ///
		& !missing(st_flow_name)
	replace cty_flow_name = cty_base_name if nonmigr == 1

	// generate FIPS codes
	gen tempvar1 = string(st_base, "%02.0f")
	gen tempvar2 = string(cty_base, "%03.0f")
	gen tempvar3 = string(st_flow, "%02.0f")
	gen tempvar4 = string(cty_flow, "%03.0f")

	gen cty_base_fips = tempvar1 + tempvar2, before(st_base_name)
	la var cty_base_fips "County `base`i'', 5-digit FIPS"
	gen cty_flow_fips = tempvar3 + tempvar4, before(st_flow_name)
	la var cty_flow_fips "County `flow`i'', 5-digit FIPS"
	drop tempvar*


	save "./DataOutput/01_prepare_data/`type`i''_vals", replace
}

