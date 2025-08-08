# **Chapter 6: The Command Center - The WAHIS-Inspired Main Dashboard**

This chapter is the centerpiece of the "Operational Dashboards" section of the book. It brings together all the data and analysis techniques from previous chapters into a single, high-level command center for decision-makers.

---

## **Introduction**

Every complex operation needs a command center. A ship's captain has the bridge, a flight controller has the main tower, and a national veterinary service needs a central dashboard. This is the single screen where a Chief Veterinary Officer, a program manager, or an epidemiologist can get a rapid, comprehensive, and up-to-the-minute understanding of the animal health situation across the entire country. It is the starting point for every strategic decision, providing the high-level context needed to ask the right questions and allocate resources effectively.

Inspired by world-class systems like the World Organisation for Animal Health's WAHIS interface, this chapter is about building that command center. We will construct a powerful, interactive dashboard that consolidates our vast repository of surveillance data into four key analytical panels:
1.  **Dynamic Filters:** To slice the data by disease, region, and time.
2.  **Key Performance Indicators (KPIs):** To provide an instant, quantitative summary of the current situation.
3.  **An Interactive Map:** To visualize the spatial distribution of filtered outbreaks.
4.  **Charts and Graphs:** To reveal temporal trends and categorical breakdowns.

This dashboard is the culmination of our work so far. It leverages the robust database schema from Chapter 1, the data ingestion pipelines from Chapter 2, and the spatial and temporal analysis techniques from Chapters 3 and 4. We will now assemble these components into a cohesive, user-friendly interface that transforms raw data into actionable intelligence.

## **6.1 The Unification Engine: The Master GeoDataFrame**

An interactive dashboard must be fast. A user expects the charts and maps to update almost instantly when they change a filter. The single greatest barrier to this is slow database queries. If our dashboard had to perform complex `JOIN` operations across five or six tables every time a user selected a different date, the experience would be frustratingly slow.

To solve this, we perform the heavy lifting of data unification *once*, up front. We will create a master **"analysis-ready" GeoDataFrame** in memory. This single, wide DataFrame will contain all the enriched information needed for the dashboard, pre-joined and cleaned.

The process involves fetching the core data from our transactional tables and merging them using pandas:
*   Start with the most granular data: `animal_disease_events_logbook`.
*   Join with `animal_diseases` to get the readable `disease_name` and other characteristics.
*   Join with `admin_woredas` to get the `woreda_name` and `zone_pcode`.
*   Join with `admin_zones` to get the `zone_name` and `region_pcode`.
*   Join with `admin_regions` to get the `region_name`.

```python
import pandas as pd
import geopandas as gpd

# Assume all individual DataFrames (df_outbreaks, df_diseases, df_woredas, etc.)
# have been loaded using the functions from Chapter 2.

print("-> Unifying data into a single, analysis-ready GeoDataFrame...")

# Merge dataframes step-by-step
merged_df = pd.merge(df_outbreaks, df_diseases, on='disease_code', how='left')
merged_df = pd.merge(merged_df, df_woredas, on='woreda_pcode', how='left')
merged_df = pd.merge(merged_df, df_zones, on='zone_pcode', how='left')
merged_df = pd.merge(merged_df, df_regions, on='region_pcode', how='left')

# Convert date columns to datetime objects for proper filtering
merged_df['reported_date'] = pd.to_datetime(merged_df['reported_date'])

# Create the final, spatially-aware GeoDataFrame
outbreaks_gdf = gpd.GeoDataFrame(
    merged_df,
    geometry=gpd.points_from_xy(merged_df.longitude, merged_df.latitude),
    crs="EPSG:4326"
)

print(f"✅ Master GeoDataFrame created with {len(outbreaks_gdf)} events.")
```
This `outbreaks_gdf` is now our single source of truth for the dashboard. All filtering and analysis will be performed on this in-memory object, ensuring a fast and responsive user experience.

## **6.2 Designing for Decision-Makers: The Four-Panel Layout**

A good dashboard tells a story. Our command center will be organized into a clear, four-panel layout built with `ipywidgets`.

**Panel 1: The Filters**
These are the user's controls. They allow decision-makers to ask specific questions of the data. We will provide dropdowns for `disease_name` and `region_name`, as well as date pickers for selecting a time window.

**Panel 2: The KPIs**
These are the "headlines" of the report. They provide an immediate, high-level summary of the filtered data. Our dashboard will feature four key indicators:
*   **Ongoing Outbreaks:** The number of events whose status is still "Ongoing."
*   **Total Cases:** The sum of all animal cases within the filtered period.
*   **Total Deaths:** The sum of all animal deaths.
*   **Affected Regions:** The number of unique regions with at least one outbreak.

**Panel 3: The Interactive Map**
This panel provides the crucial spatial context, showing the geographic distribution of the filtered outbreak events as points on an interactive `folium` map.

**Panel 4: The Charts**
This panel provides temporal and categorical context. We will include two charts:
*   **Timeline:** An epidemic curve showing the number of new outbreaks per month.
*   **Pie Chart:** A breakdown of the top 5 diseases by number of events.

## **6.3 Building the Interface and Logic**

With our master GeoDataFrame prepared and our layout designed, we can now build the dashboard itself. The entire system is driven by a single, powerful "update" function that is linked to all our filter widgets.

**1. Define the Widgets and Output Areas:**
We first create all the interactive elements (dropdowns, date pickers) and the output containers for our KPIs, map, and charts.

```python
import ipywidgets as widgets
from IPython.display import display, clear_output

# --- WIDGETS (FILTERS) ---
disease_filter = widgets.Dropdown(options=['All Diseases'] + sorted(outbreaks_gdf['disease_name'].unique()), description='Disease:')
region_filter = widgets.Dropdown(options=['All Regions'] + sorted(outbreaks_gdf['region_name'].dropna().unique()), description='Region:')
start_date_filter = widgets.DatePicker(description='Start Date', value=outbreaks_gdf['reported_date'].min())
end_date_filter = widgets.DatePicker(description='End Date', value=outbreaks_gdf['reported_date'].max())

# --- OUTPUT AREAS (LAYOUT) ---
kpi_ongoing = widgets.HTML()
kpi_cases = widgets.HTML()
map_output = widgets.Output()
timeline_output = widgets.Output()
# ... other output widgets ...
```

**2. The Core `update_dashboard` Function:**
This function is the engine of our command center. It runs every time a user changes a filter. Its logic is simple and sequential:
1.  Make a copy of the master `outbreaks_gdf`.
2.  Apply filters to this copy based on the current values of the `disease_filter`, `region_filter`, and date pickers.
3.  Calculate the new values for all KPIs from the filtered DataFrame and update the `kpi_...` HTML widgets.
4.  Clear the `map_output` and redraw the `folium` map using only the data from the filtered DataFrame.
5.  Clear the `timeline_output` and redraw the `matplotlib` charts using the filtered data.

**3. Link Widgets and Assemble the Layout:**
Finally, we use the `.observe()` method to link any change in our filter widgets to the `update_dashboard` function. Then, we arrange all the individual widgets and output areas into a clean, professional layout using `HBox` (horizontal box) and `VBox` (vertical box).

```python
# --- Link the observer function to all filter widgets ---
for w in [disease_filter, region_filter, start_date_filter, end_date_filter]:
    w.observe(update_dashboard, names='value')

# --- Assemble the final dashboard layout ---
filters_box = widgets.HBox([disease_filter, region_filter, start_date_filter, end_date_filter])
kpi_box = widgets.HBox([kpi_ongoing, kpi_cases, ...])
charts_box = widgets.VBox([timeline_output, ...])
main_content_box = widgets.HBox([map_output, charts_box])

dashboard = widgets.VBox([
    widgets.HTML("<h1>National Animal Health Surveillance Dashboard</h1>"),
    filters_box,
    widgets.HTML("<hr>"),
    kpi_box,
    widgets.HTML("<hr>"),
    main_content_box
])

# --- Display the dashboard and run the initial update ---
display(dashboard)
update_dashboard(None)
```
The full, detailed code for this dashboard is provided in Appendix B.

## **Chapter Summary**

In this chapter, we have built the command center of our NAHSP. We have learned the critical importance of creating a unified, analysis-ready master dataset to ensure a fast and responsive user experience. We have designed a user-centric, four-panel layout inspired by professional systems like WAHIS, providing at-a-glance KPIs, a spatial map, and temporal charts. Finally, we have implemented the interactive logic using `ipywidgets`, linking our filters to a central update function that brings the entire dashboard to life.

This dashboard represents the pinnacle of high-level surveillance. It transforms a complex, multi-table database into a simple, powerful, and interactive tool for decision-making. In the next chapter, we will move from this strategic overview to the world of tactical operations, building a dedicated dashboard for planning, managing, and monitoring livestock vaccination campaigns.