# Packages
library(tidyverse)
library(terra)
library(janitor)

#########
# The objective of this script is to use the same loop that was made in 
# `04_state_boarder_filter.Rmd` to mask the species performance rasters to their
# state waters. This just makes the computation easier by removing unrequired data.
#########

# File Paths
save_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/all_species_state_borders/"
all_species_performance_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/all_species_index/"
states_shape_file_path <- "/home/shares/aquaculture/AOA_climate_change/spatial/state_waters/"
depth_raster_path <- "/home/shares/aquaculture/AOA_climate_change/pressure_prep/"


# overwrite data?
overwrite <- TRUE

# read in state_waters shape file - this should not change
state_shapes <- terra::vect(paste0(states_shape_file_path, "state_waters.shp"))

# read in all_species_performance_path as our performance_file_path
performance_file_path <- all_species_performance_path

# choose result_type we are using for this section, this can change between "index" and "count"
result_type <- "index"

if (result_type == "index") {
  performance_file_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/all_species_index/"
} else {
  stop("result_type must only be index")
}

performance_files_list <- list.files(performance_file_path)

for (j in 1:n_distinct(performance_files_list)) {
  # read in results raster we are interested in
  results_raster <- terra::rast(paste0(performance_file_path, performance_files_list[j]))
  
  # apply depth mask raster to all areas and species, only areas with a depth < 200m are viable for aquaculture
  depth_mask <- terra::rast(paste0(depth_raster_path, "depth_200m.tif" ))
  
  results_raster <- terra::mask(x = results_raster,
                                mask = depth_mask)
  
  # make a list of the state
  state_list <- state_shapes$state
  # fix the two Floridas issue by removing Gulf and Pacfic Florida and adding in just Florida
  state_list <- state_list[!str_detect(state_list, pattern = "Florida")]
  state_list <- c(state_list, "Florida")
  
  # get the scenario name from the sourced tif file
  scenario_timeperiod <- str_sub(string = paste0(performance_file_path, performance_files_list[j]), 
                                 start = -17, 
                                 end = -5)
  # make empty df to add to
  all_states_df <- data.frame()
  #make empty raster with 4 layers
  all_states_raster <- terra::rast()
  
  for (i in 1:n_distinct(state_list)) {
    # retrieve the state name for the loop
    state_name <- state_list[i]
    
    # if the state name is Florida, combine the Gulf and Atlantic shapes
    if (state_name == "Florida") {
      state_results_raster <- terra::mask(x = results_raster,
                                          mask = state_shapes[state_shapes$state == c("Florida Gulf","Florida Atlantic")])
    } else{
      # else just state the state shape from the state_name
      state_results_raster <- terra::mask(x = results_raster,
                                          mask = state_shapes[state_shapes$state == state_name])
    }
    
    # if statement to make add first layers to all_state_rasters
    if (i == 1) {
      all_states_raster <- c(all_states_raster, state_results_raster)
    } else{
      # else use the merge function in terra to join the layers of matching names
      # using merge in areas where the SpatRaster objects overlap, the values of the SpatRaster that is last in the sequence of arguments will be retained. 
      all_states_raster <- terra::merge(x = all_states_raster,
                                        y = state_results_raster)
    }
    
    # make the state_df from the states_results raster
    state_df <- as.data.frame(x = state_results_raster,
                              xy = TRUE,
                              cells = TRUE)
    
    # add state name column
    state_df <- state_df %>% 
      mutate(state = state_name)
    
    # add to empty df of all states
    all_states_df <- rbind(all_states_df, state_df)
    
    # remove any state border rows that may have joined in df
    all_states_df <- all_states_df %>% 
      unique()
    
    print(paste("Done with", state_name))
  }
  
  # save the raster file
  terra::writeRaster(x = all_states_raster,
                     filename = paste0(save_path, "rasters/", "all_species_state_borders_", result_type,"_",scenario_timeperiod, ".tif"),
                     gdal="COMPRESS=NONE",
                     overwrite = overwrite)
  
  # save the data frame as a csv
  write.csv(x = all_states_df,
            file = paste0(save_path, "data_frames/", "all_species_state_borders_", result_type,"_",scenario_timeperiod, ".csv"))
  
  print(paste("Done with", performance_files_list[j]))
}