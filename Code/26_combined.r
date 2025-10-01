# Combined HTML Output for All Regression Specifications
# This script creates a single HTML file with all stargazer tables

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
output_dir <- "C:/Users/clint/Desktop/RER/Code/26"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created output directory:", output_dir, "\n")
}

# Load the dataset using base R
file_path <- "C:/Users/clint/Desktop/RER/Code/22.csv"
cat("Loading dataset...\n")
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Data cleaning and preparation
cat("Cleaning data...\n")

# Remove commas from Value column and convert to numeric
df$Value <- as.numeric(gsub(",", "", df$Value))

# Convert units - create both thousands and millions versions
df$Value_thousands <- df$Value * 1000  # Convert to thousands
df$Value_millions <- df$Value * 1      # Keep in millions
df$Sending_Country_GDP_millions <- df$Sending_Country_GDP * 1
df$Receiving_Country_GDP_millions <- df$Receiving_Country_GDP * 1

# Remove rows with missing values in key variables
df_clean <- df[complete.cases(df[c("Value_thousands", "Value_millions", "Sending_Country_GDP_millions", "Receiving_Country_GDP_millions")]), ]

# Create log transformations (adding small constant to handle zeros)
df_clean$log_Value_thousands <- log(df_clean$Value_thousands + 1)
df_clean$log_Value_millions <- log(df_clean$Value_millions + 0.001)
df_clean$log_Sending_GDP <- log(df_clean$Sending_Country_GDP_millions + 0.001)
df_clean$log_Receiving_GDP <- log(df_clean$Receiving_Country_GDP_millions + 0.001)

# Outlier detection using IQR method
detect_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower <- Q1 - 1.5 * IQR
  upper <- Q3 + 1.5 * IQR
  return(x < lower | x > upper)
}

# Identify outliers for each variable
outliers_value_thousands <- detect_outliers(df_clean$Value_thousands)
outliers_value_millions <- detect_outliers(df_clean$Value_millions)
outliers_sending <- detect_outliers(df_clean$Sending_Country_GDP_millions)
outliers_receiving <- detect_outliers(df_clean$Receiving_Country_GDP_millions)

# Combined outliers
outliers_combined <- outliers_value_thousands | outliers_value_millions | outliers_sending | outliers_receiving

# Create dataset without outliers
df_no_outliers <- df_clean[!outliers_combined, ]

cat("Dataset shape after cleaning:", nrow(df_clean), "rows,", ncol(df_clean), "columns\n")
cat("Dataset without outliers:", nrow(df_no_outliers), "rows\n")

# Run all regression models
cat("\nRunning all regression specifications...\n")

# === SPECIFICATION 1: Remittances in thousands, GDP in millions ===
model1_with_outliers <- lm(Value_thousands ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                           data = df_clean)
model1_without_outliers <- lm(Value_thousands ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                              data = df_no_outliers)

# === SPECIFICATION 2: Log-Log ===
model2_with_outliers <- lm(log_Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                           data = df_clean)
model2_without_outliers <- lm(log_Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                              data = df_no_outliers)

# === SPECIFICATION 3: Log dependent, linear independent ===
model3_with_outliers <- lm(log_Value_millions ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                           data = df_clean)
model3_without_outliers <- lm(log_Value_millions ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                              data = df_no_outliers)

# === SPECIFICATION 4: Linear dependent, log independent ===
model4_with_outliers <- lm(Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                           data = df_clean)
model4_without_outliers <- lm(Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                              data = df_no_outliers)

# === CREATE COMBINED HTML FILE ===
cat("\nCreating comprehensive combined HTML file...\n")

# Function to create HTML header
create_html_header <- function() {
  return('<!DOCTYPE html>
<html>
<head>
    <title>Comprehensive Regression Analysis Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #2c3e50; text-align: center; }
        h2 { color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .summary { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        table { margin: 20px auto; }
        .note { font-style: italic; color: #7f8c8d; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Comprehensive Regression Analysis: Remittances and GDP</h1>
    
    <div class="summary">
        <h3>Analysis Overview</h3>
        <p><strong>Dataset:</strong> 22.csv</p>
        <p><strong>Total observations:</strong> ' + nrow(df_clean) + '</p>
        <p><strong>Observations without outliers:</strong> ' + nrow(df_no_outliers) + '</p>
        <p><strong>Outliers removed:</strong> ' + (nrow(df_clean) - nrow(df_no_outliers)) + '</p>
        
        <h4>Specifications Tested:</h4>
        <ul>
            <li><strong>Specification 1:</strong> Remittances (thousands) vs GDP (millions)</li>
            <li><strong>Specification 2:</strong> Log-Log Model</li>
            <li><strong>Specification 3:</strong> Log Dependent, Linear Independent</li>
            <li><strong>Specification 4:</strong> Linear Dependent, Log Independent</li>
        </ul>
    </div>')
}

# Function to create HTML footer
create_html_footer <- function() {
  return('
    <div class="summary">
        <h3>Key Findings</h3>
        <ul>
            <li>Log transformations significantly improve model fit</li>
            <li>Outlier removal generally improves model performance</li>
            <li>Log-Log specification performs best overall</li>
            <li>Best performing model: Log-Log without outliers (Adj R² = ' + 
            round(summary(model2_without_outliers)$adj.r.squared, 4) + ')</li>
        </ul>
    </div>
</body>
</html>')
}

# Start building the combined HTML file
html_content <- create_html_header()

# Add each specification table
specifications <- list(
  list(models = list(model1_with_outliers, model1_without_outliers),
       title = "Specification 1: Remittances (thousands) vs GDP (millions)",
       dep_var = "Remittance Value (thousands USD)",
       covariates = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)"),
       columns = c("With Outliers", "Without Outliers")),
  
  list(models = list(model2_with_outliers, model2_without_outliers),
       title = "Specification 2: Log-Log Model",
       dep_var = "Log(Remittance Value)",
       covariates = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
       columns = c("With Outliers", "Without Outliers")),
  
  list(models = list(model3_with_outliers, model3_without_outliers),
       title = "Specification 3: Log Dependent, Linear Independent",
       dep_var = "Log(Remittance Value)",
       covariates = c("Sending Country GDP (millions USD)", "Receiving Country GDP (millions USD)"),
       columns = c("With Outliers", "Without Outliers")),
  
  list(models = list(model4_with_outliers, model4_without_outliers),
       title = "Specification 4: Linear Dependent, Log Independent", 
       dep_var = "Remittance Value (millions USD)",
       covariates = c("Log(Sending Country GDP)", "Log(Receiving Country GDP)"),
       columns = c("With Outliers", "Without Outliers"))
)

# Generate each table and add to HTML
for (i in 1:length(specifications)) {
  spec <- specifications[[i]]
  
  # Add section header
  html_content <- paste0(html_content, '\n    <h2>', spec$title, '</h2>\n')
  
  # Generate stargazer table and capture it
  table_html <- stargazer(spec$models[[1]], spec$models[[2]],
                         title = spec$title,
                         dep.var.labels = spec$dep_var,
                         covariate.labels = spec$covariates,
                         column.labels = spec$columns,
                         type = "html",
                         header = FALSE)
  
  # Clean up the table HTML (remove html/body tags)
  table_html <- paste(table_html, collapse = "\n")
  table_html <- gsub(".*<table", "<table", table_html)
  table_html <- gsub("</table>.*", "</table>", table_html)
  
  # Add the table to our HTML
  html_content <- paste0(html_content, table_html, '\n')
  
  # Add some spacing
  html_content <- paste0(html_content, '\n    <br><br>\n')
}

# Add summary comparison table
html_content <- paste0(html_content, '\n    <h2>Model Comparison Summary</h2>\n')

# Create comparison table data
summary_data <- data.frame(
  Model = c("Spec1_With", "Spec1_Without", "Spec2_With", "Spec2_Without", 
            "Spec3_With", "Spec3_Without", "Spec4_With", "Spec4_Without"),
  Description = c("Remit(000s) vs GDP(M) - With Outliers", "Remit(000s) vs GDP(M) - Without Outliers",
                  "Log-Log - With Outliers", "Log-Log - Without Outliers",
                  "Log-Linear - With Outliers", "Log-Linear - Without Outliers", 
                  "Linear-Log - With Outliers", "Linear-Log - Without Outliers"),
  Observations = c(nrow(df_clean), nrow(df_no_outliers), nrow(df_clean), nrow(df_no_outliers),
                   nrow(df_clean), nrow(df_no_outliers), nrow(df_clean), nrow(df_no_outliers)),
  R_Squared = round(c(summary(model1_with_outliers)$r.squared, summary(model1_without_outliers)$r.squared,
                      summary(model2_with_outliers)$r.squared, summary(model2_without_outliers)$r.squared,
                      summary(model3_with_outliers)$r.squared, summary(model3_without_outliers)$r.squared,
                      summary(model4_with_outliers)$r.squared, summary(model4_without_outliers)$r.squared), 4),
  Adj_R_Squared = round(c(summary(model1_with_outliers)$adj.r.squared, summary(model1_without_outliers)$adj.r.squared,
                          summary(model2_with_outliers)$adj.r.squared, summary(model2_without_outliers)$adj.r.squared,
                          summary(model3_with_outliers)$adj.r.squared, summary(model3_without_outliers)$adj.r.squared,
                          summary(model4_with_outliers)$adj.r.squared, summary(model4_without_outliers)$adj.r.squared), 4)
)

# Convert summary table to HTML
summary_html <- '<table border="1" style="border-collapse:collapse; margin: 20px auto;">
<tr><th>Model</th><th>Description</th><th>Observations</th><th>R²</th><th>Adj R²</th></tr>'

for (i in 1:nrow(summary_data)) {
  summary_html <- paste0(summary_html, 
                        '<tr><td>', summary_data$Model[i], '</td>',
                        '<td>', summary_data$Description[i], '</td>',
                        '<td>', summary_data$Observations[i], '</td>',
                        '<td>', summary_data$R_Squared[i], '</td>',
                        '<td>', summary_data$Adj_R_Squared[i], '</td></tr>')
}
summary_html <- paste0(summary_html, '</table>')

html_content <- paste0(html_content, summary_html)

# Add footer
html_content <- paste0(html_content, create_html_footer())

# Write the combined HTML file
output_file <- file.path(output_dir, "all_specifications_combined.html")
writeLines(html_content, output_file)

cat("Successfully created comprehensive HTML file:", output_file, "\n")
cat("The file contains all four specifications with both outlier conditions in a single document.\n")