clear all
set more off

// enter your path to directory with data folder
local directory = "/Users/malekseev/Migration"
cd "`directory'"


****************************************************************************
/* CHANGE VARIABLE NAMES AND LABELS */
****************************************************************************

loc type1 = "inflow"
loc base1 = "to"
loc flow1 = "from"
loc varname1 = "Inflow"

loc type2 = "outflow"
loc base2 = "from"
loc flow2 = "to"
loc varname2 = "Outflow"

forval i = 1/2 {
	use "./DataInput/01_prepare_data/`type`i''_allyears.dta", clear


	rename flow_county cty_flow_name
	la var cty_flow_name "County `flow`i'', name"

	rename flow_state st_flow_name
	la var st_flow_name "State `flow`i'', name"

	la var returns "Returns, #"

	rename exemptions exempt
	la var exempt "Exemptions, #"

	rename non_migrants nonmigr
	la var nonmigr "County from == county to"

	rename cty_total totalmigr
	la var totalmigr "County total migration, #"

	rename base_county cty_base_name
	la var cty_base_name "County `base`i'', name"

	rename base_state st_base_name
	la var st_base_name "State `base`i'', name"

	rename base_county_id cty_base
	la var cty_base "County `base`i'', FIPS"

	rename base_state_id st_base
	la var st_base "State `base`i'', FIPS"

	rename `varname`i''_state_id st_flow
	la var st_flow "State `flow`i'', FIPS"

	rename `varname`i''_county_id cty_flow
	la var cty_flow "County `flow`i'', FIPS"

	rename income_year year
	la var year "Income year"

	rename filing_year yr_file
	la var yr_file "Filing year"

	rename agg_income income
	la var income "Adjusted gross income, USD1000"

	order year yr_file st_base cty_base st_base_name cty_base_name ///
		st_flow cty_flow st_flow_name cty_flow_name nonmigr totalmigr ///
		returns exempt income

	save "./DataOutput/01_prepare_data/`type`i''_varnames", replace
}

