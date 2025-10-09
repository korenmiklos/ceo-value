*! Baseline Monte Carlo parameters
* number of CEO changes
local N_changes = 50000
* stdev of CEO ability, sqrt(0.01)
local sigma_z = 0.1
local half_normal = 0.797885
local true_effect = `half_normal' * `sigma_z'
* control to treated N
local control_treated_ratio = 1

local rho = 0
local sigma_epsilon0 = 0.05
local sigma_epsilon1 = 0.05
local hazard = 0
local T_max = 5
