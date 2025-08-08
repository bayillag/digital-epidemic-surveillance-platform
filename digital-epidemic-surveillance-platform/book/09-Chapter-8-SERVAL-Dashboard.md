# **Chapter 8: The System's Health Check - The SERVAL Evaluation Dashboard**

This chapter is a crucial part of the "Operational Dashboards" section, as it focuses on the vital but often overlooked process of self-evaluation and continuous improvement for the surveillance system itself.

---

## **Introduction**

How do we know if our surveillance system is actually working? It is a surprisingly difficult question to answer. A system might generate vast amounts of data, but is that data timely? Is it accurate? Does it have a real-world impact on disease control? Is the benefit we derive from the system worth the cost and effort of running it?

Simply having a surveillance system is not enough. To ensure it remains effective, efficient, and relevant, we must periodically perform a health check on the system itself. This process of structured evaluation is fundamental to building a sustainable and trustworthy National Animal Health Surveillance Platform. Without it, systems can become bloated, inefficient, and misaligned with the country's most pressing animal health needs.

In this chapter, we will build the ultimate tool for this critical task: the **SERVAL Evaluation Dashboard**. SERVAL (SuRveillance EVALuation) is a generic framework designed to facilitate the comprehensive and systematic evaluation of any animal health surveillance system. Our database schema, as detailed in Chapter 1, includes a dedicated set of tables for storing the results of these evaluations.

This dashboard will serve as the central repository and explorer for all completed evaluations. It will allow program managers, epidemiologists, and stakeholders to search for relevant evaluations, review their findings at a glance, and drill down into the detailed analysis behind the conclusions. This tool transforms the evaluation process from a static report that gathers dust on a shelf into a living, interactive resource for continuous improvement.

## **8.1 A Database for Meta-Analysis**

The foundation of this dashboard is the set of SERVAL tables we designed in Chapter 1. The architecture is key:
*   `serval_attributes`: A master lookup table containing the 22 standard attributes (e.g., Timeliness, Cost, Sensitivity) against which any system can be judged.
*   `serval_evaluations`: The main table, where each row represents a complete evaluation of a specific surveillance program (e.g., "Evaluation of Bovine TB Pre-Movement Testing, 2017").
*   `evaluation_attribute_assessments`: The results table. This crucial junction table links each evaluation to the specific attributes that were assessed and stores the detailed findings for each one.

The real power of this design comes from our backend function, `get_full_serval_report`. This PostgreSQL function joins these three tables on the server and delivers a complete, structured dataset to our Python script in a single, efficient call. This allows our dashboard to be both comprehensive and highly performant.

## **8.2 Designing for the Program Manager: The Evaluation Explorer**

The primary user of this dashboard is a manager or policymaker who needs to understand the strengths and weaknesses of different surveillance activities. The dashboard must allow them to both find relevant evaluations and quickly grasp their key findings.

Our interface will be a two-panel "explorer" layout:
*   **Left Panel (The Filter Panel):** This area contains dropdown menus that allow the user to search and filter the entire library of evaluations. They can filter by `Disease`, `Region`, `Zone`, or `Woreda` to find evaluations relevant to their specific area of interest. As they apply filters, a list of matching reports will dynamically appear below.
*   **Right Panel (The Report Viewer):** This is the main display area. When the user clicks on a report from the list in the left panel, this panel will populate with the full, detailed results of that evaluation.

## **8.3 Building the Report Viewer: Visuals and Details**

The heart of the dashboard is the report viewer, which presents the evaluation's findings in three distinct sections.

**1. The "Traffic Light" Visual Summary**
Decision-makers often need a high-level summary before they dive into the details. We will provide this using a series of color-coded "KPI cards." Each assessed attribute will be displayed as a card, with its background color determined by its final score.

*   **Green (`#27ae60`):** Excellent/Very Good
*   **Yellow (`#f1c40f`):** Good, room for improvement
*   **Red (`#e74c3c`):** Poor, in need of attention
*   **Grey (`#bdc3c7`):** Not Assessed

This "traffic light" system provides an instant, intuitive overview of the surveillance system's performance, allowing a manager to immediately see which areas are strong and which require urgent attention.

```python
# Simplified logic for creating a single KPI card
color_map = {
    'Excellent/Very Good': '#27ae60', 
    'Good, room for improvement': '#f1c40f',
    'Poor, in need of attention': '#e74c3c'
}
attribute_name = "Timeliness"
attribute_score = "Good, room for improvement"

card_html = f"""
<div style="background-color:{color_map.get(attribute_score)}; color:white; text-align:center; padding:10px; border-radius:5px;">
    <div style="font-weight:bold;">{attribute_name}</div>
</div>
"""
```

**2. The Detailed Assessment Accordion**
Beneath the visual summary, we need to provide the "why." For this, we use an `Accordion` widget. The accordion will have one section for each assessed attribute. The title of each section will show the attribute's name (e.g., "Sensitivity"). When the user clicks to expand a section, it will reveal the detailed text from the `assessment_summary` column in the database—the full justification and analysis written by the evaluators. This design keeps the initial view clean and uncluttered while providing easy access to deep information.

**3. Strengths, Weaknesses, and Recommendations**
Finally, the dashboard will display the overall conclusions of the evaluation in three clearly marked boxes:
*   A summary of the system's **Strengths**.
*   A summary of its **Weaknesses**.
*   A list of actionable **Recommendations** for improvement.

This final section translates the detailed attribute assessments into a clear, strategic summary for policymakers.

## **8.4 The Complete System in Action**

The full Python script orchestrates this entire workflow. It begins by calling the `get_full_serval_report` database function to load the entire library of evaluations into a pandas DataFrame.

The core of the interactivity is the `update_filtered_list` observer function. This function is linked to all the filter dropdowns in the left panel.
1.  Whenever a filter is changed, it applies the new criteria to the main DataFrame.
2.  It identifies the unique `evaluation_id`s that match the criteria.
3.  It then dynamically creates a list of clickable `Button` widgets, one for each matching report.

Each of these dynamically created buttons has its own click handler. When a user clicks a button, it calls the `display_evaluation_details` function, passing the specific `evaluation_id` of that report. This function then populates the right-hand panel with the header, the visual KPI cards, the detailed accordion, and the final recommendations for that single evaluation. The full code is provided in Appendix B.

## **Chapter Summary**

A surveillance system without a mechanism for self-evaluation is destined to become obsolete. In this chapter, we have built the ultimate tool for continuous improvement: the SERVAL Evaluation Explorer. By leveraging our purpose-built database schema, we have created an interactive dashboard that serves as a central, searchable library for all surveillance program evaluations.

The dashboard transforms static, text-heavy reports into a dynamic, engaging user experience. The powerful filtering capabilities allow managers to quickly find the information they need, while the "traffic light" summary and detailed accordion provide both a high-level overview and a deep dive into the findings. This tool closes the loop on the surveillance cycle, ensuring that we not only collect data but also critically assess *how* we collect it, leading to a more efficient, effective, and resilient National Animal Health Surveillance Platform. In the next chapter, we will focus on the final output of our entire system: the automated generation of professional reports for stakeholders.