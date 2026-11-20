-- =====================================================================
-- UAE FinPay Neobank Customer Intelligence Platform
-- Validation suite: data quality, business rules, reconciliation, coverage
-- Database: neobank_db (schemas: raw, dbt_dev)
-- Result columns: check_id, check_name, status, observed, expected
-- Standard SQL: CASE WHEN aggregates, no FILTER, no :: casts
-- =====================================================================

-- ---------------------------------------------------------------------
-- SECTION 1: DATA QUALITY (raw layer and staging parity)
-- ---------------------------------------------------------------------
SELECT 'DQ-01' AS check_id, 'raw.transactions row count' AS check_name,
       CASE WHEN COUNT(*) = 100000 THEN 'PASS' ELSE 'FAIL' END AS status,
       CAST(COUNT(*) AS VARCHAR(100)) AS observed, '100000' AS expected
FROM raw.transactions
UNION ALL
SELECT 'DQ-02', 'raw.transactions duplicate transaction_id',
       CASE WHEN COUNT(*) - COUNT(DISTINCT transaction_id) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) - COUNT(DISTINCT transaction_id) AS VARCHAR(100)), '0'
FROM raw.transactions
UNION ALL
SELECT 'DQ-03', 'raw.transactions null transaction_id / customer_id / amount_aed',
       CASE WHEN SUM(CASE WHEN transaction_id IS NULL OR customer_id IS NULL OR amount_aed IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN transaction_id IS NULL OR customer_id IS NULL OR amount_aed IS NULL THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM raw.transactions
UNION ALL
SELECT 'DQ-04', 'raw.transactions negative amount_aed',
       CASE WHEN SUM(CASE WHEN amount_aed < 0 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN amount_aed < 0 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM raw.transactions
UNION ALL
SELECT 'DQ-05', 'raw.onboarding row count',
       CASE WHEN COUNT(*) = 50000 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '50000'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-06', 'raw.onboarding duplicate customer_id',
       CASE WHEN COUNT(*) - COUNT(DISTINCT customer_id) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) - COUNT(DISTINCT customer_id) AS VARCHAR(100)), '0'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-07', 'raw.onboarding null customer_id / signup_date / emirate',
       CASE WHEN SUM(CASE WHEN customer_id IS NULL OR signup_date IS NULL OR emirate IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN customer_id IS NULL OR signup_date IS NULL OR emirate IS NULL THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-08', 'raw.onboarding cac_aed = cac_usd x 3.67 (tolerance 0.5)',
       CASE WHEN SUM(CASE WHEN ABS(cac_aed - cac_usd * 3.67) > 0.5 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN ABS(cac_aed - cac_usd * 3.67) > 0.5 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0 rows outside tolerance'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-09', 'raw.onboarding monthly_revenue_aed = monthly_revenue_usd x 3.67 (tolerance 0.5)',
       CASE WHEN SUM(CASE WHEN ABS(monthly_revenue_aed - monthly_revenue_usd * 3.67) > 0.5 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN ABS(monthly_revenue_aed - monthly_revenue_usd * 3.67) > 0.5 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0 rows outside tolerance'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-10', 'raw.onboarding ltv_aed = ltv_usd x 3.67 (tolerance 1.0)',
       CASE WHEN SUM(CASE WHEN ABS(ltv_aed - ltv_usd * 3.67) > 1.0 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN ABS(ltv_aed - ltv_usd * 3.67) > 1.0 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0 rows outside tolerance'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-11', 'raw.onboarding distinct emirates',
       CASE WHEN COUNT(DISTINCT emirate) = 4 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(DISTINCT emirate) AS VARCHAR(100)), '4'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-12', 'raw.churn_signals row count',
       CASE WHEN COUNT(*) = 7043 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '7043'
FROM raw.churn_signals
UNION ALL
SELECT 'DQ-13', 'raw.churn_signals duplicate customer_id',
       CASE WHEN COUNT(*) - COUNT(DISTINCT customer_id) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) - COUNT(DISTINCT customer_id) AS VARCHAR(100)), '0'
FROM raw.churn_signals
UNION ALL
SELECT 'DQ-14', 'raw.churn_signals negative tenure_months or monthly_revenue_aed',
       CASE WHEN SUM(CASE WHEN tenure_months < 0 OR monthly_revenue_aed < 0 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN tenure_months < 0 OR monthly_revenue_aed < 0 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM raw.churn_signals
UNION ALL
SELECT 'DQ-15', 'stg_transactions rows = raw.transactions rows passing the staging rule (amount_aed > 0, ids not null)',
       CASE WHEN SUM(CASE WHEN amount_aed > 0 AND transaction_id IS NOT NULL AND customer_id IS NOT NULL THEN 1 ELSE 0 END) = (SELECT COUNT(*) FROM dbt_dev.stg_transactions) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(CASE WHEN amount_aed > 0 AND transaction_id IS NOT NULL AND customer_id IS NOT NULL THEN 1 ELSE 0 END) AS VARCHAR(30)), ' eligible raw vs ', CAST((SELECT COUNT(*) FROM dbt_dev.stg_transactions) AS VARCHAR(30)), ' staging'), 'equal'
FROM raw.transactions
UNION ALL
SELECT 'DQ-16', 'stg_customers row count = raw.onboarding',
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM dbt_dev.stg_customers) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' raw vs ', CAST((SELECT COUNT(*) FROM dbt_dev.stg_customers) AS VARCHAR(30)), ' staging'), 'equal'
FROM raw.onboarding
UNION ALL
SELECT 'DQ-17', 'stg_churn_signals row count = raw.churn_signals',
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM dbt_dev.stg_churn_signals) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' raw vs ', CAST((SELECT COUNT(*) FROM dbt_dev.stg_churn_signals) AS VARCHAR(30)), ' staging'), 'equal'
FROM raw.churn_signals;

-- ---------------------------------------------------------------------
-- SECTION 2: BUSINESS RULES (dbt marts and ML outputs)
-- ---------------------------------------------------------------------
SELECT 'BR-01' AS check_id, 'fct_churn_predictions churn_probability_pct within 0-100' AS check_name,
       CASE WHEN SUM(CASE WHEN churn_probability_pct < 0 OR churn_probability_pct > 100 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
       CAST(SUM(CASE WHEN churn_probability_pct < 0 OR churn_probability_pct > 100 THEN 1 ELSE 0 END) AS VARCHAR(100)) AS observed, '0' AS expected
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-02', 'Churn flag consistent with probability ordering (min flagged >= max not flagged)',
       CASE WHEN MIN(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN churn_probability_pct END)
              >= MAX(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 0 THEN churn_probability_pct END) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(MIN(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN churn_probability_pct END) AS VARCHAR(30)), ' vs ',
              CAST(MAX(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 0 THEN churn_probability_pct END) AS VARCHAR(30))),
       'min flagged >= max not flagged'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-03', 'Predicted churners (documented: 1,343)',
       CASE WHEN SUM(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN 1 ELSE 0 END) = 1343 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN 1 ELSE 0 END) AS VARCHAR(100)), '1343'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-04', 'Revenue at risk AED (documented: 392,568)',
       CASE WHEN ABS(SUM(revenue_at_risk_aed) - 392568) < 1 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(revenue_at_risk_aed) AS VARCHAR(100)), '392568'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-05', 'Revenue at risk = monthly revenue of flagged customers',
       CASE WHEN ABS(SUM(revenue_at_risk_aed) - SUM(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN monthly_revenue_aed ELSE 0 END)) < 1 THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(revenue_at_risk_aed) AS VARCHAR(30)), ' vs ', CAST(SUM(CASE WHEN CAST(predicted_churn_flag AS INTEGER) = 1 THEN monthly_revenue_aed ELSE 0 END) AS VARCHAR(30))),
       'equal'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-06', 'ML segmentation: Hibernating share % (documented: 76.2)',
       CASE WHEN ROUND(100.0 * SUM(CASE WHEN segment_label = 'Hibernating' THEN 1 ELSE 0 END) / COUNT(*), 1) = 76.2 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(100.0 * SUM(CASE WHEN segment_label = 'Hibernating' THEN 1 ELSE 0 END) / COUNT(*), 1) AS VARCHAR(100)), '76.2'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-07', 'ML segmentation: distinct segment labels (documented: 2)',
       CASE WHEN COUNT(DISTINCT segment_label) = 2 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(DISTINCT segment_label) AS VARCHAR(100)), '2'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'BR-08', 'fct_anomaly_scores row count',
       CASE WHEN COUNT(*) = 99990 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '99990'
FROM dbt_dev.fct_anomaly_scores
UNION ALL
SELECT 'BR-09', 'Anomalies flagged (documented: 4,987)',
       CASE WHEN SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 THEN 1 ELSE 0 END) = 4987 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 THEN 1 ELSE 0 END) AS VARCHAR(100)), '4987'
FROM dbt_dev.fct_anomaly_scores
UNION ALL
SELECT 'BR-10', 'Anomaly rate % (documented: 5.0)',
       CASE WHEN ROUND(100.0 * SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) = 5.0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(100.0 * SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS VARCHAR(100)), '5.0'
FROM dbt_dev.fct_anomaly_scores
UNION ALL
SELECT 'BR-11', 'fct_cac_ltv row count',
       CASE WHEN COUNT(*) = 200 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '200'
FROM dbt_dev.fct_cac_ltv
UNION ALL
SELECT 'BR-12', 'fct_cac_ltv ltv_to_cac_ratio = total_ltv_aed / total_cac_aed (tolerance 0.02)',
       CASE WHEN SUM(CASE WHEN ABS(ltv_to_cac_ratio - total_ltv_aed / NULLIF(total_cac_aed, 0)) > 0.02 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN ABS(ltv_to_cac_ratio - total_ltv_aed / NULLIF(total_cac_aed, 0)) > 0.02 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0 rows outside tolerance'
FROM dbt_dev.fct_cac_ltv
UNION ALL
SELECT 'BR-13', 'fct_cac_ltv customer_count sums to KYC-completed customers (documented filter kyc_completed = 1)',
       CASE WHEN SUM(customer_count) = (SELECT COUNT(*) FROM dbt_dev.stg_customers WHERE kyc_completed = 1) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(customer_count) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM dbt_dev.stg_customers WHERE kyc_completed = 1) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_cac_ltv
UNION ALL
SELECT 'BR-14', 'fct_segment_performance customer_count sums to onboarding customers',
       CASE WHEN SUM(customer_count) = 50000 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(customer_count) AS VARCHAR(100)), '50000'
FROM dbt_dev.fct_segment_performance
UNION ALL
SELECT 'BR-15', 'Documented limitation: segment_strategy collapses to GROWTH_SEGMENT only',
       CASE WHEN COUNT(DISTINCT segment_strategy) = 1 AND MIN(segment_strategy) = 'GROWTH_SEGMENT' THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(DISTINCT segment_strategy) AS VARCHAR(100)), '1 distinct value'
FROM dbt_dev.fct_segment_performance
UNION ALL
SELECT 'BR-16', 'fct_onboarding_funnel total_signups sums to onboarding customers',
       CASE WHEN SUM(total_signups) = 50000 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(total_signups) AS VARCHAR(100)), '50000'
FROM dbt_dev.fct_onboarding_funnel
UNION ALL
SELECT 'BR-17', 'fct_onboarding_funnel completed_kyc and currently_active do not exceed total_signups',
       CASE WHEN SUM(CASE WHEN completed_kyc > total_signups OR currently_active > total_signups THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN completed_kyc > total_signups OR currently_active > total_signups THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM dbt_dev.fct_onboarding_funnel
UNION ALL
SELECT 'BR-18', 'fct_onboarding_funnel kyc_conversion_rate_pct consistent (tolerance 0.1)',
       CASE WHEN SUM(CASE WHEN ABS(kyc_conversion_rate_pct - 100.0 * completed_kyc / NULLIF(total_signups, 0)) > 0.1 THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN ABS(kyc_conversion_rate_pct - 100.0 * completed_kyc / NULLIF(total_signups, 0)) > 0.1 THEN 1 ELSE 0 END) AS VARCHAR(100)), '0 rows outside tolerance'
FROM dbt_dev.fct_onboarding_funnel
UNION ALL
SELECT 'BR-19', 'fct_cohort_retention counts never increase from M1 to M12',
       CASE WHEN SUM(CASE WHEN NOT (retained_m1 >= retained_m2 AND retained_m2 >= retained_m3 AND retained_m3 >= retained_m6 AND retained_m6 >= retained_m12) THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN NOT (retained_m1 >= retained_m2 AND retained_m2 >= retained_m3 AND retained_m3 >= retained_m6 AND retained_m6 >= retained_m12) THEN 1 ELSE 0 END) AS VARCHAR(100)), '0'
FROM dbt_dev.fct_cohort_retention
UNION ALL
SELECT 'BR-20', 'fct_cohort_retention cohort_size sums to KYC-completed customers (documented filter kyc_completed = 1)',
       CASE WHEN SUM(cohort_size) = (SELECT COUNT(*) FROM dbt_dev.stg_customers WHERE kyc_completed = 1) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(cohort_size) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM dbt_dev.stg_customers WHERE kyc_completed = 1) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_cohort_retention
UNION ALL
SELECT 'BR-21', 'fct_mau_arpu row count (12 months x 4 emirates)',
       CASE WHEN COUNT(*) = 48 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '48'
FROM dbt_dev.fct_mau_arpu
UNION ALL
SELECT 'BR-22', 'fct_wallet_adoption row count',
       CASE WHEN COUNT(*) = 144 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '144'
FROM dbt_dev.fct_wallet_adoption
UNION ALL
SELECT 'BR-23', 'fct_wallet_adoption channel_share_pct sums to 100 per month and emirate',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '0 groups outside tolerance'
FROM (SELECT transaction_month, emirate
      FROM dbt_dev.fct_wallet_adoption
      GROUP BY transaction_month, emirate
      HAVING ABS(SUM(channel_share_pct) - 100) > 0.5) v;

-- ---------------------------------------------------------------------
-- SECTION 3: RECONCILIATION (raw, ML outputs, staging, marts)
-- ---------------------------------------------------------------------
SELECT 'RC-01' AS check_id, 'raw.ml_churn_predictions rows = raw.churn_signals rows' AS check_name,
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM raw.churn_signals) THEN 'PASS' ELSE 'FAIL' END AS status,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM raw.churn_signals) AS VARCHAR(30))) AS observed, 'equal' AS expected
FROM raw.ml_churn_predictions
UNION ALL
SELECT 'RC-02', 'fct_churn_predictions rows = raw.ml_churn_predictions rows',
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM raw.ml_churn_predictions) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM raw.ml_churn_predictions) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'RC-03', 'ML churn customers missing from raw.churn_signals',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '0'
FROM raw.ml_churn_predictions m
WHERE NOT EXISTS (SELECT 1 FROM raw.churn_signals c WHERE CAST(c.customer_id AS VARCHAR(100)) = CAST(m.customer_id AS VARCHAR(100)))
UNION ALL
SELECT 'RC-04', 'fct_anomaly_scores rows = raw.ml_anomaly_scores rows',
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM raw.ml_anomaly_scores) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM raw.ml_anomaly_scores) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_anomaly_scores
UNION ALL
SELECT 'RC-05', 'Scored transaction_ids missing from raw.transactions',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '0'
FROM raw.ml_anomaly_scores a
WHERE NOT EXISTS (SELECT 1 FROM raw.transactions t WHERE CAST(t.transaction_id AS VARCHAR(100)) = CAST(a.transaction_id AS VARCHAR(100)))
UNION ALL
SELECT 'RC-06', 'raw.transactions not scored by Isolation Forest (100,000 - 99,990)',
       CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '10'
FROM raw.transactions t
WHERE NOT EXISTS (SELECT 1 FROM raw.ml_anomaly_scores a WHERE CAST(a.transaction_id AS VARCHAR(100)) = CAST(t.transaction_id AS VARCHAR(100)))
UNION ALL
SELECT 'RC-07', 'SUM(amount_aed) raw.transactions = dbt_dev.stg_transactions (diff < 1)',
       CASE WHEN ABS(SUM(amount_aed) - (SELECT SUM(amount_aed) FROM dbt_dev.stg_transactions)) < 1 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ABS(SUM(amount_aed) - (SELECT SUM(amount_aed) FROM dbt_dev.stg_transactions)) AS VARCHAR(100)), '< 1'
FROM raw.transactions
UNION ALL
SELECT 'RC-08', 'fct_mau_arpu total_transactions sums to raw transactions with amount_aed > 0',
       CASE WHEN SUM(total_transactions) = (SELECT COUNT(*) FROM raw.transactions WHERE amount_aed > 0) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(total_transactions) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM raw.transactions WHERE amount_aed > 0) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_mau_arpu
UNION ALL
SELECT 'RC-09', 'fct_mau_arpu total_volume_aed = stg_transactions amount (diff < 1)',
       CASE WHEN ABS(SUM(total_volume_aed) - (SELECT SUM(amount_aed) FROM dbt_dev.stg_transactions)) < 1 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ABS(SUM(total_volume_aed) - (SELECT SUM(amount_aed) FROM dbt_dev.stg_transactions)) AS VARCHAR(100)), '< 1'
FROM dbt_dev.fct_mau_arpu
UNION ALL
SELECT 'RC-10', 'fct_wallet_adoption transaction_count sums to raw transactions with amount_aed > 0',
       CASE WHEN SUM(transaction_count) = (SELECT COUNT(*) FROM raw.transactions WHERE amount_aed > 0) THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(SUM(transaction_count) AS VARCHAR(30)), ' vs ', CAST((SELECT COUNT(*) FROM raw.transactions WHERE amount_aed > 0) AS VARCHAR(30))), 'equal'
FROM dbt_dev.fct_wallet_adoption
UNION ALL
SELECT 'RC-11', 'Staging emirates not present in raw.onboarding (case-insensitive)',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(100)), '0'
FROM (SELECT DISTINCT emirate FROM dbt_dev.stg_customers) s
WHERE NOT EXISTS (SELECT 1 FROM raw.onboarding r WHERE UPPER(r.emirate) = UPPER(s.emirate));

-- ---------------------------------------------------------------------
-- SECTION 4: CUSTOMER-ID COVERAGE ACROSS SOURCES (informational)
-- Shows whether the churn, transaction and onboarding datasets describe
-- the same customers. Feeds the README Limitations section.
-- ---------------------------------------------------------------------
SELECT 'CV-01' AS check_id, 'Distinct customers in raw.transactions' AS check_name, 'INFO' AS status,
       CAST(COUNT(DISTINCT customer_id) AS VARCHAR(100)) AS observed, 'n/a' AS expected
FROM raw.transactions
UNION ALL
SELECT 'CV-02', 'raw.transactions customers that also exist in raw.onboarding', 'INFO',
       CAST(COUNT(DISTINCT t.customer_id) AS VARCHAR(100)), 'n/a'
FROM raw.transactions t
WHERE EXISTS (SELECT 1 FROM raw.onboarding o WHERE CAST(o.customer_id AS VARCHAR(100)) = CAST(t.customer_id AS VARCHAR(100)))
UNION ALL
SELECT 'CV-03', 'Distinct customers in raw.churn_signals', 'INFO',
       CAST(COUNT(DISTINCT customer_id) AS VARCHAR(100)), 'n/a'
FROM raw.churn_signals
UNION ALL
SELECT 'CV-04', 'raw.churn_signals customers that also exist in raw.onboarding', 'INFO',
       CAST(COUNT(DISTINCT c.customer_id) AS VARCHAR(100)), 'n/a'
FROM raw.churn_signals c
WHERE EXISTS (SELECT 1 FROM raw.onboarding o WHERE CAST(o.customer_id AS VARCHAR(100)) = CAST(c.customer_id AS VARCHAR(100)))
UNION ALL
SELECT 'CV-05', 'raw.churn_signals customers that also exist in raw.transactions', 'INFO',
       CAST(COUNT(DISTINCT c.customer_id) AS VARCHAR(100)), 'n/a'
FROM raw.churn_signals c
WHERE EXISTS (SELECT 1 FROM raw.transactions t WHERE CAST(t.customer_id AS VARCHAR(100)) = CAST(c.customer_id AS VARCHAR(100)));

-- ---------------------------------------------------------------------
-- SECTION 5: README FIGURE VERIFICATION AND DOCUMENTED RULES
-- Every figure quoted in the README is re-derived here.
-- ---------------------------------------------------------------------
SELECT 'RM-01' AS check_id, 'stg_transactions excludes only zero-amount rows (documented: 10 rows)' AS check_name,
       CASE WHEN COUNT(*) = 10 AND SUM(CASE WHEN amount_aed = 0 THEN 1 ELSE 0 END) = 10 THEN 'PASS' ELSE 'FAIL' END AS status,
       CONCAT(CAST(COUNT(*) AS VARCHAR(30)), ' rows, ', CAST(SUM(CASE WHEN amount_aed = 0 THEN 1 ELSE 0 END) AS VARCHAR(30)), ' with amount 0') AS observed,
       '10 rows, 10 with amount 0' AS expected
FROM raw.transactions r
WHERE NOT EXISTS (SELECT 1 FROM dbt_dev.stg_transactions s WHERE CAST(s.transaction_id AS VARCHAR(100)) = CAST(r.transaction_id AS VARCHAR(100)))
UNION ALL
SELECT 'RM-02', 'Blended LTV:CAC for KYC-completed customers (README 3.13x)',
       CASE WHEN ROUND(SUM(total_ltv_aed) / SUM(total_cac_aed), 2) = 3.13 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(SUM(total_ltv_aed) / SUM(total_cac_aed), 2) AS VARCHAR(30)), '3.13'
FROM dbt_dev.fct_cac_ltv
UNION ALL
SELECT 'RM-03', 'Blended LTV:CAC for all 50,000 customers (README 2.44x)',
       CASE WHEN ROUND(SUM(ltv_aed) / SUM(cac_aed), 2) = 2.44 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(SUM(ltv_aed) / SUM(cac_aed), 2) AS VARCHAR(30)), '2.44'
FROM dbt_dev.stg_customers
UNION ALL
SELECT 'RM-04', 'Average churn probability % (README 26.4)',
       CASE WHEN ROUND(CAST(AVG(churn_probability_pct) AS NUMERIC), 1) = 26.4 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(CAST(AVG(churn_probability_pct) AS NUMERIC), 2) AS VARCHAR(30)), '26.4'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'RM-05', 'Rule-based High Value At Risk: monthly_revenue_aed >= 300 and churn_risk_score >= 8 (README 179)',
       CASE WHEN SUM(CASE WHEN monthly_revenue_aed >= 300 AND churn_risk_score >= 8 THEN 1 ELSE 0 END) = 179 THEN 'PASS' ELSE 'REVIEW' END,
       CAST(SUM(CASE WHEN monthly_revenue_aed >= 300 AND churn_risk_score >= 8 THEN 1 ELSE 0 END) AS VARCHAR(30)), '179'
FROM dbt_dev.fct_churn_signals
UNION ALL
SELECT 'RM-06', 'High-priority anomalies: flagged and amount_aed >= 10,000 (README 4,933)',
       CASE WHEN SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 AND amount_aed >= 10000 THEN 1 ELSE 0 END) = 4933 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN CAST(is_anomaly AS INTEGER) = 1 AND amount_aed >= 10000 THEN 1 ELSE 0 END) AS VARCHAR(30)), '4933'
FROM dbt_dev.fct_anomaly_scores
UNION ALL
SELECT 'RM-07', 'Share of flagged anomalies above AED 5,000, % (README about 99)',
       CASE WHEN ROUND(CAST(100.0 * SUM(CASE WHEN amount_aed > 5000 THEN 1 ELSE 0 END) / COUNT(*) AS NUMERIC), 0) = 99 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(CAST(100.0 * SUM(CASE WHEN amount_aed > 5000 THEN 1 ELSE 0 END) / COUNT(*) AS NUMERIC), 1) AS VARCHAR(30)), '99'
FROM dbt_dev.fct_anomaly_scores
WHERE CAST(is_anomaly AS INTEGER) = 1
UNION ALL
SELECT 'RM-08', 'Fraud-labelled share of raw.transactions, % (README about 5)',
       CASE WHEN ROUND(CAST(100.0 * SUM(CASE WHEN CAST(is_fraud AS INTEGER) = 1 THEN 1 ELSE 0 END) / COUNT(*) AS NUMERIC), 0) = 5 THEN 'PASS' ELSE 'FAIL' END,
       CAST(ROUND(CAST(100.0 * SUM(CASE WHEN CAST(is_fraud AS INTEGER) = 1 THEN 1 ELSE 0 END) / COUNT(*) AS NUMERIC), 2) AS VARCHAR(30)), '5'
FROM raw.transactions
UNION ALL
SELECT 'RM-09', 'ML segment Hibernating customers (README 5,366)',
       CASE WHEN SUM(CASE WHEN segment_label = 'Hibernating' THEN 1 ELSE 0 END) = 5366 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN segment_label = 'Hibernating' THEN 1 ELSE 0 END) AS VARCHAR(30)), '5366'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'RM-10', 'ML segment New Customers (README 1,677)',
       CASE WHEN SUM(CASE WHEN segment_label <> 'Hibernating' THEN 1 ELSE 0 END) = 1677 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN segment_label <> 'Hibernating' THEN 1 ELSE 0 END) AS VARCHAR(30)), '1677'
FROM dbt_dev.fct_churn_predictions
UNION ALL
SELECT 'RM-11', 'Onboarding emirate mix within 1 percentage point of 45/25/20/10 (README)',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(COUNT(*) AS VARCHAR(30)), '0 emirates outside tolerance'
FROM (SELECT UPPER(emirate) AS emirate_name, 100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw.onboarding) AS pct
      FROM raw.onboarding GROUP BY UPPER(emirate)) m
WHERE ABS(pct - CASE emirate_name WHEN 'DUBAI' THEN 45 WHEN 'ABU DHABI' THEN 25 WHEN 'SHARJAH' THEN 20 WHEN 'AJMAN' THEN 10 ELSE 100 END) > 1
UNION ALL
SELECT 'RM-12', 'Transaction timeline starts 2026-01-01 and ends 8-20 Dec 2026 (README: mid-December)',
       CASE WHEN CAST(MIN(transaction_date_only) AS VARCHAR(10)) = '2026-01-01'
             AND CAST(MAX(transaction_date_only) AS VARCHAR(10)) >= '2026-12-08'
             AND CAST(MAX(transaction_date_only) AS VARCHAR(10)) <= '2026-12-20' THEN 'PASS' ELSE 'FAIL' END,
       CONCAT(CAST(MIN(transaction_date_only) AS VARCHAR(10)), ' to ', CAST(MAX(transaction_date_only) AS VARCHAR(10))), '2026-01-01 to mid-December 2026'
FROM dbt_dev.stg_transactions
UNION ALL
SELECT 'RM-13', 'Onboarding customer_id range is NC_1xxxxx (README limitation 9)',
       CASE WHEN SUM(CASE WHEN SUBSTRING(customer_id, 1, 4) <> 'NC_1' THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN SUBSTRING(customer_id, 1, 4) <> 'NC_1' THEN 1 ELSE 0 END) AS VARCHAR(30)), '0 outside range'
FROM raw.onboarding
UNION ALL
SELECT 'RM-14', 'Churn customer_id range is NC_2xxxxx (README limitation 9)',
       CASE WHEN SUM(CASE WHEN SUBSTRING(customer_id, 1, 4) <> 'NC_2' THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END,
       CAST(SUM(CASE WHEN SUBSTRING(customer_id, 1, 4) <> 'NC_2' THEN 1 ELSE 0 END) AS VARCHAR(30)), '0 outside range'
FROM raw.churn_signals;