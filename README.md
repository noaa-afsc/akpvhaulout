
<!-- README.md is generated from README.Rmd. Please edit that file -->

## akpvhaulout

### Alaska Harbor Seal Haul-out Behavior

This package provides access to a comprehensive dataset of harbor seal
haul-out behavior from Alaska. The data are in development and are
subject to change at any time. These data should not be used in support
of publications, scientific analysis, or management decisions. Any use
of these data should be done in coordination with the repository
author(s).

## Installation

You can install the current version of `akpvhaulout` from github

``` r
library(devtools)
devtools::install_github('jmlondon/akpvhaulout')
```

## Data Products and Structure

### Coastal Habitat Data

Haul-out behavior data associated with a coastal survey unit is included
with this data object. These data all contain the tidal covariates of
interest for each record. Glacial habitats are not included in this
dataset.

``` r
tbl_percent_locs %>% glimpse()
#> Observations: 618,948
#> Variables: 17
#> $ speno            <chr> "PV2004_0001", "PV2004_0001", "PV2004_0001", ...
#> $ species          <chr> "Pv", "Pv", "Pv", "Pv", "Pv", "Pv", "Pv", "Pv...
#> $ sex              <chr> "F", "F", "F", "F", "F", "F", "F", "F", "F", ...
#> $ age              <chr> "YOY", "YOY", "YOY", "YOY", "YOY", "YOY", "YO...
#> $ data_date        <dttm> 2004-09-16, 2004-09-16, 2004-09-16, 2004-09-...
#> $ date_time        <dttm> 2004-09-16 00:00:00, 2004-09-16 01:00:00, 20...
#> $ percent_dry      <dbl> 0, 0, 0, 3, 10, 0, 0, 0, 0, 0, 0, 3, 3, 3, 0,...
#> $ fill_xy          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL...
#> $ tide_dt          <dttm> 2004-09-16 00:30:00, 2004-09-16 01:30:00, 20...
#> $ polyid           <chr> "JF06", "JF06", "JF06", "JF06", "JF06", "JF06...
#> $ station          <chr> "Snug Harbor, Cook Inlet, Alaska", "Snug Harb...
#> $ nn_dist          <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
#> $ tide_height      <dbl> 5.303637, 5.315634, 4.670457, 3.518702, 2.121...
#> $ near_low_height  <dbl> -0.52, -0.31, -0.31, -0.31, -0.31, -0.31, -0....
#> $ near_low_time    <dttm> 2004-09-15 11:55:00, 2004-09-16 00:15:00, 20...
#> $ minutes_from_low <dbl> 335, -345, -285, -225, -165, -105, -45, 15, 7...
#> $ geometry         <list> [POINT (1519991 -2953776), POINT (1519991 -2...
```

### Glacial Habitat Data

Haul-out behavior data associated with a glacial fjord habitat is
included with this data object. These data contain none of the tidal
covariates of interest for each record.

``` r
tbl_percent_glacial %>% glimpse()
#> Observations: 16,626
#> Variables: 12
#> $ speno       <chr> "PV2006_0113", "PV2006_0113", "PV2006_0113", "PV20...
#> $ species     <chr> "Pv", "Pv", "Pv", "Pv", "Pv", "Pv", "Pv", "Pv", "P...
#> $ age         <chr> "SUB", "SUB", "SUB", "SUB", "SUB", "SUB", "SUB", "...
#> $ sex         <chr> "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", ...
#> $ data_date   <dttm> 2006-09-07, 2006-09-07, 2006-09-07, 2006-09-07, 2...
#> $ date_time   <dttm> 2006-09-07 00:00:00, 2006-09-07 01:00:00, 2006-09...
#> $ percent_dry <dbl> 3, 3, 3, 98, 90, 20, 20, 40, 10, 80, 100, 100, 100...
#> $ fill_xy     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F...
#> $ tide_dt     <dttm> 2006-09-07 00:30:00, 2006-09-07 01:30:00, 2006-09...
#> $ polyid      <chr> "DF10", "DF10", "DF10", "DF10", "DF10", "DF10", "D...
#> $ station     <chr> "Not applicable", "Not applicable", "Not applicabl...
#> $ geometry    <POINT [m]> POINT (2338597 -2515327), POINT (2338597 -25...
```

\#\#\#\#\#Disclaimer

<sub>This repository is a scientific product and is not official
communication of the Alaska Fisheries Science Center, the National
Oceanic and Atmospheric Administration, or the United States Department
of Commerce. All AFSC Marine Mammal Laboratory (AFSC-MML) GitHub project
code is provided on an ‘as is’ basis and the user assumes responsibility
for its use. AFSC-MML has relinquished control of the information and no
longer has responsibility to protect the integrity, confidentiality, or
availability of the information. Any claims against the Department of
Commerce or Department of Commerce bureaus stemming from the use of this
GitHub project will be governed by all applicable Federal law. Any
reference to specific commercial products, processes, or services by
service mark, trademark, manufacturer, or otherwise, does not constitute
or imply their endorsement, recommendation or favoring by the Department
of Commerce. The Department of Commerce seal and logo, or the seal and
logo of a DOC bureau, shall not be used in any manner to imply
endorsement of any commercial product or activity by DOC or the United
States Government.</sub>
