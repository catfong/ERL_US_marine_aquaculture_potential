library(tidyverse)
library(terra)

#######
# As there is no way to easily make the temperature raster stacks 
# separable by variable (ie. mean, mean_min, abs_max, etc.) 
# the below function `var_extract` was made using stringr. With this function 
# the temperature raster stacks can be re-separated by variable if desired.
#######

var_extract <- function(rast_stack, variable) {
  # check to make sure variable is input correctly
  if(!(variable %in% c("mean", "mean_min", "mean_max", "abs_min", "abs_max", "sd")) == TRUE){              
    stop(print("Variable must be one of: mean, mean_min, mean_max, abs_min, abs_max, sd"))
  } 
  # if variable is mean use str_end to be specific
  if(variable == "mean"){                                                                                  
    # take all the names in the rast_stack and look for the given variable
    var_lyrs <- names(rast_stack)[stringr::str_ends(string = names(rast_stack),            
                                                    pattern = variable)]
    # return a subset of the raster stack for the given variable
    return(subset(rast_stack, var_lyrs))                                                                   
  } else{
    # if variable is anything else use str_detect
    # take all the names in the rast_stack and look for the given variable
    var_lyrs <- names(rast_stack)[stringr::str_detect(string = names(rast_stack),
                                                      pattern = variable)]  
    # return a subset of the raster stack for the given variable
    return(terra::subset(rast_stack, var_lyrs))                                                                   
  }
}
