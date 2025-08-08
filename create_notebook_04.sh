#!/bin/bash

# ==============================================================================
# Script to Generate the Jupyter Notebook File for the
# "04-Epi-Curve-and-EDR-Dashboard.ipynb"
# ==============================================================================
# This script creates the .ipynb file with all necessary Python code embedded
# in the correct JSON structure for a Jupyter Notebook.
# ==============================================================================

set -e

# Define the output directory and file path
NOTEBOOK_DIR="digital-epidemic-surveillance-platform/notebooks"
OUTPUT_FILE="${NOTEBOOK_DIR}/04-Epi-Curve-and-EDR-Dashboard.ipynb"

echo "--- Creating Epi Curve & EDR Dashboard Notebook: '$OUTPUT_FILE' ---"

# Create the directory if it doesn't exist
mkdir -p "$NOTEBOOK_DIR"

# Use a 'here document' to write the multi-line JSON content into the file.
cat << 'EOF' > "$OUTPUT_FILE"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# The Epidemiologist's Toolkit: Epidemic Curve & EDR Dashboard\n",
    "\n",
    "This notebook provides a powerful tool for temporal analysis of outbreaks. It allows an epidemiologist to visualize the progression of an outbreak over time and to quantify its momentum, answering the critical question: is the outbreak growing or is it under control?\n",
    "\n",
    "**Key Features:**\n",
    "1.  **Hierarchical Filtering:** Cascading dropdowns allow a user to drill down from a national view to a specific Region, Zone, or Woreda.\n",
    "2.  **Epidemic Curve (Epi Curve):** A classic bar chart showing the number of new outbreak events reported each day.\n",
    "3.  **Estimated Dissemination Ratio (EDR):** A line plot showing the time-varying reproductive number. The critical `EDR = 1` threshold is shown, indicating the point at which the outbreak is considered to be moving towards control."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import ipywidgets as widgets\n",
    "from IPython.display import display, clear_output\n",
    "from datetime import timedelta\n",
    "from supabase import create_client, Client\n",
    "from dotenv import load_dotenv\n",
    "import os\n",
    "\n",
    "# Load environment variables and connect to Supabase\n",
    "load_dotenv()\n",
    "supabase_url = os.getenv(\"SUPABASE_URL\")\n",
    "supabase_key = os.getenv(\"SUPABASE_ANON_KEY\")\n",
    "if supabase_url and supabase_key:\n",
    "    supabase: Client = create_client(supabase_url, supabase_key)\n",
    "    print(\"✅ Successfully connected to Supabase.\")\n",
    "else:\n",
    "    print(\"❌ Supabase credentials not found.\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### Part 1: Data Preparation & Helper Functions\n",
    "\n",
    "We start by fetching the master `outbreaks_gdf` which contains all the unified data. We then create a reusable function, `calculate_epidemic_data`, to handle the core epidemiological calculations, and create the data structures needed to power the cascading dropdown widgets."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# This cell reuses the master data fetching and unification logic from the Main Dashboard\n",
    "# In a real application, this might be a shared utility function.\n",
    "try:\n",
    "    outbreaks_res = supabase.table(\"animal_disease_events_logbook\").select(\"*, admin_woredas(woreda_name, admin_zones(zone_name, admin_regions(region_name)))\", count='exact').execute()\n",
    "    df_outbreaks = pd.json_normalize(outbreaks_res.data, sep='_')\n",
    "    # Rename columns for clarity\n",
    "    df_outbreaks.rename(columns={'admin_woredas_woreda_name': 'woreda_name', 'admin_woredas_admin_zones_zone_name': 'zone_name', 'admin_woredas_admin_zones_admin_regions_region_name': 'region_name'}, inplace=True)\n",
    "    df_outbreaks['reported_date'] = pd.to_datetime(df_outbreaks['reported_date'])\n",
    "    outbreaks_gdf = df_outbreaks\n",
    "    print(f\"✅ Fetched and processed {len(outbreaks_gdf)} outbreak events.\")\n",
    "except Exception as e:\n",
    "    outbreaks_gdf = pd.DataFrame()\n",
    "    print(f\"❌ Failed to fetch data: {e}\")\n",
    "\n",
    "if not outbreaks_gdf.empty:\n",
    "    # Create Mappings for Cascading Dropdowns\n",
    "    region_to_zones_map = outbreaks_gdf.groupby('region_name')['zone_name'].unique().apply(lambda x: sorted(list(x))).to_dict()\n",
    "    zone_to_woredas_map = outbreaks_gdf.groupby('zone_name')['woreda_name'].unique().apply(lambda x: sorted(list(x))).to_dict()\n",
    "    print(\"✅ Dropdown mappings are ready.\")\n",
    "\n",
    "def calculate_epidemic_data(df, window_size=7):\n",
    "    if df.empty or df['reported_date'].isnull().all():\n",
    "        return pd.Series(), pd.Series()\n",
    "    daily_counts = df.groupby(df['reported_date'].dt.date).size()\n",
    "    full_date_range = pd.date_range(start=daily_counts.index.min(), end=daily_counts.index.max())\n",
    "    daily_counts = daily_counts.reindex(full_date_range.date, fill_value=0)\n",
    "    numerator = daily_counts.rolling(window=window_size).sum()\n",
    "    denominator = numerator.shift(window_size)\n",
    "    edr = numerator / denominator\n",
    "    edr.replace([np.inf, -np.inf], np.nan, inplace=True)\n",
    "    edr.fillna(0, inplace=True)\n",
    "    return daily_counts, edr"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### Part 2: The Multi-Level Interactive Dashboard\n",
    "\n",
    "This section defines the hierarchical widgets and the main update function that redraws the chart based on the user's geographical selection."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "if not outbreaks_gdf.empty:\n",
    "    # --- 1. DEFINE WIDGETS ---\n",
    "    region_options = ['All Regions'] + sorted(outbreaks_gdf['region_name'].dropna().unique().tolist())\n",
    "    \n",
    "    region_selector = widgets.Dropdown(options=region_options, value='All Regions', description='Region:')\n",
    "    zone_selector = widgets.Dropdown(options=['All Zones'], value='All Zones', description='Zone:')\n",
    "    woreda_selector = widgets.Dropdown(options=['All Woredas'], value='All Woredas', description='Woreda:')\n",
    "\n",
    "    dashboard_output = widgets.Output()\n",
    "\n",
    "    # --- 2. DEFINE OBSERVER FUNCTIONS ---\n",
    "    def on_region_change(change):\n",
    "        zones = ['All Zones']\n",
    "        if region_selector.value != 'All Regions': zones += region_to_zones_map.get(region_selector.value, [])\n",
    "        zone_selector.options = zones\n",
    "\n",
    "    def on_zone_change(change):\n",
    "        woredas = ['All Woredas']\n",
    "        if zone_selector.value != 'All Zones': woredas += zone_to_woredas_map.get(zone_selector.value, [])\n",
    "        woreda_selector.options = woredas\n",
    "\n",
    "    def update_dashboard(change):\n",
    "        with dashboard_output:\n",
    "            clear_output(wait=True)\n",
    "            df = outbreaks_gdf\n",
    "            title_parts = [p for p in [woreda_selector.value, zone_selector.value, region_selector.value] if not p.startswith('All')]\n",
    "            if region_selector.value != 'All Regions': df = df[df['region_name'] == region_selector.value]\n",
    "            if zone_selector.value != 'All Zones': df = df[df['zone_name'] == zone_selector.value]\n",
    "            if woreda_selector.value != 'All Woredas': df = df[df['woreda_name'] == woreda_selector.value]\n",
    "            \n",
    "            title = f\"Epidemic Curve for: {', '.join(title_parts) or 'All Ethiopia'}\"\n",
    "            if df.empty: print(f\"No data for selected criteria.\"); return\n",
    "            \n",
    "            daily_counts, edr = calculate_epidemic_data(df, window_size=7)\n",
    "            \n",
    "            fig, ax1 = plt.subplots(figsize=(15, 6))\n",
    "            ax1.bar(daily_counts.index, daily_counts.values, color='skyblue', label='Daily New Outbreaks')\n",
    "            ax1.set_ylabel('New Outbreaks', color='skyblue'); ax1.tick_params(axis='y', labelcolor='skyblue')\n",
    "            ax2 = ax1.twinx()\n",
    "            ax2.plot(edr.index, edr.values, color='red', marker='.', label='7-Day EDR')\n",
    "            ax2.axhline(y=1, color='darkred', linestyle='--', label='EDR = 1 Threshold')\n",
    "            ax2.set_ylabel('EDR', color='red'); ax2.tick_params(axis='y', labelcolor='red')\n",
    "            plt.title(title, fontsize=16); fig.legend(); plt.show()\n",
    "\n",
    "    # --- 3. LINK WIDGETS AND DISPLAY ---\n",
    "    region_selector.observe(on_region_change, names='value')\n",
    "    zone_selector.observe(on_zone_change, names='value')\n",
    "    for w in [region_selector, zone_selector, woreda_selector]: w.observe(update_dashboard, names='value')\n",
    "    \n",
    "    filters_box = widgets.HBox([region_selector, zone_selector, woreda_selector])\n",
    "    dashboard = widgets.VBox([widgets.HTML(\"<h2>Multi-Level Epidemic Curve Dashboard</h2>\"), filters_box, dashboard_output])\n",
    "    \n",
    "    display(dashboard)\n",
    "    update_dashboard(None) # Initial run\n",
    "else:\n",
    "    print(\"⚠️ Dashboard cannot be displayed as no data was loaded.\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.9.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
EOF

echo ""
echo "✅ Notebook file created successfully at: '$OUTPUT_FILE'"