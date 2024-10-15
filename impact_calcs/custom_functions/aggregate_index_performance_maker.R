# required packages
library(tidyverse)
library(terra)

###############
## Aggregate species performance by all species and taxa
# The goal of this function is to make an aggregate raster of the all species performance rasters made in 01_all_species_performance.
# The variable is as follows:
#   
# - `species_raster` is a raster stack of all our the species of interest 
###############


aggregate_index_performance_maker <- function(species_raster){
  # get the number of species in the performance raster
  number_species <- terra::nlyr(species_raster)
  
  # calculate the mean performance index across all species
  all_species_index <- sum(species_raster, na.rm = TRUE) / number_species
  
  # make a name for the raster layer
  names(all_species_index) <- "all_species_mean_index"
  
  # make a raster that the taxa can be stacked to
  scenario_performance <- all_species_index
  print("Done with all species index")
  
  # make a list of the taxa included in the species_raster
  taxa_list <- c("fish", "mollusc", "seaweed")
  
  # loop through list of taxa and make individual performance index means
  for (i in 1:n_distinct(taxa_list)){
    # get the taxa name
    taxa <- taxa_list[i]
    
    # subset species_raster_to our taxa
    var_lyrs <- names(species_raster)[stringr::str_ends(string = names(species_raster),            
                                                        pattern = taxa)]
    
    # if var_lyrs is length 0 make an empty layer using all_species_index as an example
    if (length(var_lyrs) == 0) {
      # make empty raster
      taxa_raster <- terra::rast(ext(all_species_index), resolution=res(all_species_index))
      
      # assign crs
      crs(taxa_raster) <- crs(all_species_index)
      
      # make name of layer for taxa
      names(taxa_raster) <- paste0(taxa, "_mean_index")
      
    } else {
      taxa_raster <- subset(species_raster, var_lyrs)
      
      # get the number of layers for the taxa and take the mean
      number_species <- terra::nlyr(taxa_raster)
      taxa_raster <- sum(taxa_raster, na.rm = TRUE) / number_species
      
      # name the layer
      names(taxa_raster) <- paste0(taxa, "_mean_index")
    }

    
    # add taxa raster to scenario_performance_raster
    scenario_performance <- c(scenario_performance, taxa_raster)
    print(paste0("Done with ", taxa))
  }
  
  return(scenario_performance)
}
