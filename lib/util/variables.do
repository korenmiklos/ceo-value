generate byte exporter = export > 0 & !missing(export)

* log transformations
generate lnR = ln(sales)
generate lnEBITDA = ln(EBITDA)
generate lnL = ln(employment)
generate lnM = ln(materials)
generate lnWL = ln(personnel_expenses)
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
generate ROA = EBITDA/Ltangibles
* FIXME: check winsorization levels
replace ROA = -1 if ROA < -1
_pctile ROA, p(99)
replace ROA = r(r1) if ROA > r(r1)

* manager spells etc
egen firm_year_tag = tag(frame_id_numeric year)
egen firm_tag = tag(frame_id_numeric)

egen first_time = min(year) if !missing(person_id), by(frame_id_numeric person_id)
egen first_ceo_in_sample = min(first_time), by(frame_id_numeric)
generate byte ceo_tenure = year - first_time
* arrival of a CEO triggers a new spell. leave of a CEO does not. this is relevant for when n_ceo > 1
egen byte has_new_ceo = max(first_time == year), by(frame_id_numeric year)

tabulate has_new_ceo if firm_year_tag, missing

bysort firm_year_tag frame_id_numeric (year): generate ceo_spell = sum(has_new_ceo) if firm_year_tag
* for n_ceo > 1, propagate the ceo spell variable that was only computed once per firm-year
egen tmp = max(ceo_spell), by(frame_id_numeric year)
replace ceo_spell = tmp if missing(ceo_spell)

* ceo_spell = 0 denotes early firm-years with no CEO
* if CEO is missing in later years, we assume that the CEO did not change

tabulate ceo_spell if firm_year_tag, missing
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
tabulate max_ceo_spell if firm_tag, missing

egen last_year = max(year), by(frame_id_numeric)
generate byte exit = (year == last_year)

drop tmp has_new_ceo first_time first_ceo_in_sample firm_year_tag firm_tag last_year

* we only infer gender from Hungarian names
generate expat = missing(male)
generate firm_age = year - foundyear
generate ceo_age = year - birth_year
generate byte second_ceo = (ceo_spell == 2)
generate byte third_ceo = (ceo_spell >= 3)
generate byte founder = (manager_category == 1)
replace firm_age = 20 if firm_age > 20 & !missing(firm_age)
* use 3-year windows for cohort to increase cohort sizes
generate cohort = int(foundyear/3)*3
tabulate cohort, missing
* 1989 is divisible by 3
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

* quadratics
foreach var in ceo_age firm_age ceo_tenure {
    generate `var'_sq = `var'^2
}

* variables fixed by firm, can be used for segmenting the analysis
egen byte early_exporter = max(exporter & (ceo_spell <= 1)), by(frame_id_numeric)
egen early_employment = max(cond(ceo_spell <= 1, employment, .)), by(frame_id_numeric)
generate max_size = cond(max_employment < 10, 1, 2)
generate early_size = cond(early_employment < 10, 1, 2)
label define size 1 "Small (2-9)" 2 "Large (10+)"
label values max_size size
label values early_size size

* variable labels
label variable frame_id_numeric "Numeric frame ID"
label variable foundyear "Year of foundation"
label variable person_id "Person ID"
label variable manager_category "Manager category"
label variable male "Male CEO"
label variable owner "CEO is owner"
label variable expat "Expatriate CEO"
label variable birth_year "Year of birth"
label variable firm_age "Firm age (years)"

label variable ceo_age "CEO age (years)"
label variable ceo_tenure "CEO tenure (years)"
label variable ceo_spell "CEO spell"
label variable second_ceo "Second CEO"
label variable third_ceo "Third or later CEO"
label variable founder "Founding owner"
label variable owner "Non-founding owner"
* quadratics
label variable ceo_age_sq "CEO age squared"
label variable firm_age_sq "Firm age squared"
label variable ceo_tenure_sq "CEO tenure squared"

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
label variable lnK "Fixed assets (log)"
label variable lnM "Materials (log)"
label variable intangible_share "Intangible assets share"
label variable lnWL "Wagebill (log)"
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
label variable ROA "Return on assets (EBITDA/L.tangibles, winsorized between -1 and p99)"
label variable investment "Net investment (change in log fixed assets)"
