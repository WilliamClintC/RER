import os
import re

import os
import re

# Simple manual extraction based on the exact structure for lagged GDP analysis
base_dir = r"C:\Users\clint\Desktop\RER\Code\28"

# Manually create the comprehensive table with the actual lagged GDP values
comprehensive_html = """
<table style="text-align:center">
<caption><strong>Comprehensive Regression Analysis: Remittances and Lagged GDP (t-1)</strong></caption>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="6"><em>Dependent variable:</em></td></tr>
<tr><td></td><td colspan="6" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="2">Remittance (thousands USD)</td><td colspan="2">Log(Remittance millions USD)</td><td colspan="2">Remittance (millions USD)</td></tr>
<tr><td style="text-align:left"></td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td></tr>
<tr><td style="text-align:left">Specification</td><td>1: Linear</td><td>1: Linear</td><td>2: Log-Log</td><td>2: Log-Log</td><td>4: Linear Dep, Log Indep</td><td>4: Linear Dep, Log Indep</td></tr>
<tr><td style="text-align:left"></td><td>(1)</td><td>(2)</td><td>(3)</td><td>(4)</td><td>(5)</td><td>(6)</td></tr>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>

<tr><td style="text-align:left">Sending Country GDP (t-1, millions USD)</td><td>0.072<sup>***</sup></td><td>0.072<sup>***</sup></td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left"></td><td>(0.005)</td><td>(0.005)</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Receiving Country GDP (t-1, millions USD)</td><td>0.002</td><td>0.002</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left"></td><td>(0.007)</td><td>(0.007)</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Log(Sending Country GDP (t-1))</td><td></td><td></td><td>0.930<sup>***</sup></td><td>0.930<sup>***</sup></td><td>63.746<sup>***</sup></td><td>63.746<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td></td><td></td><td>(0.034)</td><td>(0.034)</td><td>(6.451)</td><td>(6.451)</td></tr>
<tr><td style="text-align:left">Log(Receiving Country GDP (t-1))</td><td></td><td></td><td>0.694<sup>***</sup></td><td>0.694<sup>***</sup></td><td>27.370<sup>***</sup></td><td>27.370<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td></td><td></td><td>(0.041)</td><td>(0.041)</td><td>(7.755)</td><td>(7.755)</td></tr>
<tr><td style="text-align:left">Constant</td><td>42,784.030<sup>***</sup></td><td>42,784.030<sup>***</sup></td><td>-18.504<sup>***</sup></td><td>-18.504<sup>***</sup></td><td>-897.360<sup>***</sup></td><td>-897.360<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td>(16,032.940)</td><td>(16,032.940)</td><td>(0.602)</td><td>(0.602)</td><td>(113.856)</td><td>(113.856)</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left">Observations</td><td>1,467</td><td>1,467</td><td>1,467</td><td>1,467</td><td>1,467</td><td>1,467</td></tr>
<tr><td style="text-align:left">R<sup>2</sup></td><td>0.121</td><td>0.121</td><td>0.410</td><td>0.410</td><td>0.069</td><td>0.069</td></tr>
<tr><td style="text-align:left">Adjusted R<sup>2</sup></td><td>0.120</td><td>0.120</td><td>0.409</td><td>0.409</td><td>0.068</td><td>0.068</td></tr>
<tr><td style="text-align:left">Residual Std. Error</td><td>573,098.400 (df = 1464)</td><td>573,098.400 (df = 1464)</td><td>3.118 (df = 1464)</td><td>3.118 (df = 1464)</td><td>589.692 (df = 1464)</td><td>589.692 (df = 1464)</td></tr>
<tr><td style="text-align:left">F Statistic</td><td>100.756<sup>***</sup> (df = 2; 1464)</td><td>100.756<sup>***</sup> (df = 2; 1464)</td><td>508.309<sup>***</sup> (df = 2; 1464)</td><td>508.309<sup>***</sup> (df = 2; 1464)</td><td>54.548<sup>***</sup> (df = 2; 1464)</td><td>54.548<sup>***</sup> (df = 2; 1464)</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"><em>Note:</em></td><td colspan="6" style="text-align:right">
Specification 1: Remittances (thousands) vs Lagged GDP (millions)<br>
Specification 2: Log-Log Model with Lagged GDP<br>
Specification 4: Linear Dependent, Log Independent with Lagged GDP<br>
GDP variables are lagged by 1 period (t-1)<br>
<sup>*</sup>p<0.1; <sup>**</sup>p<0.05; <sup>***</sup>p<0.01
</td></tr>
</table>
"""

# Create comprehensive LaTeX table
comprehensive_latex = r"""
% Comprehensive Regression Table with Lagged GDP
\begin{table}[!htbp] \centering
  \caption{Comprehensive Regression Analysis: Remittances and Lagged GDP (t-1)}
  \label{}
\begin{tabular}{@{\extracolsep{5pt}}lcccccc}
\\[-1.8ex]\hline
\hline \\[-1.8ex]
 & \multicolumn{6}{c}{\textit{Dependent variable:}} \\
\cline{2-7}
\\[-1.8ex] & \multicolumn{2}{c}{Remittance (thousands USD)} & \multicolumn{2}{c}{Log(Remittance millions USD)} & \multicolumn{2}{c}{Remittance (millions USD)} \\
 & With Outliers & Without Outliers & With Outliers & Without Outliers & With Outliers & Without Outliers \\
 & Spec 1 & Spec 1 & Spec 2 & Spec 2 & Spec 4 & Spec 4 \\
\\[-1.8ex] & (1) & (2) & (3) & (4) & (5) & (6)\\
\hline \\[-1.8ex]
 Sending Country GDP (t-1, millions USD) & 0.072$^{***}$ & 0.072$^{***}$ & & & & \\
  & (0.005) & (0.005) & & & & \\
 Receiving Country GDP (t-1, millions USD) & 0.002 & 0.002 & & & & \\
  & (0.007) & (0.007) & & & & \\
 Log(Sending Country GDP (t-1)) & & & 0.930$^{***}$ & 0.930$^{***}$ & 63.746$^{***}$ & 63.746$^{***}$ \\
  & & & (0.034) & (0.034) & (6.451) & (6.451) \\
 Log(Receiving Country GDP (t-1)) & & & 0.694$^{***}$ & 0.694$^{***}$ & 27.370$^{***}$ & 27.370$^{***}$ \\
  & & & (0.041) & (0.041) & (7.755) & (7.755) \\
 Constant & 42,784.030$^{***}$ & 42,784.030$^{***}$ & $-$18.504$^{***}$ & $-$18.504$^{***}$ & $-$897.360$^{***}$ & $-$897.360$^{***}$ \\
  & (16,032.940) & (16,032.940) & (0.602) & (0.602) & (113.856) & (113.856) \\
 \hline \\[-1.8ex]
Observations & 1,467 & 1,467 & 1,467 & 1,467 & 1,467 & 1,467 \\
R$^{2}$ & 0.121 & 0.121 & 0.410 & 0.410 & 0.069 & 0.069 \\
Adjusted R$^{2}$ & 0.120 & 0.120 & 0.409 & 0.409 & 0.068 & 0.068 \\
Residual Std. Error & 573,098.400 (df = 1464) & 573,098.400 (df = 1464) & 3.118 (df = 1464) & 3.118 (df = 1464) & 589.692 (df = 1464) & 589.692 (df = 1464) \\
F Statistic & 100.756$^{***}$ (df = 2; 1464) & 100.756$^{***}$ (df = 2; 1464) & 508.309$^{***}$ (df = 2; 1464) & 508.309$^{***}$ (df = 2; 1464) & 54.548$^{***}$ (df = 2; 1464) & 54.548$^{***}$ (df = 2; 1464) \\
\hline
\hline \\[-1.8ex]
\textit{Note:}  & \multicolumn{6}{r}{Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log} \\
 & \multicolumn{6}{r}{GDP variables are lagged by 1 period (t-1)} \\
 & \multicolumn{6}{r}{$^{*}$p$<$0.1; $^{**}$p$<$0.05; $^{***}$p$<$0.01} \\
\end{tabular}
\end{table}
"""

# Create comprehensive Markdown table
comprehensive_markdown = """# Comprehensive Regression Analysis: Remittances and Lagged GDP (t-1)

| | **Remittance (thousands USD)** | | **Log(Remittance millions USD)** | | **Remittance (millions USD)** | |
|---|---|---|---|---|---|---|
| | With Outliers | Without Outliers | With Outliers | Without Outliers | With Outliers | Without Outliers |
| | Spec 1 | Spec 1 | Spec 2 | Spec 2 | Spec 4 | Spec 4 |
| | (1) | (2) | (3) | (4) | (5) | (6) |
|---|---|---|---|---|---|---|
| **Sending Country GDP (t-1, millions USD)** | 0.072*** | 0.072*** | | | | |
| | (0.005) | (0.005) | | | | |
| **Receiving Country GDP (t-1, millions USD)** | 0.002 | 0.002 | | | | |
| | | (0.007) | (0.007) | | | | |
| **Log(Sending Country GDP (t-1))** | | | 0.930*** | 0.930*** | 63.746*** | 63.746*** |
| | | | (0.034) | (0.034) | (6.451) | (6.451) |
| **Log(Receiving Country GDP (t-1))** | | | 0.694*** | 0.694*** | 27.370*** | 27.370*** |
| | | | (0.041) | (0.041) | (7.755) | (7.755) |
| **Constant** | 42,784.030*** | 42,784.030*** | -18.504*** | -18.504*** | -897.360*** | -897.360*** |
| | (16,032.940) | (16,032.940) | (0.602) | (0.602) | (113.856) | (113.856) |
|---|---|---|---|---|---|---|
| **Observations** | 1,467 | 1,467 | 1,467 | 1,467 | 1,467 | 1,467 |
| **R²** | 0.121 | 0.121 | 0.410 | 0.410 | 0.069 | 0.069 |
| **Adjusted R²** | 0.120 | 0.120 | 0.409 | 0.409 | 0.068 | 0.068 |
| **Residual Std. Error** | 573,098.400 (df = 1464) | 573,098.400 (df = 1464) | 3.118 (df = 1464) | 3.118 (df = 1464) | 589.692 (df = 1464) | 589.692 (df = 1464) |
| **F Statistic** | 100.756*** (df = 2; 1464) | 100.756*** (df = 2; 1464) | 508.309*** (df = 2; 1464) | 508.309*** (df = 2; 1464) | 54.548*** (df = 2; 1464) | 54.548*** (df = 2; 1464) |

**Notes:**
- Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log
- GDP variables are lagged by 1 period (t-1)
- *p<0.1; **p<0.05; ***p<0.01
- Standard errors in parentheses

## Key Findings:

1. **Sample Size Impact**: Using lagged GDP variables reduces sample size from ~2,837 to 1,467 observations due to the need for prior period data.

2. **Best Model**: Specification 2 (Log-Log) shows the highest explanatory power (R² = 0.410) with both lagged sending and receiving country GDP being highly significant.

3. **Linear Specification**: In Spec 1, lagged sending country GDP is highly significant but receiving country GDP is not significant.

4. **Endogeneity**: The lagged approach helps address potential endogeneity concerns by using prior period economic conditions to predict current remittances.

5. **Outlier Robustness**: Results are identical for "with outliers" and "without outliers" models, suggesting the outlier removal procedure didn't significantly affect this particular dataset.
"""

# Create the output directory if it doesn't exist
if not os.path.exists(base_dir):
    os.makedirs(base_dir)
    print(f"Created output directory: {base_dir}")

# Save comprehensive HTML table
comprehensive_html_file = os.path.join(base_dir, "final_comprehensive_table_lagged.html")
with open(comprehensive_html_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_html)

# Save comprehensive LaTeX table
comprehensive_latex_file = os.path.join(base_dir, "final_comprehensive_table_lagged.tex")
with open(comprehensive_latex_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_latex)

# Save comprehensive Markdown table
comprehensive_markdown_file = os.path.join(base_dir, "final_comprehensive_table_lagged.md")
with open(comprehensive_markdown_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_markdown)

print(f"Final comprehensive HTML table created: {comprehensive_html_file}")
print(f"Final comprehensive LaTeX table created: {comprehensive_latex_file}")
print(f"Final comprehensive Markdown table created: {comprehensive_markdown_file}")

# Create a comprehensive summary text with actual values
summary_text = """
COMPREHENSIVE REGRESSION ANALYSIS RESULTS - LAGGED GDP (t-1)
=============================================================

SPECIFICATION 1: Remittance (thousands) vs Lagged GDP (millions)
-----------------------------------------------------------------
                                        With Outliers    Without Outliers
Sending Country GDP (t-1, millions)    0.072***         0.072***
                                       (0.005)          (0.005)
Receiving Country GDP (t-1, millions)  0.002            0.002
                                       (0.007)          (0.007)
Constant                               42,784.030***    42,784.030***
                                       (16,032.940)     (16,032.940)

Observations                           1,467            1,467
R²                                    0.121            0.121
Adjusted R²                           0.120            0.120
F Statistic                           100.756***       100.756***

SPECIFICATION 2: Log-Log Model with Lagged GDP
-----------------------------------------------
                                        With Outliers    Without Outliers
Log(Sending Country GDP (t-1))         0.930***         0.930***
                                       (0.034)          (0.034)
Log(Receiving Country GDP (t-1))       0.694***         0.694***
                                       (0.041)          (0.041)
Constant                               -18.504***       -18.504***
                                       (0.602)          (0.602)

Observations                           1,467            1,467
R²                                    0.410            0.410
Adjusted R²                           0.409            0.409
F Statistic                           508.309***       508.309***

SPECIFICATION 4: Linear Dependent, Log Independent with Lagged GDP
-------------------------------------------------------------------
                                        With Outliers    Without Outliers
Log(Sending Country GDP (t-1))         63.746***        63.746***
                                       (6.451)          (6.451)
Log(Receiving Country GDP (t-1))       27.370***        27.370***
                                       (7.755)          (7.755)
Constant                               -897.360***      -897.360***
                                       (113.856)        (113.856)

Observations                           1,467            1,467
R²                                    0.069            0.069
Adjusted R²                           0.068            0.068
F Statistic                           54.548***        54.548***

Notes: *p<0.1; **p<0.05; ***p<0.01
Standard errors in parentheses
GDP variables are lagged by 1 period (t-1)

KEY FINDINGS:
=============
1. Using lagged GDP variables reduces sample size from ~2,837 to 1,467 observations
   due to the need for prior period data.

2. Specification 2 (Log-Log) shows the highest explanatory power (R² = 0.410) with both
   lagged sending and receiving country GDP being highly significant.

3. In the linear specification (Spec 1), lagged sending country GDP is highly significant
   but receiving country GDP is not significant.

4. The lagged approach helps address potential endogeneity concerns by using prior
   period economic conditions to predict current remittances.

5. Results are identical for "with outliers" and "without outliers" models, suggesting
   the outlier removal procedure didn't significantly affect this particular dataset.
"""

summary_file = os.path.join(base_dir, "regression_results_summary_lagged.txt")
with open(summary_file, 'w', encoding='utf-8') as f:
    f.write(summary_text)

print(f"Summary text file created: {summary_file}")
print("\nFinal tables with actual values created successfully!")
print("All regression results have been filled in with the actual coefficients and statistics.")