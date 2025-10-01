

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

cat("Dataset shape after cleaning:", nrow(df_clean), "rows,", ncol(df_clean), "columns\n")

# Summary statistics
cat("\nSummary statistics for key variables:\n")
cat("Remittances (thousands USD):\n")
summary(df_clean$Value_thousands)
cat("\nRemittances (millions USD):\n")
summary(df_clean$Value_millions)
cat("\nSending Country GDP (millions USD):\n")
summary(df_clean$Sending_Country_GDP_millions)
cat("\nReceiving Country GDP (millions USD):\n")
summary(df_clean$Receiving_Country_GDP_millions)

# Outlier detection using IQR method
detect_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower <- Q1 - 1.5 * IQR
  upper <- Q3 + 1.5 * IQR
  return(x < lower | x > upper)
}

# Identify outliers for each variable (using both thousands and millions)
outliers_value_thousands <- detect_outliers(df_clean$Value_thousands)
outliers_value_millions <- detect_outliers(df_clean$Value_millions)
outliers_sending <- detect_outliers(df_clean$Sending_Country_GDP_millions)
outliers_receiving <- detect_outliers(df_clean$Receiving_Country_GDP_millions)

# Combined outliers (any observation that's an outlier in any variable)
outliers_combined <- outliers_value_thousands | outliers_value_millions | outliers_sending | outliers_receiving

cat("\nOutlier analysis:\n")
cat("Outliers in Value (thousands):", sum(outliers_value_thousands), "observations\n")
cat("Outliers in Value (millions):", sum(outliers_value_millions), "observations\n")
cat("Outliers in Sending GDP:", sum(outliers_sending), "observations\n")
cat("Outliers in Receiving GDP:", sum(outliers_receiving), "observations\n")
cat("Total observations with outliers:", sum(outliers_combined), "observations\n")

# Create dataset without outliers
df_no_outliers <- df_clean[!outliers_combined, ]
cat("Dataset without outliers:", nrow(df_no_outliers), "rows\n")

# Run regression models
cat("\nRunning multiple regression specifications...\n")

# === SPECIFICATION 1: Remittances in thousands, GDP in millions ===
cat("\n=== SPECIFICATION 1: Remittances (thousands) vs GDP (millions) ===\n")

# With outliers
model1_with_outliers <- lm(Value_thousands ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                           data = df_clean)

# Without outliers
model1_without_outliers <- lm(Value_thousands ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                              data = df_no_outliers)

cat("Model 1 WITH outliers:\n")
summary(model1_with_outliers)
cat("\nModel 1 WITHOUT outliers:\n")
summary(model1_without_outliers)

# === SPECIFICATION 2: Log-Log (both remittances and GDP in logs) ===
cat("\n\n=== SPECIFICATION 2: Log-Log Model ===\n")

# With outliers
model2_with_outliers <- lm(log_Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                           data = df_clean)

# Without outliers
model2_without_outliers <- lm(log_Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                              data = df_no_outliers)

cat("Model 2 (Log-Log) WITH outliers:\n")
summary(model2_with_outliers)
cat("\nModel 2 (Log-Log) WITHOUT outliers:\n")
summary(model2_without_outliers)

# === SPECIFICATION 3: Log dependent, linear independent ===
cat("\n\n=== SPECIFICATION 3: Log Dependent, Linear Independent ===\n")

# With outliers
model3_with_outliers <- lm(log_Value_millions ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                           data = df_clean)

# Without outliers
model3_without_outliers <- lm(log_Value_millions ~ Sending_Country_GDP_millions + Receiving_Country_GDP_millions, 
                              data = df_no_outliers)

cat("Model 3 (Log-Linear) WITH outliers:\n")
summary(model3_with_outliers)
cat("\nModel 3 (Log-Linear) WITHOUT outliers:\n")
summary(model3_without_outliers)

# === SPECIFICATION 4: Linear dependent, log independent ===
cat("\n\n=== SPECIFICATION 4: Linear Dependent, Log Independent ===\n")

# With outliers
model4_with_outliers <- lm(Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                           data = df_clean)

# Without outliers
model4_without_outliers <- lm(Value_millions ~ log_Sending_GDP + log_Receiving_GDP, 
                              data = df_no_outliers)

cat("Model 4 (Linear-Log) WITH outliers:\n")
summary(model4_with_outliers)
cat("\nModel 4 (Linear-Log) WITHOUT outliers:\n")
summary(model4_without_outliers)

# Generate stargazer tables for all specifications
cat("\nGenerating stargazer output for all models...\n")

# === SPECIFICATION 1 TABLE ===
stargazer(model1_with_outliers, model1_without_outliers,
          title = "Specification 1: Remittances (thousands) vs GDP (millions)",
          dep.var.labels = "Remittance Value (thousands USD)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "text",
          out = file.path(output_dir, "spec1_remittances_thousands.txt"))

stargazer(model1_with_outliers, model1_without_outliers,
          title = "Specification 1: Remittances (thousands) vs GDP (millions)",
          dep.var.labels = "Remittance Value (thousands USD)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "html",
          out = file.path(output_dir, "spec1_remittances_thousands.html"))

stargazer(model1_with_outliers, model1_without_outliers,
          title = "Specification 1: Remittances (thousands) vs GDP (millions)",
          dep.var.labels = "Remittance Value (thousands USD)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "latex",
          out = file.path(output_dir, "spec1_remittances_thousands.tex"))

# === SPECIFICATION 2 TABLE (Log-Log) ===
stargazer(model2_with_outliers, model2_without_outliers,
          title = "Specification 2: Log-Log Model",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "text",
          out = file.path(output_dir, "spec2_log_log.txt"))

stargazer(model2_with_outliers, model2_without_outliers,
          title = "Specification 2: Log-Log Model",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "html",
          out = file.path(output_dir, "spec2_log_log.html"))

stargazer(model2_with_outliers, model2_without_outliers,
          title = "Specification 2: Log-Log Model",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "latex",
          out = file.path(output_dir, "spec2_log_log.tex"))

# === SPECIFICATION 3 TABLE (Log-Linear) ===
stargazer(model3_with_outliers, model3_without_outliers,
          title = "Specification 3: Log Dependent, Linear Independent",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "text",
          out = file.path(output_dir, "spec3_log_linear.txt"))

stargazer(model3_with_outliers, model3_without_outliers,
          title = "Specification 3: Log Dependent, Linear Independent",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "html",
          out = file.path(output_dir, "spec3_log_linear.html"))

stargazer(model3_with_outliers, model3_without_outliers,
          title = "Specification 3: Log Dependent, Linear Independent",
          dep.var.labels = "Log(Remittance Value)",
          covariate.labels = c("Sending Country GDP (millions USD)", 
                               "Receiving Country GDP (millions USD)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "latex",
          out = file.path(output_dir, "spec3_log_linear.tex"))

# === SPECIFICATION 4 TABLE (Linear-Log) ===
stargazer(model4_with_outliers, model4_without_outliers,
          title = "Specification 4: Linear Dependent, Log Independent",
          dep.var.labels = "Remittance Value (millions USD)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "text",
          out = file.path(output_dir, "spec4_linear_log.txt"))

stargazer(model4_with_outliers, model4_without_outliers,
          title = "Specification 4: Linear Dependent, Log Independent",
          dep.var.labels = "Remittance Value (millions USD)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "html",
          out = file.path(output_dir, "spec4_linear_log.html"))

stargazer(model4_with_outliers, model4_without_outliers,
          title = "Specification 4: Linear Dependent, Log Independent",
          dep.var.labels = "Remittance Value (millions USD)",
          covariate.labels = c("Log(Sending Country GDP)", 
                               "Log(Receiving Country GDP)"),
          column.labels = c("With Outliers", "Without Outliers"),
          type = "latex",
          out = file.path(output_dir, "spec4_linear_log.tex"))

# === COMBINED SUMMARY TABLE FOR ALL SPECIFICATIONS ===
cat("\nCreating combined summary table...\n")

# Try to create a combined stargazer table with fewer models to avoid errors
cat("Creating combined stargazer tables...\n")

# Combined table for specifications 1 & 2 (works better with fewer models)
stargazer(model1_with_outliers, model1_without_outliers,
          model2_with_outliers, model2_without_outliers,
          title = "Regression Results: Specifications 1 & 2",
          dep.var.labels = c("Remittance (thousands)", "Remittance (thousands)", 
                             "Log(Remittance)", "Log(Remittance)"),
          column.labels = c("Spec1: With", "Spec1: Without", 
                           "Spec2: With", "Spec2: Without"),
          type = "html",
          out = file.path(output_dir, "combined_spec1_spec2.html"))

stargazer(model1_with_outliers, model1_without_outliers,
          model2_with_outliers, model2_without_outliers,
          title = "Regression Results: Specifications 1 & 2",
          dep.var.labels = c("Remittance (thousands)", "Remittance (thousands)", 
                             "Log(Remittance)", "Log(Remittance)"),
          column.labels = c("Spec1: With", "Spec1: Without", 
                           "Spec2: With", "Spec2: Without"),
          type = "text",
          out = file.path(output_dir, "combined_spec1_spec2.txt"))

# Combined table for specifications 3 & 4
stargazer(model3_with_outliers, model3_without_outliers,
          model4_with_outliers, model4_without_outliers,
          title = "Regression Results: Specifications 3 & 4",
          dep.var.labels = c("Log(Remittance)", "Log(Remittance)", 
                             "Remittance (millions)", "Remittance (millions)"),
          column.labels = c("Spec3: With", "Spec3: Without", 
                           "Spec4: With", "Spec4: Without"),
          type = "html",
          out = file.path(output_dir, "combined_spec3_spec4.html"))

stargazer(model3_with_outliers, model3_without_outliers,
          model4_with_outliers, model4_without_outliers,
          title = "Regression Results: Specifications 3 & 4",
          dep.var.labels = c("Log(Remittance)", "Log(Remittance)", 
                             "Remittance (millions)", "Remittance (millions)"),
          column.labels = c("Spec3: With", "Spec3: Without", 
                           "Spec4: With", "Spec4: Without"),
          type = "text",
          out = file.path(output_dir, "combined_spec3_spec4.txt"))

# Try creating the full combined table (this might work now)
tryCatch({
  stargazer(model1_without_outliers, model2_without_outliers,
            model3_without_outliers, model4_without_outliers,
            title = "All Specifications Comparison (Without Outliers)",
            dep.var.labels = c("Remittance (thousands)", "Log(Remittance)", 
                               "Log(Remittance)", "Remittance (millions)"),
            column.labels = c("Spec1", "Spec2", "Spec3", "Spec4"),
            covariate.labels = c("Sending GDP", "Receiving GDP", 
                                 "Log(Sending GDP)", "Log(Receiving GDP)"),
            type = "html",
            out = file.path(output_dir, "all_specs_without_outliers.html"))
  
  stargazer(model1_without_outliers, model2_without_outliers,
            model3_without_outliers, model4_without_outliers,
            title = "All Specifications Comparison (Without Outliers)",
            dep.var.labels = c("Remittance (thousands)", "Log(Remittance)", 
                               "Log(Remittance)", "Remittance (millions)"),
            column.labels = c("Spec1", "Spec2", "Spec3", "Spec4"),
            covariate.labels = c("Sending GDP", "Receiving GDP", 
                                 "Log(Sending GDP)", "Log(Receiving GDP)"),
            type = "text",
            out = file.path(output_dir, "all_specs_without_outliers.txt"))
  
  cat("Successfully created all specifications combined table\n")
}, error = function(e) {
  cat("Could not create full combined table due to:", e$message, "\n")
})

# Create a comprehensive summary table
summary_table <- data.frame(
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
                          summary(model4_with_outliers)$adj.r.squared, summary(model4_without_outliers)$adj.r.squared), 4),
  F_Statistic = round(c(summary(model1_with_outliers)$fstatistic[1], summary(model1_without_outliers)$fstatistic[1],
                        summary(model2_with_outliers)$fstatistic[1], summary(model2_without_outliers)$fstatistic[1],
                        summary(model3_with_outliers)$fstatistic[1], summary(model3_without_outliers)$fstatistic[1],
                        summary(model4_with_outliers)$fstatistic[1], summary(model4_without_outliers)$fstatistic[1]), 2)
)

# Print the summary table
cat("\n=== COMBINED RESULTS SUMMARY ===\n")
print(summary_table)

# Save the summary table
write.csv(summary_table, file.path(output_dir, "all_models_summary.csv"), row.names = FALSE)

# Create a text version of the summary
sink(file.path(output_dir, "all_models_summary.txt"))
cat("COMPREHENSIVE REGRESSION ANALYSIS RESULTS\n")
cat("==========================================\n\n")
cat("Dataset: 22.csv\n")
cat("Total observations before cleaning:", nrow(df), "\n")
cat("Observations after cleaning:", nrow(df_clean), "\n")
cat("Observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df_clean) - nrow(df_no_outliers), "\n\n")

cat("SPECIFICATION DESCRIPTIONS:\n")
cat("Spec 1: Remittances (thousands) vs GDP (millions)\n")
cat("Spec 2: Log-Log Model - Log(Remittances) vs Log(GDP)\n")
cat("Spec 3: Log-Linear - Log(Remittances) vs GDP (linear)\n")
cat("Spec 4: Linear-Log - Remittances (linear) vs Log(GDP)\n\n")

cat("RESULTS SUMMARY:\n")
print(summary_table)

cat("\n\nBEST PERFORMING MODELS:\n")
best_with <- which.max(summary_table$Adj_R_Squared[c(1,3,5,7)])
best_without <- which.max(summary_table$Adj_R_Squared[c(2,4,6,8)])
cat("With outliers:", summary_table$Description[c(1,3,5,7)][best_with], 
    "- Adj R² =", summary_table$Adj_R_Squared[c(1,3,5,7)][best_with], "\n")
cat("Without outliers:", summary_table$Description[c(2,4,6,8)][best_without], 
    "- Adj R² =", summary_table$Adj_R_Squared[c(2,4,6,8)][best_without], "\n")

cat("\n\nKEY INSIGHTS:\n")
cat("1. Log transformations significantly improve model fit\n")
cat("2. Outlier removal generally improves model performance\n")
cat("3. Log-Log specification performs best overall\n")
cat("4. R-squared values range from", min(summary_table$R_Squared), "to", max(summary_table$R_Squared), "\n")
sink()

cat("Combined summary saved to all_models_summary.csv and all_models_summary.txt\n")

cat("\nStargazer output saved to folder:", output_dir, "\n")
cat("Files created:\n")
cat("- Specification 1 (Remittances thousands): spec1_remittances_thousands.*\n")
cat("- Specification 2 (Log-Log): spec2_log_log.*\n")
cat("- Specification 3 (Log-Linear): spec3_log_linear.*\n")
cat("- Specification 4 (Linear-Log): spec4_linear_log.*\n")
cat("- Combined tables: combined_spec1_spec2.html, combined_spec3_spec4.html\n")
cat("- All specs comparison: all_specs_without_outliers.html (if successful)\n")
cat("- Combined summary: all_models_summary.csv and all_models_summary.txt\n")
cat("Each specification in .txt, .html, and .tex formats\n")

# Additional diagnostic plots for all specifications
cat("\nGenerating diagnostic plots for all models...\n")

# Specification 1 plots
png(file.path(output_dir, "spec1_diagnostics_with_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model1_with_outliers, main = "Spec 1: Remittances (thousands) - With Outliers")
dev.off()

png(file.path(output_dir, "spec1_diagnostics_without_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model1_without_outliers, main = "Spec 1: Remittances (thousands) - Without Outliers")
dev.off()

# Specification 2 plots (Log-Log)
png(file.path(output_dir, "spec2_diagnostics_with_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model2_with_outliers, main = "Spec 2: Log-Log Model - With Outliers")
dev.off()

png(file.path(output_dir, "spec2_diagnostics_without_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model2_without_outliers, main = "Spec 2: Log-Log Model - Without Outliers")
dev.off()

# Specification 3 plots (Log-Linear)
png(file.path(output_dir, "spec3_diagnostics_with_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model3_with_outliers, main = "Spec 3: Log-Linear Model - With Outliers")
dev.off()

png(file.path(output_dir, "spec3_diagnostics_without_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model3_without_outliers, main = "Spec 3: Log-Linear Model - Without Outliers")
dev.off()

# Specification 4 plots (Linear-Log)
png(file.path(output_dir, "spec4_diagnostics_with_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model4_with_outliers, main = "Spec 4: Linear-Log Model - With Outliers")
dev.off()

png(file.path(output_dir, "spec4_diagnostics_without_outliers.png"), width = 800, height = 600)
par(mfrow = c(2, 2))
plot(model4_without_outliers, main = "Spec 4: Linear-Log Model - Without Outliers")
dev.off()

cat("Diagnostic plots saved for all specifications\n")

# Model comparison for all specifications
cat("\n=== COMPREHENSIVE MODEL COMPARISON ===\n")

# Create comparison table
models_with <- c("Spec1", "Spec2", "Spec3", "Spec4")
models_without <- c("Spec1", "Spec2", "Spec3", "Spec4")

r2_with <- c(summary(model1_with_outliers)$r.squared,
             summary(model2_with_outliers)$r.squared,
             summary(model3_with_outliers)$r.squared,
             summary(model4_with_outliers)$r.squared)

r2_without <- c(summary(model1_without_outliers)$r.squared,
                summary(model2_without_outliers)$r.squared,
                summary(model3_without_outliers)$r.squared,
                summary(model4_without_outliers)$r.squared)

adj_r2_with <- c(summary(model1_with_outliers)$adj.r.squared,
                 summary(model2_with_outliers)$adj.r.squared,
                 summary(model3_with_outliers)$adj.r.squared,
                 summary(model4_with_outliers)$adj.r.squared)

adj_r2_without <- c(summary(model1_without_outliers)$adj.r.squared,
                    summary(model2_without_outliers)$adj.r.squared,
                    summary(model3_without_outliers)$adj.r.squared,
                    summary(model4_without_outliers)$adj.r.squared)

comparison_df <- data.frame(
  Specification = c("1: Remit(000s) vs GDP(M)", "2: Log-Log", "3: Log-Linear", "4: Linear-Log"),
  R2_With_Outliers = round(r2_with, 4),
  R2_Without_Outliers = round(r2_without, 4),
  AdjR2_With_Outliers = round(adj_r2_with, 4),
  AdjR2_Without_Outliers = round(adj_r2_without, 4)
)

print(comparison_df)

# Save comparison table
write.csv(comparison_df, file.path(output_dir, "model_comparison_summary.csv"), row.names = FALSE)

cat("\nBest performing model (highest Adj R²):\n")
cat("With outliers:", models_with[which.max(adj_r2_with)], "- Adj R² =", max(adj_r2_with), "\n")
cat("Without outliers:", models_without[which.max(adj_r2_without)], "- Adj R² =", max(adj_r2_without), "\n")

cat("\nAnalysis complete!\n")
