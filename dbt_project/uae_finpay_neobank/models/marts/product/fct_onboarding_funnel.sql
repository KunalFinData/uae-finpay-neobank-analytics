-- Business Problem 1: Product Onboarding Funnel
-- Signup to KYC to First Transaction to Active
-- Drop-off rate at each stage by emirate

WITH customers AS (
    SELECT * FROM {{ ref("stg_customers") }}
),

funnel AS (
    SELECT
        emirate,
        COUNT(*)                                AS total_signups,
        SUM(kyc_completed)                      AS completed_kyc,
        SUM(CASE
            WHEN kyc_completed = 1
             AND first_transaction_days IS NOT NULL
            THEN 1 ELSE 0
        END)                                    AS made_first_transaction,
        SUM(is_active)                          AS currently_active,
        ROUND(
            SUM(kyc_completed)::NUMERIC
            / NULLIF(COUNT(*), 0) * 100
        , 2)                                    AS kyc_conversion_rate_pct,
        ROUND(
            SUM(CASE
                WHEN kyc_completed = 1
                 AND first_transaction_days IS NOT NULL
                THEN 1 ELSE 0
            END)::NUMERIC
            / NULLIF(SUM(kyc_completed), 0) * 100
        , 2)                                    AS activation_rate_pct,
        ROUND(
            SUM(is_active)::NUMERIC
            / NULLIF(COUNT(*), 0) * 100
        , 2)                                    AS overall_active_rate_pct,
        ROUND(AVG(kyc_completion_days)::NUMERIC
              , 1)                              AS avg_kyc_days,
        ROUND(AVG(first_transaction_days)::NUMERIC
              , 1)                              AS avg_days_to_first_txn
    FROM customers
    GROUP BY emirate
)

SELECT * FROM funnel
ORDER BY total_signups DESC
