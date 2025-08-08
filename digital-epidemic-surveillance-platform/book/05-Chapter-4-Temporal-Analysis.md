# **Chapter 4: When did it Happen? Temporal Analysis**

This chapter focuses on the time dimension of an outbreak, providing the tools to visualize its progression, measure its speed, and assess the effectiveness of control measures. It is written to be a practical guide that builds directly on the data structures and concepts from the previous chapters.

---

## **Introduction**

Time is the currency of an epidemic. The speed at which a disease spreads dictates the window of opportunity for intervention. Understanding the temporal pattern of an outbreak—when it began, how fast it grew, when it peaked, and whether it is truly declining—is fundamental to every aspect of disease control. A temporal analysis transforms a static list of cases into a dynamic narrative, revealing the outbreak's character, its momentum, and the effectiveness of our response.

While the maps in the previous chapter showed us *where* the problem was, the charts in this chapter will tell us *when* it occurred and how it is evolving. We will construct the most essential tool in outbreak investigation: the **epidemic curve (epi curve)**. This simple histogram, showing the number of new cases over time, is a powerful visual diagnostic. Its shape can suggest the mode of transmission, identify the probable exposure period, and track the impact of control measures.

But visualization alone is not enough. To manage an ongoing outbreak, we need a quantitative measure of its speed. To achieve this, we will calculate the **Estimated Dissemination Ratio (EDR)**, a practical, time-varying estimate of the reproductive number. The EDR answers the most critical question for any program manager: Is the outbreak growing or is it under control? By the end of this chapter, you will be able to build a multi-level, interactive dashboard that provides this crucial temporal intelligence for any disease at any geographical scale, from a single woreda to the entire nation.

## **4.1 The Heart of the Analysis: The Epidemic Curve**

The epidemic curve is a histogram that plots the number of new cases (y-axis) against a unit of time (x-axis). Its power lies in its simplicity. By looking at the shape of the curve, an epidemiologist can form a working hypothesis about the nature of the outbreak.

*   **Point Source Outbreak:** Characterized by a sharp, rapid rise in cases followed by a quick decline. This suggests a single, common exposure event (e.g., a contaminated feed batch).
*   **Propagated Outbreak:** Characterized by a series of progressively taller peaks. This suggests person-to-person or animal-to-animal transmission, where each wave of cases serves as the source for the next.

Our first task is to write a Python function that can take any subset of our outbreak data and generate a clean, daily count of new events. The key is to create a complete date range from the first to the last reported case and then fill in any days that had zero new outbreaks. This ensures our timeline is continuous and accurate.

```python
import pandas as pd
import matplotlib.pyplot as plt

# Assume 'outbreaks_gdf' is the GeoDataFrame loaded from the database.
# Ensure the 'reported_date' column is a proper datetime object.
if 'outbreaks_gdf' in globals():
    outbreaks_gdf['reported_date'] = pd.to_datetime(outbreaks_gdf['reported_date'])

def generate_daily_counts(df):
    """
    Calculates the daily number of new outbreak events from a DataFrame.

    Args:
        df (DataFrame): A DataFrame containing a 'reported_date' column.
    
    Returns:
        pd.Series: A pandas Series with a continuous date index and counts of new outbreaks.
    """
    if df.empty:
        return pd.Series()
        
    # Group by date and count the number of events for each day
    daily_counts = df.groupby(df['reported_date'].dt.date).size()
    
    # Create a full date range to ensure days with zero cases are included
    if not daily_counts.empty:
        full_date_range = pd.date_range(start=daily_counts.index.min(), 
                                        end=daily_counts.index.max())
        daily_counts = daily_counts.reindex(full_date_range.date, fill_value=0)
    
    return daily_counts

# Example Usage:
# daily_outbreak_counts = generate_daily_counts(outbreaks_gdf)
# print(daily_outbreak_counts.head())
```

With this function, we can now easily visualize the epidemic curve for our entire dataset.

```python
# --- Visualizing the National Epidemic Curve ---
if 'daily_outbreak_counts' in globals() and not daily_outbreak_counts.empty:
    fig, ax = plt.subplots(figsize=(15, 6))
    
    ax.bar(daily_outbreak_counts.index, daily_outbreak_counts.values, 
           color='skyblue', label='Daily New Outbreak Events')
    
    ax.set_xlabel('Date', fontsize=12)
    ax.set_ylabel('Number of New Outbreaks', fontsize=12)
    ax.set_title('National Epidemic Curve for All Diseases', fontsize=16)
    ax.grid(True, axis='y', linestyle='--', alpha=0.6)
    
    plt.show()
```
This plot gives us the first, high-level overview of the temporal pattern of all outbreaks across the country.

## **4.2 Measuring the Momentum: The Estimated Dissemination Ratio (EDR)**

While the epi curve is excellent for understanding the history of an outbreak, we need a forward-looking metric to manage it. The **Estimated Dissemination Ratio (EDR)** provides this. It is a simple, powerful calculation:

**EDR = (Number of new cases in the *current* time period) / (Number of new cases in the *previous* time period)**

The interpretation is direct and actionable:
*   **EDR > 1:** The outbreak is **growing**. Each case is generating more than one new case.
*   **EDR < 1:** The outbreak is **declining** and moving towards control.
*   **EDR = 1:** The outbreak is at a **plateau**.

We will enhance our previous function to calculate a rolling EDR. A 7-day window is a common choice, meaning we compare the number of cases in the last 7 days to the number of cases in the 7 days prior to that.

```python
import numpy as np

def calculate_epidemic_data(df, window_size=7):
    """
    Calculates daily outbreak counts and the Estimated Dissemination Ratio (EDR).
    """
    if df.empty:
        return pd.Series(), pd.Series()
        
    daily_counts = generate_daily_counts(df)

    # Calculate the EDR using a rolling sum
    numerator = daily_counts.rolling(window=window_size).sum()
    denominator = numerator.shift(window_size)
    
    edr = numerator / denominator
    
    # Clean up results: replace infinite values and fill NaNs
    edr.replace([np.inf, -np.inf], np.nan, inplace=True)
    edr.fillna(0, inplace=True)
    
    return daily_counts, edr

# Example Usage:
# daily_counts, edr_series = calculate_epidemic_data(outbreaks_gdf)
```
Now we can create a combined plot that shows the epidemic curve and the EDR on the same timeline. This is the single most important chart for an outbreak management meeting.

```python
# --- Visualizing the Combined Epi Curve and EDR ---
if 'daily_counts' in globals():
    fig, ax1 = plt.subplots(figsize=(15, 6))

    # Plot 1: Epidemic Curve (Bars)
    ax1.bar(daily_counts.index, daily_counts.values, color='skyblue', label='Daily New Outbreaks')
    ax1.set_ylabel('Number of New Outbreaks', color='skyblue')

    # Plot 2: EDR (Line on a second y-axis)
    ax2 = ax1.twinx()
    ax2.plot(edr_series.index, edr_series.values, color='red', marker='.', label='7-Day EDR')
    ax2.set_ylabel('Estimated Dissemination Ratio (EDR)', color='red')
    
    # Add the critical EDR = 1 control threshold line
    ax2.axhline(y=1, color='darkred', linestyle='--', linewidth=2, label='EDR = 1 (Control Threshold)')
    
    plt.title('National Epidemic Curve and EDR', fontsize=16)
    fig.legend(loc="upper right", bbox_to_anchor=(0.9,0.88))
    plt.show()
```
This chart tells a complete story. We can see when the outbreak peaked (where the blue bars are highest) and, critically, we can see the point in time when the red line crossed below the dashed line, indicating that our control measures were beginning to succeed.

## **4.3 A Multi-Level View: The Interactive Dashboard**

The true power of our platform is the ability to perform this analysis not just at the national level, but for any geographical area or disease of interest. To achieve this, we build an interactive dashboard using `ipywidgets`.

The dashboard will feature a series of cascading dropdown menus:
1.  **Region Selector**
2.  **Zone Selector**
3.  **Woreda Selector**
4.  **Disease Selector**

As the user makes a selection in a higher-level dropdown (e.g., choosing "Amhara" as the region), the options in the lower-level dropdowns are automatically filtered. Once the user has defined their area and disease of interest, the dashboard's core update function is triggered. This function filters our master `outbreaks_gdf` DataFrame according to the user's selections, passes the filtered data to our `calculate_epidemic_data` function, and then redraws the combined epi curve and EDR chart.

The full implementation of this interactive dashboard is a significant piece of code that combines data manipulation, widget logic, and plotting. The complete script is provided in Appendix B and was detailed in our previous work. The key takeaway is the architecture:
*   **Centralized Data:** One master GeoDataFrame (`outbreaks_gdf`) holds all the data.
*   **Hierarchical Filtering:** Widgets allow the user to slice this data by geography and disease.
*   **Reusable Logic:** A single, robust function (`calculate_epidemic_data`) performs the core epidemiological calculations.
*   **Dynamic Visualization:** A plotting function takes the results and renders the final, informative chart.

This design allows an analyst to move seamlessly from a national overview to a highly localized view, for example, generating the specific epi curve for a Lumpy Skin Disease outbreak in a single woreda, providing unparalleled situational awareness.

## **Chapter Summary**

In this chapter, we have mastered the temporal dimension of outbreak analysis. We have learned how to construct and interpret the fundamental epidemic curve, which visualizes the history and character of an outbreak. More importantly, we have moved into the realm of real-time management by learning to calculate and plot the Estimated Dissemination Ratio (EDR), our key metric for assessing whether an outbreak is growing or declining.

By encapsulating this logic into a flexible, multi-level dashboard, we have created a powerful tool for monitoring disease dynamics at any scale. We have answered the question, "When did it happen?" and, crucially, we have also provided the tools to answer, "What is happening now?" In the next chapter, we will combine our spatial and temporal skills to tackle the most complex question of all: "How did it happen?" as we dive into the world of case tracing and outbreak investigation.
