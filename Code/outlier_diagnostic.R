# Diagnostic script to check outlier detection

library(dplyr)

# Load and process data like in the script
df <- read.csv('29.csv', stringsAsFactors = FALSE)
df$Value <- as.numeric(gsub(',', '', df$Value))
df <- df[!is.na(df$Value) & !is.na(df$Sending_Country_GDP_Per_Capita) & !is.na(df$Receiving_Country_GDP_Per_Capita), ]
df <- df[df$Value > 0 & df$Sending_Country_GDP_Per_Capita > 0 & df$Receiving_Country_GDP_Per_Capita > 0, ]
df <- df[order(df$Sending_Country, df$Receiving_Country, df$Year), ]

df <- df %>% 
  group_by(Sending_Country, Receiving_Country) %>% 
  arrange(Year) %>% 
  mutate(
    Sending_Country_GDP_Per_Capita_lag1 = lag(Sending_Country_GDP_Per_Capita, 1),
    Receiving_Country_GDP_Per_Capita_lag1 = lag(Receiving_Country_GDP_Per_Capita, 1)
  ) %>% 
  ungroup()

df <- df[!is.na(df$Sending_Country_GDP_Per_Capita_lag1) & !is.na(df$Receiving_Country_GDP_Per_Capita_lag1), ]
df <- df[df$Sending_Country_GDP_Per_Capita_lag1 > 0 & df$Receiving_Country_GDP_Per_Capita_lag1 > 0, ]

df$remittance_millions <- df$Value
df$log_remittance <- log(df$remittance_millions)

cat("Data processing completed. Observations:", nrow(df), "\n")

# Check outlier detection
Q1 <- quantile(df$log_remittance, 0.25, na.rm = TRUE)
Q3 <- quantile(df$log_remittance, 0.75, na.rm = TRUE)
IQR_val <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR_val
upper_bound <- Q3 + 1.5 * IQR_val

cat('\nLog remittance summary:\n')
print(summary(df$log_remittance))

cat('\nOutlier bounds:\n')
cat('Q1:', Q1, '\n')
cat('Q3:', Q3, '\n')
cat('IQR:', IQR_val, '\n')
cat('Lower bound:', lower_bound, '\n')
cat('Upper bound:', upper_bound, '\n')
cat('Min log_remittance:', min(df$log_remittance), '\n')
cat('Max log_remittance:', max(df$log_remittance), '\n')

# Count outliers
outliers <- df$log_remittance < lower_bound | df$log_remittance > upper_bound
cat('\nNumber of outliers detected:', sum(outliers), '\n')
cat('Percentage of outliers:', round(100 * sum(outliers) / nrow(df), 2), '%\n')

# Show some extreme values
cat('\nLowest 10 log_remittance values:\n')
print(sort(df$log_remittance)[1:10])

cat('\nHighest 10 log_remittance values:\n')
print(sort(df$log_remittance, decreasing = TRUE)[1:10])

# Check if bounds are too wide
cat('\nIs the data within bounds?\n')
cat('All values >= lower_bound:', all(df$log_remittance >= lower_bound), '\n')
cat('All values <= upper_bound:', all(df$log_remittance <= upper_bound), '\n')

# Alternative outlier detection with stricter criteria
cat('\nTrying stricter outlier detection (1.0 * IQR instead of 1.5):\n')
lower_bound_strict <- Q1 - 1.0 * IQR_val
upper_bound_strict <- Q3 + 1.0 * IQR_val
outliers_strict <- df$log_remittance < lower_bound_strict | df$log_remittance > upper_bound_strict
cat('Stricter outliers detected:', sum(outliers_strict), '\n')
cat('Stricter percentage:', round(100 * sum(outliers_strict) / nrow(df), 2), '%\n')