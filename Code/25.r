# Regression Analysis: Value ~ Sending_Country_GDP + Receiving_Country_GDP
# Install and load required packages
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("Installing package:", pkg, "\n")
      install.packages(pkg, repos = "https://cran.r-project.org/")
      library(pkg, character.only = TRUE)
    }
  }
}

# Install required packages
required_packages <- c("car", "stargazer")
install_if_missing(required_packages)

# Load the dataset using base R
file_path <- "C:/Users/clint/Desktop/RER/Code/22.csv"
cat("Loading dataset...\n")
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Display basic information about the dataset
cat("Dataset dimensions:", dim(df), "\n")
cat("Column names:\n")
print(names(df))

# Display first few rows
cat("\nFirst few rows:\n")
print(head(df))

# Clean the Value column (remove commas and quotes, convert to numeric)
cat("\nCleaning data...\n")
df$Value_cleaned <- as.numeric(gsub("[,\"]", "", df$Value))

# Check for missing values in key variables
cat("\nMissing values:\n")
cat("Value_cleaned:", sum(is.na(df$Value_cleaned)), "\n")
cat("Sending_Country_GDP:", sum(is.na(df$Sending_Country_GDP)), "\n")
cat("Receiving_Country_GDP:", sum(is.na(df$Receiving_Country_GDP)), "\n")

# Remove rows with missing values in regression variables
regression_data <- df[complete.cases(df$Value_cleaned, df$Sending_Country_GDP, df$Receiving_Country_GDP), ]
cat("\nDataset after removing missing values:", nrow(regression_data), "rows\n")

# Display summary statistics using base R
cat("\nSummary statistics for regression variables:\n")
summary_stats <- summary(regression_data[c("Value_cleaned", "Sending_Country_GDP", "Receiving_Country_GDP")])
print(summary_stats)

# Fit the linear regression model
cat("\nFitting regression model...\n")
model <- lm(Value_cleaned ~ Sending_Country_GDP + Receiving_Country_GDP, data = regression_data)

# Create output folder
output_folder <- "C:/Users/clint/Desktop/RER/Code/25"
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  cat("Created output folder:", output_folder, "\n")
}

# Display comprehensive regression results
cat("\n", rep("=", 60), "\n")
cat("LINEAR REGRESSION RESULTS\n")
cat(rep("=", 60), "\n")

# Model summary
model_summary <- summary(model)
print(model_summary)

# STARGAZER OUTPUT
cat("\n", rep("=", 60), "\n")
cat("STARGAZER REGRESSION TABLE\n")
cat(rep("=", 60), "\n")

# Load stargazer
library(stargazer)

# Console output (text format)
cat("\nRegression Table (Text Format):\n")
stargazer(model, type = "text",
          title = "Regression Results: Value vs GDP Variables",
          dep.var.labels = "Value",
          covariate.labels = c("Sending Country GDP", "Receiving Country GDP"),
          omit.stat = c("ser", "f"),
          digits = 3,
          out = "")

# Save HTML version
html_file <- file.path(output_folder, "regression_table.html")
stargazer(model, type = "html",
          title = "Regression Results: Value vs GDP Variables",
          dep.var.labels = "Value",
          covariate.labels = c("Sending Country GDP", "Receiving Country GDP"),
          omit.stat = c("ser", "f"),
          digits = 3,
          out = html_file)

# Save LaTeX version
tex_file <- file.path(output_folder, "regression_table.tex")
stargazer(model, type = "latex",
          title = "Regression Results: Value vs GDP Variables",
          dep.var.labels = "Value",
          covariate.labels = c("Sending Country GDP", "Receiving Country GDP"),
          omit.stat = c("ser", "f"),
          digits = 3,
          out = tex_file)

# Save text version to file
text_file <- file.path(output_folder, "regression_table.txt")
sink(text_file)
stargazer(model, type = "text",
          title = "Regression Results: Value vs GDP Variables",
          dep.var.labels = "Value",
          covariate.labels = c("Sending Country GDP", "Receiving Country GDP"),
          omit.stat = c("ser", "f"),
          digits = 3,
          out = "")
sink()

cat(sprintf("\nStargazer outputs saved to folder: %s\n", output_folder))
cat(sprintf("- HTML: %s\n", html_file))
cat(sprintf("- LaTeX: %s\n", tex_file))
cat(sprintf("- Text: %s\n", text_file))

# Additional model statistics
cat("\nAdditional Model Statistics:\n")
cat("Number of observations:", nobs(model), "\n")
cat("Degrees of freedom:", df.residual(model), "\n")
cat("F-statistic:", model_summary$fstatistic[1], "\n")
cat("F p-value:", pf(model_summary$fstatistic[1], 
                    model_summary$fstatistic[2], 
                    model_summary$fstatistic[3], 
                    lower.tail = FALSE), "\n")

# Get model coefficients and statistics using base R functions
model_summary <- summary(model)
coeffs <- coef(model)
tidy_results <- data.frame(
  term = names(coeffs),
  estimate = coeffs,
  std.error = model_summary$coefficients[, "Std. Error"],
  statistic = model_summary$coefficients[, "t value"],
  p.value = model_summary$coefficients[, "Pr(>|t|)"]
)
cat("\nCoefficients Table:\n")
print(tidy_results)

# Model diagnostics
cat("\n", rep("=", 60), "\n")
cat("MODEL DIAGNOSTICS\n")
cat(rep("=", 60), "\n")

# Check for multicollinearity using VIF
if(require(car, quietly = TRUE)) {
  cat("\nVariance Inflation Factors (VIF):\n")
  vif_values <- vif(model)
  print(vif_values)
  
  if(any(vif_values > 5)) {
    cat("Warning: High multicollinearity detected (VIF > 5)\n")
  } else {
    cat("No serious multicollinearity issues detected (all VIF < 5)\n")
  }
}

# Residual analysis
residuals <- residuals(model)
fitted_values <- fitted(model)

cat("\nResidual Statistics:\n")
cat("Mean residual:", mean(residuals), "\n")
cat("Standard deviation of residuals:", sd(residuals), "\n")
cat("Min residual:", min(residuals), "\n")
cat("Max residual:", max(residuals), "\n")

# Create comprehensive plots
cat("\nCreating diagnostic plots...\n")

# Set up plotting area
par(mfrow = c(2, 3), mar = c(4, 4, 2, 1))

# 1. Actual vs Predicted
plot(regression_data$Value_cleaned, fitted_values,
     xlab = "Actual Values", ylab = "Predicted Values",
     main = "Actual vs Predicted Values",
     pch = 16, alpha = 0.6)
abline(a = 0, b = 1, col = "red", lwd = 2, lty = 2)
grid()

# 2. Residuals vs Fitted
plot(fitted_values, residuals,
     xlab = "Fitted Values", ylab = "Residuals",
     main = "Residuals vs Fitted",
     pch = 16, alpha = 0.6)
abline(h = 0, col = "red", lwd = 2, lty = 2)
grid()

# 3. Q-Q plot of residuals
qqnorm(residuals, main = "Q-Q Plot of Residuals", pch = 16)
qqline(residuals, col = "red", lwd = 2)
grid()

# 4. Histogram of residuals
hist(residuals, breaks = 30, main = "Distribution of Residuals",
     xlab = "Residuals", freq = FALSE, col = "lightblue", border = "black")
curve(dnorm(x, mean = mean(residuals), sd = sd(residuals)), 
      add = TRUE, col = "red", lwd = 2)
grid()

# 5. Value vs Sending Country GDP
plot(regression_data$Sending_Country_GDP, regression_data$Value_cleaned,
     xlab = "Sending Country GDP", ylab = "Value",
     main = "Value vs Sending Country GDP",
     pch = 16, alpha = 0.6)
grid()

# 6. Value vs Receiving Country GDP
plot(regression_data$Receiving_Country_GDP, regression_data$Value_cleaned,
     xlab = "Receiving Country GDP", ylab = "Value",
     main = "Value vs Receiving Country GDP",
     pch = 16, alpha = 0.6)
grid()

# Reset plotting parameters
par(mfrow = c(1, 1))

# Correlation matrix
cat("\nCorrelation Matrix:\n")
cor_matrix <- cor(regression_data[c("Value_cleaned", "Sending_Country_GDP", "Receiving_Country_GDP")], 
                  use = "complete.obs")
print(round(cor_matrix, 4))

# Save results to file
cat("\nSaving results...\n")
results_file <- file.path(output_folder, "regression_results.txt")
sink(results_file)
cat("LINEAR REGRESSION ANALYSIS RESULTS\n")
cat("Date:", Sys.Date(), "\n")
cat("Time:", Sys.time(), "\n")
cat(rep("=", 60), "\n\n")

cat("DATASET INFORMATION:\n")
cat("File:", file_path, "\n")
cat("Total observations:", nrow(df), "\n")
cat("Observations used in analysis:", nrow(regression_data), "\n")
cat("Missing values removed:", nrow(df) - nrow(regression_data), "\n\n")

cat("REGRESSION EQUATION:\n")
coeffs <- coef(model)
cat(sprintf("Value = %.6f + %.6f * Sending_Country_GDP + %.6f * Receiving_Country_GDP\n\n",
            coeffs[1], coeffs[2], coeffs[3]))

cat("MODEL SUMMARY:\n")
print(model_summary)

cat("\nSTARGAZER REGRESSION TABLE:\n")
stargazer(model, type = "text",
          title = "Regression Results: Value vs GDP Variables",
          dep.var.labels = "Value",
          covariate.labels = c("Sending Country GDP", "Receiving Country GDP"),
          omit.stat = c("ser", "f"),
          digits = 3,
          out = "")

cat("\nCOEFFICIENTS TABLE:\n")
print(tidy_results)

cat("\nCORRELATION MATRIX:\n")
print(round(cor_matrix, 4))

sink()

# Interpretation
cat("\n", rep("=", 60), "\n")
cat("INTERPRETATION\n")
cat(rep("=", 60), "\n")
cat("The regression equation is:\n")
cat(sprintf("Value = %.6f + %.6f * Sending_Country_GDP + %.6f * Receiving_Country_GDP\n\n",
            coeffs[1], coeffs[2], coeffs[3]))

r_squared <- summary(model)$r.squared
cat(sprintf("The model explains %.2f%% of the variance in the Value variable.\n\n", r_squared * 100))

cat("Statistical significance (p < 0.05):\n")
p_values <- tidy_results$p.value
var_names <- c("Intercept", "Sending_Country_GDP", "Receiving_Country_GDP")
for(i in seq_along(p_values)) {
  significance <- ifelse(p_values[i] < 0.05, "Significant", "Not significant")
  cat(sprintf("- %s: %s (p = %.6f)\n", var_names[i], significance, p_values[i]))
}

cat(sprintf("\nResults saved to: %s\n", results_file))
cat("Analysis completed successfully!\n")