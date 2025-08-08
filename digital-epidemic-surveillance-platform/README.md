# The Digital Epidemic: A Guide to Building a Modern National Animal Health Surveillance Platform

### *From Data to Decision*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)

This repository is the official open-source companion to the book, "The Digital Epidemic." It provides the complete database schemas, Python code, and Jupyter notebooks required to build and deploy a comprehensive National Animal Health Surveillance Platform (NAHSP).

## The Case for a Unified Digital System

Traditional animal health surveillance is often fragmented across paper forms, disconnected spreadsheets, and siloed databases. This creates an "information-rich, insight-poor" environment where responding to outbreaks is slow and proactive management is nearly impossible.

This project provides a practical, end-to-end blueprint for building a modern, unified system that transforms raw data into real-time, actionable intelligence.

## Core Features of the Platform

*   **Scalable Database Backend:** A robust PostgreSQL schema to manage everything from outbreak logs and detailed field investigations to vaccination campaigns and program evaluations.
*   **Spatial & Temporal Analysis:** Tools to create interactive maps, pinpoint statistically significant hotspots (LISA), visualize epidemic curves, and calculate the reproductive ratio (EDR).
*   **Operational Dashboards:** A suite of interactive dashboards built with `ipywidgets` for high-level surveillance, vaccination campaign management, outbreak investigation, and system evaluation (SERVAL).
*   **Environmental Surveillance:** Integration with **Google Earth Engine** to build proactive risk models for drought and vector-borne diseases.
*   **Automated Reporting:** A master engine to generate professional, shareable reports in **HTML**, **PDF**, and **Microsoft Word (.docx)** formats on demand.

## Repository Structure & Getting Started

Please refer to the book manuscript in the [`book/`](./book/) directory for detailed instructions on setting up the backend, running the notebooks, and understanding the methodology behind each component. A quick start guide is provided below.

### 1. Set Up the Python Environment
It is highly recommended to use a virtual environment.
```bash
python -m venv venv
source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
pip install -r requirements.txt
