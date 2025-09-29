*! Read annual minimum wages from STADAT, keep 2012 onwards
* Created: 2025-09-29
* Input: stadat-mun0069-20.8.1.16-hu.csv
* Output: temp/minimum_wage.dta

clear all

* Import CSV data with semicolon delimiter
import delimited "stadat-mun0069-20.8.1.16-hu.csv", ///
    delimiter(";") varnames(2) encoding("utf-8") clear

* Check what variable names were imported
describe

* Clean up variable names (use the actual variable names from describe output)
rename idpont date_str
rename aminimlbrhavi~t minimum_wage_str
rename aminimlbrabru~n minimum_wage_pct_avg_str  
rename garantltbrmin~t guaranteed_minimum_wage_str
rename kzfoglalkozta~s public_work_minimum_wage_str

* Drop empty observations and header rows
drop if missing(date_str) | date_str == ""
drop if _n == 1

* Extract year from date string
generate year = .
replace year = 1992 if regexm(date_str, "1992")
replace year = 1993 if regexm(date_str, "1993")
replace year = 1994 if regexm(date_str, "1994")
replace year = 1995 if regexm(date_str, "1995")
replace year = 1996 if regexm(date_str, "1996")
replace year = 1997 if regexm(date_str, "1997")
replace year = 1998 if regexm(date_str, "1998")
replace year = 1999 if regexm(date_str, "1999")
replace year = 2000 if regexm(date_str, "2000")
replace year = 2001 if regexm(date_str, "2001")
replace year = 2002 if regexm(date_str, "2002")
replace year = 2003 if regexm(date_str, "2003")
replace year = 2004 if regexm(date_str, "2004")
replace year = 2005 if regexm(date_str, "2005")
replace year = 2006 if regexm(date_str, "2006")
replace year = 2007 if regexm(date_str, "2007")
replace year = 2008 if regexm(date_str, "2008")
replace year = 2009 if regexm(date_str, "2009")
replace year = 2010 if regexm(date_str, "2010")
replace year = 2011 if regexm(date_str, "2011")
replace year = 2012 if regexm(date_str, "2012")
replace year = 2013 if regexm(date_str, "2013")
replace year = 2014 if regexm(date_str, "2014")
replace year = 2015 if regexm(date_str, "2015")
replace year = 2016 if regexm(date_str, "2016")
replace year = 2017 if regexm(date_str, "2017")
replace year = 2018 if regexm(date_str, "2018")
replace year = 2019 if regexm(date_str, "2019")
replace year = 2020 if regexm(date_str, "2020")
replace year = 2021 if regexm(date_str, "2021")
replace year = 2022 if regexm(date_str, "2022")
replace year = 2023 if regexm(date_str, "2023")

* Keep only observations from 2012 onwards
keep if year >= 2012 & !missing(year)

* Convert string variables to numeric, handling ".." as missing  
foreach var of varlist minimum_wage_str minimum_wage_pct_avg_str guaranteed_minimum_wage_str public_work_minimum_wage_str {
    replace `var' = "" if `var' == ".."
}

* Create numeric versions, handling space thousand separators
generate minimum_wage = real(subinstr(minimum_wage_str, " ", "", .))
generate minimum_wage_pct_avg = real(subinstr(minimum_wage_pct_avg_str, ",", ".", .))
generate guaranteed_minimum_wage = real(subinstr(guaranteed_minimum_wage_str, " ", "", .))  
generate public_work_minimum_wage = real(subinstr(public_work_minimum_wage_str, " ", "", .))

* Keep one observation per year (take the January observation for years with multiple entries)
sort year
by year: keep if _n == 1

* Add variable labels
label variable year "Year"
label variable minimum_wage "Minimum wage monthly amount (HUF)"
label variable minimum_wage_pct_avg "Minimum wage as % of gross average earnings"
label variable guaranteed_minimum_wage "Guaranteed minimum wage monthly amount (HUF)"
label variable public_work_minimum_wage "Public work minimum wage monthly amount (HUF)"
label variable date_str "Original date string"

* Keep relevant variables
keep year minimum_wage minimum_wage_pct_avg guaranteed_minimum_wage public_work_minimum_wage date_str

* Sort by year
sort year

* Display summary
display "Minimum wage data from 2012 onwards:"
list year minimum_wage guaranteed_minimum_wage, clean

* Save to temp directory
save "temp/minimum_wage.dta", replace

display "Minimum wage data saved to temp/minimum_wage.dta"
display "Observations: " _N