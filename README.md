# AOA_climate_change

This project has been submitted to ERL and accepted after revision. Below is a summary of the folders contained within this repo and how they are connected to the analysis.

### pressure_prep

This folder contains scripts that prepare the data used in the analysis. There are many steps to cleaning and processing the data before it can be used to produce final outputs. This includes the processing of SST, depth, and CHLA data from Actea as well as the processing of NOAA aragonite saturation data. Only the scripts that prepare the aragonite layer is publicly available. All other data pressure layers mentioned were provided by Actea and can be purchased from them for use. High-resolution ocean climate data can be obtained from Actea.earth ([info\@actea.earth](https://info&actea.earth)). For additional information on the methods that Actea used to produce the
dataset and validates the climate projections, please follow [this link](https://www.nature.com/articles/s41598-024-51160-1).

### spatial

Contains some of the scripts that prepare important spatial files for the analysis. These include vector files of state waters and the development of a raster that denotes depth constraints in our study area by zeros and ones. As the depth constraints are part of the data provided from Actea, only the state waters data prep is included in the public facing version of the repository.

### impact_calcs

These scripts process the species specific data and calculates their performance index provided by the SST, depth, aragonite, and CHLA data. There are Rmd and R scripts versions of each process so they can be run as a background job. The steps to run the scripts go in order from 0-5. There are a number of custom functions used in these scripts found inside the custom_functions folder to streamline operations.

### figs

These scripts make all of the figures used in the manuscript as well as those used in the supplementary information.
