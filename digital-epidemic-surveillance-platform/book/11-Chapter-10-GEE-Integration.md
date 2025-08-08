# **Chapter 10: The Bigger Picture - Environmental Surveillance with Google Earth Engine**

This chapter introduces a significant paradigm shift, moving the platform's capabilities from traditional epidemiology into the advanced realm of environmental and climate-driven risk analysis. It's designed to be an exciting and forward-looking part of the book.

---

## **Introduction**

Animal disease outbreaks do not occur in a vacuum. They are complex ecological events, deeply intertwined with the environment in which they emerge. A prolonged drought can weaken livestock and concentrate them around scarce water sources, accelerating transmission. An unusually wet season can lead to an explosion in mosquito populations, increasing the risk of vector-borne diseases. A shift in land cover from forest to cropland can alter wildlife habitats, increasing the likelihood of contact between wild animals, livestock, and humans.

For decades, incorporating this critical environmental context into routine surveillance has been a monumental challenge, reserved for specialized academic research projects. The sheer scale of the data—terabytes of satellite imagery, climate records, and land cover maps—was beyond the reach of most national veterinary services. The computational power required to analyze it was prohibitive.

That era is now over. **Google Earth Engine (GEE)** has democratized planetary-scale geospatial analysis. It is a cloud-based platform that provides access to a multi-petabyte catalog of satellite imagery and geospatial datasets, along with the server-side computational power to analyze them on the fly. For a National Animal Health Surveillance Program, GEE is not just a new tool; it is a revolutionary leap in capability. It allows us to move beyond simply reacting to outbreaks and begin proactively monitoring the environmental conditions that drive disease risk.

This chapter is our guide to integrating this powerful platform into our NAHSP. We will write a series of Python functions that use the GEE API to connect to this planetary-scale computer. We will build tools to extract key environmental risk factors for any outbreak location, model seasonal drought risk, and create dynamic suitability maps for vector-borne diseases. This is where our platform transcends traditional surveillance and becomes a true One Health intelligence system.

## **10.1 From Points to Pixels: Extracting Environmental Risk Factors**

The most immediate application of GEE is to enrich our existing outbreak data. When a new outbreak is logged in our `animal_disease_events_logbook`, we have its coordinates and date. GEE allows us to instantly query dozens of environmental layers to get a rich, contextual snapshot of the conditions at that precise location and time.

Our core function, `get_environmental_data_at_point`, is a powerful example. It takes a latitude, longitude, and date, and on the GEE servers, it performs a series of complex operations:
1.  It finds the relevant satellite imagery (e.g., from MODIS and CHIRPS) for a 30-day window around the outbreak date.
2.  It calculates key dynamic variables like the **Normalized Difference Vegetation Index (NDVI)**, **Land Surface Temperature (LST)**, and **total precipitation**.
3.  It queries static layers to find the **elevation**, **land cover type** (e.g., forest, cropland, grassland), and **livestock density** from global datasets like the FAO's Gridded Livestock of the World.
4.  It then extracts the values of all these layers for the specific outbreak location and returns them as a clean dictionary.

```python
import ee

def get_environmental_data_at_point(lat, lon, date_str):
    """
    Extracts a comprehensive set of environmental risk factors for a point and date.
    """
    point = ee.Geometry.Point(lon, lat)
    date = ee.Date(date_str)
    date_range = ee.DateRange(date.advance(-15, 'day'), date.advance(15, 'day'))

    # Query multiple GEE Image Collections
    ndvi = ee.ImageCollection('MODIS/061/MOD13A1').filterDate(date_range).select('NDVI').mean()
    lst_celsius = ee.ImageCollection('MODIS/061/MOD11A2').filterDate(date_range).select('LST_Day_1km').mean().multiply(0.02).subtract(273.15)
    elevation = ee.Image('USGS/SRTMGL1_003').select('elevation')
    cattle_density = ee.Image('FAO/GLW_3/Cattle/2010/density')

    # Combine all layers into one image for efficient extraction
    combined_image = ndvi.addBands(lst_celsius).addBands(elevation).addBands(cattle_density)
    
    # Extract the values and return them
    stats = combined_image.reduceRegion(reducer=ee.Reducer.mean(), geometry=point, scale=500).getInfo()
    
    return stats
```
This function transforms a simple outbreak report into a rich analytical record, enabling us to ask deeper questions: Do outbreaks of this disease tend to occur in areas with high cattle density? Are they preceded by a drop in the vegetation index? This is the first step towards data-driven risk modeling.

## **10.2 The Drought Watch: Modeling Seasonal Rainfall Anomalies**

One of the most critical environmental drivers in many regions is rainfall. A failure of the seasonal rains can have cascading effects on animal health. GEE is the perfect tool for building a proactive "Drought Risk Watch" system.

The concept is to compare the rainfall in the current season to the long-term historical average for that *same season*. This tells us not just how much rain has fallen, but whether that amount is normal, above normal, or dangerously below normal. The output is an **anomaly map**, often expressed as "Percent of Normal Rainfall."

Our dashboard for this (detailed in previous work) allows a user to:
1.  **Select a year** (e.g., 2023).
2.  **Select a key season** (e.g., "Kiremt (Jun-Sep)").
3.  The script then uses GEE to perform two massive calculations:
    *   It sums all daily rainfall images from the CHIRPS dataset for the Kiremt months in 2023.
    *   It calculates the *average* total Kiremt rainfall for a 20-year baseline period (e.g., 2000-2020).
4.  It then divides the current year's total by the long-term average and multiplies by 100 to create the final "Percent of Normal" risk map.

This tool allows managers to see, weeks or even months in advance, which regions are facing potential drought conditions, enabling them to pre-position resources, issue advisories to pastoralists, and prepare for potential downstream health consequences.

## **10.3 The Vector Risk Map: A Multi-Criteria Model for Vector-Borne Diseases**

For vector-borne diseases like Rift Valley Fever, the risk is not the disease itself, but the presence of a suitable environment for its vector (e.g., mosquitoes). We can use GEE to create a dynamic "Vector Suitability Index" map using a **Multi-Criteria Decision Analysis (MCDA)** approach.

This knowledge-driven model combines several key environmental factors, each normalized to a 0-1 risk scale:
*   **Temperature Suitability:** Is the temperature within the optimal range for vector survival and reproduction (e.g., 20-30°C)? This becomes a binary layer (1=suitable, 0=unsuitable).
*   **Rainfall Index:** How much rain has fallen recently? We normalize this to a 0-1 scale, where 1 represents the wettest areas, which are most likely to have breeding sites.
*   **Vegetation Index:** How dense is the vegetation? We normalize NDVI to a 0-1 scale to represent the availability of habitat.

We then combine these three layers using a **Weighted Linear Combination**, where we assign weights based on expert opinion of each factor's importance.

`Vector Suitability = (0.4 * Temp Risk) + (0.35 * Rainfall Risk) + (0.25 * Vegetation Risk)`

The result is a single, intuitive risk map where warmer colors indicate a higher environmental suitability for vector proliferation. The dashboard for this allows a user to select any date and instantly generate the risk map for that period. This is proactive surveillance in its most powerful form, providing an early warning of where the risk of vector-borne disease is highest.

## **10.4 The Multi-Level Environmental Dashboard**

The final step is to integrate these powerful GEE capabilities with our administrative boundaries. The master "Environmental Surveillance Dashboard" combines all these concepts into a single interface.

A user can select any Region, Zone, or Woreda from a series of dropdowns. The dashboard then uses the geometry of that specific area as the input for all the GEE analyses. It will:
*   **Calculate and display summary statistics** (average temperature, elevation, etc.) specifically for the selected area.
*   **Generate an interactive map** showing the environmental anomaly layers (e.g., NDVI anomaly) clipped to the boundary of the selected area.
*   **Plot a long-term time-series chart** of vegetation and rainfall for that exact area.

This provides an unprecedented ability to conduct detailed, localized environmental assessments on demand, transforming the way regional veterinary officers can understand and prepare for environmentally-driven health threats.

## **Chapter Summary**

In this chapter, we have fundamentally expanded the capabilities of our NAHSP. By integrating Google Earth Engine, we have added a powerful new dimension of environmental and climatic analysis to our platform. We have built functions to enrich our outbreak data with key risk factors, developed a proactive drought monitoring system based on seasonal rainfall anomalies, and created a dynamic risk model for vector-borne diseases.

By combining these server-side analytics with our administrative boundaries in an interactive dashboard, we have created a true One Health platform. We are no longer just tracking disease; we are monitoring the health of the entire ecosystem. This is the future of surveillance—a future that is proactive, data-driven, and environmentally aware. In the next chapter, we will explore another advanced integration, showing how to automate workflows in dedicated GIS software.
