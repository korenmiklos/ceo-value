---
type: Data source
title: Bloom, Sadun and Van Reenen (2012) replication data
description: Cross-country management and autonomy survey replication data used by the appendix autonomy analysis; input file absent in this checkout.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
sources:
  - id: bloom_code
    resource: ../references/code/bloom_autonomy_do.md
    locator: Lines  1-14 (source path declaration)
  - id: make_app
    resource: ../references/makefile_application.md
    locator: Line  157 (bloom rule dependency)
relations: []
---

# Bloom, Sadun and Van Reenen (2012) replication data

## Origin

Replication data from Bloom, Sadun and Van Reenen (2012), QJE, "Managers and the value of organizations" - used to test whether family-controlled firms have less managerial autonomy, appendix table A0 planned.



## Availability gap

The anticipated file `input/bloom-et-al-2012/replication.dta` is NOT presentin the current `input/` directory. The application Makefile rule for `bloom_autonomy_analysis.log` depends on it; with the input missing, this appendix target is blocked in this checkout.

## Variables used and declared sources

- `central4` - plant manager hiring autonomy, 1-5 scale
- `central5` - plant manager max capital investment authority, dollar value
- `central6` - sales and marketing autonomy, 1-5 scale


- `central7` - new product introduction autonomy, 1-5 scale
- `public`, `family`, `cty`, `sic2`, `id` - controls and clustering per the script.



[^bloom_code]: Bloom autonomy analysis code - see [bloom_autonomy.do](../references/code/bloom_autonomy_do.md)
[^make_app]: Application paper Makefile - see [Makefile](../references/makefile_application.md)
