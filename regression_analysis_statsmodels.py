import pandas as pd
import numpy as np
import statsmodels.api as sm
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from statsmodels.stats.diagnostic import het_white
from statsmodels.stats.outliers_influence import variance_inflation_factor

def main():
    # Load the dataset
    file_path = r'C:\Users\clint\Desktop\RER\Code\22.csv'
    print("Loading dataset...")
    df = pd.read_csv(file_path)
    
    # Display basic information
    print("Dataset shape:", df.shape)
    print("\nFirst few rows:")
    print(df.head())
    
    # Clean the Value column
    print("\nCleaning data...")
    df['Value_cleaned'] = df['Value'].astype(str).str.replace(',', '').str.replace('"', '')
    df['Value_cleaned'] = pd.to_numeric(df['Value_cleaned'], errors='coerce')
    
    # Check for missing values
    print("\nMissing values:")
    print("Value_cleaned:", df['Value_cleaned'].isna().sum())
    print("Sending_Country_GDP:", df['Sending_Country_GDP'].isna().sum())
    print("Receiving_Country_GDP:", df['Receiving_Country_GDP'].isna().sum())
    
    # Remove rows with missing values
    regression_data = df.dropna(subset=['Value_cleaned', 'Sending_Country_GDP', 'Receiving_Country_GDP'])
    print(f"\nDataset after removing missing values: {regression_data.shape[0]} rows")
    
    # Summary statistics
    print("\nSummary statistics:")
    print(regression_data[['Value_cleaned', 'Sending_Country_GDP', 'Receiving_Country_GDP']].describe())
    
    # Prepare variables for regression
    y = regression_data['Value_cleaned']
    X = regression_data[['Sending_Country_GDP', 'Receiving_Country_GDP']]
    
    # Add constant term (intercept)
    X = sm.add_constant(X)
    
    # Fit the regression model using OLS
    print("\nFitting OLS regression model...")
    model = sm.OLS(y, X).fit()
    
    # Print comprehensive results (R-style output)
    print("\n" + "="*80)
    print("ORDINARY LEAST SQUARES REGRESSION RESULTS")
    print("="*80)
    print(model.summary())
    
    # Additional diagnostics
    print("\n" + "="*80)
    print("ADDITIONAL DIAGNOSTIC TESTS")
    print("="*80)
    
    # Variance Inflation Factor (VIF) for multicollinearity
    print("\nVariance Inflation Factors:")
    vif_data = pd.DataFrame()
    vif_data["Variable"] = X.columns[1:]  # Exclude constant
    vif_data["VIF"] = [variance_inflation_factor(X.values, i) for i in range(1, X.shape[1])]
    print(vif_data)
    
    if any(vif_data["VIF"] > 5):
        print("Warning: High multicollinearity detected (VIF > 5)")
    else:
        print("No serious multicollinearity issues (all VIF < 5)")
    
    # White's test for heteroscedasticity
    try:
        white_test = het_white(model.resid, model.model.exog)
        print(f"\nWhite's Test for Heteroscedasticity:")
        print(f"LM statistic: {white_test[0]:.4f}")
        print(f"p-value: {white_test[1]:.6f}")
        if white_test[1] < 0.05:
            print("Heteroscedasticity detected (p < 0.05)")
        else:
            print("No heteroscedasticity detected (p >= 0.05)")
    except:
        print("Could not perform White's test")
    
    # Jarque-Bera test for normality of residuals
    jb_test = stats.jarque_bera(model.resid)
    print(f"\nJarque-Bera Test for Normality of Residuals:")
    print(f"JB statistic: {jb_test[0]:.4f}")
    print(f"p-value: {jb_test[1]:.6f}")
    if jb_test[1] < 0.05:
        print("Residuals are not normally distributed (p < 0.05)")
    else:
        print("Residuals appear normally distributed (p >= 0.05)")
    
    # Durbin-Watson test for autocorrelation
    from statsmodels.stats.diagnostic import durbin_watson
    dw_stat = durbin_watson(model.resid)
    print(f"\nDurbin-Watson Statistic: {dw_stat:.4f}")
    if dw_stat < 1.5 or dw_stat > 2.5:
        print("Potential autocorrelation in residuals")
    else:
        print("No strong evidence of autocorrelation")
    
    # Create diagnostic plots
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    
    # 1. Actual vs Predicted
    axes[0,0].scatter(y, model.fittedvalues, alpha=0.6)
    axes[0,0].plot([y.min(), y.max()], [y.min(), y.max()], 'r--', lw=2)
    axes[0,0].set_xlabel('Actual Values')
    axes[0,0].set_ylabel('Predicted Values')
    axes[0,0].set_title('Actual vs Predicted')
    axes[0,0].grid(True, alpha=0.3)
    
    # 2. Residuals vs Fitted
    axes[0,1].scatter(model.fittedvalues, model.resid, alpha=0.6)
    axes[0,1].axhline(y=0, color='r', linestyle='--')
    axes[0,1].set_xlabel('Fitted Values')
    axes[0,1].set_ylabel('Residuals')
    axes[0,1].set_title('Residuals vs Fitted')
    axes[0,1].grid(True, alpha=0.3)
    
    # 3. Q-Q plot
    stats.probplot(model.resid, dist="norm", plot=axes[0,2])
    axes[0,2].set_title('Q-Q Plot of Residuals')
    axes[0,2].grid(True, alpha=0.3)
    
    # 4. Histogram of residuals
    axes[1,0].hist(model.resid, bins=30, density=True, alpha=0.7, edgecolor='black')
    axes[1,0].set_xlabel('Residuals')
    axes[1,0].set_ylabel('Density')
    axes[1,0].set_title('Distribution of Residuals')
    axes[1,0].grid(True, alpha=0.3)
    
    # 5. Value vs Sending GDP
    axes[1,1].scatter(regression_data['Sending_Country_GDP'], y, alpha=0.6)
    axes[1,1].set_xlabel('Sending Country GDP')
    axes[1,1].set_ylabel('Value')
    axes[1,1].set_title('Value vs Sending Country GDP')
    axes[1,1].grid(True, alpha=0.3)
    
    # 6. Value vs Receiving GDP
    axes[1,2].scatter(regression_data['Receiving_Country_GDP'], y, alpha=0.6)
    axes[1,2].set_xlabel('Receiving Country GDP')
    axes[1,2].set_ylabel('Value')
    axes[1,2].set_title('Value vs Receiving Country GDP')
    axes[1,2].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(r'C:\Users\clint\Desktop\RER\regression_plots_statsmodels.png', dpi=300, bbox_inches='tight')
    print(f"\nPlots saved to: C:\\Users\\clint\\Desktop\\RER\\regression_plots_statsmodels.png")
    plt.show()
    
    # Correlation matrix
    print("\n" + "="*80)
    print("CORRELATION MATRIX")
    print("="*80)
    corr_matrix = regression_data[['Value_cleaned', 'Sending_Country_GDP', 'Receiving_Country_GDP']].corr()
    print(corr_matrix.round(4))
    
    # Save results to file
    with open(r'C:\Users\clint\Desktop\RER\regression_results_statsmodels.txt', 'w') as f:
        f.write("REGRESSION ANALYSIS RESULTS (using statsmodels)\n")
        f.write("="*60 + "\n\n")
        f.write("Dataset: C:\\Users\\clint\\Desktop\\RER\\Code\\22.csv\n")
        f.write(f"Observations used: {len(y)}\n\n")
        f.write("REGRESSION SUMMARY:\n")
        f.write(str(model.summary()))
        f.write("\n\nVARIANCE INFLATION FACTORS:\n")
        f.write(str(vif_data))
        f.write("\n\nCORRELATION MATRIX:\n")
        f.write(str(corr_matrix.round(4)))
    
    print(f"\nDetailed results saved to: C:\\Users\\clint\\Desktop\\RER\\regression_results_statsmodels.txt")
    
    # Interpretation
    print("\n" + "="*80)
    print("INTERPRETATION")
    print("="*80)
    coeffs = model.params
    print(f"Regression equation:")
    print(f"Value = {coeffs[0]:.6f} + {coeffs[1]:.6f} * Sending_Country_GDP + {coeffs[2]:.6f} * Receiving_Country_GDP")
    print(f"\nR-squared: {model.rsquared:.4f} ({model.rsquared*100:.2f}% of variance explained)")
    print(f"Adjusted R-squared: {model.rsquared_adj:.4f}")
    print(f"F-statistic: {model.fvalue:.3f} (p = {model.f_pvalue:.6f})")
    
    print(f"\nCoefficient significance:")
    for i, var in enumerate(['Constant', 'Sending_Country_GDP', 'Receiving_Country_GDP']):
        p_val = model.pvalues[i]
        sig = "Significant" if p_val < 0.05 else "Not significant"
        print(f"- {var}: {sig} (p = {p_val:.6f})")

if __name__ == "__main__":
    main()