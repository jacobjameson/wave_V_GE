library(jsonlite)
library(haven)
library(dplyr)
library(purrr)
library(broom)

# Load the codebook
codebook <- fromJSON('scraper/variable_data.json')

path = '~/Sue Goldie Dropbox/Jacob Jameson/Add Health/Data Upload 7.2021'
path = paste0(path, '/Core Files - Wave V/Wave V Mixed-Mode Survey Data')

dataset <- read_xpt(paste0(path, '/wave5.xpt'))


# Function to replace values based on codebook
replace_values <- function(column, labels) {
  # Convert factor columns to character to avoid level issues
  if (is.factor(column)) {
    column <- as.character(column)
  }
  return(ifelse(is.na(column) | !column %in% names(labels), NA, labels[column]))
}

# Apply the replacement for each column in the dataset
dataset <- dataset %>%
  mutate(across(names(codebook), ~ replace_values(., codebook[[cur_column()]])))

# Check the first few rows of a column
head(dataset$MODE)

# Check the structure of the dataset
str(dataset)

# drop variables where more than 300 observations have the value "legitamte skip"
dataset <- dataset[, colSums(dataset == "legitimate skip", na.rm = TRUE) < 300]
dataset <- dataset[, colSums(dataset == "NA", na.rm = TRUE) < 300]




gender_col <- "H5OD2B" 

# Classify variables as continuous or categorical
# Here, we assume a variable is continuous if it has more than 10 unique values
continuous_vars <- names(dataset)[sapply(dataset, function(x) length(unique(na.omit(x))) > 10)]
categorical_vars <- setdiff(names(dataset), continuous_vars)

# Function to perform t-test or chi-square test
perform_test <- function(var_name) {
  if (var_name %in% continuous_vars) {
    test_result <- t.test(reformulate(gender_col, response = var_name), data = dataset)
  } else {
    test_result <- chisq.test(table(dataset[[gender_col]], dataset[[var_name]]))
  }
  c(Variable = var_name, P_Value = test_result$p.value)
}

# Apply tests and collect results
test_results <- map_dfr(setdiff(names(dataset), gender_col), perform_test)

test_result <- chisq.test(table(dataset[[gender_col]], dataset[['H5EL6E']]))

table(dataset$H5OD2B)

dataset <- as.data.frame(dataset)
# Filter and rank by p-values
top_variables <- test_results %>%
  filter(!is.na(P_Value)) %>%
  arrange(P_Value) %>%
  head(50)

# View the top variables
print(top_variables)



