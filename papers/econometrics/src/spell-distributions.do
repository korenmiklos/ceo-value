use "../../temp/analysis-sample.dta", clear

egen firm_year_tag = tag(frame_id_numeric year)
bysort frame_id_numeric ceo_spell: egen spell_length = sum(firm_year_tag)

local spells ""
forvalues i = 1/4 {
    histogram ceo_tenure if ceo_spell == `i' [fw=1/spell_length], ///
        title("CEO Spell `i'", size(medium)) ///
        name(spell`i', replace) ///
        xtitle("") ytitle("Frequency") ///
        disc ///
        percent
    local spells "`spells' spell`i'"
}

graph combine `spells', ///
    title("Distribution of Spell Length by CEO Spell") ///
    cols(2) ///

graph export "figure/ceo-spell-distributions.pdf", replace

local no_max ""
forvalues i = 1/4 {
    histogram ceo_tenure if ceo_spell == `i' & ceo_spell != max_ceo_spell [fw=1/spell_length], ///
        title("CEO Spell `i'", size(medium)) ///
        name(no_max`i', replace) ///
        xtitle("") ytitle("Frequency") ///
        disc ///
        percent
    local no_max "`no_max' no_max`i'"
}

graph combine `no_max', ///
    title("Distribution of Spell Length by CEO Spell (not last CEO)") ///
    cols(2) ///

graph export "figure/no-max-spell-distributions.pdf", replace
