generate byte exporter = export > 0 & !missing(export)

* log transformations
generate lnK = ln(tangible_assets)
generate lnA = ln(assets)
generate lnR = ln(sales)
generate lnEBITDA = ln(EBITDA)
generate lnL = ln(employment)
generate lnM = ln(materials)
generate lnWL = ln(wagebill) - lnL
generate lnKL = lnK - lnL
generate lnRL = lnR - lnL
generate lnMR = lnM - lnR
generate lnYL = ln(sales-materials) - lnL
generate exportshare = export / sales
replace exportshare = 0 if exportshare < 0
replace exportshare = 1 if exportshare > 1 & !missing(exportshare)
generate intangible_share = intangible_assets / (tangible_assets + intangible_assets)
replace intangible_share = 0 if intangible_share < 0 | missing(intangible_share)
replace intangible_share = 1 if intangible_share > 1
generate byte has_intangible = intangible_assets > 0
egen max_employment = max(employment), by(frame_id_numeric)
generate EBITDA_share = EBITDA / sales
replace EBITDA_share = 0 if EBITDA_share < 0
replace EBITDA_share = 1 if EBITDA_share > 1 & !missing(EBITDA_share)
generate ROA = aftertax/(L.assets+assets) * 2
generate ROA_op = EBITDA/(L.tangibles + tangible_assets) * 2

sum ROA, d
replace ROA = . if ROA < r(p1) | (ROA>r(p99) & !missing(ROA))

sum ROA_op, d
replace ROA_op = . if ROA_op < r(p1) | (ROA_op>r(p99) & !missing(ROA_op))


egen firm_year_tag = tag(frame_id_numeric year)
egen firm_tag = tag(frame_id_numeric)

* ceo_spell = 0 denotes firm-years with no CEO
tabulate ceo_spell if firm_year_tag, missing
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
tabulate max_ceo_spell if firm_tag, missing

egen last_year = max(year), by(frame_id_numeric)
generate byte exit = (year == last_year)

drop firm_year_tag firm_tag last_year

* we only infer gender from Hungarian names
generate firm_age = year - foundyear
replace firm_age = 20 if firm_age > 20 & !missing(firm_age)
* use 3-year windows for cohort to increase cohort sizes
generate cohort = int(foundyear/3)*3
tabulate cohort, missing
* 1989 is divisible by 3
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

* quadratics
foreach var in firm_age {
    generate `var'_sq = `var'^2
}

* variables fixed by firm, can be used for segmenting the analysis
egen byte early_exporter = max(exporter & (ceo_spell <= 1)), by(frame_id_numeric)
egen early_employment = max(cond(ceo_spell <= 1, employment, .)), by(frame_id_numeric)
generate max_size = cond(max_employment < 10, 1, 2)
generate early_size = cond(early_employment < 10, 1, 2)

* drop, not just miss, because event study is looking for a "balanced" panel in terms of non-missing outcomes
drop if missing(ROA)

label define size 1 "Small (2-9)" 2 "Large (10+)"
label values max_size size
label values early_size size

* variable labels
label variable frame_id_numeric "Numeric frame ID"
label variable foundyear "Year of foundation"
label variable n_ceo_male "Number of male CEOs"
label variable has_expat_ceo "Expatriate CEO"
label variable has_founder "Founder CEO"
label variable firm_age "Firm age (years)"

label variable ceo_spell "CEO spell"
* quadratics
label variable firm_age_sq "Firm age squared"

label variable year "Year"
label variable sales "Sales"
label variable export "Export"
label variable employment "Employment"
label variable tangible_assets "Tangible assets"
label variable materials "Materials"
label variable wagebill "Wagebill"
label variable personnel_expenses "Personnel expenses"
label variable intangible_assets "Intangible assets"
label variable state_owned "State owned"
label variable foreign_owned "Foreign owned"
label variable n_ceo "Number of CEOs in a year"
label variable lnR "Sales (log)"
label variable lnEBITDA "EBITDA (log)"
label variable lnL "Employment (log)"
label variable lnK "Tangible assets (log)"
label variable lnA "Fixced assets (log)"
label variable lnM "Materials (log)"
label variable intangible_share "Intangible assets share"
label variable lnWL "Average wage per worker (log)"
label variable has_intangible "Has intangible assets"

label variable EBITDA "Earnings before interest, taxes, depreciation, and amortization"
label variable exporter "Exporter firm"

label variable max_employment "Maximum employment in sample"
label variable exit "Exit in year"
label variable early_exporter "Exporter in first CEO spell"
label variable early_size "Firm size in first CEO spell (2-49, 50+)"
label variable max_size "Maximum firm size in sample (2-49, 50+)"
label variable EBITDA_share "EBITDA to sales ratio (winsorized between 0 and 1)"
label variable lnKL "Capital to labor ratio (log)"
label variable lnRL "Sales to labor ratio (log)"
label variable lnMR "Materials to sales ratio (log)"
label variable exportshare "Export to sales ratio (winsorized between 0 and 1)"
label variable ROA "Return on assets (winsorized between p1 and p99)"
