# required packages for function
library(tidyverse)
library(terra)

###########
### Make Species Performance Raster for a Given Species
# The goal of this function is to make a raster of a given species growth performance across all months in the provided temperature raster.
# The variables are as follows:
#   
# - `species_name` is a species name from the `species_data` data.frame made in the first section of this Rmd
# - `species_data`  is the data.frame made in the first section of this Rmd
# - `temperature_raster` is the specified raster of sea surface temperature for the warming scenario and time period of interest
# - `variable` is the variable we want to use for performance calculations that will be extracted from the `temperature_raster` (ie. mean, abs_max, etc.)
############

# this function requires the var_extract function
source(file = here::here("impact_calcs/custom_functions", "var_extract.R")) 

# file paths required for the function
aragonite_raster_path <- "/home/shares/aquaculture/AOA_climate_change/pressure_prep/aragonite/adjusted_filters/"
chl_PI_path <- "/home/shares/aquaculture/AOA_climate_change/pressure_prep/chl/adjusted_chl_for_performance/"

# for now remove depth constraint
#depth_raster_path <- "/home/shares/aquaculture/AOA_climate_change/pressure_prep/"

species_monthly_performance <- function(species_name, species_data, temperature_raster, variable){
  # Extract the row of species data and taxa name
  species <- species_data[species_data$common_name == species_name,]
  species_taxa <- species$taxa
  
  #extract the warming scenario and time period from the temperature raster
  scenario_timeperiod <- str_sub(string = terra::sources(temperature_raster),
                                 start = -17,
                                 end = -5)
  
  # Extract raster variable of interest
  variable_raster <- var_extract(rast_stack = temperature_raster,
                                 variable = variable)
  
  # establish species optimal, high, and low temperatures
  opt_temp <- as.numeric(species$optimal)
  min_temp <- as.numeric(species$low)
  max_temp <- as.numeric(species$high)
  
  # set up slope equation to optimal temperature
  slope_increase <- as.numeric(species$growth_increase_slope)
  intercept_increase <- as.numeric(species$intercept_increase)
  
  # make raster to optimal temperature
  increase_rast <- terra::clamp(x = variable_raster,
                                lower = min_temp,
                                upper = opt_temp,
                                values = FALSE)
  # y = m*x+b
  increase_rast <- slope_increase*increase_rast + intercept_increase
  
  # set up slope equation from optimal temperature
  slope_decrease <- as.numeric(species$growth_decrease_slope)
  intercept_decrease <- as.numeric(species$intercept_decrease)
  
  # make raster from optimal temperature
  decrease_rast <- terra::clamp(x = variable_raster,
                                lower = (opt_temp+.00001),
                                upper = max_temp,
                                values = FALSE)
  
  # y = m*x+b
  decrease_rast <- slope_decrease*decrease_rast + intercept_decrease
  
  # make empty performance raster with correct extend and information
  performance_raster <- rast(crs = terra::crs(variable_raster),
                             xmin = terra::xmin(variable_raster),
                             xmax = terra::xmax(variable_raster),
                             ymin = terra::ymin(variable_raster),
                             ymax = terra::ymax(variable_raster))
  
  # 1-12 is the months of the year
  for (i in 1:12) {
    # combine rasters
    month_rast <- c(increase_rast[[i]], decrease_rast[[i]])
    # sum to make one layer, the cells should not overlap
    month_rast <- sum(month_rast, na.rm = TRUE) 
    # make a name for the layer that was just made
    names(month_rast) <- paste0(month.name[i], "_growth")
    # bind layer to performance raster
    performance_raster <- c(performance_raster, month_rast,
                            warn = FALSE)
  }
  
  # molluscs are a special taxa and require some extra filtering that is done below
  if (species_taxa == "mollusc") {
    # get scenario
    aragonite_scenario <- str_sub(string = scenario_timeperiod,
                                  start = 0,
                                  end =3)
    # get years
    aragonite_years <- str_sub(string = scenario_timeperiod,
                               start = 5)
    
    aragonite_raster <- terra::rast(paste0(aragonite_raster_path, "aragonite_filter_",aragonite_scenario,".tif" ))
    
    # subset aragonite_raster by our aragonite_years
    var_lyr <- names(aragonite_raster)[stringr::str_ends(string = names(aragonite_raster),            
                                                         pattern = aragonite_years)]
    aragonite_mask <- terra::subset(x = aragonite_raster, subset = var_lyr)
    
    # use aragonite_mask as a mask to the performance_raster
    performance_raster <- terra::mask(x = performance_raster,
                                      mask = aragonite_mask,
                                      # any cells that have been masked are made 0 (not NA)
                                      updatevalue = 0)
    
    # now read in the chl PI adjustment data and apply it
    chl_PI_adjustment <- terra::rast(paste0(chl_PI_path, "chl_adjust_PI_",scenario_timeperiod,".tif" ))

    # adjust each corresponding month
    # 1-12 is the months of the year
    for (j in 1:12) {
      #multiply the month of each raster and save it over performance raster month
      performance_raster[[j]] <- performance_raster[[j]] * chl_PI_adjustment[[j]]
    }
    
  }
  
  # apply depth mask raster to all areas and species, only areas with a depth < 200m are viable for aquaculture
  # for now we are removing the depth constraint on the calculations in the EEZ
  # depth_mask <- terra::rast(paste0(depth_raster_path, "depth_200m.tif" ))
  # 
  # performance_raster <- terra::mask(x = performance_raster,
  #                                   mask = depth_mask)
  
  # return species performance raster
  return(performance_raster)
}