#############################################
# 1. Install and load libraries
#############################################
required_packages <- c("dplyr", "readr", "janitor", "stringr", "tidyr", "writexl")
installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
}
lapply(required_packages, library, character.only = TRUE)

#############################################
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
) |>
  clean_names()

#############################################
# 4. Create output folders
#############################################
output_dir <- "Data Checks"
special_dir <- file.path(output_dir, "special_cases")
dir.create(output_dir, showWarnings = FALSE)
dir.create(special_dir, showWarnings = FALSE)

#############################################
# 5. Define Group 1 measures
#############################################
group1_measures <- c("AEW", "EWF", "FF1", "FFN2", "FNN3", "PLE1", "DPO1", "DPP1", "MEWC",
                     "MEWE", "NN1", "WMYT1", "SDU1", "PPA", "PPD", "MHCP", "HVIA", "QIQ", "LDECP1")

#############################################
# 6. Split data
#############################################
group1_data <- raw_data %>% filter(measure_id %in% group1_measures)
group_other_data <- raw_data %>% filter(!measure_id %in% group1_measures)

#############################################
# 7. Apply rule for special cases
#############################################
special_rows <- group1_data %>%
  filter(as.numeric(user_data_1) > as.numeric(user_data_2))

#############################################
# 8. Filter IFR, PUR, OBD and pivot wider
#############################################
filter_group_other_data <- group_other_data %>%
  filter(measure_id %in% c("IFR", "PUR", "OBD"))

pivoted_data <- filter_group_other_data %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, measure_id, user_data_1) %>%
  pivot_wider(names_from = measure_id, values_from = user_data_1) %>%
  mutate(
    IFR = as.numeric(IFR),
    PUR = as.numeric(PUR),
    OBD = as.numeric(OBD)
  )

#############################################
# 9. Calculate ratios
#############################################
#############################################
# 9. Create numerator and denominator columns
#############################################
ifr_data <- pivoted_data %>%
  filter(!is.na(IFR) & !is.na(OBD)) %>%
  mutate(
    IFR_num = IFR,
    IFR_den = OBD
  ) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, IFR_num, IFR_den)

pur_data <- pivoted_data %>%
  filter(!is.na(PUR) & !is.na(OBD)) %>%
  mutate(
    PUR_num = PUR,
    PUR_den = OBD
  ) %>%
  select(health_board_code_9_curr, health_board_name, location_code, sub_location_code,
         measure_date, PUR_num, PUR_den)
#############################################
# 10. Save outputs
#############################################
write_csv(group1_data, file.path(output_dir, "group1.csv"))
write_csv(group_other_data, file.path(output_dir, "other.csv"))

if (nrow(special_rows) > 0) {
  write_csv(special_rows, file.path(special_dir, "special_group1.csv"))
}

# Save IFR and PUR numerator/denominator in one Excel workbook
excel_file <- file.path(output_dir, "IFR_PUR_values.xlsx")
write_xlsx(list(
  IFR_values = ifr_data,
  PUR_values = pur_data
), path = excel_file)

