# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Load required libraries
library(stargazer)

# Create output directory
output_dir <- "C:/Users/clint/Desktop/RER/Code/27"

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
spec1_with <- lm(remittance_thousands ~ gdp_sending_millions + gdp_receiving_millions, data = df)
spec1_without <- lm(remittance_thousands ~ gdp_sending_millions + gdp_receiving_millions, data = df_no_outliers)

# SPECIFICATION 2: Log-Log Model
cat("Running Specification 2: Log-Log model...\n")
spec2_with <- lm(log_remittance ~ log_gdp_sending + log_gdp_receiving, data = df)
spec2_without <- lm(log_remittance ~ log_gdp_sending + log_gdp_receiving, data = df_no_outliers)

# SPECIFICATION 4: Linear Dependent, Log Independent (remittances in millions)
cat("Running Specification 4: Linear dependent, log independent...\n")
spec4_with <- lm(remittance_millions ~ log_gdp_sending + log_gdp_receiving, data = df)
spec4_without <- lm(remittance_millions ~ log_gdp_sending + log_gdp_receiving, data = df_no_outliers)

# Create comprehensive table by combining models sequentially
cat("Generating comprehensive stargazer table...\n")

# Create comprehensive HTML table
html_file <- file.path(output_dir, "all_specifications_combined.html")
cat("Creating comprehensive HTML table...\n")

stargazer(
  spec1_with, spec1_without,
  spec2_with, spec2_without,
  spec4_with, spec4_without,
  type = "html",
  out = html_file,
  title = "Comprehensive Regression Analysis: All Three Specifications",
  dep.var.labels = c("Remittance (thousands)", "Remittance (thousands)", 
                     "Log(Remittance)", "Log(Remittance)",
                     "Remittance (millions)", "Remittance (millions)"),
  column.labels = c("With Outliers", "Without Outliers", 
                   "With Outliers", "Without Outliers",
                   "With Outliers", "Without Outliers"),
  covariate.labels = c("Sending GDP (millions)", "Receiving GDP (millions)",
                      "Log(Sending GDP)", "Log(Receiving GDP)"),
  keep.stat = c("n", "rsq", "adj.rsq", "ser", "f"),
  digits = 3,
  star.cutoffs = c(0.1, 0.05, 0.01),
  notes = c("Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log",
           "*p<0.1; **p<0.05; ***p<0.01"),
  notes.align = "l"
)

# Create comprehensive LaTeX table
latex_file <- file.path(output_dir, "all_specifications_combined.tex")
cat("Creating comprehensive LaTeX table...\n")

stargazer(
  spec1_with, spec1_without,
  spec2_with, spec2_without,
  spec4_with, spec4_without,
  type = "latex",
  out = latex_file,
  title = "Comprehensive Regression Analysis: All Three Specifications",
  dep.var.labels = c("Remittance (thousands)", "Remittance (thousands)", 
                     "Log(Remittance)", "Log(Remittance)",
                     "Remittance (millions)", "Remittance (millions)"),
  column.labels = c("With Outliers", "Without Outliers", 
                   "With Outliers", "Without Outliers",
                   "With Outliers", "Without Outliers"),
  covariate.labels = c("Sending GDP (millions)", "Receiving GDP (millions)",
                      "Log(Sending GDP)", "Log(Receiving GDP)"),
  keep.stat = c("n", "rsq", "adj.rsq", "ser", "f"),
  digits = 3,
  star.cutoffs = c(0.1, 0.05, 0.01),
  notes = c("Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log",
           "*p<0.1; **p<0.05; ***p<0.01"),
  notes.align = "l"
)

cat("Comprehensive tables created successfully!\n")
cat("Files created:\n")
cat("- Comprehensive HTML:", html_file, "\n")
cat("- Comprehensive LaTeX:", latex_file, "\n")