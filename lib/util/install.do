foreach X in xt2treatments e2frame {
    net install `X', from(https://raw.githubusercontent.com/codedthinking/`X'/main/) replace
    which `X'
}

* from SSC
foreach X in reghdfe estout {
    ssc install `X', replace
    which `X'
}
