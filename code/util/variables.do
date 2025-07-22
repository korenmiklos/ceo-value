generate EBITDA = sales - personnel_expenses - materials

* log transformations
generate lnR = ln(sales)
generate lnEBITDA = ln(EBITDA)
generate lnL = ln(employment)
generate lnK = ln(tangible_assets)
generate lnK_w_immat = ln(tangible_assets + intangible_assets)

* manager spells etc
egen firm_year_tag = tag(frame_id_numeric year)
egen firm_tag = tag(frame_id_numeric)
egen first_time = min(year), by(frame_id_numeric person_id)
generate ceo_tenure = year - first_time
egen n_new_ceo = sum(first_time == year), by(frame_id_numeric year)
bysort firm_year_tag frame_id_numeric (year): generate ceo_spell = sum(n_new_ceo > 0) if firm_year_tag
egen tmp = max(ceo_spell), by(frame_id_numeric year)
replace ceo_spell = tmp if missing(ceo_spell)

tabulate ceo_spell if firm_year_tag, missing
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
tabulate max_ceo_spell if firm_tag, missing

drop tmp n_new_ceo first_time firm_year_tag firm_tag

* we only infer gender from Hungarian names
generate expat = missing(male)
generate firm_age = year - foundyear
generate ceo_age = year - birth_year

* quadratics
foreach var in ceo_age firm_age ceo_tenure {
    generate `var'_sq = `var'^2
}

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
label variable lnK "Tangible assets (log)"
label variable lnK_w_immat "Tangible assets + Intangible assets (log)"