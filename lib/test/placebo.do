use "output/test/placebo.dta", clear

recode event_time min/-1 = -1 1/max = 1
drop if event_time == 0
collapse (count) n_year = TFP, by(frame_id_numeric event_time skill_change)
generate str when = cond(event_time < 0, "_before", "_after")
generate str skill = cond(skill_change == -1, "worse", cond(skill_change == 0, "same", "better"))

drop event_time skill_change
reshape wide n_year, i(frame_id_numeric skill) j(when) string
mvencode n_year*, mv(0)