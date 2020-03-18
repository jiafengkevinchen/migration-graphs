# Migration data

Big picture

- IRS sample is representative and good to use for US adult workers
- Other groups, such as 16-years olds, are probably underrepresented

Data quirks

- Unexplainable HUGE downward spike in 2014 in gross flows that is not there in 2013 and 2015. Net flows are probably ok for 2014, but gross are not. Nobody knows what happened including IRS; some bug in their reporting most likely.

- In 2011/2012 and onwards IRS switched their methodology to determine county flows. Their methodology processes tax returns and changed the rules how they trace back addresses for married couples etc, which resulted in level changes in the data
- Net flows are most reliable
- IRS are censoring at 10 people moving between their counties
- Tax returns map better to households but not perfectly to individuals, so better to think about movement in terms of family units here. Better look at the data for exemptions (?? -- forgot what Gregor meant here) 
- There are smaller errors in the data. 2-3 lines differ in net outflows vs net inflows due to some IRS errors. Some lines are repeated

Rare disasters

- Exclude New Orleans in 2005 and a couple of other places and years due to natural disasters. When Hurricane Katrina hit the state, massive migration of population (like, 35%), huge outlier. The same for a couple of other disasters. Filter out outliers. (That's useful for Gregor but not sure if applies to us -- outflows after rare disasters might be interesting to look at as well)

Geographies

- Better focus on commuting zones. A lot of movement between counties within one local labor market would be registered as migrations
- Census surveys capture work vs life county. Commuting zones are defined as everything above x% threshold in cross-commuting to work.
- 1990 CZ definition most easy to use, but CZs are a dynamic thing redefined with every Census
- Commuting zones are much better to use than MSAs. MSAs are often redefined and do not map into counties well. In 2012 the Bureau broke up New England into NECTA (New England City and Town Areas) that are small, horrible and map into nothing. After that MSAs for New England are not reported.
- Around 700 CZs. There are new crosswalks from PUMAs into CZs if want to map from ACS. 

Other datasets

- If you want longer time series, go to the National Archives and find 1980-1990 data from IRS, though in abysmal format.
- Other variables to support migration flows (county-level stats) are harder to find though. E.g. QCEW starts after 1990.
- ACS is good to look at people who are moving but it is a much smaller sample. 190mln tax returns in IRS vs 2-3mln in ACS. Splitting by demographics in ACS will reduce the sample to nothing. IRS is good for time trends. ACS captures other characteristics of movers but the data is coarser