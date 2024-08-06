library(DBI)
library(dbplyr)
library(dplyr)
library(RPostgres)
library(sf)
library(geoarrow)
library(arrow)
library(arcgis)

get_deployments <- function() {
  tryCatch(
    {
      con <- dbConnect(
        RPostgres::Postgres(),
        dbname = "pep",
        host = Sys.getenv("PEP_PG_IP"),
        user = keyringr::get_kc_account("pgpep_londonj"),
        password = keyringr::decrypt_kc_pw("pgpep_londonj")
      )
    },
    error = function(cond) {
      print("Unable to connect to Database.")
    }
  )

  tbl_speno <- dplyr::tbl(con, in_schema("capture", "for_telem"))

  tbl_deploy <- dplyr::tbl(con, in_schema("telem", "tbl_tag_deployments")) |>
    dplyr::filter(species %in% c("Pv")) |>
    dplyr::mutate(species = case_when(
      species == "Pv" ~ "Harbor seal",
      .default = NA
    )) |>
    dplyr::left_join(tbl_speno, by = c("speno", "species")) |>
    dplyr::collect()

  DBI::dbDisconnect(con)

  return(tbl_deploy)
}


get_locations <- function(tbl_deploy = NULL) {
  tryCatch(
    {
      con <- dbConnect(
        RPostgres::Postgres(),
        dbname = "pep",
        host = Sys.getenv("PEP_PG_IP"),
        user = keyringr::get_kc_account("pgpep_londonj"),
        password = keyringr::decrypt_kc_pw("pgpep_londonj")
      )
    },
    error = function(cond) {
      print("Unable to connect to Database.")
    }
  )

  locs_obs <- sf::st_read(con, Id("telem", "geo_wc_locs_qa")) |>
    dplyr::collect() |> 
    dplyr::left_join(tbl_deploy) |>
    dplyr::select(
      speno, deployid, ptt, instr, tag_family, type, quality, locs_dt, latitude, longitude,
      error_radius, error_semi_major_axis, error_semi_minor_axis,
      error_ellipse_orientation, project, species, age, sex, qa_status, deploy_dt, end_dt,
      deploy_lat, deploy_long, capture_lat, capture_long, geom
    ) |>
    dplyr::filter(species == "Harbor seal")

  DBI::dbDisconnect(con)

  return(locs_obs)
}


get_timelines <- function(tbl_deploy = NULL) {
  tryCatch(
    {
      con <- dbConnect(
        RPostgres::Postgres(),
        dbname = "pep",
        host = Sys.getenv("PEP_PG_IP"),
        user = keyringr::get_kc_account("pgpep_londonj"),
        password = keyringr::decrypt_kc_pw("pgpep_londonj")
      )
    },
    error = function(cond) {
      print("Unable to connect to Database.")
    }
  )

  tbl_timelines <- dplyr::tbl(con, in_schema("telem", "tbl_wc_histos_timeline_qa")) |>
    dplyr::collect() |> 
    dplyr::left_join(tbl_deploy, by = c("deployid")) |>
    dplyr::filter(species %in% c("Pv")) |>
    dplyr::mutate(species = case_when(
      species == "Pv" ~ "Harbor seal",
      .default = NA
    )) 

  DBI::dbDisconnect(con)

  return(tbl_timelines)
}

get_survey_units <- function() {
  feature_url <- 'https://services2.arcgis.com/C8EMgrsFcRFL6LrL/arcgis/rest/services/pv_cst_polys/FeatureServer'

  ssu_sf <- arcgislayers::arc_open(feature_url) |> 
    arcgislayers::get_layer(0) |> 
    arcgislayers::arc_select()

  return(ssu_sf)
}