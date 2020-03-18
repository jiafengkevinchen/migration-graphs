clear all
set more off

// enter your path to directory with data folder
local directory = "/Users/malekseev/Migration"
cd "`directory'"


****************************************************************************
/* DROP OBSERVATIONS */
****************************************************************************

loc type1 = "inflow"
loc type2 = "outflow"


forval i = 1/2 {
	use "./DataOutput/01_prepare_data/`type`i''_vals", clear

	// drop aggregated migration stats
	drop if missing(st_flow) | st_flow >= 96 | st_flow == 0 ///
		| st_flow == 59 | cty_flow == 0

	// drop foreign migration stats
	drop if st_flow == 57

	// export
	save "./DataOutput/01_prepare_data/`type`i''_masterfile", replace
	export delimited ///
		using "./DataOutput/01_prepare_data/`type`i''_masterfile", ///
		nolabel replace
}

