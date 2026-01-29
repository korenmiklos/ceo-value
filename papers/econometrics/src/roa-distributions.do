use "../../temp/analysis-sample.dta", clear

ridgeline ROA if inlist(year, 1995, 2000, 2005, 2010, 2015, 2020, 2025), ///
    by(year) norm(local) overlap(10) palette(CET C7)
graph export "figure/ridgeline-ROA.pdf", replace

vioplot ROA if inlist(year, 1995, 2000, 2005, 2010, 2015, 2020, 2025), ///
    over(year) horizontal
graph export "figure/violin-ROA.pdf", replace
