# Packages
library(tidyverse)
library(terra)
library(janitor)

#########
# The objective of this script is to use the output from script 05a and filter 
# the species to those allowed in each state. The output is then saved.
# The exact operation is in 05_state_permitted_species_filter.Rmd. This script 
# exists to be able to run the calculations in the background.
#########


# make a save path for the output from this section
save_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/"
overwrite <- TRUE

### source custom functions needed
source("~/AOA_climate_change/impact_calcs/custom_functions/aggregate_index_performance_maker.R", echo = FALSE, verbose = FALSE)
source("~/AOA_climate_change/impact_calcs/custom_functions/aggregate_count_performance_maker.R", echo = FALSE, verbose = FALSE)
source("~/AOA_climate_change/impact_calcs/custom_functions/all_species_aggregate_index_performance_maker.R", echo = FALSE, verbose = FALSE)

# read in state shapes file
states_shape_file_path <- "/home/shares/aquaculture/AOA_climate_change/spatial/state_waters/"

all_species_state_borders_path <- "/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/all_species_state_borders/rasters/"
all_species_state_borders_list <- list.files(all_species_state_borders_path)

# read in the clean permitted species data
permitted_species_clean <- read.csv(file = "/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/permitted_species_clean.csv") %>% 
  select(-X)

# read in state_waters shape file - this should not change
state_shapes <- terra::vect(paste0(states_shape_file_path, "state_waters.shp"))

for (j in 1:n_distinct(all_species_state_borders_list)) {
  # read in results raster we are interested in
  results_raster <- terra::rast(x = paste0(all_species_state_borders_path, all_species_state_borders_list[j]))
  
  # make a list of the state
  state_list <- state_shapes$state
  # fix the two Floridas issue by removing Gulf and Pacfic Florida and adding in just Florida
  state_list <- state_list[!str_detect(state_list, pattern = "Florida")]
  state_list <- c(state_list, "Florida")
  
  # get the scenario name from the sourced tif file
  scenario_timeperiod <- str_sub(string = paste0(all_species_state_borders_path, all_species_state_borders_list[j]), 
                                 start = -17, 
                                 end = -5)
  # # make empty df to add to
  # all_states_df <- data.frame()
  # #make empty rasters and df with 4 layers
  all_states_index_raster <- terra::rast("/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/empty_index_raster_template.tif")
  all_states_index_df <- data.frame()
  all_states_total_species_index_raster <- terra::rast("/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/empty_index_raster_template.tif")
  all_states_total_species_index_df <- data.frame()
  all_states_count_raster <- terra::rast("/home/shares/aquaculture/AOA_climate_change/performance_calcs/state_permitted_species/empty_count_raster_template.tif")
  all_states_count_df <- data.frame()
  
  for (i in 1:n_distinct(state_list)) {
    # retrieve the state name for the loop
    state_name <- state_list[i]
    
    # filter for the state in the permitted_species_clean df and only species allowed by the state
    state_permitted_species <- permitted_species_clean %>% 
      filter(state == state_name,
             species_permitted == TRUE)
    
    # extract layers for the permitted species of this state
    var_lyrs <- names(results_raster)[stringr::str_detect(string = names(results_raster),            
                                                          pattern = paste(state_permitted_species$common_name, collapse = "|"))]
    state_species_raster <- subset(results_raster, var_lyrs)
    
    
    # if the state name is Florida, combine the Gulf and Atlantic shapes
    if (state_name == "Florida") {
      state_results_raster <- terra::mask(x = state_species_raster,
                                          mask = state_shapes[state_shapes$state == c("Florida Gulf","Florida Atlantic")])
    } else{
      # else just state the state shape from the state_name
      state_results_raster <- terra::mask(x = state_species_raster,
                                          mask = state_shapes[state_shapes$state == state_name])
    }
    #########
    ### Calculate mean index performance for allowed species
    state_results_permitted_index <- aggregate_index_performance_maker(species_raster = state_results_raster)
    
    # merge with all_states raster
    all_states_index_raster <- terra::merge(x = all_states_index_raster,
                                            y = state_results_permitted_index)
    
    # make the state_df from the states_results raster
    state_permitted_df <- as.data.frame(x = state_results_permitted_index,
                                        xy = TRUE,
                                        na.rm = FALSE,
                                        cells = TRUE)  %>% 
      filter(!is.na(all_species_mean_index))
    
    # add state name column
    state_permitted_df <- state_permitted_df %>% 
      mutate(state = state_name)
    
    # add to empty df of all states
    all_states_index_df <- rbind(all_states_index_df, state_permitted_df)
    
    # remove any state border rows that may have joined in df
    all_states_index_df <- all_states_index_df %>% 
      unique()
    
    # remove state_df from memory so it does not hold up calculations
    rm(state_permitted_df)
    
    #########
    ### Calculate mean index performance for all species and all species within taxa
    state_results_total_index <- all_species_aggregate_index_performance_maker(species_raster = state_results_raster)
    
    # merge with all_states raster
    all_states_total_species_index_raster <- terra::merge(x = all_states_total_species_index_raster,
                                                          y = state_results_total_index)
    
    # make the state_df from the states_results raster
    state_df <- as.data.frame(x = state_results_total_index,
                              xy = TRUE,
                              na.rm = FALSE,
                              cells = TRUE) %>% 
      filter(!is.na(all_species_mean_index))
    
    # add state name column
    state_df <- state_df %>%
      mutate(state = state_name)
    
    # add to empty df of all states
    all_states_total_species_index_df <- rbind(all_states_total_species_index_df, state_df)
    
    # remove any state border rows that may have joined in df
    all_states_total_species_index_df <- all_states_total_species_index_df %>%
      unique()
    # remove state_df from memory so it does not hold up calculations
    rm(state_df)
    
    #########
    ### Calculate count performance for allowed species
    state_results_permitted_count <- aggregate_count_performance_maker(species_raster = state_results_raster,
                                                                       GPI_filter = 0.5)
    
    # merge with all_states raster
    all_states_count_raster <- terra::merge(x = all_states_count_raster,
                                            y = state_results_permitted_count)
    
    # make the state_df from the states_results raster
    state_df <- as.data.frame(x = state_results_permitted_count,
                              xy = TRUE,
                              na.rm = FALSE,
                              cells = TRUE) %>% 
      filter(!is.na(all_species_count))
    
    # add state name column
    state_df <- state_df %>%
      mutate(state = state_name)
    
    # add to empty df of all states
    all_states_count_df <- rbind(all_states_count_df, state_df)
    
    # remove any state border rows that may have joined in df
    all_states_count_df <- all_states_count_df %>%
      unique()
    
    # remove state_df from memory so it does not hold up calculations
    rm(state_df)
    #########
    
    print(paste(state_name, " - DONE"))
  }
  
  ###########
  # Write index raster and df for permitted species
  # save the raster file
  terra::writeRaster(x = all_states_index_raster,
                     filename = paste0(save_path, "permitted_species_index/rasters/", "permitted_species_index_", scenario_timeperiod, ".tif"),
                     gdal="COMPRESS=NONE",
                     overwrite = overwrite)
  
  # save the data frame as a csv
  write.csv(x = all_states_index_df,
            file = paste0(save_path, "permitted_species_index/data_frames/", "permitted_species_index_", scenario_timeperiod, ".csv"))
  
  ###########
  # Write index raster and df for all species
  # save raster file
  terra::writeRaster(x = all_states_total_species_index_raster,
                     filename = paste0(save_path, "all_species_index/rasters/", "all_species_index_", scenario_timeperiod, ".tif"),
                     gdal="COMPRESS=NONE",
                     overwrite = overwrite)
  
  # save the data frame as a csv
  write.csv(x = all_states_total_species_index_df,
            file = paste0(save_path, "all_species_index/data_frames/", "all_species_index_", scenario_timeperiod, ".csv"))
  
  
  ###########
  # Write count raster and df for permitted species
  # save the raster file
  terra::writeRaster(x = all_states_count_raster,
                     filename = paste0(save_path, "permitted_species_count/rasters/", "permitted_species_count_", scenario_timeperiod, ".tif"),
                     gdal="COMPRESS=NONE",
                     overwrite = overwrite)
  
  # save the data frame as a csv
  write.csv(x = all_states_count_df,
            file = paste0(save_path, "permitted_species_count/data_frames/", "permitted_species_count_", scenario_timeperiod, ".csv"))
  
  ############
  # print that file is done
  print(paste("Done with", all_species_state_borders_list[j]))
}

