# Data Dictionary

Column definitions for the raw, ML-output and dbt mart layers of the UAE FinPay Neobank Customer Intelligence Platform. All data is synthetic or adapted from public datasets (see the [README](README.md)). Raw tables store emirate names in title case; the dbt staging layer converts them to upper case.

## raw.transactions (from PaySim, UAE-adapted)

| Column | Type | Description |
|---|---|---|
| transaction_id | text | Unique transaction identifier |
| customer_id | text | Customer identifier (`NC_` + last six characters of the PaySim originator ID) |
| transaction_date | timestamp | Synthetic timestamp, 5-minute intervals from 2026-01-01 |
| amount_aed | numeric | PaySim amount multiplied by 3.67 |
| emirate | text | Dubai / Abu Dhabi / Sharjah / Ajman (weights 45 / 25 / 20 / 10) |
| payment_channel | text | card / wallet / bank_transfer |
| product_type | text | payment / transfer / wallet_top_up |
| is_fraud | integer | 0/1 flag from PaySim source labels |

## raw.onboarding (synthetic)

| Column | Type | Description |
|---|---|---|
| customer_id | text | Customer identifier (`NC_100000` onwards) |
| signup_date | date | Date of signup |
| emirate | text | Customer emirate |
| profession | text | Customer profession category |
| acquisition_channel | text | app_store / referral / social_media / google_ads / employer_partnership |
| cac_usd / cac_aed | numeric | Customer acquisition cost in USD and AED |
| kyc_completed | integer | 0/1 |
| kyc_completion_days | integer | Days to complete KYC (null if not completed) |
| first_transaction_days | integer | Days to first transaction after KYC (null if KYC not completed) |
| monthly_revenue_usd / monthly_revenue_aed | numeric | Average monthly revenue per customer |
| tenure_months | integer | Months since signup (1–18) |
| ltv_usd / ltv_aed | numeric | Monthly revenue × tenure months (revenue to date) |
| is_active | integer | 0/1 |
| nationality | text | Customer nationality group |

## raw.churn_signals (adapted from IBM Telco Churn)

| Column | Type | Description |
|---|---|---|
| customer_id | text | Customer identifier (`NC_200000` onwards) |
| tenure_months | integer | Months as customer |
| monthly_revenue_aed | numeric | Telco monthly charges × 3.67 (ARPU proxy) |
| has_wallet | integer | Proxy flag mapped from Telco phone service |
| has_savings | integer | Proxy flag mapped from Telco multiple lines |
| has_investment | integer | Proxy flag mapped from Telco fibre internet service |
| is_churned | integer | 0/1 |
| contract_type | text | Contract type (Telco-origin field) |
| emirate | text | Customer emirate (synthetic weights) |

## raw.ml_churn_predictions (Python-generated)

| Column | Type | Description |
|---|---|---|
| customer_id | text | Customer identifier |
| churn_probability_pct | numeric | Predicted churn probability (%) |
| predicted_churn_flag | integer | 0/1, set when probability exceeds 50% |
| segment_label | text | KMeans-derived segment (Hibernating / New_Customers) |
| monthly_revenue_aed | numeric | Revenue used for risk weighting |
| emirate | text | Customer emirate |

## raw.ml_anomaly_scores (Python-generated)

| Column | Type | Description |
|---|---|---|
| transaction_id | text | Transaction identifier |
| customer_id | text | Customer identifier |
| amount_aed | numeric | Transaction amount |
| is_anomaly | integer | 0/1, Isolation Forest flag (5% contamination) |
| anomaly_confidence | numeric | Higher means more anomalous |
| emirate | text | Transaction emirate |

## dbt mart models

| Model | Layer | Description |
|---|---|---|
| fct_onboarding_funnel | product | Signup → KYC → activation funnel by emirate |
| fct_mau_arpu | product | Monthly active users and ARPU trend |
| fct_segment_performance | product | LTV/CAC by profession and emirate (all customers), with rule-based `segment_strategy` |
| fct_cac_ltv | finance | CAC, LTV and payback by emirate, channel and profession (KYC-completed customers only) |
| fct_cohort_retention | finance | M1–M12 retention by signup cohort |
| fct_wallet_adoption | finance | Payment channel share and volume |
| fct_churn_signals | risk | RFM-style churn risk scoring (`churn_risk_score`, `churn_risk_tier`, `priority_flag`) |
| fct_churn_predictions | risk | ML churn probability, alert level and revenue at risk |
| fct_anomaly_scores | risk | ML anomaly flags with priority tiers |

## Derived classification fields

| Field | Model | Rule |
|---|---|---|
| churn_alert_level | fct_churn_predictions | CRITICAL ≥ 70% • HIGH ≥ 50% • MEDIUM ≥ 30% • LOW below 30% |
| revenue_at_risk_aed | fct_churn_predictions | Monthly revenue if predicted_churn_flag = 1, otherwise 0 |
| anomaly_priority | fct_anomaly_scores | HIGH_PRIORITY: anomaly ≥ AED 10,000 • MEDIUM_PRIORITY: anomaly ≥ AED 5,000 • LOW_PRIORITY: other anomalies • NORMAL: not flagged |
| churn_risk_score | fct_churn_signals | Recency (tenure) + monetary (revenue) + engagement (feature adoption) scores |
| priority_flag | fct_churn_signals | HIGH_VALUE_AT_RISK when monthly revenue ≥ AED 300 and churn_risk_score ≥ 8, otherwise STANDARD |
| segment_strategy | fct_segment_performance | PRIORITY ≥ 3.0x LTV:CAC • GROWTH ≥ 2.0x • WATCH ≥ 1.0x • REVIEW below 1.0x |
| unit_economics_status | fct_cac_ltv | EXCELLENT ≥ 3.0x • GOOD ≥ 2.0x • BREAK_EVEN ≥ 1.0x • LOSS_MAKING below 1.0x |

---

## Complete column catalogue (generated from PostgreSQL)

185 columns across 17 tables and views in the `raw` and `dbt_dev` schemas of `neobank_db`, read from `information_schema`. The sections above describe the business meaning of the main fields; the derivation of every mart column is in the dbt model SQL under `dbt_project/uae_finpay_neobank/models/`. The AED columns in `raw.onboarding` equal the USD columns multiplied by 3.67 (checks DQ-08 to DQ-10 in `sql_analysis/`).

### dbt_dev.fct_anomaly_scores (table)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_id` | text | YES |
| `customer_id` | text | YES |
| `emirate` | text | YES |
| `amount_aed` | numeric | YES |
| `is_anomaly` | bigint | YES |
| `anomaly_confidence` | numeric | YES |
| `anomaly_priority` | text | YES |

### dbt_dev.fct_cac_ltv (table)

| Column | Data type | Nullable |
|---|---|---|
| `emirate` | text | YES |
| `acquisition_channel` | text | YES |
| `profession` | text | YES |
| `customer_count` | bigint | YES |
| `avg_cac_aed` | numeric | YES |
| `avg_ltv_aed` | numeric | YES |
| `avg_monthly_revenue_aed` | numeric | YES |
| `avg_payback_months` | numeric | YES |
| `ltv_to_cac_ratio` | numeric | YES |
| `total_ltv_aed` | numeric | YES |
| `total_cac_aed` | numeric | YES |
| `unit_economics_status` | text | YES |

### dbt_dev.fct_churn_predictions (table)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `emirate` | text | YES |
| `churn_probability_pct` | numeric | YES |
| `predicted_churn_flag` | bigint | YES |
| `monthly_revenue_aed` | numeric | YES |
| `segment_label` | text | YES |
| `churn_alert_level` | text | YES |
| `revenue_at_risk_aed` | numeric | YES |

### dbt_dev.fct_churn_signals (table)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `emirate` | text | YES |
| `tenure_months` | integer | YES |
| `monthly_revenue_aed` | numeric | YES |
| `has_wallet` | integer | YES |
| `has_savings` | integer | YES |
| `has_investment` | integer | YES |
| `feature_adoption_count` | bigint | YES |
| `is_churned` | integer | YES |
| `customer_lifecycle_stage` | text | YES |
| `contract_type` | text | YES |
| `recency_score` | integer | YES |
| `monetary_score` | integer | YES |
| `engagement_score` | integer | YES |
| `churn_risk_score` | integer | YES |
| `churn_risk_tier` | text | YES |
| `priority_flag` | text | YES |

### dbt_dev.fct_cohort_retention (table)

| Column | Data type | Nullable |
|---|---|---|
| `cohort_month` | text | YES |
| `cohort_size` | bigint | YES |
| `retained_m1` | bigint | YES |
| `retained_m2` | bigint | YES |
| `retained_m3` | bigint | YES |
| `retained_m6` | bigint | YES |
| `retained_m12` | bigint | YES |
| `retention_m1_pct` | numeric | YES |
| `retention_m2_pct` | numeric | YES |
| `retention_m3_pct` | numeric | YES |
| `retention_m6_pct` | numeric | YES |
| `retention_m12_pct` | numeric | YES |
| `avg_revenue_aed` | numeric | YES |

### dbt_dev.fct_mau_arpu (table)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_month` | text | YES |
| `emirate` | text | YES |
| `mau` | bigint | YES |
| `total_transactions` | bigint | YES |
| `total_volume_aed` | numeric | YES |
| `avg_transaction_aed` | numeric | YES |
| `arpu_aed` | numeric | YES |
| `prev_month_mau` | bigint | YES |
| `mau_mom_growth_pct` | numeric | YES |
| `volume_mom_growth_pct` | numeric | YES |

### dbt_dev.fct_onboarding_funnel (table)

| Column | Data type | Nullable |
|---|---|---|
| `emirate` | text | YES |
| `total_signups` | bigint | YES |
| `completed_kyc` | bigint | YES |
| `made_first_transaction` | bigint | YES |
| `currently_active` | bigint | YES |
| `kyc_conversion_rate_pct` | numeric | YES |
| `activation_rate_pct` | numeric | YES |
| `overall_active_rate_pct` | numeric | YES |
| `avg_kyc_days` | numeric | YES |
| `avg_days_to_first_txn` | numeric | YES |

### dbt_dev.fct_segment_performance (table)

| Column | Data type | Nullable |
|---|---|---|
| `profession` | text | YES |
| `emirate` | text | YES |
| `customer_count` | bigint | YES |
| `avg_cac_aed` | numeric | YES |
| `avg_ltv_aed` | numeric | YES |
| `avg_monthly_revenue_aed` | numeric | YES |
| `avg_payback_months` | numeric | YES |
| `ltv_cac_ratio` | numeric | YES |
| `kyc_completed_count` | bigint | YES |
| `kyc_rate_pct` | numeric | YES |
| `active_customers` | bigint | YES |
| `active_rate_pct` | numeric | YES |
| `ltv_rank` | bigint | YES |
| `segment_strategy` | text | YES |

### dbt_dev.fct_wallet_adoption (table)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_month` | text | YES |
| `emirate` | text | YES |
| `payment_channel` | text | YES |
| `transaction_count` | bigint | YES |
| `total_volume_aed` | numeric | YES |
| `unique_customers` | bigint | YES |
| `avg_transaction_aed` | numeric | YES |
| `channel_share_pct` | numeric | YES |
| `volume_share_pct` | numeric | YES |

### dbt_dev.stg_churn_signals (view)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `tenure_months` | integer | YES |
| `monthly_revenue_aed` | numeric | YES |
| `has_wallet` | integer | YES |
| `has_savings` | integer | YES |
| `has_investment` | integer | YES |
| `is_churned` | integer | YES |
| `contract_type` | text | YES |
| `emirate` | text | YES |
| `customer_lifecycle_stage` | text | YES |
| `feature_adoption_count` | bigint | YES |

### dbt_dev.stg_customers (view)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `signup_date` | date | YES |
| `signup_month` | text | YES |
| `emirate` | text | YES |
| `profession` | text | YES |
| `acquisition_channel` | text | YES |
| `cac_aed` | numeric | YES |
| `kyc_completed` | integer | YES |
| `kyc_completion_days` | bigint | YES |
| `first_transaction_days` | bigint | YES |
| `monthly_revenue_aed` | numeric | YES |
| `tenure_months` | integer | YES |
| `ltv_aed` | numeric | YES |
| `is_active` | integer | YES |
| `nationality` | text | YES |
| `payback_months` | numeric | YES |

### dbt_dev.stg_transactions (view)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_id` | text | YES |
| `customer_id` | text | YES |
| `transaction_date` | timestamp without time zone | YES |
| `transaction_date_only` | date | YES |
| `transaction_month` | text | YES |
| `month_number` | numeric | YES |
| `year_number` | numeric | YES |
| `amount_aed` | numeric | YES |
| `emirate` | text | YES |
| `payment_channel` | text | YES |
| `product_type` | text | YES |
| `is_fraud` | integer | YES |

### raw.churn_signals (table)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `tenure_months` | bigint | YES |
| `monthly_revenue_aed` | double precision | YES |
| `has_wallet` | bigint | YES |
| `has_savings` | bigint | YES |
| `has_investment` | bigint | YES |
| `is_churned` | bigint | YES |
| `contract_type` | text | YES |
| `emirate` | text | YES |

### raw.ml_anomaly_scores (table)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_id` | text | YES |
| `customer_id` | text | YES |
| `amount_aed` | double precision | YES |
| `is_anomaly` | bigint | YES |
| `anomaly_confidence` | double precision | YES |
| `emirate` | text | YES |

### raw.ml_churn_predictions (table)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `churn_probability_pct` | double precision | YES |
| `predicted_churn_flag` | bigint | YES |
| `segment_label` | text | YES |
| `monthly_revenue_aed` | double precision | YES |
| `emirate` | text | YES |

### raw.onboarding (table)

| Column | Data type | Nullable |
|---|---|---|
| `customer_id` | text | YES |
| `signup_date` | timestamp without time zone | YES |
| `emirate` | text | YES |
| `profession` | text | YES |
| `acquisition_channel` | text | YES |
| `cac_usd` | double precision | YES |
| `cac_aed` | double precision | YES |
| `kyc_completed` | bigint | YES |
| `kyc_completion_days` | bigint | YES |
| `first_transaction_days` | bigint | YES |
| `monthly_revenue_usd` | double precision | YES |
| `monthly_revenue_aed` | double precision | YES |
| `tenure_months` | integer | YES |
| `ltv_usd` | double precision | YES |
| `ltv_aed` | double precision | YES |
| `is_active` | bigint | YES |
| `nationality` | text | YES |

### raw.transactions (table)

| Column | Data type | Nullable |
|---|---|---|
| `transaction_id` | text | YES |
| `customer_id` | text | YES |
| `transaction_date` | timestamp without time zone | YES |
| `amount_aed` | double precision | YES |
| `emirate` | text | YES |
| `payment_channel` | text | YES |
| `product_type` | text | YES |
| `is_fraud` | bigint | YES |
