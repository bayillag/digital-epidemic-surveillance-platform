# **Chapter 1: The Blueprint - Designing a Scalable Database Schema**

The Chapter 1, written to be informative, authoritative, and accessible. It establishes the "why" behind the design choices before presenting the "what," guiding the reader through the architectural philosophy of the platform.

---

## **Introduction**

Before a single brick is laid for a skyscraper, architects and engineers spend countless hours perfecting its blueprint. They understand that the foundation dictates the strength, height, and longevity of the entire structure. A flawed foundation will amplify its weaknesses through every subsequent floor, leading to cracks, instability, and eventual failure. A well-designed foundation, however, provides a stable, resilient base upon which great things can be built.

A database schema is the foundation of any digital information system. For a National Animal Health Surveillance Platform, the design of this schema is the single most important factor determining its success. A poorly designed schema will be rigid, inefficient, and difficult to maintain, leading to slow performance, frustrated users, and an inability to adapt to new challenges. A well-designed schema, however, creates a system that is fast, flexible, scalable, and—most importantly—a powerful tool in the hands of epidemiologists and decision-makers.

This chapter is our architectural blueprint. We will lay out the core design principles and then detail the structure of every table that forms the foundation of our NAHSP. We will not only present the `CREATE TABLE` statements but also explain the purpose and rationale behind each design choice. This schema is the bedrock upon which every dashboard, analysis, and report in the subsequent chapters will be built.

## **1.1 The Core Principles: Normalization and Flexibility**

Our database architecture is guided by two fundamental principles: **normalization** to ensure data integrity and the use of **JSONB** to provide structured flexibility.

**Normalization: The "Single Source of Truth"**

In simple terms, normalization is the practice of ensuring that every piece of information is stored in only one place. For example, the name of a region, like "Oromia," should exist in exactly one row in a table dedicated to regions. Other tables that need to reference Oromia will do so by storing a unique identifier (its `region_pcode` or `id`), not by re-typing the name.

The benefits of this are immense:
*   **Data Integrity:** If the name needs to be corrected (e.g., a typo), you only have to change it in one place. This change is instantly reflected everywhere that references it, eliminating the risk of inconsistent data.
*   **Efficiency:** Storing a small integer or a short code is far more space-efficient than storing a long text string hundreds or thousands of times. This leads to a smaller, faster database.
*   **Clarity:** The structure of the data becomes logical and self-documenting.

**Flexibility with `JSONB`: The Schema within the Schema**

The traditional challenge of database design for a platform like ours is accommodating the vast differences between species. The key questions in a swine outbreak investigation (e.g., "What is the parity structure of the herd?") are entirely different from those in a poultry investigation (e.g., "What was the source hatchery?"). A rigid, traditional schema would require creating hundreds of columns, most of which would be empty for any given investigation.

This is where PostgreSQL's `JSONB` data type becomes our superpower. A `JSONB` column allows us to store rich, structured data—like a text file with key-value pairs—directly within a database row. This gives us the best of both worlds: a structured, relational core for universal data (dates, locations, IDs) and a flexible, "schema-within-a-schema" for species-specific details. We will use this extensively in our investigation and risk assessment tables to create a system that can adapt to any animal health scenario without requiring a database administrator to change the table structure.

## **1.2 Modeling the Real World: Administrative Boundaries**

The foundation of any spatial analysis is a clear and accurate representation of geography. Our platform models the administrative hierarchy of the nation through a series of linked tables.

*   `admin_regions`: The highest level (e.g., a state or federal region).
*   `admin_zones`: The next level down.
*   `admin_woredas`: The primary unit for many local operations.
*   `admin_kebeles`: The most granular community-level unit.

Each table is linked to the one above it through a foreign key constraint, enforcing the hierarchy. One Region can have many Zones, but each Zone belongs to exactly one Region.

```sql
CREATE TABLE public.admin_regions (
    region_place_code text primary key,
    region_name text not null unique
);

CREATE TABLE public.admin_zones (
    zone_place_code text primary key,
    zone_name text not null,
    region_place_code text not null references public.admin_regions(region_place_code)
);

CREATE TABLE public.admin_woredas (
    woreda_place_code text primary key,
    woreda_name text not null,
    zone_place_code text not null references public.admin_zones(zone_place_code),
    woreda_map geometry(Polygon, 4326) -- For storing map polygons
);

CREATE TABLE public.admin_kebeles (
    kebele_place_code text primary key,
    kebele_name text not null,
    woreda_place_code text not null references public.admin_woredas(woreda_place_code)
);
```

## **1.3 The Knowledge Base: `animal_diseases`**

This is one of the most critical tables in the entire system. Instead of hard-coding vital epidemiological information into our Python scripts, we store it in the database. This table becomes the central, authoritative source of truth for disease characteristics.

```sql
CREATE TABLE public.animal_diseases (
  disease_code text primary key,
  disease_name text not null unique,
  incubation_period_min_days integer,
  incubation_period_max_days integer,
  species_affected text[],
  zoonotic_potential boolean,
  transmission text,
  -- ... other fields from the full schema ...
);
```
Storing `incubation_period_min_days` and `incubation_period_max_days` here is the key that unlocks the powerful, dynamic case tracing analysis we will build in Chapter 5. If new research reveals a more accurate incubation period for a disease, an administrator updates one row in this table, and every future analysis on the platform is instantly corrected.

## **1.4 The Front Line: The `animal_disease_events_logbook`**

This is our main transactional table, designed for speed and simplicity. It captures the initial report of an outbreak event. We make a conscious design choice here to **denormalize** slightly by including columns from the parent "master event" (like `event_start_date`). While this duplicates a small amount of data, it means that our most frequent queries for high-level dashboard summaries can be run on this single table without requiring complex `JOIN`s, making the user interface fast and responsive.

```sql
CREATE TABLE public.animal_disease_events_logbook (
    outbreak_event_id bigint generated always as identity primary key,
    -- Master Event Info (Denormalized)
    event_id bigint,
    event_start_date date,
    -- Individual Outbreak Info
    woreda_pcode text references public.admin_woredas(woreda_pcode),
    disease_code text references public.animal_diseases(disease_code),
    reported_date date not null,
    cases integer not null,
    deaths integer not null,
    -- ... other fields from the full schema ...
);
```

## **1.5 The Deep Dive: Structuring Outbreak Investigations**

This is where our `JSONB` strategy shines. An investigation is a deep, complex process. We model it with a central `outbreak_investigations` table linked to several child tables for one-to-many data.

The main table captures the universal details, including the crucial `primary_species_investigated` field, which sets the context for the flexible data to follow.

```sql
CREATE TABLE public.outbreak_investigations (
    investigation_id bigint generated by default as identity primary key,
    outbreak_event_id bigint references public.animal_disease_events_logbook(outbreak_event_id),
    primary_species_investigated text not null,
    -- ... other universal fields ...
    population_characteristics_details jsonb,
    biosecurity_details jsonb
);
```
The child tables capture the repeating sections of the investigation form:
*   `investigation_diagnostic_tests`: For the list of lab tests.
*   `investigation_nearby_premises`: For other farms/sites in the area.
*   `risk_pathway_assessments`: This is the most powerful child table. It stores the final risk assessment (Low/Medium/High) for each potential pathway (e.g., 'Live Animal Entry', 'Feed Delivery'). Its `pathway_details` `JSONB` column stores all the specific question-and-answer data for that pathway, perfectly mirroring the structure of the field form.

## **1.6 Proactive Management: The Vaccination Campaign Schema**

Effective surveillance includes proactive measures. Our schema includes a complete subsystem for managing vaccination campaigns, from planning and resource allocation to field execution and monitoring. The core tables include `vaccination_campaigns`, `vaccine_batches`, `vaccination_sites`, `personnel`, and the crucial `vaccine_stock_ledger` which provides a fully auditable trail for every single dose. The full SQL for this subsystem is provided in Appendix A.

## **1.7 Closing the Loop: The SERVAL Evaluation Schema**

Finally, a surveillance system must be able to evaluate itself. We include a dedicated set of tables for implementing the SERVAL (SuRveillance EVALuation) framework. This allows managers to conduct formal evaluations of their own programs, assessing them against standard attributes like Timeliness, Cost, and Sensitivity, and storing the results directly within the platform. This creates a cycle of continuous improvement. The full SQL is provided in Appendix A.

## **Chapter Summary**

The database schema is the most critical component of our platform. By adhering to the principles of normalization for integrity and leveraging the flexibility of `JSONB` for species-specific details, we have designed a blueprint that is both robust and adaptable. We have created dedicated tables for administrative boundaries, a disease knowledge base, event logging, deep investigations, vaccination campaigns, and system evaluation.

This is our foundation. It is solid, scalable, and ready. In the next chapter, we will begin to build upon it, writing the backend code and data ingestion pipelines that will bring this blueprint to life.