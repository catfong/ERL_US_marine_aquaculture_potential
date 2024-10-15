# required packages
library(tidyverse)
library(terra)

###############
## Aggregate species performance by all species and taxa using the count methodology
# The goal of this function is to make an aggregate raster of the all species performance rasters made in 01_all_species_performance.
# The variables are as follows:
#   
# - `species_raster` is a raster stack of all our the species of interest 
# - `GPI_filter` or Growth Performance Index filter, is the threshold of growth performance used for the calculation and must be a value from 0-1
###############

aggregate_count_performance_maker <- function(species_raster, GPI_filter){
  # filter the growth performance values for all layers so that only values greater than 0.5 are included and equal to 1
  species_raster <- terra::ifel(test = species_raster >= GPI_filter,
                                yes = 1,
                                no = NA)
  
  # calculate the total count of all species above our GPI_filter
  all_species_count <- sum(species_raster, na.rm = TRUE)
  
  # make a name for the raster layer
  names(all_species_count) <- "all_species_count"
  
  # make a raster that the taxa can be stacked to
  scenario_counts <- all_species_count
  print("Done with all species count")
  
  # make a list of the taxa included in the species_raster
  taxa_list <- c("fish", "mollusc", "seaweed")
  
  # loop through list of taxa and make individual performance index means
  for (i in 1:n_distinct(taxa_list)){
    # get the taxa name
    taxa <- taxa_list[i]
    
    # subset species_raster_to our taxa
    var_lyrs <- names(species_raster)[stringr::str_ends(string = names(species_raster),            
                                                        pattern = taxa)]
    
    # if var_lyrs is length 0 make an empty layer using all_species_count as an example
    if (length(var_lyrs) == 0) {
      # make empty raster
      taxa_raster <- terra::rast(ext(all_species_count), resolution=res(all_species_count))
      
      # assign crs
      crs(taxa_raster) <- crs(all_species_count)
      
      # make name of layer for taxa
      names(taxa_raster) <- paste0(taxa, "_count")
      
    } else {
      taxa_raster <- subset(species_raster, var_lyrs)
      
      # calculate the total count of species in taxa above our GPI_filter
      taxa_raster <- sum(taxa_raster, na.rm = TRUE)
      
      # name the layer
      names(taxa_raster) <- paste0(taxa, "_count")
    }
    
    # add taxa raster to scenario_performance_raster
    scenario_counts <- c(scenario_counts, taxa_raster)
    print(paste0("Done with ", taxa))
  }
  
  return(scenario_counts)
}