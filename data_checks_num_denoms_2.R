##############################################################################.
## Data Checks
## Author: Eilish Mackinnon
## Date written: Nov 2025
## Description:
# This script identifies any obvious errors in CAIR data
# The first check calculates the rate & outliers in the selected data - meas_data → group1.csv
# Special rows, where num>denom are saved out - special_rows → special_group1.csv 
#IFR/OBD/PUR are processed to calculate the rate - IFR_PUR_values.xlsx
#All other data saved - group_other_data → other.csv


#############################################
# 1. Install and load libraries
#############################################
install.packages("dplyr")
install.packages("readr")
install.packages("janitor")
install.packages("stringr")
install.packages("tidyr")
install.packages("writexl")
library("dplyr")
library("readr")
library("janitor")
library("stringr")
library("tidyr")
library("writexl")
