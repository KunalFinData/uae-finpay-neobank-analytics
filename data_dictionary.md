\# Data Dictionary



\## raw.transactions (from PaySim, UAE-adapted)

| Column | Type | Description |

|---|---|---|

| transaction\_id | text | Unique transaction identifier |

| customer\_id | text | Customer identifier |

| transaction\_date | timestamp | Transaction timestamp |

| amount\_aed | numeric | Transaction amount in AED |

| emirate | text | Dubai / Abu Dhabi / Sharjah / Ajman |

| payment\_channel | text | card / wallet / bank\_transfer |

| product\_type | text | payment / transfer / wallet\_top\_up |

| is\_fraud | integer | 0/1 flag from PaySim source labels |



\## raw.onboarding (synthetic)

| Column | Type | Description |

|---|---|---|

| customer\_id | text | Customer identifier |

| signup\_date | date | Date of signup |

| emirate | text | Customer emirate |

| profession | text | Customer profession category |

| acquisition\_channel | text | app\_store / referral / social\_media / google\_ads / employer\_partnership |

| cac\_aed | numeric | Customer acquisition cost |

| kyc\_completed | integer | 0/1 |

| kyc\_completion\_days | integer | Days to complete KYC (null if not completed) |

| first\_transaction\_days | integer | Days to first transaction post-KYC |

| monthly\_revenue\_aed | numeric | Average monthly revenue per customer |

| tenure\_months | integer | Months since signup |

| ltv\_aed | numeric | Lifetime value in AED |

| is\_active | integer | 0/1 |

| nationality | text | Customer nationality group |



\## raw.churn\_signals (adapted from Telco churn)

| Column | Type | Description |

|---|---|---|

| customer\_id | text | Customer identifier |

| tenure\_months | integer | Months as customer |

| monthly\_revenue\_aed | numeric | ARPU proxy |

| has\_wallet / has\_savings / has\_investment | integer | Feature adoption flags |

| is\_churned | integer | 0/1 |

| contract\_type | text | Contract type (Telco-origin field) |

| emirate | text | Customer emirate |



\## raw.ml\_churn\_predictions (Python-generated)

| Column | Type | Description |

|---|---|---|

| customer\_id | text | Customer identifier |

| churn\_probability\_pct | numeric | Predicted churn probability (%) |

| predicted\_churn\_flag | integer | 0/1, threshold at 50% |

| segment\_label | text | KMeans-derived segment |

| monthly\_revenue\_aed | numeric | Revenue for risk-weighting |

| emirate | text | Customer emirate |



\## raw.ml\_anomaly\_scores (Python-generated)

| Column | Type | Description |

|---|---|---|

| transaction\_id | text | Transaction identifier |

| customer\_id | text | Customer identifier |

| amount\_aed | numeric | Transaction amount |

| is\_anomaly | integer | 0/1, Isolation Forest flag |

| anomaly\_confidence | numeric | Higher = more anomalous |

| emirate | text | Transaction emirate |



\## dbt mart models

| Model | Layer | Description |

|---|---|---|

| fct\_onboarding\_funnel | product | Signup → KYC → activation funnel by emirate |

| fct\_cac\_ltv | finance | CAC, LTV, payback period by emirate/channel/profession |

| fct\_cohort\_retention | finance | M1–M12 retention by signup cohort |

| fct\_mau\_arpu | product | Monthly active users and ARPU trend |

| fct\_wallet\_adoption | finance | Payment channel share and volume |

| fct\_segment\_performance | product | LTV/CAC ranked segments by profession/emirate |

| fct\_churn\_signals | risk | RFM-style churn risk scoring |

| fct\_churn\_predictions | risk | ML churn probability + revenue-at-risk, alert tiers |

| fct\_anomaly\_scores | risk | ML anomaly flags with priority tiers |

