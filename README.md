# \# UAE FinPay Neobank Customer Intelligence Platform

# 

# Predictive analytics, CAC/LTV, and AI-powered churn prevention for a UAE digital-first neobank. Full analytics-to-AI pipeline built on a free, local stack — no cloud dependency.

# 

# \*\*Disclosure:\*\* UAE FinPay is a fictional company created for this portfolio. All customer, transaction, and financial data is synthetic or derived from public Kaggle datasets (PaySim, IBM Telco Churn), adapted with a UAE context layer (AED currency, emirate distribution, KYC fields).

# 

# \## Business Problems Solved

# 1\. Customer onboarding funnel and drop-off analysis by emirate

# 2\. CAC vs LTV and unit economics by acquisition channel and profession

# 3\. Cohort retention analysis (M1–M12)

# 4\. Predictive customer churn (ML-driven, 30-day probability)

# 5\. Monthly Active Users (MAU) and ARPU tracking

# 6\. High-value customer segment identification

# 7\. Wallet/card/bank-transfer adoption analysis

# 8\. Transaction anomaly detection (unsupervised, no fraud labels required)

# 

# \## Tech Stack

# PostgreSQL 17 · dbt Core 1.11 · Python 3.12 (pandas, scikit-learn) · Power BI Desktop · Tabular Editor · DAX Studio · GitHub

# 

\## Architecture
Raw data (PaySim + synthetic onboarding + Telco churn)
===

# → PostgreSQL raw schema

# → dbt staging models (cleaning/standardisation)

# → dbt mart models (finance / product / risk)

# → Python ML layer (churn prediction, segmentation, anomaly detection)

# → ML outputs written back to PostgreSQL

# → dbt models read ML outputs as sources

→ Power BI (star schema, DAX measures, Tabular Editor for model refinement)

===

\## AI/ML Models

| Model | Technique | Result |

|---|---|---|

| Churn Prediction | Logistic Regression + Random Forest | AUC-ROC 0.8232 (Logistic Regression) |

| Customer Segmentation | KMeans (k=3, silhouette-optimised) | Hibernating (76.2%), New Customers (23.8%) |

| Anomaly Detection | Isolation Forest (5% contamination) | 5.0% anomaly rate, 4,987 flagged transactions |



\## Key Results

\- Predicted churners: 1,343 customers

\- Revenue at risk from churn: AED 392,568/month

\- Note: AUC of 0.8232 exceeds the \~0.77 industry benchmark for churn models, reflecting clean signal separation in the underlying dataset.



\## Business Impact

\[Write 3–4 sentences: what a UAE fintech could act on — e.g. targeted retention campaigns for the 1,343 at-risk customers worth AED 392K/month, reallocating CAC spend toward channels with best LTV:CAC ratio, prioritising anomalous high-value transactions for manual review.]



\## Business Recommendations

\[Write 3–5 bullet points tied to the mart model outputs — e.g. onboarding funnel bottleneck by emirate, channel reallocation, segment-specific retention playbooks.]



\## Limitations

\- Synthetic/adapted datasets — not live UAE neobank data; some transaction amounts (from PaySim) are unrealistically large, inflating anomaly exposure figures

\- Churn signals adapted from a telecom dataset — feature semantics (e.g. "has\_investment") are proxies, not native neobank behavioural data

\- No live data refresh — Power BI connects to a static PostgreSQL snapshot, not a streaming pipeline



\## Repository Structure

data/ raw datasets (gitignored)

notebooks/ Python EDA and AI analytics notebooks

charts/ saved chart outputs

dbt\_project/ dbt models (staging + marts)

sql\_analysis/ data quality, business rule validation, reconciliation (planned)

