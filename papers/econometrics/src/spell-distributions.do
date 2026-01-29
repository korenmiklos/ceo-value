use "../../temp/analysis-sample.dta", clear

bysort frame_id_numeric ceo_spell: egen spell_length = count(year)

local spells ""
forvalues i = 1/4 {
    histogram spell_length if ceo_spell == `i' [fw=spell_length], ///
        title("CEO Spell `i'", size(medium)) ///
        frequency ///
        name(spell`i', replace) ///
        xtitle("") ytitle("Frequency")
    local spells "`spells' spell`i'"
}

graph combine `spells', ///
    title("Distribution of Spell Length by CEO Spell") ///
    cols(2) ///

graph export "figure/ceo-spell-distributions.pdf", replace

local no_max ""
forvalues i = 1/4 {
    histogram spell_length if ceo_spell == `i' & ceo_spell != max_ceo_spell [fw=spell_length], ///
        title("CEO Spell `i'", size(medium)) ///
        frequency ///
        name(no_max`i', replace) ///
        xtitle("") ytitle("Frequency")
    local no_max "`no_max' no_max`i'"
}

graph combine `no_max', ///
    title("Distribution of Spell Length by CEO Spell (not last CEO)") ///
    cols(2) ///

graph export "figure/no-max-spell-distributions.pdf", replace
