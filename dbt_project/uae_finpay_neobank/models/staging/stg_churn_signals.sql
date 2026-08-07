-- UAE FinPay Neobank â€” Churn Signal Staging Layer
-- Source: Telco churn dataset adapted for neobank
-- Tenure = months as customer
-- Monthly charges = ARPU proxy
-- Service adoption = feature usage proxy

WITH source AS (
    SELECT * FROM {{ source('raw', 'churn_signals') }}
),

cleaned AS (
    SELECT
        customer_id,
        CAST(tenure_months AS INTEGER)             AS tenure_months,
        CAST(monthly_revenue_aed AS NUMERIC(10,2)) AS monthly_revenue_aed,
        CAST(has_wallet AS INTEGER)                AS has_wallet,
        CAST(has_savings AS INTEGER)               AS has_savings,
        CAST(has_investment AS INTEGER)            AS has_investment,
        CAST(is_churned AS INTEGER)                AS is_churned,
        contract_type,
        UPPER(emirate)                              AS emirate,
        CASE
            WHEN tenure_months <= 6   THEN 'NEW'
            WHEN tenure_months <= 12  THEN 'DEVELOPING'
            WHEN tenure_months <= 24  THEN 'ESTABLISHED'
            ELSE                           'LOYAL'
        END                                        AS customer_lifecycle_stage,
        (has_wallet + has_savings + has_investment) AS feature_adoption_count
    FROM source
    WHERE customer_id IS NOT NULL
)

SELECT * FROM cleaned
