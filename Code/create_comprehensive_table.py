import re
import os

# Set up paths
base_dir = r"C:\Users\clint\Desktop\RER\Code\27"

# Read the individual HTML files
def read_html_file(filename):
    with open(os.path.join(base_dir, filename), 'r', encoding='utf-8') as f:
        return f.read()

# Parse table data from HTML
def extract_table_data(html_content):
    # Extract coefficients and statistics
    lines = html_content.split('\n')
    data = {}
    
    # Find coefficient rows
    for i, line in enumerate(lines):
        if 'Sending Country GDP' in line:
            # Look for the next line with values
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                match = re.search(r'<td>\(([^)]+)\)</td><td>\(([^)]+)\)</td>', next_line)
                if match:
                    # This line has standard errors, so coefficients are in current line
                    coef_match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
                    if coef_match:
                        data['sending_with'] = coef_match.group(1)
                        data['sending_without'] = coef_match.group(2)
        elif 'Receiving Country GDP' in line:
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                match = re.search(r'<td>\(([^)]+)\)</td><td>\(([^)]+)\)</td>', next_line)
                if match:
                    coef_match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
                    if coef_match:
                        data['receiving_with'] = coef_match.group(1)
                        data['receiving_without'] = coef_match.group(2)
        elif 'Log(Sending Country GDP)' in line:
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                match = re.search(r'<td>\(([^)]+)\)</td><td>\(([^)]+)\)</td>', next_line)
                if match:
                    coef_match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
                    if coef_match:
                        data['log_sending_with'] = coef_match.group(1)
                        data['log_sending_without'] = coef_match.group(2)
        elif 'Log(Receiving Country GDP)' in line:
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                match = re.search(r'<td>\(([^)]+)\)</td><td>\(([^)]+)\)</td>', next_line)
                if match:
                    coef_match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
                    if coef_match:
                        data['log_receiving_with'] = coef_match.group(1)
                        data['log_receiving_without'] = coef_match.group(2)
        elif 'Constant' in line:
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                match = re.search(r'<td>\(([^)]+)\)</td><td>\(([^)]+)\)</td>', next_line)
                if match:
                    coef_match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
                    if coef_match:
                        data['constant_with'] = coef_match.group(1)
                        data['constant_without'] = coef_match.group(2)
        elif 'Observations' in line:
            match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
            if match:
                data['obs_with'] = match.group(1)
                data['obs_without'] = match.group(2)
        elif 'R<sup>2</sup>' in line:
            match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
            if match:
                data['r2_with'] = match.group(1)
                data['r2_without'] = match.group(2)
        elif 'Adjusted R<sup>2</sup>' in line:
            match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
            if match:
                data['adj_r2_with'] = match.group(1)
                data['adj_r2_without'] = match.group(2)
        elif 'Residual Std. Error' in line:
            match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
            if match:
                data['rse_with'] = match.group(1)
                data['rse_without'] = match.group(2)
        elif 'F Statistic' in line:
            match = re.search(r'<td>([^<]+)</td><td>([^<]+)</td>', line)
            if match:
                data['f_with'] = match.group(1)
                data['f_without'] = match.group(2)
    
    return data

# Read the three specification files
print("Reading specification files...")
spec1_html = read_html_file("spec1_remittances_thousands.html")
spec2_html = read_html_file("spec2_log_log.html")
spec4_html = read_html_file("spec4_linear_dep_log_indep.html")

# Extract data from each specification
spec1_data = extract_table_data(spec1_html)
spec2_data = extract_table_data(spec2_html)
spec4_data = extract_table_data(spec4_html)

# Create comprehensive HTML table
comprehensive_html = f"""
<table style="text-align:center">
<caption><strong>Comprehensive Regression Analysis: All Three Specifications</strong></caption>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="6"><em>Dependent variable:</em></td></tr>
<tr><td></td><td colspan="6" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td colspan="2">Remittance Value (thousands USD)</td><td colspan="2">Log(Remittance Value)</td><td colspan="2">Remittance Value (millions USD)</td></tr>
<tr><td style="text-align:left"></td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td><td>With Outliers</td><td>Without Outliers</td></tr>
<tr><td style="text-align:left">Specification</td><td>1: Linear</td><td>1: Linear</td><td>2: Log-Log</td><td>2: Log-Log</td><td>4: Linear Dep, Log Indep</td><td>4: Linear Dep, Log Indep</td></tr>
<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>

<tr><td style="text-align:left">Sending Country GDP (millions USD)</td><td>{spec1_data.get('sending_with', '')}</td><td>{spec1_data.get('sending_without', '')}</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Receiving Country GDP (millions USD)</td><td>{spec1_data.get('receiving_with', '')}</td><td>{spec1_data.get('receiving_without', '')}</td><td></td><td></td><td></td><td></td></tr>
<tr><td style="text-align:left">Log(Sending Country GDP)</td><td></td><td></td><td>{spec2_data.get('log_sending_with', '')}</td><td>{spec2_data.get('log_sending_without', '')}</td><td>{spec4_data.get('log_sending_with', '')}</td><td>{spec4_data.get('log_sending_without', '')}</td></tr>
<tr><td style="text-align:left">Log(Receiving Country GDP)</td><td></td><td></td><td>{spec2_data.get('log_receiving_with', '')}</td><td>{spec2_data.get('log_receiving_without', '')}</td><td>{spec4_data.get('log_receiving_with', '')}</td><td>{spec4_data.get('log_receiving_without', '')}</td></tr>
<tr><td style="text-align:left">Constant</td><td>{spec1_data.get('constant_with', '')}</td><td>{spec1_data.get('constant_without', '')}</td><td>{spec2_data.get('constant_with', '')}</td><td>{spec2_data.get('constant_without', '')}</td><td>{spec4_data.get('constant_with', '')}</td><td>{spec4_data.get('constant_without', '')}</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left">Observations</td><td>{spec1_data.get('obs_with', '')}</td><td>{spec1_data.get('obs_without', '')}</td><td>{spec2_data.get('obs_with', '')}</td><td>{spec2_data.get('obs_without', '')}</td><td>{spec4_data.get('obs_with', '')}</td><td>{spec4_data.get('obs_without', '')}</td></tr>
<tr><td style="text-align:left">R<sup>2</sup></td><td>{spec1_data.get('r2_with', '')}</td><td>{spec1_data.get('r2_without', '')}</td><td>{spec2_data.get('r2_with', '')}</td><td>{spec2_data.get('r2_without', '')}</td><td>{spec4_data.get('r2_with', '')}</td><td>{spec4_data.get('r2_without', '')}</td></tr>
<tr><td style="text-align:left">Adjusted R<sup>2</sup></td><td>{spec1_data.get('adj_r2_with', '')}</td><td>{spec1_data.get('adj_r2_without', '')}</td><td>{spec2_data.get('adj_r2_with', '')}</td><td>{spec2_data.get('adj_r2_without', '')}</td><td>{spec4_data.get('adj_r2_with', '')}</td><td>{spec4_data.get('adj_r2_without', '')}</td></tr>
<tr><td style="text-align:left">Residual Std. Error</td><td>{spec1_data.get('rse_with', '')}</td><td>{spec1_data.get('rse_without', '')}</td><td>{spec2_data.get('rse_with', '')}</td><td>{spec2_data.get('rse_without', '')}</td><td>{spec4_data.get('rse_with', '')}</td><td>{spec4_data.get('rse_without', '')}</td></tr>
<tr><td style="text-align:left">F Statistic</td><td>{spec1_data.get('f_with', '')}</td><td>{spec1_data.get('f_without', '')}</td><td>{spec2_data.get('f_with', '')}</td><td>{spec2_data.get('f_without', '')}</td><td>{spec4_data.get('f_with', '')}</td><td>{spec4_data.get('f_without', '')}</td></tr>

<tr><td colspan="7" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"><em>Note:</em></td><td colspan="6" style="text-align:right">
Specification 1: Remittances (thousands) vs GDP (millions)<br>
Specification 2: Log-Log Model<br>
Specification 4: Linear Dependent, Log Independent<br>
<sup>*</sup>p<0.1; <sup>**</sup>p<0.05; <sup>***</sup>p<0.01
</td></tr>
</table>
"""

# Save comprehensive HTML table
comprehensive_file = os.path.join(base_dir, "comprehensive_all_specifications.html")
with open(comprehensive_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_html)

print(f"Comprehensive HTML table created: {comprehensive_file}")

# Also create a LaTeX version by reading the LaTeX files
def read_latex_file(filename):
    with open(os.path.join(base_dir, filename), 'r', encoding='utf-8') as f:
        return f.read()

# Extract LaTeX data
def extract_latex_data(latex_content):
    lines = latex_content.split('\\n')
    data = {}
    
    for line in lines:
        if 'Sending Country GDP' in line or 'Log(Sending Country GDP)' in line:
            # Extract coefficient values from LaTeX
            parts = line.split('&')
            if len(parts) >= 3:
                data['sending_with'] = parts[1].strip()
                data['sending_without'] = parts[2].replace('\\\\', '').strip()
        elif 'Receiving Country GDP' in line or 'Log(Receiving Country GDP)' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['receiving_with'] = parts[1].strip()
                data['receiving_without'] = parts[2].replace('\\\\', '').strip()
        elif 'Constant' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['constant_with'] = parts[1].strip()
                data['constant_without'] = parts[2].replace('\\\\', '').strip()
        elif 'Observations' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['obs_with'] = parts[1].strip()
                data['obs_without'] = parts[2].replace('\\\\', '').strip()
        elif 'R$^{2}$' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['r2_with'] = parts[1].strip()
                data['r2_without'] = parts[2].replace('\\\\', '').strip()
        elif 'Adjusted R$^{2}$' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['adj_r2_with'] = parts[1].strip()
                data['adj_r2_without'] = parts[2].replace('\\\\', '').strip()
        elif 'Residual Std. Error' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['rse_with'] = parts[1].strip()
                data['rse_without'] = parts[2].replace('\\\\', '').strip()
        elif 'F Statistic' in line:
            parts = line.split('&')
            if len(parts) >= 3:
                data['f_with'] = parts[1].strip()
                data['f_without'] = parts[2].replace('\\\\', '').strip()
    
    return data

# Read LaTeX files
spec1_latex = read_latex_file("spec1_remittances_thousands.tex")
spec2_latex = read_latex_file("spec2_log_log.tex")
spec4_latex = read_latex_file("spec4_linear_dep_log_indep.tex")

# Extract LaTeX data
spec1_latex_data = extract_latex_data(spec1_latex)
spec2_latex_data = extract_latex_data(spec2_latex)
spec4_latex_data = extract_latex_data(spec4_latex)

# Create comprehensive LaTeX table
comprehensive_latex = f"""
% Comprehensive Regression Table
\\begin{{table}}[!htbp] \\centering
  \\caption{{Comprehensive Regression Analysis: All Three Specifications}}
  \\label{{}}
\\begin{{tabular}}{{@{{\\extracolsep{{5pt}}}}lcccccc}}
\\\\[-1.8ex]\\hline
\\hline \\\\[-1.8ex]
 & \\multicolumn{{6}}{{c}}{{\\textit{{Dependent variable:}}}} \\\\
\\cline{{2-7}}
\\\\[-1.8ex] & \\multicolumn{{2}}{{c}}{{Remittance Value (thousands USD)}} & \\multicolumn{{2}}{{c}}{{Log(Remittance Value)}} & \\multicolumn{{2}}{{c}}{{Remittance Value (millions USD)}} \\\\
 & With Outliers & Without Outliers & With Outliers & Without Outliers & With Outliers & Without Outliers \\\\
 & Spec 1 & Spec 1 & Spec 2 & Spec 2 & Spec 4 & Spec 4 \\\\
\\\\[-1.8ex] & (1) & (2) & (3) & (4) & (5) & (6)\\\\
\\hline \\\\[-1.8ex]
 Sending Country GDP (millions USD) & {spec1_latex_data.get('sending_with', '')} & {spec1_latex_data.get('sending_without', '')} & & & & \\\\
 Receiving Country GDP (millions USD) & {spec1_latex_data.get('receiving_with', '')} & {spec1_latex_data.get('receiving_without', '')} & & & & \\\\
 Log(Sending Country GDP) & & & {spec2_latex_data.get('sending_with', '')} & {spec2_latex_data.get('sending_without', '')} & {spec4_latex_data.get('sending_with', '')} & {spec4_latex_data.get('sending_without', '')} \\\\
 Log(Receiving Country GDP) & & & {spec2_latex_data.get('receiving_with', '')} & {spec2_latex_data.get('receiving_without', '')} & {spec4_latex_data.get('receiving_with', '')} & {spec4_latex_data.get('receiving_without', '')} \\\\
 Constant & {spec1_latex_data.get('constant_with', '')} & {spec1_latex_data.get('constant_without', '')} & {spec2_latex_data.get('constant_with', '')} & {spec2_latex_data.get('constant_without', '')} & {spec4_latex_data.get('constant_with', '')} & {spec4_latex_data.get('constant_without', '')} \\\\
 \\hline \\\\[-1.8ex]
Observations & {spec1_latex_data.get('obs_with', '')} & {spec1_latex_data.get('obs_without', '')} & {spec2_latex_data.get('obs_with', '')} & {spec2_latex_data.get('obs_without', '')} & {spec4_latex_data.get('obs_with', '')} & {spec4_latex_data.get('obs_without', '')} \\\\
R$^{{2}}$ & {spec1_latex_data.get('r2_with', '')} & {spec1_latex_data.get('r2_without', '')} & {spec2_latex_data.get('r2_with', '')} & {spec2_latex_data.get('r2_without', '')} & {spec4_latex_data.get('r2_with', '')} & {spec4_latex_data.get('r2_without', '')} \\\\
Adjusted R$^{{2}}$ & {spec1_latex_data.get('adj_r2_with', '')} & {spec1_latex_data.get('adj_r2_without', '')} & {spec2_latex_data.get('adj_r2_with', '')} & {spec2_latex_data.get('adj_r2_without', '')} & {spec4_latex_data.get('adj_r2_with', '')} & {spec4_latex_data.get('adj_r2_without', '')} \\\\
Residual Std. Error & {spec1_latex_data.get('rse_with', '')} & {spec1_latex_data.get('rse_without', '')} & {spec2_latex_data.get('rse_with', '')} & {spec2_latex_data.get('rse_without', '')} & {spec4_latex_data.get('rse_with', '')} & {spec4_latex_data.get('rse_without', '')} \\\\
F Statistic & {spec1_latex_data.get('f_with', '')} & {spec1_latex_data.get('f_without', '')} & {spec2_latex_data.get('f_with', '')} & {spec2_latex_data.get('f_without', '')} & {spec4_latex_data.get('f_with', '')} & {spec4_latex_data.get('f_without', '')} \\\\
\\hline
\\hline \\\\[-1.8ex]
\\textit{{Note:}}  & \\multicolumn{{6}}{{r}}{{Specification 1: Linear (thousands), Specification 2: Log-Log, Specification 4: Linear-Log}} \\\\
 & \\multicolumn{{6}}{{r}}{{$^{{*}}$p$<$0.1; $^{{**}}$p$<$0.05; $^{{***}}$p$<$0.01}} \\\\
\\end{{tabular}}
\\end{{table}}
"""

# Save comprehensive LaTeX table
comprehensive_latex_file = os.path.join(base_dir, "comprehensive_all_specifications.tex")
with open(comprehensive_latex_file, 'w', encoding='utf-8') as f:
    f.write(comprehensive_latex)

print(f"Comprehensive LaTeX table created: {comprehensive_latex_file}")
print("All comprehensive tables completed successfully!")