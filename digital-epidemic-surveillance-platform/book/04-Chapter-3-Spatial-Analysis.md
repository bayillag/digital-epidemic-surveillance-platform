# **Chapter 3: Where is it Happening? Spatial Analysis and Mapping**

This chapter is designed to be a practical, hands-on guide to the core spatial analysis techniques that form a cornerstone of any modern surveillance platform. It builds directly on the database and backend infrastructure established in the previous chapters.

---


## **Introduction**

In 1854, a devastating cholera outbreak gripped the Soho district of London. At the time, the prevailing theory was that the disease spread through "miasma," or bad air. A physician named John Snow, however, had a different hypothesis. He did not have microscopes or germ theory, but he had a map. He meticulously plotted the location of each cholera death, marking them as black bars on a street map. The pattern that emerged was undeniable: the deaths were overwhelmingly clustered around a single public water pump on Broad Street. By mapping the *where*, Snow was able to deduce the *how*. His work led to the removal of the pump handle, the outbreak subsided, and the field of epidemiology was born.

The map is the single most powerful tool in an epidemiologist's arsenal. It transforms lists of data into visual patterns, revealing clusters, identifying potential sources, and guiding interventions. In the 21st century, we have moved beyond pins on a paper map. We now have access to powerful digital tools that allow us to create dynamic, multi-layered, and statistically robust spatial analyses.

This chapter is about building that modern map. We will take the raw outbreak data from our database and transform it into a series of increasingly sophisticated spatial insights. We will start by simply putting dots on a map, then move to aggregating data into choropleth maps to visualize density. Finally, we will dive into the core of Exploratory Spatial Data Analysis (ESDA) to answer two fundamental questions: Is the pattern we see statistically significant, or just random chance? And if it is significant, where exactly are the hotspots and cold spots? This is the journey from data to spatial intelligence.

## **3.1 The Foundation: GeoDataFrames**

Before any mapping can occur, our data must be made "spatially aware." We accomplish this using **GeoPandas**, a cornerstone library in the Python geospatial ecosystem. GeoPandas introduces the `GeoDataFrame`, a powerful data structure that is essentially a pandas DataFrame with a special `geometry` column. This column can hold geographic objects like points, lines, or polygons.

Our first task is to convert the outbreak data we fetched in Chapter 2, which contains simple latitude and longitude columns, into a `GeoDataFrame` with a `Point` geometry for each outbreak event.

```python
import pandas as pd
import geopandas as gpd

# Assume 'df_outbreaks' is the DataFrame loaded from the 
# 'animal_disease_events_logbook' table using our fetch_all_records function.

if not df_outbreaks.empty:
    # Convert latitude and longitude columns to numeric, coercing errors
    df_outbreaks['latitude'] = pd.to_numeric(df_outbreaks['latitude'], errors='coerce')
    df_outbreaks['longitude'] = pd.to_numeric(df_outbreaks['longitude'], errors='coerce')

    # Drop any rows where conversion failed
    df_outbreaks.dropna(subset=['latitude', 'longitude'], inplace=True)

    # Create the GeoDataFrame
    outbreaks_gdf = gpd.GeoDataFrame(
        df_outbreaks,
        geometry=gpd.points_from_xy(df_outbreaks.longitude, df_outbreaks.latitude),
        crs="EPSG:4326"  # WGS84 - The standard CRS for latitude/longitude data
    )
    
    print("✅ GeoDataFrame created successfully.")
    print(outbreaks_gdf.head())
else:
    print("⚠️ Outbreak DataFrame is empty. Cannot create GeoDataFrame.")
```
With this simple conversion, `outbreaks_gdf` is no longer just a table of numbers. It is a rich geospatial dataset, ready for mapping, spatial joins, and advanced analysis.

## **3.2 First Look: Basic Outbreak Mapping**

The most intuitive first step in any investigation is to visualize the distribution of cases. We will use the `folium` library to create an interactive point map. This allows us to quickly see the geographic spread and identify any obvious visual clusters. We will also add pop-ups to each point, providing immediate access to key information about that specific outbreak event.

```python
import folium

# Ensure the GeoDataFrame exists and is not empty
if 'outbreaks_gdf' in globals() and not outbreaks_gdf.empty:
    # Center the map on the mean coordinates of our data
    map_center = [outbreaks_gdf.latitude.mean(), outbreaks_gdf.longitude.mean()]
    
    # Initialize the map
    outbreak_map = folium.Map(location=map_center, zoom_start=6, tiles="CartoDB positron")

    # Add each outbreak event as a circle marker
    for _, row in outbreaks_gdf.iterrows():
        # Create informative popup text
        popup_html = f"""
        <b>Disease:</b> {row['disease_name']}<br>
        <b>Woreda:</b> {row['woreda_pcode']}<br>
        <b>Reported Date:</b> {row['reported_date']}<br>
        <b>Cases:</b> {row['cases']} | <b>Deaths:</b> {row['deaths']}
        """
        
        folium.CircleMarker(
            location=[row['latitude'], row['longitude']],
            radius=5,
            color='red',
            fill=True,
            fill_color='red',
            fill_opacity=0.6,
            popup=folium.Popup(popup_html, max_width=300)
        ).add_to(outbreak_map)

    # To display in a Jupyter Notebook:
    # display(outbreak_map) 
    
    # To save as a standalone HTML file:
    # outbreak_map.save("outbreak_point_map.html")
    print("✅ Interactive point map generated.")
```
This produces a shareable HTML file containing a fully interactive map. Users can zoom in, pan, and click on any point to get immediate context about that event—a powerful first step in any investigation.

## **3.3 Seeing the Bigger Picture: Aggregating to Geographies**

While a point map is useful, it can become cluttered and difficult to interpret when dealing with thousands of events. The next logical step is to aggregate these points into administrative boundaries to create a **choropleth map**, where each area is colored according to a specific value (in our case, the number of outbreaks).

This process involves a powerful geospatial operation called a **spatial join**. We will count how many outbreak points fall inside each administrative polygon (e.g., Woreda).

```python
# Assume 'gdf_woredas_validated' is the GeoDataFrame of Woreda boundaries from Chapter 1.
if all(name in globals() for name in ['outbreaks_gdf', 'gdf_woredas_validated']):
    # Ensure both GeoDataFrames use the same Coordinate Reference System (CRS)
    gdf_woredas_validated = gdf_woredas_validated.to_crs(outbreaks_gdf.crs)

    # Perform the spatial join
    joined_gdf = gpd.sjoin(outbreaks_gdf, gdf_woredas_validated, how="inner", op='within')

    # Count the number of outbreaks (points) for each Woreda
    outbreak_counts = joined_gdf['woreda_name'].value_counts().reset_index()
    outbreak_counts.columns = ['woreda_name', 'outbreak_count']

    # Merge the counts back to the original Woreda polygons
    gdf_woredas_counts = gdf_woredas_validated.merge(outbreak_counts, on='woreda_name', how='left')
    gdf_woredas_counts['outbreak_count'] = gdf_woredas_counts['outbreak_count'].fillna(0)

    # Create the choropleth map
    m = folium.Map(location=[9.145, 40.4897], zoom_start=6)
    folium.Choropleth(
        geo_data=gdf_woredas_counts,
        name='choropleth',
        data=gdf_woredas_counts,
        columns=['woreda_name', 'outbreak_count'],
        key_on='feature.properties.woreda_name',
        fill_color='YlOrRd', # Yellow-Orange-Red color scale
        fill_opacity=0.7,
        line_opacity=0.2,
        legend_name='Number of Outbreaks per Woreda'
    ).add_to(m)

    # display(m)
    print("✅ Choropleth map of outbreak counts per Woreda generated.")
```
This map immediately provides a clearer picture of the disease burden, highlighting which administrative areas are most affected. But it leads to a critical question: is this pattern meaningful, or just random?

## **3.4 Is it Random? Global Spatial Autocorrelation**

A choropleth map can be misleading. An area might have a high count simply because it is larger or has a higher livestock population. **Exploratory Spatial Data Analysis (ESDA)** provides the statistical tools to determine if the spatial pattern we see is significant.

The core concept is **spatial autocorrelation**: the degree to which features are clustered, dispersed, or randomly located. To measure this for the entire study area, we use a global statistic called **Moran's I**.

Moran's I tests the null hypothesis of complete spatial randomness. The process involves:
1.  **Defining Neighbors:** First, we must tell the algorithm which polygons are neighbors. We use a **spatial weights matrix** for this. The "Queen Contiguity" method is common: two polygons are neighbors if they share a border or even a single corner.
2.  **Calculating the Statistic:** We then calculate Moran's I, which typically ranges from -1 to +1.
    *   **I > 0:** Indicates positive spatial autocorrelation (clustering). High-value areas are near other high-value areas.
    *   **I < 0:** Indicates negative spatial autocorrelation (dispersion, like a checkerboard).
    *   **I ≈ 0:** Indicates a random pattern.
3.  **Assessing Significance:** A p-value is calculated to determine if the observed pattern is statistically significant (typically p < 0.05).

```python
from libpysal.weights import Queen
from esda.moran import Moran
from splot.esda import plot_moran

if 'gdf_woredas_counts' in globals():
    # Define neighbors using Queen Contiguity
    w = Queen.from_dataframe(gdf_woredas_counts)
    w.transform = 'r' # Row-standardize the weights

    # Calculate Moran's I
    moran_global = Moran(gdf_woredas_counts['outbreak_count'], w)
    
    print(f"Global Moran's I Statistic: {moran_global.I:.4f}")
    print(f"P-value (from simulation): {moran_global.p_sim:.4f}")

    # Visualize the Moran Scatterplot
    plot_moran(moran_global, figsize=(8, 6))
    plt.suptitle("Global Moran's I for Woreda Outbreak Counts")
    plt.show()
```
This analysis gives us a single, powerful number and a p-value that tells us *if* our map shows a significant pattern of clustering. If it does, the next logical question is: *where* are those clusters?

## **3.5 Pinpointing the Hotspots: Local Cluster Analysis (LISA)**

The global Moran's I gives us a single number for the entire map. To find the exact locations of significant clusters, we use **Local Indicators of Spatial Association (LISA)**. The Local Moran's I statistic is calculated for *each individual polygon*, comparing its value to the values of its neighbors.

This analysis classifies each significant polygon into one of four categories:
*   **High-High (Hotspot):** A Woreda with a high number of outbreaks, surrounded by other Woredas with high numbers. These are our primary areas of concern.
*   **Low-Low (Cold Spot):** A Woreda with a low number of outbreaks, surrounded by other Woredas with low numbers. These areas may have effective control measures or protective factors.
*   **High-Low (Spatial Outlier):** A high-outbreak Woreda surrounded by low-outbreak neighbors. This might indicate a localized source or a new incursion.
*   **Low-High (Spatial Outlier):** A low-outbreak Woreda surrounded by high-outbreak neighbors. This could be an area with excellent biosecurity that is resisting an encroaching epidemic.

```python
from esda.moran import Moran_Local
from splot.esda import lisa_cluster

if 'moran_global' in globals():
    # Calculate Local Moran's I for each Woreda
    moran_local = Moran_Local(gdf_woredas_counts['outbreak_count'], w)

    # Visualize the results on a LISA Cluster Map
    fig, ax = plt.subplots(figsize=(12, 10))
    lisa_cluster(moran_local, gdf_woredas_counts, p=0.05, ax=ax)
    ax.set_title('LISA Cluster Map for Woreda Outbreaks (p < 0.05)', fontsize=16)
    plt.show()

    # We can also add the cluster type to our DataFrame for reporting
    gdf_woredas_counts['lisa_cluster_type'] = moran_local.q
```
The resulting LISA Cluster Map is the most actionable output of our spatial analysis. It moves beyond simple visualization to a statistically validated map of risk, clearly delineating the hotspots that require immediate attention and the cold spots that may hold lessons for successful disease control.

## **Chapter Summary**

In this chapter, we have journeyed through the complete workflow of spatial epidemiological analysis. We began by making our data "spatially aware" using `GeoDataFrames`. We then created a simple, interactive point map to get a first look at the data. To see the bigger picture, we aggregated our data into a choropleth map, visualizing the density of outbreaks by Woreda.

Most importantly, we moved beyond simple visualization into statistical analysis. We used a Global Moran's I test to confirm that the observed clustering of outbreaks was statistically significant. Finally, we used a Local Moran's I (LISA) analysis to pinpoint the exact locations of the significant **hotspots** and **cold spots**. We have successfully answered the question, "Where is it happening?" with both visual clarity and statistical rigor. In the next chapter, we will turn our attention to the temporal dimension to answer the question, "When did it happen?"