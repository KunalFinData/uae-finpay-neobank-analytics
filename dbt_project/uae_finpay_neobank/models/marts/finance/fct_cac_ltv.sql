-- Business Problem 2: CAC vs LTV by Emirate
-- Customer Acquisition Cost vs Lifetime Value
-- Payback period in months by emirate and channel

WITH customers AS (
    SELECT * FROM {{ ref("stg_customers") }}
),

cac_ltv AS (
    SELECT
        emirate,
        acquisition_channel,
        profession,
        COUNT(*)                                AS customer_count,
        ROUND(AVG(cac_aed)::NUMERIC, 2)        AS avg_cac_aed,
        ROUND(AVG(ltv_aed)::NUMERIC, 2)        AS avg_ltv_aed,
        ROUND(AVG(monthly_revenue_aed)
              ::NUMERIC, 2)                     AS avg_monthly_revenue_aed,
        ROUND(AVG(payback_months)::NUMERIC, 1) AS avg_payback_months,
        ROUND(
            AVG(ltv_aed) / NULLIF(AVG(cac_aed), 0)
        , 2)                                    AS ltv_to_cac_ratio,
        ROUND(SUM(ltv_aed)::NUMERIC, 2)        AS total_ltv_aed,
        ROUND(SUM(cac_aed)::NUMERIC, 2)        AS total_cac_aed,
        CASE
            WHEN AVG(ltv_aed) / NULLIF(AVG(cac_aed), 0) >= 3
            THEN 'EXCELLENT'
            WHEN AVG(ltv_aed) / NULLIF(AVG(cac_aed), 0) >= 2
            THEN 'GOOD'
            WHEN AVG(ltv_aed) / NULLIF(AVG(cac_aed), 0) >= 1
            THEN 'BREAK_EVEN'
            ELSE 'LOSS_MAKING'
        END                                     AS unit_economics_status
    FROM customers
    WHERE kyc_completed = 1
    GROUP BY emirate, acquisition_channel, profession
)

SELECT * FROM cac_ltv
ORDER BY avg_ltv_aed DESC
