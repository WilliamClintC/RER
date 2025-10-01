# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)
}

# Install required packages
required_packages <- c("car", "stargazer", "dplyr", "rmarkdown", "knitr", "broom")
install_if_missing(required_packages)

# Load required libraries
library(car)
library(stargazer)
library(dplyr)
library(rmarkdown)
library(knitr)
library(broom)

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

# Create simplified variable names to avoid stargazer issues
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

# Model 1: Contemporaneous (unlagged) with outliers
model1_with_outliers <- lm(Y ~ X1 + X2, data = df_complete_clean)

# Model 2: Contemporaneous (unlagged) without outliers
model2_no_outliers <- lm(Y ~ X1 + X2, data = df_no_outliers_clean)

# Model 3: Lagged (1 period) with outliers
model3_lagged_with_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_complete_lagged_clean)

# Model 4: Lagged (1 period) without outliers
model4_lagged_no_outliers <- lm(Y ~ X1_lag + X2_lag, data = df_no_outliers_lagged_clean)

# Print model summaries
cat("\n=== MODEL 1: Contemporaneous with Outliers ===\n")
print(summary(model1_with_outliers))

cat("\n=== MODEL 2: Contemporaneous without Outliers ===\n")
print(summary(model2_no_outliers))

cat("\n=== MODEL 3: Lagged (1 period) with Outliers ===\n")
print(summary(model3_lagged_with_outliers))

cat("\n=== MODEL 4: Lagged (1 period) without Outliers ===\n")
print(summary(model4_lagged_no_outliers))

# Create stargazer tables with simplified approach and error handling
create_stargazer_table <- function(models, filename, type_output) {
  tryCatch({
    stargazer(models[[1]], models[[2]], models[[3]], models[[4]],
              title = "Change in Remittances Models",
              dep.var.labels = "Change in Remittances (Thousands USD)",
              covariate.labels = c("Change in Sending GDP per Capita", 
                                  "Change in Receiving GDP per Capita",
                                  "Lagged Change in Sending GDP per Capita",
                                  "Lagged Change in Receiving GDP per Capita"),
              column.labels = c("Contemp. w/ Outliers", "Contemp. w/o Outliers", 
                               "Lagged w/ Outliers", "Lagged w/o Outliers"),
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

# Try creating stargazer tables
models_list <- list(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers)

# Text version
create_stargazer_table(models_list, file.path(output_dir, "change_models_results.txt"), "text")

# HTML version
create_stargazer_table(models_list, file.path(output_dir, "change_models_results.html"), "html")

# LaTeX version
create_stargazer_table(models_list, file.path(output_dir, "change_models_results.tex"), "latex")

# Alternative: Create manual HTML table if stargazer fails
create_manual_html <- function() {
  # Get model statistics
  models <- list(model1_with_outliers, model2_no_outliers, model3_lagged_with_outliers, model4_lagged_no_outliers)
  
  html_content <- paste0(
    '<!DOCTYPE html>\n',
    '<html>\n<head>\n<title>Change in Remittances Models</title>\n',
    '<style>\n',
    'table { border-collapse: collapse; margin: 20px auto; }\n',
    'th, td { border: 1px solid black; padding: 8px; text-align: center; }\n',
    'th { background-color: #f2f2f2; }\n',
    '.model-header { background-color: #e6f3ff; }\n',
    '</style>\n</head>\n<body>\n',
    '<h2 style="text-align: center;">Change in Remittances Models</h2>\n',
    '<table>\n'
  )
  
  # Table headers
  html_content <- paste0(html_content,
    '<tr>\n',
    '<th></th>\n',
    '<th class="model-header">Model 1<br>Contemp. w/ Outliers</th>\n',
    '<th class="model-header">Model 2<br>Contemp. w/o Outliers</th>\n',
    '<th class="model-header">Model 3<br>Lagged w/ Outliers</th>\n',
    '<th class="model-header">Model 4<br>Lagged w/o Outliers</th>\n',
    '</tr>\n'
  )
  
  # Coefficients
  coef1 <- summary(model1_with_outliers)$coefficients
  coef2 <- summary(model2_no_outliers)$coefficients
  coef3 <- summary(model3_lagged_with_outliers)$coefficients
  coef4 <- summary(model4_lagged_no_outliers)$coefficients
  
  # Change in Sending GDP per Capita
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>Change in Sending GDP per Capita</strong></td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef1[2,1], coef1[2,2]), '</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef2[2,1], coef2[2,2]), '</td>\n',
    '<td>-</td>\n<td>-</td>\n</tr>\n'
  )
  
  # Change in Receiving GDP per Capita
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>Change in Receiving GDP per Capita</strong></td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef1[3,1], coef1[3,2]), '</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef2[3,1], coef2[3,2]), '</td>\n',
    '<td>-</td>\n<td>-</td>\n</tr>\n'
  )
  
  # Lagged variables
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>Lagged Change in Sending GDP per Capita</strong></td>\n',
    '<td>-</td>\n<td>-</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef3[2,1], coef3[2,2]), '</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef4[2,1], coef4[2,2]), '</td>\n</tr>\n'
  )
  
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>Lagged Change in Receiving GDP per Capita</strong></td>\n',
    '<td>-</td>\n<td>-</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef3[3,1], coef3[3,2]), '</td>\n',
    '<td>', sprintf("%.4f<br>(%.4f)", coef4[3,1], coef4[3,2]), '</td>\n</tr>\n'
  )
  
  # R-squared and observations
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>R-squared</strong></td>\n',
    '<td>', sprintf("%.4f", summary(model1_with_outliers)$r.squared), '</td>\n',
    '<td>', sprintf("%.4f", summary(model2_no_outliers)$r.squared), '</td>\n',
    '<td>', sprintf("%.4f", summary(model3_lagged_with_outliers)$r.squared), '</td>\n',
    '<td>', sprintf("%.4f", summary(model4_lagged_no_outliers)$r.squared), '</td>\n</tr>\n'
  )
  
  html_content <- paste0(html_content,
    '<tr>\n<td><strong>Observations</strong></td>\n',
    '<td>', nobs(model1_with_outliers), '</td>\n',
    '<td>', nobs(model2_no_outliers), '</td>\n',
    '<td>', nobs(model3_lagged_with_outliers), '</td>\n',
    '<td>', nobs(model4_lagged_no_outliers), '</td>\n</tr>\n'
  )
  
  html_content <- paste0(html_content,
    '</table>\n',
    '<p style="text-align: center; font-size: 12px;">',
    'Standard errors in parentheses. Dependent variable: Change in Remittances (Thousands USD)',
    '</p>\n</body>\n</html>'
  )
  
  writeLines(html_content, file.path(output_dir, "change_models_manual.html"))
  cat("Manual HTML table created: change_models_manual.html\n")
}

# Create manual HTML table as backup
create_manual_html()

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
cat("- detailed_results.txt (complete model summaries)\n")
cat("- change_models_results.txt/html/tex (stargazer output if successful)\n")
cat("- change_models_manual.html (manual HTML table as backup)\n")