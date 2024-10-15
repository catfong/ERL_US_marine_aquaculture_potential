# Packages
library(tidyverse)
library(terra)

# The contents of this script also exist in the Rmd with the same title.
# This script exists so that the operation done below can be run as a background
# while continuing to do other work

# set up file paths
temp_raster_path <- "/home/shares/aquaculture/AOA_climate_change/pressure_prep/sst/"
save_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/all_species_index/"
species_data <- read.csv("/home/shares/aquaculture/AOA_climate_change/pressure_calcs/species_growth_equations.csv")
functions_path <- here::here("impact_calcs/custom_functions/")
overwrite <- TRUE

# source custom functions
source(file = paste0(functions_path, "var_extract.R"))
source(file = paste0(functions_path, "species_monthly_performance.R"))
source(file = paste0(functions_path, "species_time_period_performance.R"))
source(file = paste0(functions_path, "all_species_stack_maker.R"))

# list monthly sst files from temp_raster_path
temp_files_list <- list.files(temp_raster_path, pattern = "monthly")


for (i in 1:n_distinct(temp_files_list)) {
  # extract the scenario and time period
  scenario_years <- stringr::str_sub(string = temp_files_list[i],
                                     start = -17,
                                     end = -5)
  
  # read in the monthly sst data for that scenario and time period
  monthly_scenario_rast <- terra::rast(paste0(temp_raster_path, "monthly_sst_", scenario_years, ".tif"))
  
  # apply the all_species_stack_maker function to this monthly_sst_raster
  species_stack <- all_species_stack_maker(species_data = species_data,
                                           temperature_raster = monthly_scenario_rast)
  
  # save raster
  writeRaster(x = species_stack,
              filename = paste0(save_path, "all_species_", scenario_years, ".tif"),
              gdal="COMPRESS=NONE",
              overwrite = overwrite)
}