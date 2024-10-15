# Packages
library(tidyverse)
library(terra)

#############
### Make big raster stack function of each seaweed species for each warming scenario and timespan
# The below function, `all_species_stack_maker` takes the species data and temperature data raster as inputs and generates a raster of each species performance for the provided raster. To do this the function uses the two functions made above, `species_monthly_performance` and `species_time_period_performance`. The variable inputs for the function are:
#   
# - `species_data` is the data.frame made in the first section of this Rmd
# - `temperature raster` is the specified raster of sea surface temperature for the warming scenario and time period of interest
#############

# this function requires the var_extract function
source(file = here::here("impact_calcs/custom_functions", "species_time_period_performance.R")) 

all_species_stack_maker <- function(species_data, temperature_raster){
  # read in temperature raster
  temperature_raster <- temperature_raster
  # make empty raster to stack on in loop
  time_period_raster <- terra::rast()
  # force the variable of interest within this function that will be used in species_time_period_performance below
  variable <-  "mean"
  # arrange the species data by taxa for better organization
  species_data <- arrange(species_data, taxa)
  
  # make for loop that goes through each row of the species data
  for (i in 1:nrow(species_data)) {
    # use the species common name from row i
    species_name <- species_data[i,1]
    # get the taxa name for the species to add to the raster layer name
    taxa_name <- species_data[i,3]
    # apply species name to species_time_period_performance function
    species_raster <- species_time_period_performance(species_name = species_name,
                                                      species_data = species_data,
                                                      temperature_raster = temperature_raster,
                                                      variable = variable)
    # get the current name from the species_raster
    layer_name <- names(species_raster)
    
    # add the taxa at the end of the name
    names(species_raster) <- paste0(layer_name, "_", taxa_name)
    
    # combine species raster to time period raster of all species
    time_period_raster <- c(time_period_raster, species_raster,
                            warn = FALSE)
    print(paste("Done with", species_name))
  }
  
  # return the final raster which should have a mean and sd for each species for the temp raster
  return(time_period_raster)
}