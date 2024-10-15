#packages
library(tidyverse)
library(terra)
library(janitor)

###########
### Take mean of each monthly performance stack
# The goal of this function is to take the `species_monthly_raster` function made in the 
# chunk above and take the mean of the monthly performance of the species across all 12 months. The variables are as follows:
#   
# - `species_name` is a species name from the `species_data` data.frame made in the first section of this Rmd
# - `species_data`  is the data.frame made in the first section of this Rmd
# - `temperature_raster` is the specified raster of sea surface temperature for the warming scenario and time period of interest
# - `variable` is the variable we want to use for performance calculations that will be extracted from the `temperature_raster` (ie. mean, abs_max, etc.)
############

# this function requires the species_monthly_performance function
source(file = here::here("impact_calcs/custom_functions", "species_monthly_performance.R")) 

species_time_period_performance <- function(species_name, species_data, temperature_raster, variable){
  # Use species_monthly_performance function above to generate monthly data for species
  species_monthly_raster <- species_monthly_performance(species_name = species_name,
                                                        species_data = species_data,
                                                        temperature_raster = temperature_raster,
                                                        variable = variable)
  
  # Take the mean of the monthly data
  mean_raster <- sum(species_monthly_raster,
                     na.rm = TRUE) / 12 # months so that low values are not given a higher value by just removing NA in mean calc
  
  # Make variable name, clean name of species name using janitor package
  names(mean_raster) <- paste0(janitor::make_clean_names(string = species_name), "_mean")
  
  # return final raster
  return(mean_raster)
}