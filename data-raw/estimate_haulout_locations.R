source(here::here('data-raw/get_data.R'))

# connect to GCP Bucket
bucket <- arrow::gs_bucket("pep_storage", anonymous = FALSE)
fs <- arrow::GcsFileSystem$create(anonymous = FALSE)

# get location data
locs_sf <- arrow::open_dataset(
  "gs://pep_storage/josh-london/akpvhaulout/locations.parquet"
) |>
  sf::st_as_sf() |>
  dplyr::select(
    speno, deployid, tag_family, type, quality, locs_dt,
    starts_with("error"), project, age, sex, deploy_dt, end_dt
  ) |>
  dplyr::filter(between(locs_dt, deploy_dt, end_dt)) |>
  dplyr::mutate(
    unique_day =
      glue::glue("{lubridate::year(locs_dt)}",
        "{lubridate::yday(locs_dt)}",
        .sep = "_"
      )
  )

  loc_qual_tbl <- tibble::tribble(
    ~quality, ~error_radius,
    "3", 250,
    "2", 500,
    "1", 1500,
    "0", 2500,
    "A", 2500,
    "B", 2500
  )

# calculate daily locations
locs_daily <- locs_sf |> 
  dplyr::filter(quality %in% c("3", "2", "1", "0", "A", "B")) |> 
  dplyr::left_join(loc_qual_tbl, by = "quality") |> 
  sf::st_transform(3338) |> 
  dplyr::mutate(
    x = sf::st_coordinates(geom)[, "X"],
    y = sf::st_coordinates(geom)[, "Y"]
  ) |> 
  sf::st_set_geometry(NULL) |> 
  dplyr::mutate(error_radius.x = ifelse(is.na(error_radius.x),
  error_radius.y,
  error_radius.x))  |> 
dplyr::rename(error_radius = error_radius.x)  |> 
dplyr::select(-error_radius.y)  |> 
  dplyr::mutate(
    error_radius = ifelse(type %in% c("GPS", "FastGPS"),
      50, error_radius
    ),
    error_radius = ifelse(type %in% c("User"),
      50, error_radius
    )
  ) |> 
  dplyr::group_by(speno, unique_day, age, sex) |> 
  dplyr::summarise(
    x = weighted.mean(x, 1 / error_radius),
    y = weighted.mean(y, 1 / error_radius)
  )

# get timeline data & join with daily locations
tbl_percent_locs <- arrow::read_parquet(
  "gs://pep_storage/josh-london/akpvhaulout/timelines.parquet"
) |>
  dplyr::filter(between(timeline_start_dt, deploy_dt, end_dt)) |>
  dplyr::mutate(
    unique_day =
      glue::glue("{lubridate::year(timeline_start_dt)}",
        "{lubridate::yday(timeline_start_dt)}",
        .sep = "_"
      )
  ) |>
  dplyr::mutate(timeline_hour = lubridate::hour(timeline_start_dt),
                tide_dt = timeline_start_dt +lubridate::minutes(30)) |>
  dplyr::reframe(
    timeline_start_dt = lubridate::floor_date(timeline_start_dt, "hours"),
    percent_dry = mean(percent_dry, na.rm = TRUE),
    .by = c(speno, age, sex, unique_day, timeline_hour, tide_dt)
  ) |>
  dplyr::select(-timeline_hour) |>
  # now join with daily locations
  dplyr::full_join(locs_daily,
    by = c(
      "speno", "age", "sex", "unique_day"
    )
  ) |>
  dplyr::arrange(speno, unique_day, timeline_start_dt, tide_dt) |>
  dplyr::group_by(speno) |>
  tidyr::nest() |>
  dplyr::mutate(
    start_idx = purrr::map_int(data, ~ which.max(!is.na(.x$x))),
    data = purrr::map2(data, start_idx, ~ slice(.x, .y:nrow(.x)))
  ) |>
  dplyr::select(-start_idx) |>
  tidyr::unnest(cols = c(data)) |>
  dplyr::mutate(fill_xy = ifelse(is.na(x), TRUE, FALSE)) |>
  dplyr::group_by(speno) |>
  tidyr::fill(x, y) |>
  dplyr::ungroup() |>
  dplyr::filter(!is.na(percent_dry)) |>
  dplyr::filter(!is.na(x)) |>
  sf::st_as_sf(coords = c("x", "y")) |>
  sf::st_set_crs(3338) |>
  dplyr::rename(haulout_dt = timeline_start_dt) |>
  dplyr::select(speno, age, sex, haulout_dt, tide_dt, percent_dry, fill_xy)

# get seal survey units and transform to 3338
ssu_sf <- get_survey_units() |> 
  sf::st_transform(3338) |> 
  dplyr::filter(iliamna != 'Y')

ssu_cent <- ssu_sf |> 
  sf::st_centroid()

# intersect and bind tbl_percent_locs w/ ssus to get tidal station
ssu_idx <- tbl_percent_locs |> 
sf::st_intersects(ssu_sf) |> 
purrr::map_int(1,.default = NA)

ssu_df <- ssu_sf |> 
sf::st_set_geometry(NULL)

tbl_percent_locs <- tbl_percent_locs |> 
dplyr::bind_cols(ssu_df[ssu_idx,c("polyid","station","stockid","stockname","glacier_name")])

# get glacial SSUs
glacial_ssu_sf <- get_survey_units() |> 
  sf::st_transform(3338) |> 
  dplyr::filter(!is.na(glacier_name))

locs_na <- tbl_percent_locs  |>  
  dplyr::filter(is.na(polyid))  |>  
  sf::st_coordinates()

ssu_mat <- ssu_cent  |>  
  sf::st_coordinates()

library(nabor)

locs_ssu_nn <- nabor::knn(data=ssu_mat, query=locs_na, k = 1)  |>
  purrr::map(c) |> tibble::as_tibble() |> 
  rlang::set_names(c("ssu_idx","nn_dist")) |>
  dplyr::mutate(polyid = ssu_cent$polyid[ssu_idx],
                station = ssu_cent$station[ssu_idx])  |>  
  dplyr::select(-ssu_idx)

locs_na <- tbl_percent_locs  |>  
  dplyr::filter(is.na(polyid))  |>  
  dplyr::select(-c(polyid,station))  |>  
  dplyr::bind_cols(locs_ssu_nn)

tbl_percent_locs <- tbl_percent_locs  |>  
  dplyr::filter(!is.na(polyid))  |>  
  dplyr::mutate(nn_dist = 0)  |>  
  rbind(locs_na)  |>  
  dplyr::arrange(speno,haulout_dt)

tbl_percent_glacial <- tbl_percent_locs  |>  
  dplyr::filter(polyid %in% glacial_ssu_sf$polyid) 

tbl_percent_locs <- tbl_percent_locs  |>  
  dplyr::filter(!polyid %in% glacial_ssu_sf$polyid,
                nn_dist < 250000) 

tbl_percent_locs <- tbl_percent_locs |> 
  dplyr::mutate( station = case_when(
    station == 'Lituya Bay, 2 miles inside entrance, Alaska' ~ 'Lituya Bay, 2 mi inside entrance, Alaska',
    .default = station
  ))

# locs <- tbl_percent_locs %>% dplyr::sample_frac(0.025) 

# ggplot() +
#   geom_sf(data = locs, size = 0.1, alpha = 0.2) +
#   scale_x_continuous(breaks = c(180, -160, -140)) +
#   ggtitle("Spatial distribution of haul-out behavior records",
#           subtitle = "note: only 2.5% of data shown")


# library(mapgl)

# mapboxgl(style = "mapbox://styles/mapbox-public/ckngin2db09as17p84ejhe24y") |>
#   fit_bounds(tbl_percent_locs, animate = FALSE) |>
#   add_circle_layer(id = "haulout-locs", source = tbl_percent_locs, circle_radius = , circle_color = "purple")

tbl_percent_locs <- tbl_percent_locs %>% 
  dplyr::group_by(speno,sex,age) %>% tidyr::nest()

create_tidestats <- function(tbl_data) {
  get_tide_height <- purrr::possibly(tidextractr::GetTideHeight, 
                                     otherwise = NA, quiet = FALSE)
  get_nearest <- purrr::possibly(tidextractr::GetNearestLow, 
                                 otherwise = NA, quiet = FALSE)
  
  tbl_data <- tbl_data %>%
    dplyr::mutate(
      tide_height = purrr::map2_dbl(tide_dt, station,
                                    ~ get_tide_height(.x, .y)),
      near_low = purrr::map2(tide_dt, station,
                             ~ get_nearest(.x, .y)),
      near_low_height = purrr::map_dbl(near_low, "height"),
      near_low_time = purrr::map(near_low, "time") %>%
        purrr::reduce(c)
    ) %>% 
    dplyr::filter(inherits(near_low_time,"POSIXct")) %>%
    dplyr::mutate(
      minutes_from_low = purrr::map2(tide_dt, near_low_time, 
                                     ~ difftime(.x, .y, units = "mins")) %>%
        as.numeric()
    ) %>% 
    dplyr::select(-(near_low))
}

# tbl_percent_locs <- tbl_percent_locs |> 
#   dplyr::rowwise() |> 
#   dplyr::mutate(data = list(create_tidestats(data)))

stats_list <- vector(mode = "list", length = nrow(tbl_percent_locs))

for (i in 1:nrow(tbl_percent_locs)) {
  stats_list[[i]] <- create_tidestats(tbl_percent_locs$data[[i]])
}