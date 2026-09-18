# UAE FinPay — Neobank Customer Intelligence Platform
### Predictive Churn, CAC/LTV Unit Economics & AI-Powered Segmentation for a UAE Digital-First Neobank

![Python](https://img.shields.io/badge/Python-3.12-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)
![dbt](https://img.shields.io/badge/dbt--core-1.11-orange)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-yellow)
![Status](https://img.shields.io/badge/status-complete-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A full analytics-to-AI pipeline for a UAE neobank, combining churn prediction, customer segmentation, and unsupervised anomaly detection with a live Power BI decision layer — built entirely on a free, local stack with no cloud dependency.

**Disclosure:** UAE FinPay is a fictional company created for this portfolio. All customer, transaction, and financial data is synthetic or adapted from public Kaggle datasets (PaySim, IBM Telco Churn), layered with a UAE context (AED currency, emirate distribution, KYC fields).

**Built for:** customer analytics, growth/product analytics, and BI-with-ML roles in UAE neobanks and digital-first fintechs.

---

## Executive Summary

This project builds a customer intelligence platform for a UAE neobank using PostgreSQL, dbt, Python (pandas, scikit-learn), and Power BI. It combines a predictive churn model with unsupervised customer segmentation and anomaly detection, then writes all three model outputs back into the warehouse so a single Power BI semantic model can serve growth, risk, and finance stakeholders from one source of truth.

Rather than treating churn prediction as an isolated notebook exercise, the pipeline closes the loop: ML predictions land back in PostgreSQL, dbt reads them as sources and re-models them into governed marts, and Power BI surfaces them next to CAC/LTV and cohort retention — so a churn score is never disconnected from the revenue and acquisition context a growth team actually decides on.

---

## Key Findings

- Logistic Regression achieved an **AUC-ROC of 0.8232**, outperforming Random Forest at **0.7712** — and exceeding the ~0.77 industry benchmark typically cited for churn models.
- **1,343 customers** are predicted to churn within 30 days, representing **AED 392,568/month** in revenue at risk.
- Unsupervised **KMeans segmentation (k=3, silhouette-optimised)** separated the base into two dominant behavioral clusters: **Hibernating (76.2%)** and **New Customers (23.8%)**.
- **Isolation Forest (5% contamination)** flagged **4,987 transactions (5.0%)** as anomalous with no fraud labels required, using purely unsupervised detection.
- A separate, business-rule-based segment tier in the dbt mart layer collapsed to a single tier (**GROWTH_SEGMENT**) across the entire customer base — a synthetic-data limitation distinct from the ML segmentation, and documented below rather than smoothed over.

---

## Business Problem

A neobank’s growth and risk teams need more than dashboards showing what already happened. They need to know:

- Which customers are likely to churn in the next 30 days, and how much revenue that represents.
- Which acquisition channels and professions produce customers worth keeping, on a CAC-vs-LTV basis.
- Where in the onboarding funnel customers are dropping off, and whether that varies by emirate.
- Which customers behave anomalously enough to warrant manual review, without waiting for labeled fraud data.
- Whether the customer base has structurally different segments, or whether apparent segmentation is an artifact of the data.

Without this, retention spend, underwriting-adjacent decisions, and channel budget get allocated on intuition rather than measurable customer economics.

---

## Business Objectives

- Map the onboarding funnel and identify drop-off points by emirate.
- Quantify CAC vs LTV and unit economics by acquisition channel and profession.
- Track cohort retention from M1 through M12.
- Predict 30-day customer churn probability and quantify revenue at risk.
- Track Monthly Active Users (MAU) and ARPU over time.
- Identify high-value customer segments using unsupervised learning.
- Detect transaction anomalies without relying on fraud labels.
- Feed all of the above into a single governed Power BI semantic model.

---

## Data Lineage

```text
Raw data (PaySim + synthetic onboarding + Telco churn)
        ↓
PostgreSQL raw schema
        ↓
dbt staging models (cleaning / standardisation)
        ↓
dbt mart models (finance / product / risk)
        ↓
Python ML layer (churn prediction, segmentation, anomaly detection)
        ↓
ML outputs written back to PostgreSQL
        ↓
dbt models read ML outputs as sources → fct_churn_predictions / fct_anomaly_scores
        ↓
Power BI (star schema: DimEmirate / DimMonth / DimDate, DAX measures, Tabular Editor)