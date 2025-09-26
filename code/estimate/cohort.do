use "temp/unfiltered.dta", clear
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen

* for babyboom, we measure manager skills in revenue units, not as TFP
replace manager_skill = manager_skill / chi
BRK
keep if component_id > 0
generate byte hungarian_name = !missing(male)

keep if hungarian_name

collapse (mean) manager_skill (min) birth_year first_year = year (max) male last_year = year (min) component_id (max) component_size, by(person_id founder)
reshape wide manager_skill first_year last_year birth_year male, i(person_id) j(founder)

* relatively few overlap, use the first ceo spell
egen first_year = rowmin(first_year?)
egen last_year = rowmax(last_year?)
egen manager_skill = rowmean(manager_skill?)
egen birth_year = rowmin(birth_year?)
egen male = rowmax(male?)

generate byte founder = first_year0 > first_year
tabulate first_year founder

generate cohort = int(first_year/5)*5
tabulate cohort founder

generate birth_cohort = int(birth_year/5)*5

egen n = count(person_id), by(first_year founder male)
generate ln_n = ln(n)

local controls male
local FEs component_id birth_cohort
local sample birth_year <= 2000

* different components may have different means
reghdfe manager_skill ib1985.cohort `controls' if founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill ib1985.cohort `controls' if !founder & `sample', a(`FEs') cluster(first_year )

reghdfe manager_skill ln_n `controls' if !founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill ln_n `controls' if founder & `sample', a(`FEs') cluster(first_year )
reghdfe manager_skill i.founder##c.ln_n `controls' if `sample', a(`FEs') cluster(first_year )

/*
. reghdfe lnR founder if N_jobs == 1, a(teaor08_2d##year) cluster(frame_id_numeric )
(dropped 95 singleton observations)
(MWFE estimator converged in 1 iterations)

HDFE Linear regression                            Number of obs   =  6,644,272
Absorbing 1 HDFE group                            F(   1, 756956) =    6211.92
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.1392
                                                  Adj R-squared   =     0.1388
                                                  Within R-sq.    =     0.0099
Number of clusters (frame_id_numeric) =    756,957Root MSE        =     1.9026

                 (Std. err. adjusted for 756,957 clusters in frame_id_numeric)
------------------------------------------------------------------------------
             |               Robust
         lnR | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     founder |    -.46113   .0058507   -78.82   0.000    -.4725973   -.4496628
       _cons |   9.565178   .0055272  1730.55   0.000     9.554345    9.576011
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------------+
       Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------------+---------------------------------------|
   teaor08_2d#year |      2837           0        2837     |
-----------------------------------------------------------+

. reghdfe lnR founder if N_jobs == 1, a(teaor08_2d##year person_id ) cluster(frame_id_numeric )
(dropped 146096 singleton observations)
(MWFE estimator converged in 44 iterations)

HDFE Linear regression                            Number of obs   =  6,498,271
Absorbing 2 HDFE groups                           F(   1, 691784) =    4246.81
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.7512
                                                  Adj R-squared   =     0.7154
                                                  Within R-sq.    =     0.0053
Number of clusters (frame_id_numeric) =    691,785Root MSE        =     1.0869

                 (Std. err. adjusted for 691,785 clusters in frame_id_numeric)
------------------------------------------------------------------------------
             |               Robust
         lnR | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
     founder |  -.5765646   .0088474   -65.17   0.000    -.5939053    -.559224
       _cons |   9.673032   .0068833  1405.30   0.000     9.659541    9.686523
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------------+
       Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------------+---------------------------------------|
   teaor08_2d#year |      2833           0        2833     |
         person_id |    815118           1      815117     |
-----------------------------------------------------------+

*/