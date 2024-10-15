# required packages
library(tidyverse)
library(terra)

# The contents of this script also exist in the Rmd with the same title.
# This script exists so that the operation done below can be run as a background
# while continuing to do other work

# File Paths
performance_rasters_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/all_species_index/"
save_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/counts/"

# source custom functions
source(here::here("impact_calcs/custom_functions/aggregate_count_performance_maker.R"))


overwrite <- TRUE
performance_files <- list.files(path = performance_rasters_path,
                                pattern = "all_species_*")
number_files <- n_distinct(performance_files)

for (i in 1:number_files){
  scenario <- str_sub(string = performance_files[i],
                      start = 13,
                      end = 25)
  scenario_raster <- terra::rast(paste0(performance_rasters_path, performance_files[i]))
  
  scenario_raster <- aggregate_count_performance_maker(species_raster = scenario_raster,
                                                       GPI_filter = 0.5)
  
  terra::writeRaster(x = scenario_raster,
                     filename = paste0(save_path, "count_", scenario, ".tif"),
                     gdal="COMPRESS=NONE",
                     overwrite = overwrite)
  print(paste("Done with", performance_files[i]))
}