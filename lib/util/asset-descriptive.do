local year 2015

use "temp/analysis-sample.dta", clear
duplicates drop frame_id_numeric year, force

gen ln_tang = ln(tangible_assets)
gen ln_assets = ln(assets)
bysort year: egen mean_tang = mean(ln_tang)
bysort year: egen sd_tang = sd(ln_tang)
bysort year: egen mean_assets = mean(ln_assets)
bysort year: egen sd_assets = sd(ln_assets)

* Create z-scores
gen z_tang = (ln_tang - mean_tang) / sd_tang
gen z_assets = (ln_assets - mean_assets) / sd_assets

* Step 2: Histogram for tangible assets
histogram z_tang if year == `year', normal ///
    title("Tangible Assets Distribution (`year')") ///
    xtitle("Standardized Values") ytitle("Density") ///
    name(tang_hist, replace)

* Step 3: Histogram for total assets
histogram z_assets if year == `year', normal ///
    title("Total Assets Distribution (`year')") ///
    xtitle("Standardized Values") ytitle("Density") ///
    name(assets_hist, replace)

* Step 4: Combine both
graph combine tang_hist assets_hist, rows(1)
graph export "output/assets-`year'.png", replace width(2400)


histogram ln_tang if year > 2010, by(year) title("Log(tangibles)") xtitle("value") ytitle("Density")
graph export "output/tangibles.png", replace

histogram ln_assets if year > 2010, by(year) title("Log(assets)") xtitle("value") ytitle("Density")
graph export "output/assets.png", replace
/*
estpost tabstat tangible_assets assets, by(year) statistics(mean median p25 p75 min max) columns(statistics)

esttab using "output/assets-summary-analysis.tex", replace cells("mean(fmt(2)) median(fmt(2)) p25 p75 min max") label title("Asset Statistics by Year")
*/
