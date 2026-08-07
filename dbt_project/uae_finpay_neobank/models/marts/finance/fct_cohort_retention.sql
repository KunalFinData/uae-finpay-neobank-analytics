-- Business Problem 3: Cohort Retention Analysis
-- Month 1 to Month 12 retention by signup cohort
-- Foundation for Power BI retention heatmap

WITH customers AS (
    SELECT * FROM {{ ref("stg_customers") }}
),

cohort_base AS (
    SELECT
        signup_month                            AS cohort_month,
        customer_id,
        tenure_months,
        is_active,
        monthly_revenue_aed
    FROM customers
    WHERE kyc_completed = 1
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id)            AS cohort_size
    FROM cohort_base
    GROUP BY cohort_month
),

retention AS (
    SELECT
        cb.cohort_month,
        cs.cohort_size,
        SUM(CASE WHEN cb.tenure_months >= 1
            THEN 1 ELSE 0 END)                 AS retained_m1,
        SUM(CASE WHEN cb.tenure_months >= 2
            THEN 1 ELSE 0 END)                 AS retained_m2,
        SUM(CASE WHEN cb.tenure_months >= 3
            THEN 1 ELSE 0 END)                 AS retained_m3,
        SUM(CASE WHEN cb.tenure_months >= 6
            THEN 1 ELSE 0 END)                 AS retained_m6,
        SUM(CASE WHEN cb.tenure_months >= 12
            THEN 1 ELSE 0 END)                 AS retained_m12,
        ROUND(AVG(monthly_revenue_aed)
              ::NUMERIC, 2)                     AS avg_revenue_aed
    FROM cohort_base cb
    JOIN cohort_size cs
      ON cb.cohort_month = cs.cohort_month
    GROUP BY cb.cohort_month, cs.cohort_size
)

SELECT
    cohort_month,
    cohort_size,
    retained_m1,
    retained_m2,
    retained_m3,
    retained_m6,
    retained_m12,
    ROUND(retained_m1::NUMERIC
          / NULLIF(cohort_size, 0) * 100, 1)  AS retention_m1_pct,
    ROUND(retained_m2::NUMERIC
          / NULLIF(cohort_size, 0) * 100, 1)  AS retention_m2_pct,
    ROUND(retained_m3::NUMERIC
          / NULLIF(cohort_size, 0) * 100, 1)  AS retention_m3_pct,
    ROUND(retained_m6::NUMERIC
          / NULLIF(cohort_size, 0) * 100, 1)  AS retention_m6_pct,
    ROUND(retained_m12::NUMERIC
          / NULLIF(cohort_size, 0) * 100, 1)  AS retention_m12_pct,
    avg_revenue_aed
FROM retention
ORDER BY cohort_month
