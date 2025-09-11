

# Visual Analysis

## Geographic Distribution

### Sending Countries Analysis

![Top 15 Remittance Sending Countries](images/sending_countries_static.png){#fig-sending-static width=100%}

The analysis reveals that developed nations dominate remittance sending, with Canada leading at 18 records, followed by Italy, USA, Spain, France, and Germany each contributing 14-15 records.

::: {.callout-tip}
**Interactive Version Available**

For the full interactive choropleth map with hover details and zoom capabilities, open: 
`_output/exported_figures/01_sending_countries_choropleth.html`
:::

### Receiving Countries Analysis

![All 20 Remittance Receiving Countries](images/receiving_countries_static.png){#fig-receiving-static width=100%}

The receiving countries show strong concentration in Latin America, with Ecuador (183 records) and Mexico (169 records) dominating the dataset.

::: {.callout-tip}
**Interactive Version Available**

For the full interactive choropleth map, open: 
`_output/exported_figures/02_receiving_countries_choropleth.html`
:::

## Temporal Analysis

### Data Availability Over Time

![Remittance Data by Year](images/temporal_distribution_static.png){#fig-temporal-static width=100%}

The temporal distribution shows 2022 as the peak year with 408 records, while 2023 data is completely missing from the dataset.

::: {.callout-tip}
**Interactive Version Available**

For the interactive temporal chart, open: 
`_output/exported_figures/03_temporal_bar_chart.html`
:::

### Detailed Temporal Patterns

#### Receiving Countries by Year

![Receiving Countries Temporal Heatmap](images/receiving_heatmap.png){#fig-receiving-heatmap width=100%}

#### Sending Countries by Year  

![Top 30 Sending Countries Temporal Heatmap](images/sending_heatmap.png){#fig-sending-heatmap width=100%}

## Flow Network Analysis

### Network Overview

![Global Remittance Network Overview](images/flow_network_overview.png){#fig-network-overview width=100%}

The remittance network shows a many-to-few pattern: 206 sending countries directing flows to just 20 receiving countries.

::: {.callout-important}
**Complete Flow Analysis Available**

The static images above provide an overview, but the full flow analysis includes:

- **Initial Flow Map (Top 50)**: `04_initial_flow_map_top50.html`
- **Complete Flow Map (All 728)**: `05_complete_flow_map_all728.html`  
- **Enhanced Coordinate Coverage**: `06_updated_flow_map_expanded_coords.html`
- **Final 100% Coverage Map**: `07_final_flow_map_100percent_coverage.html`
- **Diagnostic Enhanced Visibility**: `08_diagnostic_enhanced_visibility.html`
- **Comparative Analysis**: `09_comparison_top50_vs_all_flows.html`

These interactive maps feature:
- Curved flow lines between countries
- Great circle path calculations
- Zoom and pan capabilities
- Hover details for each flow
- Enhanced visibility for small flows
:::

## Key Insights

### Geographic Patterns
- **Sending Concentration**: Developed nations (G7 countries) account for majority of sending records
- **Receiving Concentration**: Latin America dominates with Ecuador, Mexico, and Panama representing 62.4% of all records
- **Global Coverage**: 206 sending countries provide good global representation

### Temporal Patterns  
- **Peak Activity**: 2022 shows maximum data collection (408 records)
- **Data Gaps**: Complete absence of 2023 data suggests collection challenges
- **Growth Pattern**: Steady increase from 2019 (10) to 2022 (408)

### Network Structure
- **Flow Direction**: Strong unidirectional pattern from developed to developing nations
- **Corridor Concentration**: Major corridors focus on Latin American destinations
- **Diaspora Patterns**: Reflects global migration and diaspora settlement patterns

