# Compliance & Regulatory Context

This project is a fictional portfolio exercise built to demonstrate analytics and data-engineering capability for the UAE fintech sector. It references real UAE regulatory frameworks for context and realism, but it does not constitute compliance advice or an actual compliance implementation.

## Referenced Frameworks

- **CBUAE AML/CFT/CPF Guidance Package (April 2026)** — informs the anomaly-detection and review-signal framing used across the UAE FinPay portfolio.
- **PDPL — UAE Federal Decree-Law No. 45 of 2021 on the Protection of Personal Data** — informs the data-handling note below.

## PDPL Note

All ML models in this project operate on anonymised `customer_id` values only. No personally identifiable information (names, Emirates ID, phone numbers, physical addresses) is used, stored or processed at any stage. This reflects the purpose-limitation and data-minimisation approach set out in the PDPL processing controls (Article 5), applied here for portfolio demonstration purposes.

In practice, personal data held by a licensed bank may also fall under sector-specific CBUAE requirements, so a real deployment would need its own legal review.

## Model Governance Note

- Churn probabilities are analytical estimates, not decisions about individual customers.
- Anomaly flags are review signals, not fraud determinations. Human investigation would be required before any action.
- Model outputs are written back to PostgreSQL and documented in the [data dictionary](data_dictionary.md), so every downstream metric can be traced to its source.

## Scope Disclaimer

This is not a regulated financial product and was not built for, or reviewed by, an MLRO, compliance officer or legal counsel. It should not be used as a template for regulatory submissions. Regulatory references exist solely to demonstrate awareness of the environment a UAE fintech data analyst would work within.
