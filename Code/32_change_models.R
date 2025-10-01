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

# Create a unique corridor identifier
df$Corridor <- paste(df$Sending_Country, df$Receiving_Country, sep = " -> ")

# Sort data by corridor and year
df <- df %>% 
  arrange(Corridor, Year)

# Calculate changes (first differences)
df <- df %>%
  group_by(Corridor) %>%
  arrange(Year) %>%
  mutate(
    # Change in remittances (dependent variable)
    Change_Remittances_Thousands = Remittances_Thousands - lag(Remittances_Thousands),
    
    # Change in sending country GDP per capita (independent variable)
    Change_Sending_GDP_Per_Capita = Sending_Country_GDP_Per_Capita - lag(Sending_Country_GDP_Per_Capita),
    
    # Change in receiving country GDP per capita (independent variable)
    Change_Receiving_GDP_Per_Capita = Receiving_Country_GDP_Per_Capita - lag(Receiving_Country_GDP_Per_Capita),
    
    # Lagged change variables (for lagged models)
    Lag_Change_Sending_GDP_Per_Capita = lag(Change_Sending_GDP_Per_Capita),
    Lag_Change_Receiving_GDP_Per_Capita = lag(Change_Receiving_GDP_Per_Capita)
  ) %>%
  ungroup()

# Remove rows with missing values for the main analysis
df_complete <- df %>%
  filter(!is.na(Change_Remittances_Thousands) & 
         !is.na(Change_Sending_GDP_Per_Capita) & 
         !is.na(Change_Receiving_GDP_Per_Capita))

cat("Complete cases for main analysis:", nrow(df_complete), "\n")

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
outlier_vars <- c("Change_Remittances_Thousands", "Change_Sending_GDP_Per_Capita", "Change_Receiving_GDP_Per_Capita")
df_no_outliers <- remove_outliers(df_complete, outlier_vars)

cat("Data without outliers:", nrow(df_no_outliers), "observations\n")
cat("Outliers removed:", nrow(df_complete) - nrow(df_no_outliers), "observations\n")

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

cat("Complete cases for lagged analysis:", nrow(df_complete_lagged), "\n")
cat("Complete cases for lagged analysis (no outliers):", nrow(df_no_outliers_lagged), "\n")

# Model 1: Contemporaneous (unlagged) with outliers
model1_with_outliers <- lm(Change_Remittances_Thousands ~ Change_Sending_GDP_Per_Capita + Change_Receiving_GDP_Per_Capita, 
                          data = df_complete)

# Model 2: Contemporaneous (unlagged) without outliers
model2_no_outliers <- lm(Change_Remittances_Thousands ~ Change_Sending_GDP_Per_Capita + Change_Receiving_GDP_Per_Capita, 
                        data = df_no_outliers)

# Model 3: Lagged (1 period) with outliers
model3_lagged_with_outliers <- lm(Change_Remittances_Thousands ~ Lag_Change_Sending_GDP_Per_Capita + Lag_Change_Receiving_GDP_Per_Capita, 
                                 data = df_complete_lagged)

# Model 4: Lagged (1 period) without outliers
model4_lagged_no_outliers <- lm(Change_Remittances_Thousands ~ Lag_Change_Sending_GDP_Per_Capita + Lag_Change_Receiving_GDP_Per_Capita, 
                               data = df_no_outliers_lagged)

# Print model summaries
cat("\n=== MODEL 1: Contemporaneous with Outliers ===\n")
summary(model1_with_outliers)

cat("\n=== MODEL 2: Contemporaneous without Outliers ===\n")
summary(model2_no_outliers)

cat("\n=== MODEL 3: Lagged (1 period) with Outliers ===\n")
summary(model3_lagged_with_outliers)

cat("\n=== MODEL 4: Lagged (1 period) without Outliers ===\n")
summary(model4_lagged_no_outliers)

# Create comprehensive stargazer table
stargazer(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers,
          title = "Change in Remittances Models",
          dep.var.labels = "Change in Remittances (Thousands USD)",
          covariate.labels = c("Change in Sending GDP per Capita", 
                              "Change in Receiving GDP per Capita",
                              "Lagged Change in Sending GDP per Capita",
                              "Lagged Change in Receiving GDP per Capita"),
          column.labels = c("Contemp. w/ Outliers", "Contemp. w/o Outliers", 
                           "Lagged w/ Outliers", "Lagged w/o Outliers"),
          type = "text",
          out = file.path(output_dir, "change_models_results.txt"))

# Save HTML version
stargazer(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers,
          title = "Change in Remittances Models",
          dep.var.labels = "Change in Remittances (Thousands USD)",
          covariate.labels = c("Change in Sending GDP per Capita", 
                              "Change in Receiving GDP per Capita",
                              "Lagged Change in Sending GDP per Capita",
                              "Lagged Change in Receiving GDP per Capita"),
          column.labels = c("Contemp. w/ Outliers", "Contemp. w/o Outliers", 
                           "Lagged w/ Outliers", "Lagged w/o Outliers"),
          type = "html",
          out = file.path(output_dir, "change_models_results.html"))

# Save LaTeX version
stargazer(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers,
          title = "Change in Remittances Models",
          dep.var.labels = "Change in Remittances (Thousands USD)",
          covariate.labels = c("Change in Sending GDP per Capita", 
                              "Change in Receiving GDP per Capita",
                              "Lagged Change in Sending GDP per Capita",
                              "Lagged Change in Receiving GDP per Capita"),
          column.labels = c("Contemp. w/ Outliers", "Contemp. w/o Outliers", 
                           "Lagged w/ Outliers", "Lagged w/o Outliers"),
          type = "latex",
          out = file.path(output_dir, "change_models_results.tex"))

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

sink()

cat("\nAnalysis complete! Results saved to:", output_dir, "\n")
cat("Files created:\n")
cat("- change_models_results.txt (stargazer text output)\n")
cat("- change_models_results.html (stargazer HTML output)\n")
cat("- change_models_results.tex (stargazer LaTeX output)\n")
cat("- detailed_results.txt (complete model summaries)\n")