-- Business Problem 6: High Value Segment Identification
-- Profession and emirate performance analysis

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

segment_stats AS (
    SELECT
        profession,
        emirate,
        COUNT(*)                                        AS customer_count,
        ROUND(AVG(cac_aed)::NUMERIC, 2)               AS avg_cac_aed,
        ROUND(AVG(ltv_aed)::NUMERIC, 2)               AS avg_ltv_aed,
        ROUND(AVG(monthly_revenue_aed)::NUMERIC, 2)   AS avg_monthly_revenue_aed,
        ROUND(AVG(payback_months)::NUMERIC, 1)        AS avg_payback_months,
        ROUND(AVG(ltv_aed) / NULLIF(AVG(cac_aed), 0), 2) AS ltv_cac_ratio,
        SUM(kyc_completed)                             AS kyc_completed_count,
        ROUND(SUM(kyc_completed)::NUMERIC / COUNT(*) * 100, 2) AS kyc_rate_pct,
        SUM(is_active)                                 AS active_customers,
        ROUND(SUM(is_active)::NUMERIC / COUNT(*) * 100, 2) AS active_rate_pct
    FROM customers
    GROUP BY profession, emirate
)

SELECT
    *,
    RANK() OVER (ORDER BY avg_ltv_aed DESC) AS ltv_rank,
    CASE
        WHEN ltv_cac_ratio >= 3 THEN 'PRIORITY_SEGMENT'
        WHEN ltv_cac_ratio >= 2 THEN 'GROWTH_SEGMENT'
        WHEN ltv_cac_ratio >= 1 THEN 'WATCH_SEGMENT'
        ELSE 'REVIEW_SEGMENT'
    END AS segment_strategy
FROM segment_stats
ORDER BY avg_ltv_aed DESC