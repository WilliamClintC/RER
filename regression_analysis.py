import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

def main():
    # Load the dataset
    file_path = r'C:\Users\clint\Desktop\RER\Code\22.csv'
    print("Loading dataset...")
    df = pd.read_csv(file_path)
    
    # Display basic information about the dataset
    print("Dataset shape:", df.shape)
    print("\nFirst few rows:")
    print(df.head())
    print("\nColumn names:")
    print(df.columns.tolist())
    
    # Clean the Value column (remove commas and convert to numeric)
    print("\nCleaning data...")
    df['Value_cleaned'] = df['Value'].astype(str).str.replace(',', '').str.replace('"', '')
    df['Value_cleaned'] = pd.to_numeric(df['Value_cleaned'], errors='coerce')
    
    # Check for missing values in our key variables
    print("\nMissing values:")
    print("Value_cleaned:", df['Value_cleaned'].isna().sum())
    print("Sending_Country_GDP:", df['Sending_Country_GDP'].isna().sum())
    print("Receiving_Country_GDP:", df['Receiving_Country_GDP'].isna().sum())
    
    # Remove rows with missing values in our regression variables
    regression_data = df.dropna(subset=['Value_cleaned', 'Sending_Country_GDP', 'Receiving_Country_GDP'])
    print(f"\nDataset after removing missing values: {regression_data.shape[0]} rows")
    
    # Display summary statistics
    print("\nSummary statistics for regression variables:")
    print(regression_data[['Value_cleaned', 'Sending_Country_GDP', 'Receiving_Country_GDP']].describe())
    
    # Prepare the regression variables
    X = regression_data[['Sending_Country_GDP', 'Receiving_Country_GDP']]
    y = regression_data['Value_cleaned']
    
    # Fit the linear regression model
    print("\nFitting regression model...")
    model = LinearRegression()
    model.fit(X, y)
    
    # Make predictions
    y_pred = model.predict(X)
    
    # Calculate R-squared
    r2 = r2_score(y, y_pred)
    
    # Display regression results
    print("\n" + "="*60)
    print("LINEAR REGRESSION RESULTS")
    print("="*60)
    print(f"Dependent Variable: Value")
    print(f"Independent Variables: Sending_Country_GDP, Receiving_Country_GDP")
    print(f"Number of observations: {len(y)}")
    print(f"R-squared: {r2:.4f}")
    print(f"Adjusted R-squared: {1 - (1 - r2) * (len(y) - 1) / (len(y) - X.shape[1] - 1):.4f}")
    print("\nCoefficients:")
    print(f"Intercept: {model.intercept_:.6f}")
    print(f"Sending_Country_GDP: {model.coef_[0]:.6f}")
    print(f"Receiving_Country_GDP: {model.coef_[1]:.6f}")
    
    # Calculate residuals
    residuals = y - y_pred
    print(f"\nModel Performance:")
    print(f"Residual Sum of Squares: {np.sum(residuals**2):.2f}")
    print(f"Mean Squared Error: {np.mean(residuals**2):.2f}")
    print(f"Root Mean Squared Error: {np.sqrt(np.mean(residuals**2)):.2f}")
    
    # Statistical significance testing
    n = len(y)
    k = X.shape[1]
    dof = n - k - 1
    
    # Calculate standard errors
    mse = np.sum(residuals**2) / dof
    X_with_intercept = np.column_stack([np.ones(n), X])
    
    try:
        cov_matrix = mse * np.linalg.inv(X_with_intercept.T @ X_with_intercept)
        std_errors = np.sqrt(np.diag(cov_matrix))
        
        # Calculate t-statistics
        coefficients = np.array([model.intercept_, model.coef_[0], model.coef_[1]])
        t_stats = coefficients / std_errors
        p_values = 2 * (1 - stats.t.cdf(np.abs(t_stats), dof))
        
        print("\n" + "="*60)
        print("STATISTICAL SIGNIFICANCE")
        print("="*60)
        print(f"{'Variable':<25} {'Coefficient':<15} {'Std Error':<15} {'t-stat':<10} {'p-value':<10}")
        print("-" * 75)
        print(f"{'Intercept':<25} {coefficients[0]:<15.6f} {std_errors[0]:<15.6f} {t_stats[0]:<10.3f} {p_values[0]:<10.3f}")
        print(f"{'Sending_Country_GDP':<25} {coefficients[1]:<15.6f} {std_errors[1]:<15.6f} {t_stats[1]:<10.3f} {p_values[1]:<10.3f}")
        print(f"{'Receiving_Country_GDP':<25} {coefficients[2]:<15.6f} {std_errors[2]:<15.6f} {t_stats[2]:<10.3f} {p_values[2]:<10.3f}")
        
        # F-statistic for overall model significance
        ssr = np.sum((y_pred - np.mean(y))**2)
        sse = np.sum(residuals**2)
        f_stat = (ssr / k) / (sse / dof)
        f_p_value = 1 - stats.f.cdf(f_stat, k, dof)
        
        print(f"\nOVERALL MODEL SIGNIFICANCE:")
        print(f"F-statistic: {f_stat:.3f}")
        print(f"p-value: {f_p_value:.6f}")
        
        # Print interpretation
        print("\n" + "="*60)
        print("INTERPRETATION")
        print("="*60)
        print(f"The regression equation is:")
        print(f"Value = {model.intercept_:.6f} + {model.coef_[0]:.6f} * Sending_Country_GDP + {model.coef_[1]:.6f} * Receiving_Country_GDP")
        print(f"\nThe model explains {r2*100:.2f}% of the variance in the Value variable.")
        print(f"\nStatistical significance (p < 0.05):")
        print(f"- Sending_Country_GDP: {'Significant' if p_values[1] < 0.05 else 'Not significant'} (p = {p_values[1]:.6f})")
        print(f"- Receiving_Country_GDP: {'Significant' if p_values[2] < 0.05 else 'Not significant'} (p = {p_values[2]:.6f})")
        
    except np.linalg.LinAlgError:
        print("\nWarning: Could not calculate standard errors due to multicollinearity issues.")
        print("The regression coefficients are still valid.")
    
    # Create and save visualizations
    plt.figure(figsize=(15, 10))
    
    # 1. Actual vs Predicted values
    plt.subplot(2, 3, 1)
    plt.scatter(y, y_pred, alpha=0.6)
    plt.plot([y.min(), y.max()], [y.min(), y.max()], 'r--', lw=2)
    plt.xlabel('Actual Values')
    plt.ylabel('Predicted Values')
    plt.title('Actual vs Predicted Values')
    plt.grid(True, alpha=0.3)
    
    # 2. Residual plot
    plt.subplot(2, 3, 2)
    plt.scatter(y_pred, residuals, alpha=0.6)
    plt.axhline(y=0, color='r', linestyle='--')
    plt.xlabel('Predicted Values')
    plt.ylabel('Residuals')
    plt.title('Residual Plot')
    plt.grid(True, alpha=0.3)
    
    # 3. Q-Q plot for residuals normality
    plt.subplot(2, 3, 3)
    stats.probplot(residuals, dist="norm", plot=plt)
    plt.title('Q-Q Plot of Residuals')
    plt.grid(True, alpha=0.3)
    
    # 4. Distribution of residuals
    plt.subplot(2, 3, 4)
    plt.hist(residuals, bins=30, density=True, alpha=0.7, edgecolor='black')
    plt.xlabel('Residuals')
    plt.ylabel('Density')
    plt.title('Distribution of Residuals')
    plt.grid(True, alpha=0.3)
    
    # 5. Value vs Sending Country GDP
    plt.subplot(2, 3, 5)
    plt.scatter(regression_data['Sending_Country_GDP'], regression_data['Value_cleaned'], alpha=0.6)
    plt.xlabel('Sending Country GDP')
    plt.ylabel('Value')
    plt.title('Value vs Sending Country GDP')
    plt.grid(True, alpha=0.3)
    
    # 6. Value vs Receiving Country GDP
    plt.subplot(2, 3, 6)
    plt.scatter(regression_data['Receiving_Country_GDP'], regression_data['Value_cleaned'], alpha=0.6)
    plt.xlabel('Receiving Country GDP')
    plt.ylabel('Value')
    plt.title('Value vs Receiving Country GDP')
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(r'C:\Users\clint\Desktop\RER\regression_plots.png', dpi=300, bbox_inches='tight')
    print(f"\nPlots saved to: C:\\Users\\clint\\Desktop\\RER\\regression_plots.png")
    plt.show()

if __name__ == "__main__":
    main()