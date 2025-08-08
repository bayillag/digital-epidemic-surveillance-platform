# **Chapter 11: Integrating with GIS - Automating QGIS Workflows**


This chapter serves as a bridge between the Python-notebook environment where the platform was developed and the professional desktop GIS software used by analysts and cartographers. It's a practical guide to operationalizing the platform's analyses.

---

## **Introduction**

While our web-based dashboards provide powerful tools for managers and field staff, the dedicated GIS (Geographic Information System) analyst often requires a more powerful and flexible environment for deep spatial analysis and professional cartography. Software like **QGIS**—the world's leading open-source GIS—provides a rich suite of tools for advanced geoprocessing, sophisticated data styling, and the creation of high-quality, print-ready maps.

A modern surveillance platform should not exist in isolation from these professional tools. The ideal workflow is a seamless integration where the platform's centralized database serves as the "single source of truth" for the GIS analyst. However, manually exporting data from the database and importing it into QGIS for every new analysis is tedious, slow, and prone to error.

This chapter is about building that seamless bridge. We will move beyond the interactive notebook environment and into the world of **PyQGIS**—the Python API that allows us to control and automate the entire QGIS application with code. We will write a standalone Python script that a GIS analyst can run to automatically:
1.  Connect directly to our PostgreSQL database.
2.  Load the necessary spatial layers.
3.  Perform a complex, multi-step analysis.
4.  Produce a final, styled risk map.

By automating this workflow, we ensure that our analyses are repeatable, consistent, and always based on the latest data from the central server. This chapter will demonstrate this process by scripting the complete knowledge-driven risk assessment for Foot and Mouth Disease (FMD), translating the manual workflow from the FAO handbook into a powerful, one-click automated process.

## **11.1 The Power of PyQGIS: Moving Beyond the Notebook**

Every action you can perform with a mouse click in the QGIS interface—from loading a layer to running a geoprocessing tool—can be executed with a line of Python code. This is the power of PyQGIS. It allows us to chain together dozens of individual steps into a single, automated workflow.

For our NAHSP, this provides several key advantages:
*   **Repeatability:** An analyst can re-run a complex risk assessment for a new time period or with updated parameters by changing a single line of code and executing the script.
*   **Consistency:** The script ensures that the exact same methodology (projections, resolutions, classification schemes) is used every time the analysis is run, eliminating human error.
*   **Efficiency:** A process that might take hours of manual clicking can be completed in minutes.
*   **Integration:** The script can directly connect to our live PostgreSQL database, ensuring that every analysis is always performed on the most current data available.

Our goal is to create a standalone Python script (`.py` file) that a GIS analyst can run from their computer's command line to generate the final risk map.

## **11.2 A Practical Example: Scripting a Knowledge-Driven Risk Assessment**

To demonstrate the power of PyQGIS, we will fully automate the "Spatial risk assessment using a knowledge-driven approach" outlined in the FAO's "GIS for spatial analysis of animal health data" handbook. This multi-step process involves loading several risk factor raster layers, standardizing them, normalizing their values, and combining them using a Weighted Linear Combination (WLC).

Our Python script will perform the following steps automatically:

**Step 1: Setup the QGIS Environment and Define Paths**
The script first needs to know where QGIS is installed so it can access its libraries. It then defines the input and output directories for the project.

```python
import os
import sys
from qgis.core import QgsApplication, QgsProcessingFeedback, QgsRasterLayer
# ... other QGIS imports ...

# IMPORTANT: The user must change this path to their QGIS installation
QGIS_INSTALL_PATH = 'C:/Program Files/QGIS 3.28.3'

# Configure and initialize the QGIS application in standalone mode
QgsApplication.setPrefixPath(QGIS_INSTALL_PATH, True)
qgs = QgsApplication([], False)
qgs.initQgis()

# Initialize the QGIS Processing framework
sys.path.append(os.path.join(QGIS_INSTALL_PATH, 'apps/qgis/python/plugins'))
import processing
from processing.core.Processing import Processing
Processing.initialize()
```

**Step 2: Load Spatial Layers**
The script will load all the necessary input layers: the country boundary polygon and the individual raster layers representing our risk factors (e.g., proximity to roads, livestock density).

**Step 3: Standardize the Layers (Clip to Boundary)**
Consistency is key. All raster analyses must be performed on the exact same geographic extent and grid alignment. The script will use the `gdal:cliprasterbymasklayer` processing algorithm to clip each of the risk factor rasters to the country's boundary polygon.

```python
# --- Example of clipping one raster ---
clipped_path = os.path.join(OUTPUT_DIR, 'clipped_livestock_density.tif')
params = {
    'INPUT': 'path/to/original/livestock_density.tif',
    'MASK': 'path/to/country_boundary.shp',
    'OUTPUT': clipped_path
}
processing.run("gdal:cliprasterbymasklayer", params)
```
This is repeated for every risk factor layer.

**Step 4: Normalize the Layers (0-1 Scale)**
A Weighted Linear Combination requires all input layers to be on a common scale, typically 0 to 1, where 0 represents the lowest risk and 1 represents the highest risk. The script will use the `QgsRasterCalculator` to perform this normalization for each layer.

```python
# --- Example of normalizing one raster ---
layer = QgsRasterLayer('path/to/clipped_livestock_density.tif')
stats = layer.dataProvider().bandStatistics(1)
min_val, max_val = stats.minimumValue, stats.maximumValue

normalized_path = os.path.join(OUTPUT_DIR, 'normalized_livestock_density.tif')
expression = f'("{layer.name()}@1" - {min_val}) / ({max_val} - {min_val})'
# ... setup and run QgsRasterCalculator ...
```
This process ensures that a high value in the road proximity layer is directly comparable to a high value in the livestock density layer.

**Step 5: Apply the Weighted Linear Combination (WLC)**
This is the final step, where expert knowledge is encoded. The script uses a dictionary to define the weight (importance) of each risk factor. It then constructs a final `QgsRasterCalculator` expression that multiplies each normalized layer by its weight and sums the results.

```python
# --- Example of the final WLC calculation ---
weights = {'livestock_density': 0.5, 'road_proximity': 0.3, 'water_proximity': 0.2}

expression_parts = []
for name, path in normalized_raster_paths.items():
    expression_parts.append(f'("{name}@1" * {weights[name]})')

final_expression = ' + '.join(expression_parts)
final_risk_map_path = os.path.join(OUTPUT_DIR, 'FMD_RISK_SURFACE.tif')

# ... setup and run QgsRasterCalculator with the final expression ...
```

The output of this script is `FMD_RISK_SURFACE.tif`, a single, powerful raster layer where each pixel's value represents its relative risk score. A GIS analyst can then load this final product into QGIS, apply a color ramp, and produce a professional cartographic map for their final report. The complete, runnable script is provided in Appendix B.

## **Chapter Summary**

In this chapter, we have successfully bridged the gap between our central surveillance platform and the powerful desktop GIS tools used by analysts. By leveraging the PyQGIS API, we have transformed a complex, manual, multi-step risk assessment workflow into a single, automated, one-click script.

This approach embodies the principles of a modern, efficient surveillance system. It ensures that our analyses are **repeatable**, **consistent**, and always based on the **most current data** available from our central database. This frees the GIS analyst from the tedious work of data preparation and allows them to focus on their core expertise: interpreting the results, producing high-quality maps, and communicating spatial intelligence to decision-makers. In the final chapter, we will look to the future, discussing how this platform can be extended and integrated into a broader One Health vision.