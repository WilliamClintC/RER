# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)
}

# Install required packages
required_packages <- c("car", "stargazer", "dplyr", "rmarkdown", "knitr", "readr")
install_if_missing(required_packages)

# Load required libraries
library(car)
library(stargazer)
library(dplyr)
library(rmarkdown)
library(knitr)
library(readr)

# Create output directory
output_dir <- "C:/Users/clint/Desktop/RER/Code/32_models"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created output directory:", output_dir, "\n")
}

# Load the dataset
file_path <- "C:/Users/clint/Desktop/RER/Code/29.csv"
cat("Loading dataset...\n")
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Check data structure
cat("Data dimensions:", nrow(df), "rows,", ncol(df), "columns\n")
cat("Year range:", min(df$Year), "to", max(df$Year), "\n")
cat("Unique years:", paste(sort(unique(df$Year)), collapse=", "), "\n")

# Clean the Value column (remove commas and convert to numeric)
df$Value <- as.numeric(gsub(",", "", df$Value))

# Convert remittances to thousands (Value is in USD millions, so multiply by 1000 to get thousands)
df$Remittances_Thousands <- df$Value * 1000

# Keep remittances in millions (original Value column) - this is the default
df$Remittances_Millions <- df$Value

# Check for problematic values that could cause log issues
cat("Checking for problematic values:\n")
cat("Zero remittances (thousands):", sum(df$Remittances_Thousands == 0, na.rm = TRUE), "\n")
cat("Negative remittances (thousands):", sum(df$Remittances_Thousands < 0, na.rm = TRUE), "\n")
cat("Min remittances (thousands):", min(df$Remittances_Thousands, na.rm = TRUE), "\n")
cat("Zero remittances (millions):", sum(df$Remittances_Millions == 0, na.rm = TRUE), "\n")
cat("Negative remittances (millions):", sum(df$Remittances_Millions < 0, na.rm = TRUE), "\n")
cat("Min remittances (millions):", min(df$Remittances_Millions, na.rm = TRUE), "\n")
cat("Zero GDP per capita sending:", sum(df$Sending_Country_GDP_Per_Capita <= 0, na.rm = TRUE), "\n")
cat("Zero GDP per capita receiving:", sum(df$Receiving_Country_GDP_Per_Capita <= 0, na.rm = TRUE), "\n")
cat("Zero GDP total sending:", sum(df$Sending_Country_GDP <= 0, na.rm = TRUE), "\n")
cat("Zero GDP total receiving:", sum(df$Receiving_Country_GDP <= 0, na.rm = TRUE), "\n")

# Create a unique corridor identifier
df$Corridor <- paste(df$Sending_Country, df$Receiving_Country, sep = " -> ")

# Sort data by corridor and year
df <- df %>% 
  arrange(Corridor, Year)

# Filter out any problematic values before calculations
df <- df %>%
  filter(Remittances_Thousands > 0 & 
         Remittances_Millions > 0 &
         Sending_Country_GDP_Per_Capita > 0 & 
         Receiving_Country_GDP_Per_Capita > 0 &
         Sending_Country_GDP > 0 &
         Receiving_Country_GDP > 0)

cat("After filtering out zero/negative values:", nrow(df), "observations\n")

# Calculate changes (first differences)
df <- df %>%
  group_by(Corridor) %>%
  arrange(Year) %>%
  mutate(
    # Change in remittances (dependent variable) - THOUSANDS
    Change_Remittances_Thousands = Remittances_Thousands - lag(Remittances_Thousands),
    
    # Change in remittances (dependent variable) - MILLIONS (default)
    Change_Remittances_Millions = Remittances_Millions - lag(Remittances_Millions),
    
    # Change in sending country GDP per capita (independent variable)
    Change_Sending_GDP_Per_Capita = Sending_Country_GDP_Per_Capita - lag(Sending_Country_GDP_Per_Capita),
    
    # Change in receiving country GDP per capita (independent variable)
    Change_Receiving_GDP_Per_Capita = Receiving_Country_GDP_Per_Capita - lag(Receiving_Country_GDP_Per_Capita),
    
    # Change in sending country GDP (total, not per capita)
    Change_Sending_GDP = Sending_Country_GDP - lag(Sending_Country_GDP),
    
    # Change in receiving country GDP (total, not per capita)
    Change_Receiving_GDP = Receiving_Country_GDP - lag(Receiving_Country_GDP),
    
    # Lagged change variables (for lagged models)
    Lag_Change_Sending_GDP_Per_Capita = lag(Change_Sending_GDP_Per_Capita),
    Lag_Change_Receiving_GDP_Per_Capita = lag(Change_Receiving_GDP_Per_Capita),
    
    # Lagged change variables for GDP (total)
    Lag_Change_Sending_GDP = lag(Change_Sending_GDP),
    Lag_Change_Receiving_GDP = lag(Change_Receiving_GDP),
    
    # LOG SPECIFICATIONS: First take logs, then calculate changes (log differences = growth rates)
    # Log of variables (safe since we filtered out zero/negative values)
    Log_Remittances_Thousands = log(Remittances_Thousands),
    Log_Remittances_Millions = log(Remittances_Millions),
    Log_Sending_GDP_Per_Capita = log(Sending_Country_GDP_Per_Capita),
    Log_Receiving_GDP_Per_Capita = log(Receiving_Country_GDP_Per_Capita),
    Log_Sending_GDP = log(Sending_Country_GDP),
    Log_Receiving_GDP = log(Receiving_Country_GDP),
    
    # Changes in logs (growth rates) for remittances
    Change_Log_Remittances_Thousands = Log_Remittances_Thousands - lag(Log_Remittances_Thousands),
    Change_Log_Remittances_Millions = Log_Remittances_Millions - lag(Log_Remittances_Millions),
    # Changes in logs (growth rates) for GDP per capita
    Change_Log_Sending_GDP = Log_Sending_GDP_Per_Capita - lag(Log_Sending_GDP_Per_Capita),
    Change_Log_Receiving_GDP = Log_Receiving_GDP_Per_Capita - lag(Log_Receiving_GDP_Per_Capita),
    
    # Changes in logs (growth rates) for total GDP
    Change_Log_Sending_GDP_Total = Log_Sending_GDP - lag(Log_Sending_GDP),
    Change_Log_Receiving_GDP_Total = Log_Receiving_GDP - lag(Log_Receiving_GDP),
    
    # Lagged log changes for GDP per capita
    Lag_Change_Log_Sending_GDP = lag(Change_Log_Sending_GDP),
    Lag_Change_Log_Receiving_GDP = lag(Change_Log_Receiving_GDP),
    
    # Lagged log changes for total GDP
    Lag_Change_Log_Sending_GDP_Total = lag(Change_Log_Sending_GDP_Total),
    Lag_Change_Log_Receiving_GDP_Total = lag(Change_Log_Receiving_GDP_Total)
  ) %>%
  ungroup()

# Remove rows with missing values for the main analysis
df_complete <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Change_Sending_GDP_Per_Capita) & 
         !is.na(Change_Receiving_GDP_Per_Capita))

# Remove rows with missing values for millions analysis
df_complete_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Change_Sending_GDP_Per_Capita) & 
         !is.na(Change_Receiving_GDP_Per_Capita))

# Remove rows with missing values for GDP (total) analysis
df_complete_gdp <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Change_Sending_GDP) & 
         !is.na(Change_Receiving_GDP))

# Remove rows with missing values for GDP (total) analysis - millions
df_complete_gdp_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Change_Sending_GDP) & 
         !is.na(Change_Receiving_GDP))

cat("Complete cases for main analysis (GDP per capita, thousands):", nrow(df_complete), "\n")
cat("Complete cases for main analysis (GDP per capita, millions):", nrow(df_complete_millions), "\n")
cat("Complete cases for GDP total analysis (thousands):", nrow(df_complete_gdp), "\n")
cat("Complete cases for GDP total analysis (millions):", nrow(df_complete_gdp_millions), "\n")

# Function to remove outliers based on percentiles
remove_outliers <- function(data, variables, lower_percentile = 0.05, upper_percentile = 0.95) {
  for (var in variables) {
    lower_bound <- quantile(data[[var]], lower_percentile, na.rm = TRUE)
    upper_bound <- quantile(data[[var]], upper_percentile, na.rm = TRUE)
    data <- data[data[[var]] >= lower_bound & data[[var]] <= upper_bound, ]
  }
  return(data)
}

# Create dataset without outliers (5th and 95th percentiles)
# Remove outliers based on RAW remittance levels, not changes
outlier_vars <- c("Remittances_Thousands", "Change_Sending_GDP_Per_Capita", "Change_Receiving_GDP_Per_Capita")
df_no_outliers <- remove_outliers(df_complete, outlier_vars)

# Create dataset without outliers for millions
# Remove outliers based on RAW remittance levels, not changes
outlier_vars_millions <- c("Remittances_Millions", "Change_Sending_GDP_Per_Capita", "Change_Receiving_GDP_Per_Capita")
df_no_outliers_millions <- remove_outliers(df_complete_millions, outlier_vars_millions)

# Create dataset without outliers for GDP (total)
# Remove outliers based on RAW remittance levels, not changes
outlier_vars_gdp <- c("Remittances_Thousands", "Change_Sending_GDP", "Change_Receiving_GDP")
df_no_outliers_gdp <- remove_outliers(df_complete_gdp, outlier_vars_gdp)

# Create dataset without outliers for GDP (total) - millions
# Remove outliers based on RAW remittance levels, not changes
outlier_vars_gdp_millions <- c("Remittances_Millions", "Change_Sending_GDP", "Change_Receiving_GDP")
df_no_outliers_gdp_millions <- remove_outliers(df_complete_gdp_millions, outlier_vars_gdp_millions)

cat("Data without outliers (GDP per capita, thousands):", nrow(df_no_outliers), "observations\n")
cat("Outliers removed (GDP per capita, thousands):", nrow(df_complete) - nrow(df_no_outliers), "observations\n")
cat("Data without outliers (GDP per capita, millions):", nrow(df_no_outliers_millions), "observations\n")
cat("Outliers removed (GDP per capita, millions):", nrow(df_complete_millions) - nrow(df_no_outliers_millions), "observations\n")
cat("Data without outliers (GDP total, thousands):", nrow(df_no_outliers_gdp), "observations\n")
cat("Outliers removed (GDP total, thousands):", nrow(df_complete_gdp) - nrow(df_no_outliers_gdp), "observations\n")
cat("Data without outliers (GDP total, millions):", nrow(df_no_outliers_gdp_millions), "observations\n")
cat("Outliers removed (GDP total, millions):", nrow(df_complete_gdp_millions) - nrow(df_no_outliers_gdp_millions), "observations\n")
cat("NOTE: Outliers removed based on RAW remittance levels, not changes in remittances\n")

# For lagged models, we need complete cases including lagged variables
df_complete_lagged <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Lag_Change_Sending_GDP_Per_Capita) & 
         !is.na(Lag_Change_Receiving_GDP_Per_Capita))

# Remove outliers for lagged data
df_no_outliers_lagged <- remove_outliers(df_complete_lagged, 
                                        c("Change_Remittances_Thousands", 
                                          "Lag_Change_Sending_GDP_Per_Capita", 
                                          "Lag_Change_Receiving_GDP_Per_Capita"))

# For lagged models, we need complete cases including lagged variables
df_complete_lagged <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Lag_Change_Sending_GDP_Per_Capita) & 
         !is.na(Lag_Change_Receiving_GDP_Per_Capita))

# For lagged models - millions
df_complete_lagged_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Lag_Change_Sending_GDP_Per_Capita) & 
         !is.na(Lag_Change_Receiving_GDP_Per_Capita))

# For lagged models with GDP total
df_complete_lagged_gdp <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Lag_Change_Sending_GDP) & 
         !is.na(Lag_Change_Receiving_GDP))

# For lagged models with GDP total - millions
df_complete_lagged_gdp_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Lag_Change_Sending_GDP) & 
         !is.na(Lag_Change_Receiving_GDP))

# Remove outliers for lagged data
# Remove outliers based on RAW remittance levels, not changes
df_no_outliers_lagged <- remove_outliers(df_complete_lagged, 
                                        c("Remittances_Thousands", 
                                          "Lag_Change_Sending_GDP_Per_Capita", 
                                          "Lag_Change_Receiving_GDP_Per_Capita"))

df_no_outliers_lagged_millions <- remove_outliers(df_complete_lagged_millions, 
                                                 c("Remittances_Millions", 
                                                   "Lag_Change_Sending_GDP_Per_Capita", 
                                                   "Lag_Change_Receiving_GDP_Per_Capita"))

df_no_outliers_lagged_gdp <- remove_outliers(df_complete_lagged_gdp, 
                                            c("Remittances_Thousands", 
                                              "Lag_Change_Sending_GDP", 
                                              "Lag_Change_Receiving_GDP"))

df_no_outliers_lagged_gdp_millions <- remove_outliers(df_complete_lagged_gdp_millions, 
                                                     c("Remittances_Millions", 
                                                       "Lag_Change_Sending_GDP", 
                                                       "Lag_Change_Receiving_GDP"))

cat("Complete cases for lagged analysis (GDP per capita, thousands):", nrow(df_complete_lagged), "\n")
cat("Complete cases for lagged analysis without outliers (GDP per capita, thousands):", nrow(df_no_outliers_lagged), "\n")
cat("Complete cases for lagged analysis (GDP per capita, millions):", nrow(df_complete_lagged_millions), "\n")
cat("Complete cases for lagged analysis without outliers (GDP per capita, millions):", nrow(df_no_outliers_lagged_millions), "\n")
cat("Complete cases for lagged analysis (GDP total, thousands):", nrow(df_complete_lagged_gdp), "\n")
cat("Complete cases for lagged analysis without outliers (GDP total, thousands):", nrow(df_no_outliers_lagged_gdp), "\n")
cat("Complete cases for lagged analysis (GDP total, millions):", nrow(df_complete_lagged_gdp_millions), "\n")
cat("Complete cases for lagged analysis without outliers (GDP total, millions):", nrow(df_no_outliers_lagged_gdp_millions), "\n")

# LOG MODEL DATA PREPARATION
# Complete cases for log-log models (both dependent and independent variables in logs) - GDP per capita - THOUSANDS
df_complete_loglog <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Change_Log_Sending_GDP) & 
         !is.na(Change_Log_Receiving_GDP))

# Complete cases for log-log models (both dependent and independent variables in logs) - GDP per capita - MILLIONS
df_complete_loglog_millions <- df %>%
  filter(!is.na(Change_Log_Remittances_Millions) & 
         !is.na(Change_Log_Sending_GDP) & 
         !is.na(Change_Log_Receiving_GDP))

# Complete cases for log-log models (both dependent and independent variables in logs) - GDP total - THOUSANDS
df_complete_loglog_gdp <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Change_Log_Sending_GDP_Total) & 
         !is.na(Change_Log_Receiving_GDP_Total))

# Complete cases for log-log models (both dependent and independent variables in logs) - GDP total - MILLIONS
df_complete_loglog_gdp_millions <- df %>%
  filter(!is.na(Change_Log_Remittances_Millions) & 
         !is.na(Change_Log_Sending_GDP_Total) & 
         !is.na(Change_Log_Receiving_GDP_Total))

# Complete cases for log-linear models (dependent variable in logs, independent in levels) - GDP per capita - THOUSANDS
df_complete_loglinear <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Change_Sending_GDP_Per_Capita) & 
         !is.na(Change_Receiving_GDP_Per_Capita))

# Complete cases for log-linear models (dependent variable in logs, independent in levels) - GDP per capita - MILLIONS
df_complete_loglinear_millions <- df %>%
  filter(!is.na(Change_Log_Remittances_Millions) & 
         !is.na(Change_Sending_GDP_Per_Capita) & 
         !is.na(Change_Receiving_GDP_Per_Capita))

# Complete cases for log-linear models (dependent variable in logs, independent in levels) - GDP total - THOUSANDS
df_complete_loglinear_gdp <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Change_Sending_GDP) & 
         !is.na(Change_Receiving_GDP))

# Complete cases for log-linear models (dependent variable in logs, independent in levels) - GDP total - MILLIONS
df_complete_loglinear_gdp_millions <- df %>%
  filter(!is.na(Change_Log_Remittances_Millions) & 
         !is.na(Change_Sending_GDP) & 
         !is.na(Change_Receiving_GDP))

# Complete cases for linear-log models (dependent variable in levels, independent in logs) - GDP per capita - THOUSANDS
df_complete_linearlog <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Change_Log_Sending_GDP) & 
         !is.na(Change_Log_Receiving_GDP))

# Complete cases for linear-log models (dependent variable in levels, independent in logs) - GDP per capita - MILLIONS
df_complete_linearlog_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Change_Log_Sending_GDP) & 
         !is.na(Change_Log_Receiving_GDP))

# Complete cases for linear-log models (dependent variable in levels, independent in logs) - GDP total - THOUSANDS
df_complete_linearlog_gdp <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Change_Log_Sending_GDP_Total) & 
         !is.na(Change_Log_Receiving_GDP_Total))

# Complete cases for linear-log models (dependent variable in levels, independent in logs) - GDP total - MILLIONS
df_complete_linearlog_gdp_millions <- df %>%
  filter(!is.na(Change_Remittances_Millions) & 
         !is.na(Change_Log_Sending_GDP_Total) & 
         !is.na(Change_Log_Receiving_GDP_Total))

# Remove outliers for log models - GDP per capita
# Use RAW remittance levels for outlier detection, not changes
outlier_vars_loglog <- c("Remittances_Thousands", "Change_Log_Sending_GDP", "Change_Log_Receiving_GDP")
df_no_outliers_loglog <- remove_outliers(df_complete_loglog, outlier_vars_loglog)

outlier_vars_loglinear <- c("Remittances_Thousands", "Change_Sending_GDP_Per_Capita", "Change_Receiving_GDP_Per_Capita")
df_no_outliers_loglinear <- remove_outliers(df_complete_loglinear, outlier_vars_loglinear)

outlier_vars_linearlog <- c("Remittances_Thousands", "Change_Log_Sending_GDP", "Change_Log_Receiving_GDP")
df_no_outliers_linearlog <- remove_outliers(df_complete_linearlog, outlier_vars_linearlog)

# Remove outliers for log models - GDP total
# Use RAW remittance levels for outlier detection, not changes
outlier_vars_loglog_gdp <- c("Remittances_Thousands", "Change_Log_Sending_GDP_Total", "Change_Log_Receiving_GDP_Total")
df_no_outliers_loglog_gdp <- remove_outliers(df_complete_loglog_gdp, outlier_vars_loglog_gdp)

outlier_vars_loglinear_gdp <- c("Remittances_Thousands", "Change_Sending_GDP", "Change_Receiving_GDP")
df_no_outliers_loglinear_gdp <- remove_outliers(df_complete_loglinear_gdp, outlier_vars_loglinear_gdp)

outlier_vars_linearlog_gdp <- c("Remittances_Thousands", "Change_Log_Sending_GDP_Total", "Change_Log_Receiving_GDP_Total")
df_no_outliers_linearlog_gdp <- remove_outliers(df_complete_linearlog_gdp, outlier_vars_linearlog_gdp)

# Lagged log models - GDP per capita
df_complete_loglog_lagged <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Lag_Change_Log_Sending_GDP) & 
         !is.na(Lag_Change_Log_Receiving_GDP))

df_no_outliers_loglog_lagged <- remove_outliers(df_complete_loglog_lagged, 
                                               c("Remittances_Thousands", 
                                                 "Lag_Change_Log_Sending_GDP", 
                                                 "Lag_Change_Log_Receiving_GDP"))

# Lagged log models - GDP total
df_complete_loglog_lagged_gdp <- df %>%
  filter(!is.na(Change_Log_Remittances_Thousands) & 
         !is.na(Lag_Change_Log_Sending_GDP_Total) & 
         !is.na(Lag_Change_Log_Receiving_GDP_Total))

df_no_outliers_loglog_lagged_gdp <- remove_outliers(df_complete_loglog_lagged_gdp, 
                                                   c("Remittances_Thousands", 
                                                     "Lag_Change_Log_Sending_GDP_Total", 
                                                     "Lag_Change_Log_Receiving_GDP_Total"))

cat("Complete cases for log-log analysis (GDP per capita):", nrow(df_complete_loglog), "\n")
cat("Complete cases for log-log analysis without outliers (GDP per capita):", nrow(df_no_outliers_loglog), "\n")
cat("Complete cases for log-linear analysis (GDP per capita):", nrow(df_complete_loglinear), "\n")
cat("Complete cases for log-linear analysis without outliers (GDP per capita):", nrow(df_no_outliers_loglinear), "\n")
cat("Complete cases for linear-log analysis (GDP per capita):", nrow(df_complete_linearlog), "\n")
cat("Complete cases for linear-log analysis without outliers (GDP per capita):", nrow(df_no_outliers_linearlog), "\n")
cat("Complete cases for lagged log-log analysis (GDP per capita):", nrow(df_complete_loglog_lagged), "\n")
cat("Complete cases for lagged log-log analysis without outliers (GDP per capita):", nrow(df_no_outliers_loglog_lagged), "\n")

cat("Complete cases for log-log analysis (GDP total):", nrow(df_complete_loglog_gdp), "\n")
cat("Complete cases for log-log analysis without outliers (GDP total):", nrow(df_no_outliers_loglog_gdp), "\n")
cat("Complete cases for log-linear analysis (GDP total):", nrow(df_complete_loglinear_gdp), "\n")
cat("Complete cases for log-linear analysis without outliers (GDP total):", nrow(df_no_outliers_loglinear_gdp), "\n")
cat("Complete cases for linear-log analysis (GDP total):", nrow(df_complete_linearlog_gdp), "\n")
cat("Complete cases for linear-log analysis without outliers (GDP total):", nrow(df_no_outliers_linearlog_gdp), "\n")
cat("Complete cases for lagged log-log analysis (GDP total):", nrow(df_complete_loglog_lagged_gdp), "\n")
cat("Complete cases for lagged log-log analysis without outliers (GDP total):", nrow(df_no_outliers_loglog_lagged_gdp), "\n")

# Clean datasets with simple variable names for stargazer compatibility
df_complete_clean <- df_complete %>%
  select(Change_Remittances_Thousands, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

df_no_outliers_clean <- df_no_outliers %>%
  select(Change_Remittances_Thousands, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

df_complete_lagged_clean <- df_complete_lagged %>%
  select(Change_Remittances_Thousands, Lag_Change_Sending_GDP_Per_Capita, Lag_Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1_lag = Lag_Change_Sending_GDP_Per_Capita,
    X2_lag = Lag_Change_Receiving_GDP_Per_Capita
  )

df_no_outliers_lagged_clean <- df_no_outliers_lagged %>%
  select(Change_Remittances_Thousands, Lag_Change_Sending_GDP_Per_Capita, Lag_Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1_lag = Lag_Change_Sending_GDP_Per_Capita,
    X2_lag = Lag_Change_Receiving_GDP_Per_Capita
  )

# Clean datasets for GDP total models
df_complete_gdp_clean <- df_complete_gdp %>%
  select(Change_Remittances_Thousands, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

df_no_outliers_gdp_clean <- df_no_outliers_gdp %>%
  select(Change_Remittances_Thousands, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

df_complete_lagged_gdp_clean <- df_complete_lagged_gdp %>%
  select(Change_Remittances_Thousands, Lag_Change_Sending_GDP, Lag_Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1_lag = Lag_Change_Sending_GDP,
    X2_lag = Lag_Change_Receiving_GDP
  )

df_no_outliers_lagged_gdp_clean <- df_no_outliers_lagged_gdp %>%
  select(Change_Remittances_Thousands, Lag_Change_Sending_GDP, Lag_Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Thousands,
    X1_lag = Lag_Change_Sending_GDP,
    X2_lag = Lag_Change_Receiving_GDP
  )

# LOG MODEL CLEAN DATASETS
# Log-log models (both dependent and independent variables in logs)
df_complete_loglog_clean <- df_complete_loglog %>%
  select(Change_Log_Remittances_Thousands, Change_Log_Sending_GDP, Change_Log_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log = Change_Log_Sending_GDP,
    X2_log = Change_Log_Receiving_GDP
  )

df_no_outliers_loglog_clean <- df_no_outliers_loglog %>%
  select(Change_Log_Remittances_Thousands, Change_Log_Sending_GDP, Change_Log_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log = Change_Log_Sending_GDP,
    X2_log = Change_Log_Receiving_GDP
  )

# Log-linear models (dependent variable in logs, independent in levels)
df_complete_loglinear_clean <- df_complete_loglinear %>%
  select(Change_Log_Remittances_Thousands, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

df_no_outliers_loglinear_clean <- df_no_outliers_loglinear %>%
  select(Change_Log_Remittances_Thousands, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

# Lagged log-log models
df_complete_loglog_lagged_clean <- df_complete_loglog_lagged %>%
  select(Change_Log_Remittances_Thousands, Lag_Change_Log_Sending_GDP, Lag_Change_Log_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log_lag = Lag_Change_Log_Sending_GDP,
    X2_log_lag = Lag_Change_Log_Receiving_GDP
  )

df_no_outliers_loglog_lagged_clean <- df_no_outliers_loglog_lagged %>%
  select(Change_Log_Remittances_Thousands, Lag_Change_Log_Sending_GDP, Lag_Change_Log_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log_lag = Lag_Change_Log_Sending_GDP,
    X2_log_lag = Lag_Change_Log_Receiving_GDP
  )

# LOG MODEL CLEAN DATASETS FOR GDP TOTAL
# Log-log models (both dependent and independent variables in logs) - GDP total
df_complete_loglog_gdp_clean <- df_complete_loglog_gdp %>%
  select(Change_Log_Remittances_Thousands, Change_Log_Sending_GDP_Total, Change_Log_Receiving_GDP_Total) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log = Change_Log_Sending_GDP_Total,
    X2_log = Change_Log_Receiving_GDP_Total
  )

df_no_outliers_loglog_gdp_clean <- df_no_outliers_loglog_gdp %>%
  select(Change_Log_Remittances_Thousands, Change_Log_Sending_GDP_Total, Change_Log_Receiving_GDP_Total) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log = Change_Log_Sending_GDP_Total,
    X2_log = Change_Log_Receiving_GDP_Total
  )

# Log-linear models (dependent variable in logs, independent in levels) - GDP total
df_complete_loglinear_gdp_clean <- df_complete_loglinear_gdp %>%
  select(Change_Log_Remittances_Thousands, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

df_no_outliers_loglinear_gdp_clean <- df_no_outliers_loglinear_gdp %>%
  select(Change_Log_Remittances_Thousands, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

# Linear-log models (dependent variable in levels, independent in logs) - GDP total
df_clean_linearlog_gdp <- df_complete_linearlog_gdp %>%
  select(Change_Remittances_Thousands, Change_Log_Sending_GDP_Total, Change_Log_Receiving_GDP_Total) %>%
  rename(Y = Change_Remittances_Thousands,
         X1 = Change_Log_Sending_GDP_Total,
         X2 = Change_Log_Receiving_GDP_Total)

df_clean_linearlog_gdp_no_outliers <- df_no_outliers_linearlog_gdp %>%
  select(Change_Remittances_Thousands, Change_Log_Sending_GDP_Total, Change_Log_Receiving_GDP_Total) %>%
  rename(Y = Change_Remittances_Thousands,
         X1 = Change_Log_Sending_GDP_Total,
         X2 = Change_Log_Receiving_GDP_Total)

# Lagged log-log models - GDP total
df_complete_loglog_lagged_gdp_clean <- df_complete_loglog_lagged_gdp %>%
  select(Change_Log_Remittances_Thousands, Lag_Change_Log_Sending_GDP_Total, Lag_Change_Log_Receiving_GDP_Total) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log_lag = Lag_Change_Log_Sending_GDP_Total,
    X2_log_lag = Lag_Change_Log_Receiving_GDP_Total
  )

df_no_outliers_loglog_lagged_gdp_clean <- df_no_outliers_loglog_lagged_gdp %>%
  select(Change_Log_Remittances_Thousands, Lag_Change_Log_Sending_GDP_Total, Lag_Change_Log_Receiving_GDP_Total) %>%
  rename(
    Y_log = Change_Log_Remittances_Thousands,
    X1_log_lag = Lag_Change_Log_Sending_GDP_Total,
    X2_log_lag = Lag_Change_Log_Receiving_GDP_Total
  )

# Model 1: Contemporaneous (unlagged) with outliers
model1_with_outliers <- lm(Y ~ X1 + X2, data = df_complete_clean)

# Model 2: Contemporaneous (unlagged) without outliers
model2_no_outliers <- lm(Y ~ X1 + X2, data = df_no_outliers_clean)

# Model 3: Lagged (1 period) with outliers
model3_lagged_with_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_complete_lagged_clean)

# Model 4: Lagged (1 period) without outliers
model4_lagged_no_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_no_outliers_lagged_clean)

# LOG-LOG MODELS (Elasticity interpretation)
# Model 5: Log-log contemporaneous with outliers
model5_loglog_with_outliers <- lm(Y_log ~ X1_log + X2_log, data = df_complete_loglog_clean)

# Model 6: Log-log contemporaneous without outliers
model6_loglog_no_outliers <- lm(Y_log ~ X1_log + X2_log, data = df_no_outliers_loglog_clean)

# Model 7: Log-log lagged with outliers
model7_loglog_lagged_with_outliers <- lm(Y_log ~ X1_log_lag + X2_log_lag, data = df_complete_loglog_lagged_clean)

# Model 8: Log-log lagged without outliers
model8_loglog_lagged_no_outliers <- lm(Y_log ~ X1_log_lag + X2_log_lag, data = df_no_outliers_loglog_lagged_clean)

# LOG-LINEAR MODELS (Semi-elasticity interpretation)
# Model 9: Log-linear contemporaneous with outliers
model9_loglinear_with_outliers <- lm(Y_log ~ X1 + X2, data = df_complete_loglinear_clean)

# Model 10: Log-linear contemporaneous without outliers
model10_loglinear_no_outliers <- lm(Y_log ~ X1 + X2, data = df_no_outliers_loglinear_clean)

# Create clean datasets for linear-log analysis (for stargazer compatibility)
df_clean_linearlog <- df_complete_linearlog %>%
  select(Change_Remittances_Thousands, Change_Log_Sending_GDP, Change_Log_Receiving_GDP) %>%
  rename(Y = Change_Remittances_Thousands,
         X1 = Change_Log_Sending_GDP,
         X2 = Change_Log_Receiving_GDP)

df_clean_linearlog_no_outliers <- df_no_outliers_linearlog %>%
  select(Change_Remittances_Thousands, Change_Log_Sending_GDP, Change_Log_Receiving_GDP) %>%
  rename(Y = Change_Remittances_Thousands,
         X1 = Change_Log_Sending_GDP,
         X2 = Change_Log_Receiving_GDP)

# LINEAR-LOG MODELS (Log-linear with level dependent variable)
# Model 11: Linear-log contemporaneous with outliers
model11_linearlog_with_outliers <- lm(Y ~ X1 + X2, data = df_clean_linearlog)

# Model 12: Linear-log contemporaneous without outliers
model12_linearlog_no_outliers <- lm(Y ~ X1 + X2, data = df_clean_linearlog_no_outliers)

# ADDITIONAL MODELS 13-24: USING GDP TOTAL INSTEAD OF GDP PER CAPITA
# LEVEL MODELS (GDP Total) - Models 13-16
# Model 13: Contemporaneous with outliers (GDP total)
model13_gdp_with_outliers <- lm(Y ~ X1 + X2, data = df_complete_gdp_clean)

# Model 14: Contemporaneous without outliers (GDP total)
model14_gdp_no_outliers <- lm(Y ~ X1 + X2, data = df_no_outliers_gdp_clean)

# Model 15: Lagged (1 period) with outliers (GDP total)
model15_gdp_lagged_with_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_complete_lagged_gdp_clean)

# Model 16: Lagged (1 period) without outliers (GDP total)
model16_gdp_lagged_no_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_no_outliers_lagged_gdp_clean)

# LOG-LOG MODELS (GDP Total) - Models 17-20
# Model 17: Log-log contemporaneous with outliers (GDP total)
model17_loglog_gdp_with_outliers <- lm(Y_log ~ X1_log + X2_log, data = df_complete_loglog_gdp_clean)

# Model 18: Log-log contemporaneous without outliers (GDP total)
model18_loglog_gdp_no_outliers <- lm(Y_log ~ X1_log + X2_log, data = df_no_outliers_loglog_gdp_clean)

# Model 19: Log-log lagged with outliers (GDP total)
model19_loglog_gdp_lagged_with_outliers <- lm(Y_log ~ X1_log_lag + X2_log_lag, data = df_complete_loglog_lagged_gdp_clean)

# Model 20: Log-log lagged without outliers (GDP total)
model20_loglog_gdp_lagged_no_outliers <- lm(Y_log ~ X1_log_lag + X2_log_lag, data = df_no_outliers_loglog_lagged_gdp_clean)

# LOG-LINEAR MODELS (GDP Total) - Models 21-22
# Model 21: Log-linear contemporaneous with outliers (GDP total)
model21_loglinear_gdp_with_outliers <- lm(Y_log ~ X1 + X2, data = df_complete_loglinear_gdp_clean)

# Model 22: Log-linear contemporaneous without outliers (GDP total)
model22_loglinear_gdp_no_outliers <- lm(Y_log ~ X1 + X2, data = df_no_outliers_loglinear_gdp_clean)

# LINEAR-LOG MODELS (GDP Total) - Models 23-24
# Model 23: Linear-log contemporaneous with outliers (GDP total)
model23_linearlog_gdp_with_outliers <- lm(Y ~ X1 + X2, data = df_clean_linearlog_gdp)

# Model 24: Linear-log contemporaneous without outliers (GDP total)
model24_linearlog_gdp_no_outliers <- lm(Y ~ X1 + X2, data = df_clean_linearlog_gdp_no_outliers)

# ADDITIONAL MODELS 25-48: USING REMITTANCES IN MILLIONS (DEFAULT)
# These models replicate the thousands models but use millions as dependent variable

# Clean datasets for millions - GDP per capita
df_complete_millions_clean <- df_complete_millions %>%
  select(Change_Remittances_Millions, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Millions,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

df_no_outliers_millions_clean <- df_no_outliers_millions %>%
  select(Change_Remittances_Millions, Change_Sending_GDP_Per_Capita, Change_Receiving_GDP_Per_Capita) %>%
  rename(
    Y = Change_Remittances_Millions,
    X1 = Change_Sending_GDP_Per_Capita,
    X2 = Change_Receiving_GDP_Per_Capita
  )

# Clean datasets for millions - GDP total
df_complete_gdp_millions_clean <- df_complete_gdp_millions %>%
  select(Change_Remittances_Millions, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Millions,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

df_no_outliers_gdp_millions_clean <- df_no_outliers_gdp_millions %>%
  select(Change_Remittances_Millions, Change_Sending_GDP, Change_Receiving_GDP) %>%
  rename(
    Y = Change_Remittances_Millions,
    X1 = Change_Sending_GDP,
    X2 = Change_Receiving_GDP
  )

# LEVEL MODELS (Millions) - Models 25-28
# Model 25: Contemporaneous with outliers (GDP per capita, millions)
model25_millions_with_outliers <- lm(Y ~ X1 + X2, data = df_complete_millions_clean)

# Model 26: Contemporaneous without outliers (GDP per capita, millions)
model26_millions_no_outliers <- lm(Y ~ X1 + X2, data = df_no_outliers_millions_clean)

# Model 27: Contemporaneous with outliers (GDP total, millions)
model27_gdp_millions_with_outliers <- lm(Y ~ X1 + X2, data = df_complete_gdp_millions_clean)

# Model 28: Contemporaneous without outliers (GDP total, millions)
model28_gdp_millions_no_outliers <- lm(Y ~ X1 + X2, data = df_no_outliers_gdp_millions_clean)

# Print model summaries
cat("\n=== MODEL 1: Contemporaneous with Outliers ===\n")
summary(model1_with_outliers)

cat("\n=== MODEL 2: Contemporaneous without Outliers ===\n")
summary(model2_no_outliers)

cat("\n=== MODEL 3: Lagged (1 period) with Outliers ===\n")
summary(model3_lagged_with_outliers)

cat("\n=== MODEL 4: Lagged (1 period) without Outliers ===\n")
summary(model4_lagged_no_outliers)

cat("\n=== MODEL 5: Log-Log Contemporaneous with Outliers ===\n")
summary(model5_loglog_with_outliers)

cat("\n=== MODEL 6: Log-Log Contemporaneous without Outliers ===\n")
summary(model6_loglog_no_outliers)

cat("\n=== MODEL 7: Log-Log Lagged with Outliers ===\n")
summary(model7_loglog_lagged_with_outliers)

cat("\n=== MODEL 8: Log-Log Lagged without Outliers ===\n")
summary(model8_loglog_lagged_no_outliers)

cat("\n=== MODEL 9: Log-Linear Contemporaneous with Outliers ===\n")
summary(model9_loglinear_with_outliers)

cat("\n=== MODEL 10: Log-Linear Contemporaneous without Outliers ===\n")
summary(model10_loglinear_no_outliers)

cat("\n=== MODEL 11: Linear-Log Contemporaneous with Outliers ===\n")
summary(model11_linearlog_with_outliers)

cat("\n=== MODEL 12: Linear-Log Contemporaneous without Outliers ===\n")
summary(model12_linearlog_no_outliers)

cat("\n=== MODEL 13: GDP Total Contemporaneous with Outliers ===\n")
summary(model13_gdp_with_outliers)

cat("\n=== MODEL 14: GDP Total Contemporaneous without Outliers ===\n")
summary(model14_gdp_no_outliers)

cat("\n=== MODEL 15: GDP Total Lagged (1 period) with Outliers ===\n")
summary(model15_gdp_lagged_with_outliers)

cat("\n=== MODEL 16: GDP Total Lagged (1 period) without Outliers ===\n")
summary(model16_gdp_lagged_no_outliers)

cat("\n=== MODEL 17: GDP Total Log-Log Contemporaneous with Outliers ===\n")
summary(model17_loglog_gdp_with_outliers)

cat("\n=== MODEL 18: GDP Total Log-Log Contemporaneous without Outliers ===\n")
summary(model18_loglog_gdp_no_outliers)

cat("\n=== MODEL 19: GDP Total Log-Log Lagged with Outliers ===\n")
summary(model19_loglog_gdp_lagged_with_outliers)

cat("\n=== MODEL 20: GDP Total Log-Log Lagged without Outliers ===\n")
summary(model20_loglog_gdp_lagged_no_outliers)

cat("\n=== MODEL 21: GDP Total Log-Linear Contemporaneous with Outliers ===\n")
summary(model21_loglinear_gdp_with_outliers)

cat("\n=== MODEL 22: GDP Total Log-Linear Contemporaneous without Outliers ===\n")
summary(model22_loglinear_gdp_no_outliers)

cat("\n=== MODEL 23: GDP Total Linear-Log Contemporaneous with Outliers ===\n")
summary(model23_linearlog_gdp_with_outliers)

cat("\n=== MODEL 24: GDP Total Linear-Log Contemporaneous without Outliers ===\n")
summary(model24_linearlog_gdp_no_outliers)

cat("\n=== MODEL 25: GDP Per Capita Contemporaneous with Outliers (Millions) ===\n")
summary(model25_millions_with_outliers)

cat("\n=== MODEL 26: GDP Per Capita Contemporaneous without Outliers (Millions) ===\n")
summary(model26_millions_no_outliers)

cat("\n=== MODEL 27: GDP Total Contemporaneous with Outliers (Millions) ===\n")
summary(model27_gdp_millions_with_outliers)

cat("\n=== MODEL 28: GDP Total Contemporaneous without Outliers (Millions) ===\n")
summary(model28_gdp_millions_no_outliers)

# Create comprehensive stargazer table with error handling
create_stargazer_table <- function(models, filename, type_output, title_text, dep_var_label, covar_labels, col_labels) {
  tryCatch({
    stargazer(models[[1]], models[[2]], models[[3]], models[[4]],
              title = title_text,
              dep.var.labels = dep_var_label,
              covariate.labels = covar_labels,
              column.labels = col_labels,
              type = type_output,
              out = filename,
              omit.stat = c("f", "ser"),
              digits = 4)
    cat(paste("Successfully created", type_output, "table:", filename, "\n"))
    return(TRUE)
  }, error = function(e) {
    cat(paste("Error creating", type_output, "table:", e$message, "\n"))
    return(FALSE)
  })
}

# LEVEL MODELS (Original specification)
models_level <- list(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers)

# Text version - Level models
create_stargazer_table(models_level, file.path(output_dir, "level_models_results.txt"), "text",
                       "Change in Remittances Models - Level Specification",
                       "ΔRemit (000s USD)",
                       c("ΔGDP/cap Send", "ΔGDP/cap Recv", "L.ΔGDP/cap Send", "L.ΔGDP/cap Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# HTML version - Level models
create_stargazer_table(models_level, file.path(output_dir, "level_models_results.html"), "html",
                       "Change in Remittances Models - Level Specification",
                       "ΔRemit (000s USD)",
                       c("ΔGDP/cap Send", "ΔGDP/cap Recv", "L.ΔGDP/cap Send", "L.ΔGDP/cap Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LaTeX version - Level models
create_stargazer_table(models_level, file.path(output_dir, "level_models_results.tex"), "latex",
                       "Change in Remittances Models - Level Specification",
                       "ΔRemit (000s USD)",
                       c("ΔGDP/cap Send", "ΔGDP/cap Recv", "L.ΔGDP/cap Send", "L.ΔGDP/cap Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LOG-LOG MODELS (Elasticity interpretation)
models_loglog <- list(model5_loglog_with_outliers, model6_loglog_no_outliers, model7_loglog_lagged_with_outliers, model8_loglog_lagged_no_outliers)

# Text version - Log-log models
create_stargazer_table(models_loglog, file.path(output_dir, "loglog_models_results.txt"), "text",
                       "Change in Remittances Models - Log-Log Specification",
                       "Δlog(Remit)",
                       c("Δlog(GDP/cap Send)", "Δlog(GDP/cap Recv)", "L.Δlog(GDP/cap Send)", "L.Δlog(GDP/cap Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# HTML version - Log-log models
create_stargazer_table(models_loglog, file.path(output_dir, "loglog_models_results.html"), "html",
                       "Change in Remittances Models - Log-Log Specification",
                       "Δlog(Remit)",
                       c("Δlog(GDP/cap Send)", "Δlog(GDP/cap Recv)", "L.Δlog(GDP/cap Send)", "L.Δlog(GDP/cap Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LaTeX version - Log-log models
create_stargazer_table(models_loglog, file.path(output_dir, "loglog_models_results.tex"), "latex",
                       "Change in Remittances Models - Log-Log Specification",
                       "Δlog(Remit)",
                       c("Δlog(GDP/cap Send)", "Δlog(GDP/cap Recv)", "L.Δlog(GDP/cap Send)", "L.Δlog(GDP/cap Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LOG-LINEAR MODELS (Semi-elasticity interpretation) - Only contemporaneous models
models_loglinear <- list(model9_loglinear_with_outliers, model10_loglinear_no_outliers)

# Create 2-model stargazer function for log-linear
create_stargazer_table_2 <- function(models, filename, type_output, title_text, dep_var_label, covar_labels, col_labels) {
  tryCatch({
    stargazer(models[[1]], models[[2]],
              title = title_text,
              dep.var.labels = dep_var_label,
              covariate.labels = covar_labels,
              column.labels = col_labels,
              type = type_output,
              out = filename,
              omit.stat = c("f", "ser"),
              digits = 4)
    cat(paste("Successfully created", type_output, "table:", filename, "\n"))
    return(TRUE)
  }, error = function(e) {
    cat(paste("Error creating", type_output, "table:", e$message, "\n"))
    return(FALSE)
  })
}

# Text version - Log-linear models
create_stargazer_table_2(models_loglinear, file.path(output_dir, "loglinear_models_results.txt"), "text",
                         "Change in Remittances Models - Log-Linear Specification",
                         "Δlog(Remit)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Log-linear models
create_stargazer_table_2(models_loglinear, file.path(output_dir, "loglinear_models_results.html"), "html",
                         "Change in Remittances Models - Log-Linear Specification",
                         "Δlog(Remit)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Log-linear models
create_stargazer_table_2(models_loglinear, file.path(output_dir, "loglinear_models_results.tex"), "latex",
                         "Change in Remittances Models - Log-Linear Specification",
                         "Δlog(Remit)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LINEAR-LOG MODELS (Linear dependent variable, log independent variables)
models_linearlog <- list(model11_linearlog_with_outliers, model12_linearlog_no_outliers)

# Text version - Linear-log models
create_stargazer_table_2(models_linearlog, file.path(output_dir, "linearlog_models_results.txt"), "text",
                         "Change in Remittances Models - Linear-Log Specification",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP/cap) Send", "Δlog(GDP/cap) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Linear-log models
create_stargazer_table_2(models_linearlog, file.path(output_dir, "linearlog_models_results.html"), "html",
                         "Change in Remittances Models - Linear-Log Specification",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP/cap) Send", "Δlog(GDP/cap) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Linear-log models
create_stargazer_table_2(models_linearlog, file.path(output_dir, "linearlog_models_results.tex"), "latex",
                         "Change in Remittances Models - Linear-Log Specification",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP/cap) Send", "Δlog(GDP/cap) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# GDP TOTAL MODELS - LEVEL SPECIFICATION (Models 13-16)
models_level_gdp <- list(model13_gdp_with_outliers, model14_gdp_no_outliers, model15_gdp_lagged_with_outliers, model16_gdp_lagged_no_outliers)

# Text version - Level models (GDP total)
create_stargazer_table(models_level_gdp, file.path(output_dir, "level_gdp_models_results.txt"), "text",
                       "Change in Remittances Models - Level Specification (GDP Total)",
                       "ΔRemit (000s USD)",
                       c("ΔGDP Send", "ΔGDP Recv", "L.ΔGDP Send", "L.ΔGDP Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# HTML version - Level models (GDP total)
create_stargazer_table(models_level_gdp, file.path(output_dir, "level_gdp_models_results.html"), "html",
                       "Change in Remittances Models - Level Specification (GDP Total)",
                       "ΔRemit (000s USD)",
                       c("ΔGDP Send", "ΔGDP Recv", "L.ΔGDP Send", "L.ΔGDP Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LaTeX version - Level models (GDP total)
create_stargazer_table(models_level_gdp, file.path(output_dir, "level_gdp_models_results.tex"), "latex",
                       "Change in Remittances Models - Level Specification (GDP Total)",
                       "ΔRemit (000s USD)",
                       c("ΔGDP Send", "ΔGDP Recv", "L.ΔGDP Send", "L.ΔGDP Recv"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# GDP TOTAL MODELS - LOG-LOG SPECIFICATION (Models 17-20)
models_loglog_gdp <- list(model17_loglog_gdp_with_outliers, model18_loglog_gdp_no_outliers, model19_loglog_gdp_lagged_with_outliers, model20_loglog_gdp_lagged_no_outliers)

# Text version - Log-log models (GDP total)
create_stargazer_table(models_loglog_gdp, file.path(output_dir, "loglog_gdp_models_results.txt"), "text",
                       "Change in Remittances Models - Log-Log Specification (GDP Total)",
                       "Δlog(Remit)",
                       c("Δlog(GDP Send)", "Δlog(GDP Recv)", "L.Δlog(GDP Send)", "L.Δlog(GDP Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# HTML version - Log-log models (GDP total)
create_stargazer_table(models_loglog_gdp, file.path(output_dir, "loglog_gdp_models_results.html"), "html",
                       "Change in Remittances Models - Log-Log Specification (GDP Total)",
                       "Δlog(Remit)",
                       c("Δlog(GDP Send)", "Δlog(GDP Recv)", "L.Δlog(GDP Send)", "L.Δlog(GDP Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# LaTeX version - Log-log models (GDP total)
create_stargazer_table(models_loglog_gdp, file.path(output_dir, "loglog_gdp_models_results.tex"), "latex",
                       "Change in Remittances Models - Log-Log Specification (GDP Total)",
                       "Δlog(Remit)",
                       c("Δlog(GDP Send)", "Δlog(GDP Recv)", "L.Δlog(GDP Send)", "L.Δlog(GDP Recv)"),
                       c("Cont.+Out", "Cont.-Out", "Lag+Out", "Lag-Out"))

# GDP TOTAL MODELS - LOG-LINEAR SPECIFICATION (Models 21-22)
models_loglinear_gdp <- list(model21_loglinear_gdp_with_outliers, model22_loglinear_gdp_no_outliers)

# Text version - Log-linear models (GDP total)
create_stargazer_table_2(models_loglinear_gdp, file.path(output_dir, "loglinear_gdp_models_results.txt"), "text",
                         "Change in Remittances Models - Log-Linear Specification (GDP Total)",
                         "Δlog(Remit)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Log-linear models (GDP total)
create_stargazer_table_2(models_loglinear_gdp, file.path(output_dir, "loglinear_gdp_models_results.html"), "html",
                         "Change in Remittances Models - Log-Linear Specification (GDP Total)",
                         "Δlog(Remit)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Log-linear models (GDP total)
create_stargazer_table_2(models_loglinear_gdp, file.path(output_dir, "loglinear_gdp_models_results.tex"), "latex",
                         "Change in Remittances Models - Log-Linear Specification (GDP Total)",
                         "Δlog(Remit)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# GDP TOTAL MODELS - LINEAR-LOG SPECIFICATION (Models 23-24)
models_linearlog_gdp <- list(model23_linearlog_gdp_with_outliers, model24_linearlog_gdp_no_outliers)

# Text version - Linear-log models (GDP total)
create_stargazer_table_2(models_linearlog_gdp, file.path(output_dir, "linearlog_gdp_models_results.txt"), "text",
                         "Change in Remittances Models - Linear-Log Specification (GDP Total)",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP) Send", "Δlog(GDP) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Linear-log models (GDP total)
create_stargazer_table_2(models_linearlog_gdp, file.path(output_dir, "linearlog_gdp_models_results.html"), "html",
                         "Change in Remittances Models - Linear-Log Specification (GDP Total)",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP) Send", "Δlog(GDP) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Linear-log models (GDP total)
create_stargazer_table_2(models_linearlog_gdp, file.path(output_dir, "linearlog_gdp_models_results.tex"), "latex",
                         "Change in Remittances Models - Linear-Log Specification (GDP Total)",
                         "ΔRemit (1000s)",
                         c("Δlog(GDP) Send", "Δlog(GDP) Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# REMITTANCES IN MILLIONS MODELS (Models 25-28)
models_level_millions_gdp_per_capita <- list(model25_millions_with_outliers, model26_millions_no_outliers)
models_level_millions_gdp_total <- list(model27_gdp_millions_with_outliers, model28_gdp_millions_no_outliers)

# Text version - Level models (Millions, GDP per capita)
create_stargazer_table_2(models_level_millions_gdp_per_capita, file.path(output_dir, "level_millions_gdp_per_capita_results.txt"), "text",
                         "Change in Remittances Models - Level Specification (Millions, GDP Per Capita)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Level models (Millions, GDP per capita)
create_stargazer_table_2(models_level_millions_gdp_per_capita, file.path(output_dir, "level_millions_gdp_per_capita_results.html"), "html",
                         "Change in Remittances Models - Level Specification (Millions, GDP Per Capita)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Level models (Millions, GDP per capita)
create_stargazer_table_2(models_level_millions_gdp_per_capita, file.path(output_dir, "level_millions_gdp_per_capita_results.tex"), "latex",
                         "Change in Remittances Models - Level Specification (Millions, GDP Per Capita)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP/cap Send", "ΔGDP/cap Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# Text version - Level models (Millions, GDP total)
create_stargazer_table_2(models_level_millions_gdp_total, file.path(output_dir, "level_millions_gdp_total_results.txt"), "text",
                         "Change in Remittances Models - Level Specification (Millions, GDP Total)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# HTML version - Level models (Millions, GDP total)
create_stargazer_table_2(models_level_millions_gdp_total, file.path(output_dir, "level_millions_gdp_total_results.html"), "html",
                         "Change in Remittances Models - Level Specification (Millions, GDP Total)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# LaTeX version - Level models (Millions, GDP total)
create_stargazer_table_2(models_level_millions_gdp_total, file.path(output_dir, "level_millions_gdp_total_results.tex"), "latex",
                         "Change in Remittances Models - Level Specification (Millions, GDP Total)",
                         "ΔRemit (Millions USD)",
                         c("ΔGDP Send", "ΔGDP Recv"),
                         c("Cont.+Out", "Cont.-Out"))

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Contemporaneous Models (with outliers):\n")
cat("Observations:", nrow(df_complete), "\n")
cat("Mean change in remittances:", round(mean(df_complete$Change_Remittances_Thousands, na.rm = TRUE), 2), "thousands USD\n")
cat("SD change in remittances:", round(sd(df_complete$Change_Remittances_Thousands, na.rm = TRUE), 2), "thousands USD\n")

cat("\nContemporaneous Models (without outliers):\n")
cat("Observations:", nrow(df_no_outliers), "\n")
cat("Mean change in remittances:", round(mean(df_no_outliers$Change_Remittances_Thousands, na.rm = TRUE), 2), "thousands USD\n")
cat("SD change in remittances:", round(sd(df_no_outliers$Change_Remittances_Thousands, na.rm = TRUE), 2), "thousands USD\n")

cat("\nLagged Models (with outliers):\n")
cat("Observations:", nrow(df_complete_lagged), "\n")

cat("\nLagged Models (without outliers):\n")
cat("Observations:", nrow(df_no_outliers_lagged), "\n")

# Save detailed results to file
sink(file.path(output_dir, "detailed_results.txt"))
cat("=== CHANGE IN REMITTANCES ANALYSIS ===\n")
cat("Date:", Sys.Date(), "\n\n")

cat("=== DATA SUMMARY ===\n")
cat("Total observations in dataset:", nrow(df), "\n")
cat("Complete cases for contemporaneous analysis:", nrow(df_complete), "\n")
cat("Complete cases without outliers:", nrow(df_no_outliers), "\n")
cat("Complete cases for lagged analysis:", nrow(df_complete_lagged), "\n")
cat("Complete cases for lagged analysis without outliers:", nrow(df_no_outliers_lagged), "\n\n")

cat("=== MODEL 1: Contemporaneous with Outliers ===\n")
print(summary(model1_with_outliers))
cat("\n")

cat("=== MODEL 2: Contemporaneous without Outliers ===\n")
print(summary(model2_no_outliers))
cat("\n")

cat("=== MODEL 3: Lagged (1 period) with Outliers ===\n")
print(summary(model3_lagged_with_outliers))
cat("\n")

cat("=== MODEL 4: Lagged (1 period) without Outliers ===\n")
print(summary(model4_lagged_no_outliers))
cat("\n")

cat("=== MODEL 5: Log-Log Contemporaneous with Outliers ===\n")
print(summary(model5_loglog_with_outliers))
cat("\n")

cat("=== MODEL 6: Log-Log Contemporaneous without Outliers ===\n")
print(summary(model6_loglog_no_outliers))
cat("\n")

cat("=== MODEL 7: Log-Log Lagged with Outliers ===\n")
print(summary(model7_loglog_lagged_with_outliers))
cat("\n")

cat("=== MODEL 8: Log-Log Lagged without Outliers ===\n")
print(summary(model8_loglog_lagged_no_outliers))
cat("\n")

cat("=== MODEL 9: Log-Linear Contemporaneous with Outliers ===\n")
print(summary(model9_loglinear_with_outliers))
cat("\n")

cat("=== MODEL 10: Log-Linear Contemporaneous without Outliers ===\n")
print(summary(model10_loglinear_no_outliers))
cat("\n")

cat("=== MODEL 11: Linear-Log Contemporaneous with Outliers ===\n")
print(summary(model11_linearlog_with_outliers))
cat("\n")

cat("=== MODEL 12: Linear-Log Contemporaneous without Outliers ===\n")
print(summary(model12_linearlog_no_outliers))
cat("\n")

cat("=== MODEL 13: GDP Total Contemporaneous with Outliers ===\n")
print(summary(model13_gdp_with_outliers))
cat("\n")

cat("=== MODEL 14: GDP Total Contemporaneous without Outliers ===\n")
print(summary(model14_gdp_no_outliers))
cat("\n")

cat("=== MODEL 15: GDP Total Lagged (1 period) with Outliers ===\n")
print(summary(model15_gdp_lagged_with_outliers))
cat("\n")

cat("=== MODEL 16: GDP Total Lagged (1 period) without Outliers ===\n")
print(summary(model16_gdp_lagged_no_outliers))
cat("\n")

cat("=== MODEL 17: GDP Total Log-Log Contemporaneous with Outliers ===\n")
print(summary(model17_loglog_gdp_with_outliers))
cat("\n")

cat("=== MODEL 18: GDP Total Log-Log Contemporaneous without Outliers ===\n")
print(summary(model18_loglog_gdp_no_outliers))
cat("\n")

cat("=== MODEL 19: GDP Total Log-Log Lagged with Outliers ===\n")
print(summary(model19_loglog_gdp_lagged_with_outliers))
cat("\n")

cat("=== MODEL 20: GDP Total Log-Log Lagged without Outliers ===\n")
print(summary(model20_loglog_gdp_lagged_no_outliers))
cat("\n")

cat("=== MODEL 21: GDP Total Log-Linear Contemporaneous with Outliers ===\n")
print(summary(model21_loglinear_gdp_with_outliers))
cat("\n")

cat("=== MODEL 22: GDP Total Log-Linear Contemporaneous without Outliers ===\n")
print(summary(model22_loglinear_gdp_no_outliers))
cat("\n")

cat("=== MODEL 23: GDP Total Linear-Log Contemporaneous with Outliers ===\n")
print(summary(model23_linearlog_gdp_with_outliers))
cat("\n")

cat("=== MODEL 24: GDP Total Linear-Log Contemporaneous without Outliers ===\n")
print(summary(model24_linearlog_gdp_no_outliers))
cat("\n")

cat("=== MODEL 25: GDP Per Capita Contemporaneous with Outliers (Millions) ===\n")
print(summary(model25_millions_with_outliers))
cat("\n")

cat("=== MODEL 26: GDP Per Capita Contemporaneous without Outliers (Millions) ===\n")
print(summary(model26_millions_no_outliers))
cat("\n")

cat("=== MODEL 27: GDP Total Contemporaneous with Outliers (Millions) ===\n")
print(summary(model27_gdp_millions_with_outliers))
cat("\n")

cat("=== MODEL 28: GDP Total Contemporaneous without Outliers (Millions) ===\n")
print(summary(model28_gdp_millions_no_outliers))
cat("\n")

sink()

cat("\nAnalysis complete! Results saved to:", output_dir, "\n")
cat("Files created:\n")
cat("GDP PER CAPITA MODELS:\n")
cat("LEVEL MODELS (Original Specification):\n")
cat("- level_models_results.txt/html/tex\n")
cat("LOG-LOG MODELS (Elasticity Interpretation):\n")
cat("- loglog_models_results.txt/html/tex\n")
cat("LOG-LINEAR MODELS (Semi-elasticity Interpretation):\n")
cat("- loglinear_models_results.txt/html/tex\n")
cat("LINEAR-LOG MODELS (Log-linear with level dependent variable):\n")
cat("- linearlog_models_results.txt/html/tex\n")

cat("GDP TOTAL MODELS:\n")
cat("LEVEL MODELS (GDP Total Specification):\n")
cat("- level_gdp_models_results.txt/html/tex\n")
cat("LOG-LOG MODELS (GDP Total Elasticity Interpretation):\n")
cat("- loglog_gdp_models_results.txt/html/tex\n")
cat("LOG-LINEAR MODELS (GDP Total Semi-elasticity Interpretation):\n")
cat("- loglinear_gdp_models_results.txt/html/tex\n")
cat("LINEAR-LOG MODELS (GDP Total Log-linear with level dependent variable):\n")
cat("- linearlog_gdp_models_results.txt/html/tex\n")

cat("REMITTANCES IN MILLIONS MODELS (Models 25-28):\n")
cat("LEVEL MODELS (Millions, GDP Per Capita):\n")
cat("- level_millions_gdp_per_capita_results.txt/html/tex\n")
cat("LEVEL MODELS (Millions, GDP Total):\n")
cat("- level_millions_gdp_total_results.txt/html/tex\n")

cat("DETAILED RESULTS:\n")
cat("- detailed_results.txt (complete model summaries for all 28 models)\n")
cat("\nModel Interpretations:\n")
cat("GDP PER CAPITA MODELS (Models 1-12):\n")
cat("- Level models: Coefficients show change in remittances (000s USD) per unit change in GDP/capita\n")
cat("- Log-log models: Coefficients show elasticities (% change in remittances per % change in GDP/capita)\n")
cat("- Log-linear models: Coefficients show semi-elasticities (% change in remittances per unit change in GDP/capita)\n")
cat("- Linear-log models: Coefficients show change in remittances (000s USD) per % change in GDP/capita\n")
cat("GDP TOTAL MODELS (Models 13-24):\n")
cat("- Level models: Coefficients show change in remittances (000s USD) per unit change in total GDP\n")
cat("- Log-log models: Coefficients show elasticities (% change in remittances per % change in total GDP)\n")
cat("- Log-linear models: Coefficients show semi-elasticities (% change in remittances per unit change in total GDP)\n")
cat("- Linear-log models: Coefficients show change in remittances (000s USD) per % change in total GDP\n")
cat("REMITTANCES IN MILLIONS MODELS (Models 25-28):\n")
cat("- Level models (GDP per capita): Coefficients show change in remittances (Millions USD) per unit change in GDP/capita\n")
cat("- Level models (GDP total): Coefficients show change in remittances (Millions USD) per unit change in total GDP\n")
cat("\nOUTLIER REMOVAL METHOD:\n")
cat("- Outliers are removed based on RAW remittance levels (not changes in remittances)\n")
cat("- Uses 5th and 95th percentiles as cutoffs\n")
cat("- This preserves all observations with large remittance changes while removing extreme remittance levels\n")