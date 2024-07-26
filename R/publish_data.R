
publish_data <- function() {
  deploy <- get_deployments()
  locations <- get_locations(deploy)
  timelines <- get_timelines(deploy)

  bucket <- gs_bucket("pep_storage", anonymous = FALSE)
  fs <- GcsFileSystem$create(anonymous = FALSE)
  write_parquet(deploy, "gs://pep_storage/josh-london/akpvhaulout/deploy.parquet")
  write_parquet(locations,"gs://pep_storage/josh-london/akpvhaulout/locations.parquet")
  write_parquet(timelines,"gs://pep_storage/josh-london/akpvhaulout/timelines.parquet")
}