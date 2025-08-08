# digital-epidemic-surveillance-platform
A complete guide and open-source implementation of a modern National Animal Health Surveillance Platform, from database design to operational dashboards and automated reporting.

# The Digital Epidemic: A Guide to Building a Modern National Animal Health Surveillance Platform

### *From Data to Decision*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)

This repository is the official open-source companion to the book, "The Digital Epidemic: A Guide to Building a Modern National Animal Health Surveillance Platform" It provides the complete database schemas, Python code, and Jupyter notebooks required to build and deploy a comprehensive National Animal Health Surveillance Platform (NAHSP).

## The Case for a Unified Digital System

Traditional animal health surveillance is often fragmented across paper forms, disconnected spreadsheets, and siloed databases. This creates an "information-rich, insight-poor" environment where responding to outbreaks is slow and proactive management is nearly impossible.

This project provides a practical, end-to-end blueprint for building a modern, unified system that transforms raw data into real-time, actionable intelligence.

## Core Features of the Platform

*   **Scalable Database Backend:** A robust PostgreSQL schema to manage everything from outbreak logs and detailed field investigations to vaccination campaigns and program evaluations.
*   **Spatial & Temporal Analysis:** Tools to create interactive maps, pinpoint statistically significant hotspots (LISA), visualize epidemic curves, and calculate the reproductive ratio (EDR).
*   **Operational Dashboards:** A suite of interactive dashboards built with `ipywidgets` for:
    *   **High-Level Surveillance (WAHIS-Inspired):** A command center for CVOs and program managers.
    *   **Vaccination Campaign Management:** A logistical hub for tracking performance, inventory, and cold chain integrity.
    *   **Outbreak Investigation:** A deep-dive tool for epidemiologists to explore investigation findings and risk pathways.
    *   **System Evaluation (SERVAL):** A dashboard for monitoring the performance of the surveillance system itself.
*   **Environmental Surveillance:** Integration with **Google Earth Engine** to build proactive risk models for drought and vector-borne diseases.
*   **Automated Reporting:** A master engine to generate professional, shareable reports in **HTML**, **PDF**, and **Microsoft Word (.docx)** formats on demand.

## Technology Stack

*   **Backend:** Supabase (Managed PostgreSQL)
*   **Primary Language:** Python 3.9+
*   **Core Libraries:** Pandas, GeoPandas, Supabase, ipywidgets
*   **Geospatial Analysis:** Folium, `esda` (PySAL), Google Earth Engine API (`earthengine-api`), geemap
*   **Reporting:** Matplotlib, WeasyPrint, python-docx, Selenium
