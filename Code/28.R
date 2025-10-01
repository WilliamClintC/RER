# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)
}

# Install required packages
required_packages <- c("car", "stargazer", "dplyr")
install_if_missing(required_packages)

# Load required libraries
library(car)
library(stargazer)
library(dplyr)

# Create output directory
output_dir <- "C:/Users/clint/Desktop/RER/Code/28"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created output directory:", output_dir, "\n")
}

# Load the dataset using base R
file_path <- "C:/Users/clint/Desktop/RER/Code/22.csv"
cat("Loading dataset...\n")
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Data preprocessing
cat("Preprocessing data...\n")

# Clean the Value column - remove commas and convert to numeric
df$Value <- as.numeric(gsub(",", "", df$Value))

# Remove rows with missing values for key variables
df <- df[!is.na(df$Value) & !is.na(df$Sending_Country_GDP) & !is.na(df$Receiving_Country_GDP), ]

# Remove rows where Value is 0 or negative (for log transformations)
df <- df[df$Value > 0 & df$Sending_Country_GDP > 0 & df$Receiving_Country_GDP > 0, ]

# Sort data by country pairs and year for proper lagging
df <- df[order(df$Sending_Country, df$Receiving_Country, df$Year), ]

cat("Dataset loaded successfully with", nrow(df), "observations\n")

# Create lagged GDP variables
cat("Creating lagged GDP variables...\n")
df <- df %>%
  group_by(Sending_Country, Receiving_Country) %>%
  arrange(Year) %>%
  mutate(
    Sending_Country_GDP_lag1 = lag(Sending_Country_GDP, 1),
    Receiving_Country_GDP_lag1 = lag(Receiving_Country_GDP, 1)
  ) %>%
  ungroup()

# Remove rows with missing lagged values
df <- df[!is.na(df$Sending_Country_GDP_lag1) & !is.na(df$Receiving_Country_GDP_lag1), ]
df <- df[df$Sending_Country_GDP_lag1 > 0 & df$Receiving_Country_GDP_lag1 > 0, ]

cat("After creating lagged variables:", nrow(df), "observations remain\n")

# Create variables for different specifications using lagged GDP
df$remittance_millions <- df$Value  # Already in millions
df$remittance_thousands <- df$Value * 1000  # Convert to thousands
df$gdp_sending_millions_lag1 <- df$Sending_Country_GDP_lag1  # Lagged sending GDP
df$gdp_receiving_millions_lag1 <- df$Receiving_Country_GDP_lag1  # Lagged receiving GDP

# Log transformations
df$log_remittance <- log(df$remittance_millions)
df$log_gdp_sending_lag1 <- log(df$gdp_sending_millions_lag1)
df$log_gdp_receiving_lag1 <- log(df$gdp_receiving_millions_lag1)

# Identify outliers using IQR method for log remittances
Q1 <- quantile(df$log_remittance, 0.25, na.rm = TRUE)
Q3 <- quantile(df$log_remittance, 0.75, na.rm = TRUE)
IQR <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR

# Create dataset without outliers
df_no_outliers <- df[df$log_remittance >= lower_bound & df$log_remittance <= upper_bound, ]

cat("After removing outliers:", nrow(df_no_outliers), "observations remain\n")

# SPECIFICATION 1: Remittances (thousands) vs Lagged GDP (millions)
cat("Running Specification 1: Linear model with remittances in thousands and lagged GDP...\n")
spec1_with_outliers <- lm(remittance_thousands ~ gdp_sending_millions_lag1 + gdp_receiving_millions_lag1, data = df)
spec1_without_outliers <- lm(remittance_thousands ~ gdp_sending_millions_lag1 + gdp_receiving_millions_lag1, data = df_no_outliers)

# SPECIFICATION 2: Log-Log Model with Lagged GDP
cat("Running Specification 2: Log-Log model with lagged GDP...\n")
spec2_with_outliers <- lm(log_remittance ~ log_gdp_sending_lag1 + log_gdp_receiving_lag1, data = df)
spec2_without_outliers <- lm(log_remittance ~ log_gdp_sending_lag1 + log_gdp_receiving_lag1, data = df_no_outliers)

# SPECIFICATION 4: Linear Dependent, Log Independent (remittances in millions) with Lagged GDP
cat("Running Specification 4: Linear dependent, log independent with lagged GDP...\n")
spec4_with_outliers <- lm(remittance_millions ~ log_gdp_sending_lag1 + log_gdp_receiving_lag1, data = df)
spec4_without_outliers <- lm(remittance_millions ~ log_gdp_sending_lag1 + log_gdp_receiving_lag1, data = df_no_outliers)

# Create comprehensive stargazer table
cat("Generating stargazer tables...\n")

# Try to generate tables with error handling
tryCatch({
  # Create HTML table
  html_file <- file.path(output_dir, "comprehensive_regression_results_lagged.html")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers, 
    spec4_with_outliers, spec4_without_outliers,
    type = "html",
    out = html_file,
    title = "Comprehensive Regression Analysis: Remittances and Lagged GDP (t-1)",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP (t-1, millions USD)", "Receiving Country GDP (t-1, millions USD)",
                        "Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Remittances (thousands) vs Lagged GDP (millions)",
             "Specification 2: Log-Log Model with Lagged GDP", 
             "Specification 4: Linear Dependent, Log Independent with Lagged GDP",
             "GDP variables are lagged by 1 period (t-1)",
             "Note: *p<0.1; **p<0.05; ***p<0.01"),
    notes.align = "l",
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("HTML table created successfully!\n")
}, error = function(e) {
  cat("Error creating comprehensive HTML table:", e$message, "\n")
})

tryCatch({
  # Create LaTeX table
  latex_file <- file.path(output_dir, "comprehensive_regression_results_lagged.tex")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers, 
    spec4_with_outliers, spec4_without_outliers,
    type = "latex",
    out = latex_file,
    title = "Comprehensive Regression Analysis: Remittances and Lagged GDP (t-1)",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP (t-1, millions USD)", "Receiving Country GDP (t-1, millions USD)",
                        "Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Remittances (thousands) vs Lagged GDP (millions)",
             "Specification 2: Log-Log Model with Lagged GDP", 
             "Specification 4: Linear Dependent, Log Independent with Lagged GDP",
             "GDP variables are lagged by 1 period (t-1)",
             "Note: *p<0.1; **p<0.05; ***p<0.01"),
    notes.align = "l",
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("LaTeX table created successfully!\n")
}, error = function(e) {
  cat("Error creating comprehensive LaTeX table:", e$message, "\n")
})

# Also create individual specification tables for comparison
cat("Creating individual specification tables...\n")

# Specification 1 only
tryCatch({
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec1_remittances_thousands_lagged.html"),
    title = "Specification 1: Remittances (thousands) vs Lagged GDP (millions)",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP (t-1, millions USD)", "Receiving Country GDP (t-1, millions USD)"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 1 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 1 table:", e$message, "\n")
})

# Specification 2 only
tryCatch({
  stargazer(
    spec2_with_outliers, spec2_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec2_log_log_lagged.html"),
    title = "Specification 2: Log-Log Model with Lagged GDP",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 2 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 2 table:", e$message, "\n")
})

# Specification 4 only
tryCatch({
  stargazer(
    spec4_with_outliers, spec4_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec4_linear_dep_log_indep_lagged.html"),
    title = "Specification 4: Linear Dependent, Log Independent with Lagged GDP",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 4 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 4 table:", e$message, "\n")
})

# Create LaTeX versions of individual specifications
tryCatch({
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec1_remittances_thousands_lagged.tex"),
    title = "Specification 1: Remittances (thousands) vs Lagged GDP (millions)",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP (t-1, millions USD)", "Receiving Country GDP (t-1, millions USD)"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 1 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 1 LaTeX table:", e$message, "\n")
})

tryCatch({
  stargazer(
    spec2_with_outliers, spec2_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec2_log_log_lagged.tex"),
    title = "Specification 2: Log-Log Model with Lagged GDP",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 2 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 2 LaTeX table:", e$message, "\n")
})

tryCatch({
  stargazer(
    spec4_with_outliers, spec4_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec4_linear_dep_log_indep_lagged.tex"),
    title = "Specification 4: Linear Dependent, Log Independent with Lagged GDP",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP (t-1))", "Log(Receiving Country GDP (t-1))"),
    notes = c("GDP variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 4 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 4 LaTeX table:", e$message, "\n")
})

cat("All tables generated successfully!\n")
cat("Files created:\n")
cat("- Comprehensive HTML table:", html_file, "\n")
cat("- Comprehensive LaTeX table:", latex_file, "\n")
cat("- Individual specification HTML tables in:", output_dir, "\n")

# Print regression summaries to text files for easier extraction
cat("Creating regression summary files...\n")

# Save detailed regression summaries
summary_file <- file.path(output_dir, "regression_summaries_lagged.txt")
sink(summary_file)
cat("COMPREHENSIVE REGRESSION ANALYSIS WITH LAGGED GDP (t-1)\n")
cat("=======================================================\n\n")

cat("SPECIFICATION 1: Remittances (thousands) vs Lagged GDP (millions)\n")
cat("------------------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec1_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec1_without_outliers))

cat("\n\nSPECIFICATION 2: Log-Log Model with Lagged GDP\n")
cat("----------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec2_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec2_without_outliers))

cat("\n\nSPECIFICATION 4: Linear Dependent, Log Independent with Lagged GDP\n")
cat("------------------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec4_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec4_without_outliers))

cat("\n\nDATA SUMMARY:\n")
cat("=============\n")
cat("Original observations:", nrow(df), "\n")
cat("Observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df) - nrow(df_no_outliers), "\n")
cat("Note: GDP variables are lagged by 1 period (t-1)\n")
sink()

# Create coefficient extraction file for easy table creation
coeff_file <- file.path(output_dir, "coefficient_extraction_lagged.txt")
sink(coeff_file)
cat("COEFFICIENT EXTRACTION FOR TABLE CREATION\n")
cat("==========================================\n\n")

# Function to extract key statistics
extract_stats <- function(model, name) {
  cat(name, ":\n")
  coeff <- summary(model)$coefficients
  cat("Coefficients:\n")
  print(coeff)
  cat("R-squared:", summary(model)$r.squared, "\n")
  cat("Adj R-squared:", summary(model)$adj.r.squared, "\n")
  cat("F-statistic:", summary(model)$fstatistic[1], "\n")
  cat("F p-value:", pf(summary(model)$fstatistic[1], summary(model)$fstatistic[2], summary(model)$fstatistic[3], lower.tail = FALSE), "\n")
  cat("Observations:", nobs(model), "\n")
  cat("Residual SE:", summary(model)$sigma, "\n")
  cat("\n")
}

extract_stats(spec1_with_outliers, "Spec 1 - With Outliers")
extract_stats(spec1_without_outliers, "Spec 1 - Without Outliers")
extract_stats(spec2_with_outliers, "Spec 2 - With Outliers")
extract_stats(spec2_without_outliers, "Spec 2 - Without Outliers")
extract_stats(spec4_with_outliers, "Spec 4 - With Outliers")
extract_stats(spec4_without_outliers, "Spec 4 - Without Outliers")
sink()

cat("Regression summary files created:\n")
cat("- Detailed summaries:", summary_file, "\n")
cat("- Coefficient extraction:", coeff_file, "\n")

# Print summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Total observations with outliers:", nrow(df), "\n")
cat("Total observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df) - nrow(df_no_outliers), "\n")
cat("Note: GDP variables are lagged by 1 period (t-1)\n")

# Instructions for creating final tables
cat("\n=== NEXT STEPS ===\n")
cat("1. Run create_final_tables_lagged.py to create template files\n")
cat("2. Use coefficient_extraction_lagged.txt to update the template placeholders\n")
cat("3. The final formatted tables will be saved as final_comprehensive_table_lagged.html/.tex\n")