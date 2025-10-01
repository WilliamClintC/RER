

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)
}

# Install required packages
required_packages <- c("car", "stargazer")
install_if_missing(required_packages)

# Load required libraries
library(car)
library(stargazer)

# Create output directory
output_dir <- "C:/Users/clint/Desktop/RER/Code/27"
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

cat("Dataset loaded successfully with", nrow(df), "observations\n")

# Create variables for different specifications
df$remittance_millions <- df$Value  # Already in millions
df$remittance_thousands <- df$Value * 1000  # Convert to thousands
df$gdp_sending_millions <- df$Sending_Country_GDP  # Already in millions  
df$gdp_receiving_millions <- df$Receiving_Country_GDP  # Already in millions

# Log transformations
df$log_remittance <- log(df$remittance_millions)
df$log_gdp_sending <- log(df$gdp_sending_millions)
df$log_gdp_receiving <- log(df$gdp_receiving_millions)

# Identify outliers using IQR method for log remittances
Q1 <- quantile(df$log_remittance, 0.25, na.rm = TRUE)
Q3 <- quantile(df$log_remittance, 0.75, na.rm = TRUE)
IQR <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR

# Create dataset without outliers
df_no_outliers <- df[df$log_remittance >= lower_bound & df$log_remittance <= upper_bound, ]

cat("After removing outliers:", nrow(df_no_outliers), "observations remain\n")

# SPECIFICATION 1: Remittances (thousands) vs GDP (millions)
cat("Running Specification 1: Linear model with remittances in thousands...\n")
spec1_with_outliers <- lm(remittance_thousands ~ gdp_sending_millions + gdp_receiving_millions, data = df)
spec1_without_outliers <- lm(remittance_thousands ~ gdp_sending_millions + gdp_receiving_millions, data = df_no_outliers)

# SPECIFICATION 2: Log-Log Model
cat("Running Specification 2: Log-Log model...\n")
spec2_with_outliers <- lm(log_remittance ~ log_gdp_sending + log_gdp_receiving, data = df)
spec2_without_outliers <- lm(log_remittance ~ log_gdp_sending + log_gdp_receiving, data = df_no_outliers)

# SPECIFICATION 4: Linear Dependent, Log Independent (remittances in millions)
cat("Running Specification 4: Linear dependent, log independent...\n")
spec4_with_outliers <- lm(remittance_millions ~ log_gdp_sending + log_gdp_receiving, data = df)
spec4_without_outliers <- lm(remittance_millions ~ log_gdp_sending + log_gdp_receiving, data = df_no_outliers)

# Create comprehensive stargazer table
cat("Generating stargazer tables...\n")

# Try to generate tables with error handling
tryCatch({
  # Create HTML table
  html_file <- file.path(output_dir, "comprehensive_regression_results.html")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers, 
    spec4_with_outliers, spec4_without_outliers,
    type = "html",
    out = html_file,
    title = "Comprehensive Regression Analysis: Remittances and GDP",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)",
                        "Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Remittances (thousands) vs GDP (millions)",
             "Specification 2: Log-Log Model", 
             "Specification 4: Linear Dependent, Log Independent",
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
  latex_file <- file.path(output_dir, "comprehensive_regression_results.tex")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers, 
    spec4_with_outliers, spec4_without_outliers,
    type = "latex",
    out = latex_file,
    title = "Comprehensive Regression Analysis: Remittances and GDP",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)",
                        "Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Remittances (thousands) vs GDP (millions)",
             "Specification 2: Log-Log Model", 
             "Specification 4: Linear Dependent, Log Independent",
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
    out = file.path(output_dir, "spec1_remittances_thousands.html"),
    title = "Specification 1: Remittances (thousands) vs GDP (millions)",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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
    out = file.path(output_dir, "spec2_log_log.html"),
    title = "Specification 2: Log-Log Model",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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
    out = file.path(output_dir, "spec4_linear_dep_log_indep.html"),
    title = "Specification 4: Linear Dependent, Log Independent",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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
    out = file.path(output_dir, "spec1_remittances_thousands.tex"),
    title = "Specification 1: Remittances (thousands) vs GDP (millions)",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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
    out = file.path(output_dir, "spec2_log_log.tex"),
    title = "Specification 2: Log-Log Model",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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
    out = file.path(output_dir, "spec4_linear_dep_log_indep.tex"),
    title = "Specification 4: Linear Dependent, Log Independent",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
    notes = "Note: *p<0.1; **p<0.05; ***p<0.01",
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

# Print summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Total observations with outliers:", nrow(df), "\n")
cat("Total observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df) - nrow(df_no_outliers), "\n")


