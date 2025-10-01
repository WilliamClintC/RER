import os
import re

# Simple manual extraction based on the exact structure
base_dir = r"C:\Users\clint\Desktop\RER\Code\27"

# Manually create the comprehensive table with the known values from the output
comprehensive_html = """
<table style="text-align:center">
<caption><strong>Comprehensive Regression Analysis: All Three Specifications</strong></caption>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="6"><em>Dependent variable:</em></td></tr>
<tr><td></td><td colspan="6" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="2">Remittance (thousands USD)</td><td colspan="2">Log(Remittance millions USD)</td><td colspan="2">Remittance (millions USD)</td></tr>
<tr><td style="text-align:left"></td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td></tr>
<tr><td style="text-align:left">Specification</td><td>1: Linear</td><td>1: Linear</td><td>2: Log-Log</td><td>2: Log-Log</td><td>4: Linear Dep, Log Indep</td><td>4: Linear Dep, Log Indep</td></tr>
<tr><td style="text-align:left"></td><td>(1)</td><td>(2)</td><td>(3)</td><td>(4)</td><td>(5)</td><td>(6)</td></tr>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>

<tr><td style="text-align:left">Sending Country GDP (millions USD)</td><td>0.164<sup>**</sup></td><td>0.138<sup>***</sup></td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left"></td><td>(0.071)</td><td>(0.040)</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Receiving Country GDP (millions USD)</td><td>-0.061</td><td>-0.034</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left"></td><td>(0.112)</td><td>(0.063)</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Log(Sending Country GDP)</td><td></td><td></td><td>0.959<sup>***</sup></td><td>0.955<sup>***</sup></td><td>420.896<sup>***</sup></td><td>269.502<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td></td><td></td><td>(0.026)</td><td>(0.026)</td><td>(94.764)</td><td>(53.469)</td></tr>
<tr><td style="text-align:left">Log(Receiving Country GDP)</td><td></td><td></td><td>0.561<sup>***</sup></td><td>0.561<sup>***</sup></td><td>67.770</td><td>54.125</td></tr>
<tr><td style="text-align:left"></td><td></td><td></td><td>(0.033)</td><td>(0.033)</td><td>(120.338)</td><td>(67.852)</td></tr>
<tr><td style="text-align:left">Constant</td><td>691,495.500<sup>***</sup></td><td>434,211.800<sup>***</sup></td><td>-17.492<sup>***</sup></td><td>-17.451<sup>***</sup></td><td>-4,583.081<sup>***</sup></td><td>-3,032.175<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td>(247,444.700)</td><td>(139,545.700)</td><td>(0.474)</td><td>(0.473)</td><td>(1,740.371)</td><td>(981.506)</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left">Observations</td><td>2,837</td><td>2,835</td><td>2,837</td><td>2,835</td><td>2,837</td><td>2,835</td></tr>
<tr><td style="text-align:left">R<sup>2</sup></td><td>0.002</td><td>0.004</td><td>0.370</td><td>0.370</td><td>0.007</td><td>0.009</td></tr>
<tr><td style="text-align:left">Adjusted R<sup>2</sup></td><td>0.001</td><td>0.004</td><td>0.370</td><td>0.369</td><td>0.006</td><td>0.008</td></tr>
<tr><td style="text-align:left">Residual Std. Error</td><td>12,261,774.000 (df = 2834)</td><td>6,913,052.000 (df = 2832)</td><td>3.334 (df = 2834)</td><td>3.324 (df = 2832)</td><td>12,231.000 (df = 2834)</td><td>6,896.314 (df = 2832)</td></tr>
<tr><td style="text-align:left">F Statistic</td><td>2.855<sup>*</sup> (df = 2; 2834)</td><td>6.088<sup>***</sup> (df = 2; 2832)</td><td>832.296<sup>***</sup> (df = 2; 2834)</td><td>830.160<sup>***</sup> (df = 2; 2832)</td><td>10.009<sup>***</sup> (df = 2; 2834)</td><td>13.000<sup>***</sup> (df = 2; 2832)</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"><em>Note:</em></td><td colspan="6" style="text-align:right">
Specification 1: Remittances (thousands) vs GDP (millions)<br>
Specification 2: Log-Log Model<br>
Specification 4: Linear Dependent, Log Independent<br>
<sup>*</sup>p<0.1; <sup>**</sup>p<0.05; <sup>***</sup>p<0.01
</td></tr>
</table>
"""

# Create comprehensive LaTeX table
comprehensive_latex = r"""
% Comprehensive Regression Table
\begin{table}[!htbp] \centering
  \caption{Comprehensive Regression Analysis: All Three Specifications}
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
 Sending Country GDP (millions USD) & 0.164$^{**}$ & 0.138$^{***}$ & & & & \\
  & (0.071) & (0.040) & & & & \\
 Receiving Country GDP (millions USD) & $-$0.061 & $-$0.034 & & & & \\
  & (0.112) & (0.063) & & & & \\
 Log(Sending Country GDP) & & & 0.959$^{***}$ & 0.955$^{***}$ & 420.896$^{***}$ & 269.502$^{***}$ \\
  & & & (0.026) & (0.026) & (94.764) & (53.469) \\
 Log(Receiving Country GDP) & & & 0.561$^{***}$ & 0.561$^{***}$ & 67.770 & 54.125 \\
  & & & (0.033) & (0.033) & (120.338) & (67.852) \\
 Constant & 691,495.500$^{***}$ & 434,211.800$^{***}$ & $-$17.492$^{***}$ & $-$17.451$^{***}$ & $-$4,583.081$^{***}$ & $-$3,032.175$^{***}$ \\
  & (247,444.700) & (139,545.700) & (0.474) & (0.473) & (1,740.371) & (981.506) \\
 \hline \\[-1.8ex]
Observations & 2,837 & 2,835 & 2,837 & 2,835 & 2,837 & 2,835 \\
R$^{2}$ & 0.002 & 0.004 & 0.370 & 0.370 & 0.007 & 0.009 \\
Adjusted R$^{2}$ & 0.001 & 0.004 & 0.370 & 0.369 & 0.006 & 0.008 \\
Residual Std. Error & 12,261,774.000 (df = 2834) & 6,913,052.000 (df = 2832) & 3.334 (df = 2834) & 3.324 (df = 2832) & 12,231.000 (df = 2834) & 6,896.314 (df = 2832) \\
F Statistic & 2.855$^{*}$ (df = 2; 2834) & 6.088$^{***}$ (df = 2; 2832) & 832.296$^{***}$ (df = 2; 2834) & 830.160$^{***}$ (df = 2; 2832) & 10.009$^{***}$ (df = 2; 2834) & 13.000$^{***}$ (df = 2; 2832) \\
\hline
\hline \\[-1.8ex]
\textit{Note:}  & \multicolumn{6}{r}{Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log} \\
 & \multicolumn{6}{r}{$^{*}$p$<$0.1; $^{**}$p$<$0.05; $^{***}$p$<$0.01} \\
\end{tabular}
\end{table}
"""

# Save comprehensive HTML table
comprehensive_html_file = os.path.join(base_dir, "final_comprehensive_table.html")
with open(comprehensive_html_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_html)

# Save comprehensive LaTeX table
comprehensive_latex_file = os.path.join(base_dir, "final_comprehensive_table.tex")
with open(comprehensive_latex_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_latex)

print(f"Final comprehensive HTML table created: {comprehensive_html_file}")
print(f"Final comprehensive LaTeX table created: {comprehensive_latex_file}")
print("Final comprehensive tables completed successfully!")

# Also create a text summary
summary_text = """
COMPREHENSIVE REGRESSION ANALYSIS RESULTS
==========================================

SPECIFICATION 1: Remittance (thousands) vs GDP (millions)
----------------------------------------------------------
                                    With Outliers    Without Outliers
Sending Country GDP (millions)      0.164**          0.138***
                                   (0.071)          (0.040)
Receiving Country GDP (millions)   -0.061           -0.034
                                   (0.112)          (0.063)
Constant                           691,495.500***   434,211.800***
                                   (247,444.700)    (139,545.700)

Observations                       2,837            2,835
R²                                0.002            0.004
Adjusted R²                       0.001            0.004
F Statistic                       2.855*           6.088***

SPECIFICATION 2: Log-Log Model
------------------------------
                                    With Outliers    Without Outliers
Log(Sending Country GDP)           0.959***         0.955***
                                   (0.026)          (0.026)
Log(Receiving Country GDP)         0.561***         0.561***
                                   (0.033)          (0.033)
Constant                          -17.492***       -17.451***
                                   (0.474)          (0.473)

Observations                       2,837            2,835
R²                                0.370            0.370
Adjusted R²                       0.370            0.369
F Statistic                       832.296***       830.160***

SPECIFICATION 4: Linear Dependent, Log Independent
--------------------------------------------------
                                    With Outliers    Without Outliers
Log(Sending Country GDP)           420.896***       269.502***
                                   (94.764)         (53.469)
Log(Receiving Country GDP)         67.770           54.125
                                   (120.338)        (67.852)
Constant                          -4,583.081***    -3,032.175***
                                   (1,740.371)      (981.506)

Observations                       2,837            2,835
R²                                0.007            0.009
Adjusted R²                       0.006            0.008
F Statistic                       10.009***        13.000***

Notes: *p<0.1; **p<0.05; ***p<0.01
Standard errors in parentheses
"""

summary_file = os.path.join(base_dir, "regression_results_summary.txt")
with open(summary_file, 'w', encoding='utf-8') as f:
    f.write(summary_text)

print(f"Summary text file created: {summary_file}")