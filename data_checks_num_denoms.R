
###############################################################################.
## Data Checks - Apr-23
## Author: Eilish Mackinnon
## Date written: Nov 2025

## Description:
# This script identifies any obvious errors in CAIR data.
# The first check checks for data where num>denom


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

# 2. Set working directory
#############################################
setwd("/conf/EIC/Data Submission")  # ✅ Change if needed

#############################################
# 3. Read the file (UTF-16, tab-delimited)
#############################################
raw_data <- read_delim(
  "Raw submissions - data table.csv",
  delim = "\t",
  locale = locale(encoding = "UTF-16"),
  trim_ws = TRUE
) %>%
  clean_names()

#############################################
# 4. Create output folders
#############################################
output_dir <- "Data Checks"
special_dir <- file.path(output_dir, "special_cases")
dir.create(output_dir, showWarnings = FALSE)
dir.create(special_dir, showWarnings = FALSE)

#############################################
# 5. Measures to be included (2 data fields only)
#############################################
meas <- c("AEW", "EWF", "FF1", "FFN2", "FNN3", "PLE1", "DPO1", "DPP1", "MEWC",
          "MEWE", "NN1", "SDU1", "PPA", "PPD", "MHCP", "HVIA")

#############################################
# 6. Split data
#############################################
meas_data <- raw_data %>% filter(measure_id %in% meas)
group_other_data <- raw_data %>% filter(!measure_id %in% meas)

#############################################
# 7. Add columns: calculate rate & flag outliers
#############################################
meas_data <- meas_data %>%
  mutate(
    user_data_1 = as.numeric(user_data_1),
    user_data_2 = as.numeric(user_data_2),
    rate_pct = ifelse(!is.na(user_data_1) & !is.na(user_data_2) & user_data_2 != 0,
                      (user_data_1 / user_data_2) * 100,
                      NA),
    outlier_flag = ifelse(rate_pct > 100, "High", "Normal")
  ) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, measure_id, user_data_1, user_data_2, rate_pct, outlier_flag)

#############################################
# 8. Apply rule for special cases (num > denom)
#############################################
special_rows <- meas_data %>% filter(user_data_1 > user_data_2)

#############################################
# 9. Process IFR, PUR, OBD measures
#############################################
pivoted_data <- group_other_data %>%
  filter(measure_id %in% c("IFR", "PUR", "OBD")) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, measure_id, user_data_1) %>%
  pivot_wider(names_from = measure_id, values_from = user_data_1) %>%
  mutate(
    IFR = as.numeric(IFR),
    PUR = as.numeric(PUR),
    OBD = as.numeric(OBD)
  )

# IFR section
ifr_data <- pivoted_data %>%
  filter(!is.na(IFR) & !is.na(OBD)) %>%
  mutate(
    IFR_num = IFR,
    IFR_den = OBD,
    rate = (IFR_num / IFR_den) * 1000   # IFR rate per 1000
  ) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, IFR_num, IFR_den, rate)

# PUR section
pur_data <- pivoted_data %>%
  filter(!is.na(PUR) & !is.na(OBD)) %>%
  mutate(
    PUR_num = PUR,
    PUR_den = OBD,
    rate = (PUR_num / PUR_den) * 1000   # PUR rate per 1000
  ) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, PUR_num, PUR_den, rate)

#############################################
# 10. Save outputs
#############################################
write_csv(meas_data, file.path(output_dir, "group1.csv"))
write_csv(group_other_data, file.path(output_dir, "other.csv"))

if (nrow(special_rows) > 0) {
  write_csv(special_rows, file.path(special_dir, "special_group1.csv"))
}

excel_file <- file.path(output_dir, "IFR_PUR_values.xlsx")
write_xlsx(list(
  IFR_values = ifr_data,
  PUR_values = pur_data
), path = excel_file)

###################End##########################

