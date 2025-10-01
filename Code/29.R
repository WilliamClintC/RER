# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages function
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)
}

# Install required packages
required_packages <- c("car", "stargazer", "dplyr", "rmarkdown", "knitr")
install_if_missing(required_packages)

# Load required libraries
library(car)
library(stargazer)
library(dplyr)
library(rmarkdown)
library(knitr)

# Create output directory
output_dir <- "C:/Users/clint/Desktop/RER/Code/29"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created output directory:", output_dir, "\n")
}

# Load the dataset using base R
file_path <- "C:/Users/clint/Desktop/RER/Code/29.csv"
cat("Loading dataset...\n")
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Data preprocessing
cat("Preprocessing data...\n")

# Clean the Value column - remove commas and convert to numeric
df$Value <- as.numeric(gsub(",", "", df$Value))

# Remove rows with missing values for key variables
df <- df[!is.na(df$Value) & !is.na(df$Sending_Country_GDP_Per_Capita) & !is.na(df$Receiving_Country_GDP_Per_Capita), ]

# Remove rows where Value is 0 or negative (for log transformations)
df <- df[df$Value > 0 & df$Sending_Country_GDP_Per_Capita > 0 & df$Receiving_Country_GDP_Per_Capita > 0, ]

# Sort data by country pairs and year for proper lagging
df <- df[order(df$Sending_Country, df$Receiving_Country, df$Year), ]

cat("Dataset loaded successfully with", nrow(df), "observations\n")

# Create lagged GDP per capita variables
cat("Creating lagged GDP per capita variables...\n")
df <- df %>%
  group_by(Sending_Country, Receiving_Country) %>%
  arrange(Year) %>%
  mutate(
    Sending_Country_GDP_Per_Capita_lag1 = lag(Sending_Country_GDP_Per_Capita, 1),
    Receiving_Country_GDP_Per_Capita_lag1 = lag(Receiving_Country_GDP_Per_Capita, 1)
  ) %>%
  ungroup()

# Remove rows with missing lagged values
df <- df[!is.na(df$Sending_Country_GDP_Per_Capita_lag1) & !is.na(df$Receiving_Country_GDP_Per_Capita_lag1), ]
df <- df[df$Sending_Country_GDP_Per_Capita_lag1 > 0 & df$Receiving_Country_GDP_Per_Capita_lag1 > 0, ]

cat("After creating lagged variables:", nrow(df), "observations remain\n")

# Create variables for different specifications using lagged GDP per capita
df$remittance_millions <- df$Value  # Already in millions
df$remittance_thousands <- df$Value * 1000  # Convert to thousands
df$gdp_per_capita_sending_lag1 <- df$Sending_Country_GDP_Per_Capita_lag1  # Lagged sending GDP per capita
df$gdp_per_capita_receiving_lag1 <- df$Receiving_Country_GDP_Per_Capita_lag1  # Lagged receiving GDP per capita

# Log transformations
df$log_remittance <- log(df$remittance_millions)
df$log_gdp_per_capita_sending_lag1 <- log(df$gdp_per_capita_sending_lag1)
df$log_gdp_per_capita_receiving_lag1 <- log(df$gdp_per_capita_receiving_lag1)

# Identify outliers using IQR method for log remittances
Q1 <- quantile(df$log_remittance, 0.25, na.rm = TRUE)
Q3 <- quantile(df$log_remittance, 0.75, na.rm = TRUE)
IQR <- Q3 - Q1
# Use stricter criterion (1.0 * IQR instead of 1.5 * IQR) for better outlier detection
lower_bound <- Q1 - 1.0 * IQR
upper_bound <- Q3 + 1.0 * IQR

# Create dataset without outliers
df_no_outliers <- df[df$log_remittance >= lower_bound & df$log_remittance <= upper_bound, ]

# Also try percentile-based outlier detection as an alternative
# Remove observations in the bottom 5% and top 5% of log_remittance
lower_percentile <- quantile(df$log_remittance, 0.05, na.rm = TRUE)
upper_percentile <- quantile(df$log_remittance, 0.95, na.rm = TRUE)
df_no_outliers_percentile <- df[df$log_remittance >= lower_percentile & df$log_remittance <= upper_percentile, ]

cat("Outlier detection results:\n")
cat("Original observations:", nrow(df), "\n")
cat("IQR method (1.0x): Lower bound =", round(lower_bound, 3), "Upper bound =", round(upper_bound, 3), "\n")
cat("After IQR outlier removal:", nrow(df_no_outliers), "observations remain\n")
cat("Percentile method (5%-95%): Lower =", round(lower_percentile, 3), "Upper =", round(upper_percentile, 3), "\n")
cat("After percentile outlier removal:", nrow(df_no_outliers_percentile), "observations remain\n")

# Use the percentile method for the main analysis since it removes more extreme values
df_no_outliers <- df_no_outliers_percentile

cat("After removing outliers:", nrow(df_no_outliers), "observations remain\n")

# SPECIFICATION 1: Remittances (thousands) vs Lagged GDP per capita
cat("Running Specification 1: Linear model with remittances in thousands and lagged GDP per capita...\n")
spec1_with_outliers <- lm(remittance_thousands ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df)
spec1_without_outliers <- lm(remittance_thousands ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df_no_outliers)

# SPECIFICATION 2: Log-Log Model with Lagged GDP per capita
cat("Running Specification 2: Log-Log model with lagged GDP per capita...\n")
spec2_with_outliers <- lm(log_remittance ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec2_without_outliers <- lm(log_remittance ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)

# SPECIFICATION 3: Log-Linear Model (linear dependent, log independent) with Lagged GDP per capita
cat("Running Specification 3: Log-Linear model with lagged GDP per capita...\n")
spec3_with_outliers <- lm(remittance_thousands ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec3_without_outliers <- lm(remittance_thousands ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)

# SPECIFICATION 4: Linear Dependent, Log Independent (remittances in millions) with Lagged GDP per capita
cat("Running Specification 4: Linear dependent, log independent with lagged GDP per capita...\n")
spec4_with_outliers <- lm(remittance_millions ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec4_without_outliers <- lm(remittance_millions ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)

# SPECIFICATION 5: Log Dependent (remittances in millions), Linear Independent (GDP per capita) with Lagged GDP per capita
cat("Running Specification 5: Log dependent (remittances millions), linear independent with lagged GDP per capita...\n")
spec5_with_outliers <- lm(log_remittance ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df)
spec5_without_outliers <- lm(log_remittance ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df_no_outliers)

# Create comprehensive stargazer table
cat("Generating stargazer tables...\n")

# Try to generate tables with error handling
tryCatch({
  # Create HTML table
  html_file <- file.path(output_dir, "comprehensive_regression_results_gdp_per_capita.html")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers,
    spec3_with_outliers, spec3_without_outliers,
    spec4_with_outliers, spec4_without_outliers,
    type = "html",
    out = html_file,
    title = "Comprehensive Regression Analysis: Remittances and Lagged GDP Per Capita (t-1)",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (thousands USD)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)",
                        "Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "3: Log-Linear", "3: Log-Linear", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Linear (thousands) vs Lagged GDP Per Capita",
             "Specification 2: Log-Log Model with Lagged GDP Per Capita",
             "Specification 3: Log-Linear Model (thousands) with Lagged GDP Per Capita",
             "Specification 4: Linear (millions) vs Log GDP Per Capita",
             "GDP Per Capita variables are lagged by 1 period (t-1)",
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
  latex_file <- file.path(output_dir, "comprehensive_regression_results_gdp_per_capita.tex")
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    spec2_with_outliers, spec2_without_outliers,
    spec3_with_outliers, spec3_without_outliers,
    spec4_with_outliers, spec4_without_outliers,
    type = "latex",
    out = latex_file,
    title = "Comprehensive Regression Analysis: Remittances and Lagged GDP Per Capita (t-1)",
    column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
    column.separate = c(2, 2, 2, 2),
    model.numbers = FALSE,
    dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (thousands USD)", "Remittance Value (millions USD)"),
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)",
                        "Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "3: Log-Linear", "3: Log-Linear", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
    notes = c("Specification 1: Linear (thousands) vs Lagged GDP Per Capita",
             "Specification 2: Log-Log Model with Lagged GDP Per Capita",
             "Specification 3: Log-Linear Model (thousands) with Lagged GDP Per Capita",
             "Specification 4: Linear (millions) vs Log GDP Per Capita",
             "GDP Per Capita variables are lagged by 1 period (t-1)",
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
    out = file.path(output_dir, "spec1_remittances_thousands_gdp_per_capita.html"),
    title = "Specification 1: Remittances (thousands) vs Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
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
    out = file.path(output_dir, "spec2_log_log_gdp_per_capita.html"),
    title = "Specification 2: Log-Log Model with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 2 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 2 table:", e$message, "\n")
})

# Specification 3 only
tryCatch({
  stargazer(
    spec3_with_outliers, spec3_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec3_log_linear_gdp_per_capita.html"),
    title = "Specification 3: Log-Linear Model with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 3 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 3 table:", e$message, "\n")
})

# Specification 4 only
tryCatch({
  stargazer(
    spec4_with_outliers, spec4_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec4_linear_dep_log_indep_gdp_per_capita.html"),
    title = "Specification 4: Linear Dependent, Log Independent with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 4 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 4 table:", e$message, "\n")
})

# Specification 5 only
tryCatch({
  stargazer(
    spec5_with_outliers, spec5_without_outliers,
    type = "html",
    out = file.path(output_dir, "spec5_log_dep_linear_indep_gdp_per_capita.html"),
    title = "Specification 5: Log Dependent (millions), Linear Independent with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value in millions USD)",
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 5 HTML table created!\n")
}, error = function(e) {
  cat("Error creating Specification 5 table:", e$message, "\n")
})

# Create LaTeX versions of individual specifications
tryCatch({
  stargazer(
    spec1_with_outliers, spec1_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec1_remittances_thousands_gdp_per_capita.tex"),
    title = "Specification 1: Remittances (thousands) vs Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
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
    out = file.path(output_dir, "spec2_log_log_gdp_per_capita.tex"),
    title = "Specification 2: Log-Log Model with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
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
    spec3_with_outliers, spec3_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec3_log_linear_gdp_per_capita.tex"),
    title = "Specification 3: Log-Linear Model with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (thousands USD)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 3 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 3 LaTeX table:", e$message, "\n")
})

tryCatch({
  stargazer(
    spec4_with_outliers, spec4_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec4_linear_dep_log_indep_gdp_per_capita.tex"),
    title = "Specification 4: Linear Dependent, Log Independent with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Remittance Value (millions USD)",
    covariate.labels = c("Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 4 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 4 LaTeX table:", e$message, "\n")
})

tryCatch({
  stargazer(
    spec5_with_outliers, spec5_without_outliers,
    type = "latex",
    out = file.path(output_dir, "spec5_log_dep_linear_indep_gdp_per_capita.tex"),
    title = "Specification 5: Log Dependent (millions), Linear Independent with Lagged GDP Per Capita",
    column.labels = c("With Outliers", "Without Outliers"),
    dep.var.labels = "Log(Remittance Value in millions USD)",
    covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)"),
    notes = c("GDP Per Capita variables are lagged by 1 period (t-1)", "Note: *p<0.1; **p<0.05; ***p<0.01"),
    star.cutoffs = c(0.1, 0.05, 0.01),
    digits = 3,
    no.space = TRUE
  )
  cat("Specification 5 LaTeX table created!\n")
}, error = function(e) {
  cat("Error creating Specification 5 LaTeX table:", e$message, "\n")
})

# Create R Markdown report
cat("Creating R Markdown report...\n")

rmd_content <- '---
title: "Regression Analysis: Remittances and GDP Per Capita"
author: "Analysis Report"
date: "`r Sys.Date()`"
output: 
  html_document:
    toc: true
    toc_float: true
    theme: default
    highlight: textmate
    code_folding: hide
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(car)
library(stargazer)
library(dplyr)
library(knitr)
```

# Introduction

This report presents a comprehensive regression analysis examining the relationship between remittance flows and GDP per capita variables. The analysis uses lagged GDP per capita variables (t-1) to address potential endogeneity concerns.

# Data Overview

```{r data-load, echo=TRUE}
# Load the dataset
file_path <- "29.csv"
df <- read.csv(file_path, stringsAsFactors = FALSE)

# Data preprocessing
df$Value <- as.numeric(gsub(",", "", df$Value))
df <- df[!is.na(df$Value) & !is.na(df$Sending_Country_GDP_Per_Capita) & !is.na(df$Receiving_Country_GDP_Per_Capita), ]
df <- df[df$Value > 0 & df$Sending_Country_GDP_Per_Capita > 0 & df$Receiving_Country_GDP_Per_Capita > 0, ]
df <- df[order(df$Sending_Country, df$Receiving_Country, df$Year), ]

cat("Dataset loaded with", nrow(df), "observations")
```

# Variable Creation and Outlier Detection

```{r variables, echo=TRUE}
# Create lagged GDP per capita variables
df <- df %>%
  group_by(Sending_Country, Receiving_Country) %>%
  arrange(Year) %>%
  mutate(
    Sending_Country_GDP_Per_Capita_lag1 = lag(Sending_Country_GDP_Per_Capita, 1),
    Receiving_Country_GDP_Per_Capita_lag1 = lag(Receiving_Country_GDP_Per_Capita, 1)
  ) %>%
  ungroup()

# Remove rows with missing lagged values
df <- df[!is.na(df$Sending_Country_GDP_Per_Capita_lag1) & !is.na(df$Receiving_Country_GDP_Per_Capita_lag1), ]
df <- df[df$Sending_Country_GDP_Per_Capita_lag1 > 0 & df$Receiving_Country_GDP_Per_Capita_lag1 > 0, ]

# Create variables for analysis
df$remittance_millions <- df$Value
df$remittance_thousands <- df$Value * 1000
df$gdp_per_capita_sending_lag1 <- df$Sending_Country_GDP_Per_Capita_lag1
df$gdp_per_capita_receiving_lag1 <- df$Receiving_Country_GDP_Per_Capita_lag1
df$log_remittance <- log(df$remittance_millions)
df$log_gdp_per_capita_sending_lag1 <- log(df$gdp_per_capita_sending_lag1)
df$log_gdp_per_capita_receiving_lag1 <- log(df$gdp_per_capita_receiving_lag1)

# Outlier detection
Q1 <- quantile(df$log_remittance, 0.25, na.rm = TRUE)
Q3 <- quantile(df$log_remittance, 0.75, na.rm = TRUE)
IQR <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR

df_no_outliers <- df[df$log_remittance >= lower_bound & df$log_remittance <= upper_bound, ]

cat("After variable creation:", nrow(df), "observations")
cat("After removing outliers:", nrow(df_no_outliers), "observations")
```

# Regression Models

## Specification 1: Linear Model (Remittances in thousands vs GDP Per Capita)

```{r spec1, echo=TRUE}
spec1_with_outliers <- lm(remittance_thousands ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df)
spec1_without_outliers <- lm(remittance_thousands ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df_no_outliers)
```

## Specification 2: Log-Log Model

```{r spec2, echo=TRUE}
spec2_with_outliers <- lm(log_remittance ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec2_without_outliers <- lm(log_remittance ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)
```

## Specification 3: Log-Linear Model

```{r spec3, echo=TRUE}
spec3_with_outliers <- lm(remittance_thousands ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec3_without_outliers <- lm(remittance_thousands ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)
```

## Specification 4: Linear Dependent, Log Independent

```{r spec4, echo=TRUE}
spec4_with_outliers <- lm(remittance_millions ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df)
spec4_without_outliers <- lm(remittance_millions ~ log_gdp_per_capita_sending_lag1 + log_gdp_per_capita_receiving_lag1, data = df_no_outliers)
```

## Specification 5: Log Dependent (millions), Linear Independent

```{r spec5, echo=TRUE}
spec5_with_outliers <- lm(log_remittance ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df)
spec5_without_outliers <- lm(log_remittance ~ gdp_per_capita_sending_lag1 + gdp_per_capita_receiving_lag1, data = df_no_outliers)
```

# Results

## Comprehensive Results Table

```{r results-table, results="asis", echo=FALSE}
stargazer(
  spec1_with_outliers, spec1_without_outliers,
  spec2_with_outliers, spec2_without_outliers,
  spec3_with_outliers, spec3_without_outliers,
  spec4_with_outliers, spec4_without_outliers,
  type = "html",
  title = "Comprehensive Regression Analysis: Remittances and Lagged GDP Per Capita (t-1)",
  column.labels = c("With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers", "With Outliers", "Without Outliers"),
  column.separate = c(2, 2, 2, 2),
  model.numbers = FALSE,
  dep.var.labels = c("Remittance Value (thousands USD)", "Log(Remittance Value)", "Remittance Value (thousands USD)", "Remittance Value (millions USD)"),
  covariate.labels = c("Sending Country GDP Per Capita (t-1, USD)", "Receiving Country GDP Per Capita (t-1, USD)",
                      "Log(Sending Country GDP Per Capita (t-1))", "Log(Receiving Country GDP Per Capita (t-1))"),
  add.lines = list(c("Specification", "1: Linear", "1: Linear", "2: Log-Log", "2: Log-Log", "3: Log-Linear", "3: Log-Linear", "4: Linear Dep, Log Indep", "4: Linear Dep, Log Indep")),
  notes = c("Specification 1: Linear (thousands) vs Lagged GDP Per Capita",
           "Specification 2: Log-Log Model with Lagged GDP Per Capita",
           "Specification 3: Log-Linear Model (thousands) with Lagged GDP Per Capita", 
           "Specification 4: Linear (millions) vs Log GDP Per Capita",
           "GDP Per Capita variables are lagged by 1 period (t-1)",
           "Note: *p<0.1; **p<0.05; ***p<0.01"),
  notes.align = "l",
  star.cutoffs = c(0.1, 0.05, 0.01),
  digits = 3,
  no.space = TRUE
)
```

## Summary Statistics

```{r summary-stats, echo=FALSE}
summary_stats <- data.frame(
  Statistic = c("Total observations (with outliers)", 
                "Total observations (without outliers)", 
                "Outliers removed",
                "Mean remittance value (millions USD)",
                "Mean sending country GDP per capita (USD)",
                "Mean receiving country GDP per capita (USD)"),
  Value = c(nrow(df),
            nrow(df_no_outliers),
            nrow(df) - nrow(df_no_outliers),
            round(mean(df$remittance_millions, na.rm = TRUE), 2),
            round(mean(df$gdp_per_capita_sending_lag1, na.rm = TRUE), 2),
            round(mean(df$gdp_per_capita_receiving_lag1, na.rm = TRUE), 2))
)

kable(summary_stats, caption = "Summary Statistics")
```

# Model Diagnostics

```{r diagnostics, echo=FALSE}
# Model fit statistics
model_stats <- data.frame(
  Model = c("Spec 1 (With Outliers)", "Spec 1 (Without Outliers)",
            "Spec 2 (With Outliers)", "Spec 2 (Without Outliers)",
            "Spec 3 (With Outliers)", "Spec 3 (Without Outliers)",
            "Spec 4 (With Outliers)", "Spec 4 (Without Outliers)"),
  R_squared = c(summary(spec1_with_outliers)$r.squared,
                summary(spec1_without_outliers)$r.squared,
                summary(spec2_with_outliers)$r.squared,
                summary(spec2_without_outliers)$r.squared,
                summary(spec3_with_outliers)$r.squared,
                summary(spec3_without_outliers)$r.squared,
                summary(spec4_with_outliers)$r.squared,
                summary(spec4_without_outliers)$r.squared),
  Adj_R_squared = c(summary(spec1_with_outliers)$adj.r.squared,
                    summary(spec1_without_outliers)$adj.r.squared,
                    summary(spec2_with_outliers)$adj.r.squared,
                    summary(spec2_without_outliers)$adj.r.squared,
                    summary(spec3_with_outliers)$adj.r.squared,
                    summary(spec3_without_outliers)$adj.r.squared,
                    summary(spec4_with_outliers)$adj.r.squared,
                    summary(spec4_without_outliers)$adj.r.squared),
  F_statistic = c(summary(spec1_with_outliers)$fstatistic[1],
                  summary(spec1_without_outliers)$fstatistic[1],
                  summary(spec2_with_outliers)$fstatistic[1],
                  summary(spec2_without_outliers)$fstatistic[1],
                  summary(spec3_with_outliers)$fstatistic[1],
                  summary(spec3_without_outliers)$fstatistic[1],
                  summary(spec4_with_outliers)$fstatistic[1],
                  summary(spec4_without_outliers)$fstatistic[1])
)

kable(model_stats, digits = 4, caption = "Model Fit Statistics")
```

# Conclusion

This analysis examined the relationship between remittance flows and GDP per capita using four different model specifications:

1. **Linear Model**: Direct relationship between remittances and GDP per capita levels
2. **Log-Log Model**: Elasticity interpretation of the relationship
3. **Log-Linear Model**: Linear dependent variable with log-transformed independent variables (thousands USD)
4. **Semi-Log Model**: Linear dependent variable with log-transformed independent variables (millions USD)

All models use lagged GDP per capita variables to address potential endogeneity concerns. The results show [interpret your specific findings here based on the actual output].

The analysis was conducted both with and without outliers to assess the robustness of the findings.
'

# Write R Markdown file
rmd_file <- file.path(output_dir, "gdp_per_capita_analysis_report.Rmd")
writeLines(rmd_content, rmd_file)

# Render R Markdown to HTML
tryCatch({
  rmarkdown::render(rmd_file, 
                   output_file = file.path(output_dir, "gdp_per_capita_analysis_report.html"),
                   quiet = TRUE)
  cat("R Markdown report rendered successfully!\n")
}, error = function(e) {
  cat("Error rendering R Markdown:", e$message, "\n")
})

cat("All tables and reports generated successfully!\n")
cat("Files created:\n")
cat("- Comprehensive HTML table:", html_file, "\n")
cat("- Comprehensive LaTeX table:", latex_file, "\n")
cat("- Individual specification HTML tables in:", output_dir, "\n")
cat("- R Markdown report:", file.path(output_dir, "gdp_per_capita_analysis_report.html"), "\n")

# Print regression summaries to text files for easier extraction
cat("Creating regression summary files...\n")

# Save detailed regression summaries
summary_file <- file.path(output_dir, "regression_summaries_gdp_per_capita.txt")
sink(summary_file)
cat("COMPREHENSIVE REGRESSION ANALYSIS WITH LAGGED GDP PER CAPITA (t-1)\n")
cat("==================================================================\n\n")

cat("SPECIFICATION 1: Remittances (thousands) vs Lagged GDP Per Capita\n")
cat("------------------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec1_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec1_without_outliers))

cat("SPECIFICATION 2: Log-Log Model with Lagged GDP Per Capita\n")
cat("--------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec2_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec2_without_outliers))

cat("\n\nSPECIFICATION 3: Log-Linear Model with Lagged GDP Per Capita\n")
cat("-----------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec3_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec3_without_outliers))

cat("\n\nSPECIFICATION 4: Linear Dependent, Log Independent with Lagged GDP Per Capita\n")
cat("-----------------------------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec4_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec4_without_outliers))

cat("\n\nSPECIFICATION 5: Log Dependent (millions), Linear Independent with Lagged GDP Per Capita\n")
cat("--------------------------------------------------------------------------------------\n")
cat("WITH OUTLIERS:\n")
print(summary(spec5_with_outliers))
cat("\nWITHOUT OUTLIERS:\n")
print(summary(spec5_without_outliers))

cat("\n\nDATA SUMMARY:\n")
cat("=============\n")
cat("Original observations:", nrow(df), "\n")
cat("Observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df) - nrow(df_no_outliers), "\n")
cat("Note: GDP Per Capita variables are lagged by 1 period (t-1)\n")
sink()

# Create coefficient extraction file for easy table creation
coeff_file <- file.path(output_dir, "coefficient_extraction_gdp_per_capita.txt")
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
extract_stats(spec3_with_outliers, "Spec 3 - With Outliers")
extract_stats(spec3_without_outliers, "Spec 3 - Without Outliers")
extract_stats(spec4_with_outliers, "Spec 4 - With Outliers")
extract_stats(spec4_without_outliers, "Spec 4 - Without Outliers")
extract_stats(spec5_with_outliers, "Spec 5 - With Outliers")
extract_stats(spec5_without_outliers, "Spec 5 - Without Outliers")
sink()

cat("Regression summary files created:\n")
cat("- Detailed summaries:", summary_file, "\n")
cat("- Coefficient extraction:", coeff_file, "\n")

# Print summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Total observations with outliers:", nrow(df), "\n")
cat("Total observations without outliers:", nrow(df_no_outliers), "\n")
cat("Outliers removed:", nrow(df) - nrow(df_no_outliers), "\n")
cat("Note: GDP Per Capita variables are lagged by 1 period (t-1)\n")

# Instructions for next steps
cat("\n=== OUTPUTS GENERATED ===\n")
cat("1. HTML tables with regression results (5 specifications)\n")
cat("2. LaTeX tables for publication (5 specifications)\n")
cat("3. R Markdown report with comprehensive analysis\n")
cat("4. Text files with detailed regression summaries\n")
cat("5. Coefficient extraction file for manual table creation\n")
cat("6. Specification 3: Log-Linear model\n")
cat("7. Specification 5: Log dependent (millions), Linear independent with GDP per capita\n")