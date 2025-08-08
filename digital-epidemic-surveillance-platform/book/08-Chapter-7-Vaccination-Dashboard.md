# **Chapter 7: Managing the Campaign - The Vaccination Dashboard**

This chapter shifts the focus from reactive surveillance (monitoring outbreaks) to proactive intervention (managing vaccination campaigns). It is a practical, operations-focused chapter that demonstrates how to build a logistical command center.

---

## **Introduction**

Surveillance tells us where the fire is. Intervention is about putting the fire out. While outbreak monitoring is a critical function of any NAHSP, the ultimate goal is to control and prevent disease. The most powerful tool in our arsenal for proactive control is the vaccination campaign. However, a successful campaign is a monumental logistical challenge. It is an intricate dance of supply chain management, cold chain integrity, resource allocation, and field team coordination.

A campaign manager is constantly asking critical questions: Do we have enough vaccine doses in the central store? Has the shipment arrived at the Afar regional hub? What is the current temperature in the refrigerators at the Debark district office? Which vaccinators have been dispatched their equipment? How many cattle have we vaccinated in the Borena zone, and how does that compare to our target?

Answering these questions with data from paper logbooks and phone calls is slow, inefficient, and prone to error. To manage a modern campaign, we need a digital command center. This chapter is about building that center. We will construct a dedicated, multi-tabbed **Vaccination Campaign Dashboard** that provides a real-time, comprehensive overview of every aspect of a campaign, from the national level down to the individual vaccinator. This dashboard is the logistical backbone of our platform, designed to transform campaign data into operational intelligence.

## **7.1 The Backend: A Database Built for Logistics**

Before we can build a dashboard, we need a robust data foundation. As detailed in Chapter 1, our database schema includes a comprehensive set of tables specifically designed for vaccination management. The most critical of these is the `vaccine_stock_ledger`.

This table is not just a simple inventory count. It is a **fully auditable, transactional ledger**. Every single movement of a vaccine batch—from its initial receipt at the central store, to its transfer to a regional hub, its dispatch to a vaccinator, its administration to an animal, and even its disposal as wastage—is recorded as an immutable transaction.

```sql
-- A simplified view of the vaccine_stock_ledger table
CREATE TABLE public.vaccine_stock_ledger (
    ledger_id bigint primary key,
    batch_id bigint references public.vaccine_batches(batch_id),
    transaction_type public.stock_transaction_type_enum not null,
    quantity_doses_changed integer not null, -- Positive for in, negative for out
    transaction_date timestamp with time zone not null,
    site_id bigint references public.vaccination_sites(site_id),
    personnel_id bigint references public.personnel(personnel_id)
);
```
This design is incredibly powerful. To find the current stock of a vaccine batch at any site, we simply sum all transactions for that `batch_id` at that `site_id`. This provides a complete, auditable history of every vial, ensuring accountability and enabling powerful logistical analysis. Our dashboard will be built upon this rock-solid foundation.

## **7.2 Designing for the Campaign Manager: A Multi-Tabbed Interface**

A campaign has multiple facets, and our dashboard must reflect this. A single screen with too much information would be overwhelming. Instead, we will use a tabbed interface (`widgets.Tab`) to organize the information into logical sections, allowing a manager to drill down into the area that requires their immediate attention.

Our dashboard will have four primary tabs:

**1. Overview:** The high-level summary. This tab will show the campaign's progress against its targets, a map of vaccination activity, and key KPIs.
**2. Inventory & Cold Chain:** The logistics hub. This tab will focus on vaccine stock levels at every site in the distribution chain and monitor the status of the cold chain.
**3. Field Operations:** The personnel management view. This tab will track the activity of individual vaccinators and teams.
**4. Pharmacovigilance:** The safety monitoring center. This tab will display any reported adverse reactions to the vaccines.

## **7.3 Building the Dashboard, Tab by Tab**

We will construct the dashboard by creating a dedicated function to generate the content for each tab. The main dashboard will allow the user to select an active campaign from a dropdown, which will then trigger all the tab functions to populate with the relevant data.

### **Tab 1: The Overview**

This is the first screen a CVO or campaign manager will see. It needs to answer the most important question: "Are we on track?"

*   **KPIs:** Simple, bold numbers showing "Total Animals Vaccinated," "Percent of Target Achieved," and "Vaccines Administered Today."
*   **Performance Chart:** A bar chart comparing the number of animals vaccinated in each region against the pre-defined targets from the `campaign_targets` table.
*   **Activity Map:** A `folium` map showing the locations of `vaccination_visits`. We will use a heatmap or cluster map to visualize the intensity of vaccination activities across the country.

### **Tab 2: Inventory & Cold Chain**

This tab provides the critical supply chain intelligence.

*   **Stock Levels Table:** A detailed pivot table, generated with pandas, showing the current number of available doses for each vaccine batch at every `vaccination_site` (from Central Store down to District Office).
*   **Wastage Analysis:** A pie chart showing the breakdown of vaccine wastage, calculated from the `vaccine_stock_ledger`.
*   **Cold Chain Status:** A table displaying the most recent temperature readings from the `cold_chain_logs` table for each site's refrigerator, color-coded to flag any deviations from the safe range (2-8°C).

```python
# Simplified logic for generating the stock level table
def get_current_stock(df_ledger):
    # Sum all transactions grouped by site and batch
    current_stock = df_ledger.groupby(['site_name', 'vaccine_name', 'batch_number'])['quantity_doses_changed'].sum()
    return current_stock.reset_index()
```

### **Tab 3: Field Operations**

This tab focuses on the performance and activity of the vaccinators.

*   **Vaccinator Leaderboard:** A simple table showing the number of animals vaccinated per day by each vaccinator (`personnel`), allowing managers to identify high-performing and potentially struggling teams.
*   **Daily Activity Log:** A filterable list of all `vaccination_visits` conducted on the current day, showing which owner was visited by which vaccinator.
*   **Equipment Tracking:** A summary from the `equipment_stock_ledger` showing which teams have been dispatched critical supplies like cooler boxes and sharps containers.

### **Tab 4: Pharmacovigilance**

This tab is dedicated to monitoring vaccine safety.

*   **Adverse Reaction Log:** A table listing all reports from the `adverse_reaction_reports` table.
*   **Batch Alert System:** The logic will automatically flag if multiple adverse reaction reports are linked to the *same* `batch_id`. This is a critical early warning system that can trigger a recall or investigation into a specific vaccine batch.

## **7.4 The Complete System in Action**

The full Python script for this dashboard is a sophisticated orchestration of database queries, pandas data manipulation, and `ipywidgets` layout. The core logic resides in a central `update_dashboard` function that is triggered when a user selects a campaign from the main dropdown.

```python
# --- The main update function's workflow ---
def update_vaccination_dashboard(change):
    selected_campaign_id = campaign_selector.value
    
    # 1. Fetch all transactional data for this campaign from the database
    # (vaccination_records, vaccine_stock_ledger, etc.)
    
    # 2. Update the Overview Tab
    # - Calculate KPIs and performance vs. targets
    # - Generate and display the activity map
    
    # 3. Update the Inventory & Cold Chain Tab
    # - Calculate current stock levels and create the pivot table
    # - Display the latest temperature logs
    
    # 4. Update the Field Operations Tab
    # - Create the vaccinator leaderboard
    
    # 5. Update the Pharmacovigilance Tab
    # - Display adverse reaction reports and check for batch alerts
```
The full code is provided in Appendix B.

## **Chapter Summary**

A vaccination campaign is a complex logistical operation. In this chapter, we have designed and built the digital command center needed to manage it effectively. By leveraging our purpose-built database schema, we have created a multi-tabbed dashboard that provides real-time intelligence on every facet of the campaign.

From monitoring high-level performance against targets to tracking the temperature of a single refrigerator in a remote district office, this dashboard transforms a mountain of logistical data into clear, actionable insights. It empowers campaign managers to identify bottlenecks, mitigate risks, and ensure that vaccines are delivered safely and effectively to the animals that need them. In the next chapter, we will turn our attention inward, building a dashboard to evaluate the performance of our surveillance system itself.