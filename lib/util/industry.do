capture drop sector
generate byte sector = .
replace sector = 1 if teaor08_1d == "A" // Agriculture, forestry and fishing
replace sector = 2 if teaor08_1d == "B" // Mining and quarrying
replace sector = 3 if teaor08_1d == "C" // Manufacturing
replace sector = 4 if inlist(teaor08_1d, "G", "H") // Wholesale and retail trade; repair of motor vehicles and motorcycles
replace sector = 5 if inlist(teaor08_1d, "J", "M") // Information and communication; Professional, scientific and technical activities
replace sector = 9 if teaor08_1d == "K" // Finance
replace sector = 6 if teaor08_1d == "F" // Construction
replace sector = 7 if missing(sector) // Nontradable services

tempvar constant_sector
foreach X in sector teaor08_2d {
    egen `constant_sector' = mode(`X'), by(frame_id_numeric) maxmode
    replace `X' = `constant_sector'
    drop `constant_sector'
}

label define sector 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Wholesale, Retail, Transportation" 5 "Telecom and Business Services" 6 "Construction" 7 "Nontradable services" 9 "Finance, Insurance and Real Estate"
label values sector sector

compress
tabulate sector, missing
