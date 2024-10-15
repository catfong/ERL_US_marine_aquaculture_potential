# Packages
library(tidyverse)
library(terra)
library(here)

# The goal of this script is to run all of the other.R scripts in sequential order
script_path <- here::here("impact_calcs/")

# run script 1
source(paste0(script_path, "01_all_species_performance.R"))

# run script 2
source(paste0(script_path, "02_aggregate_performance_indexing.R"))

# run script 3
source(paste0(script_path, "03_aggregate_performance_counts.R"))

# run script 4a
source(paste0(script_path, "04a_state_border_filter_index.R"))

# run script 4b
source(paste0(script_path, "04b_state_border_filter_count.R"))

# run script 5a
source(paste0(script_path, "05a_filter_all_species_to_state_waters.R"))

# run script 5b
source(paste0(script_path, "05b_state_permitted_species_filter.R"))

