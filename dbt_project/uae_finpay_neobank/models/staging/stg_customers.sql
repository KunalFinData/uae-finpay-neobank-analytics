-- UAE FinPay Neobank â€” Customer Staging Layer
-- Source: Synthetic onboarding data

WITH source AS (
    SELECT * FROM {{ source('raw', 'onboarding') }}
),

cleaned AS (
    SELECT
        customer_id,
        CAST(signup_date AS DATE)               AS signup_date,
        TO_CHAR(signup_date, 'YYYY-MM')         AS signup_month,
        UPPER(emirate)                           AS emirate,
        LOWER(profession)                        AS profession,
        LOWER(acquisition_channel)              AS acquisition_channel,
        CAST(cac_aed AS NUMERIC(10,2))          AS cac_aed,
        CAST(kyc_completed AS INTEGER)          AS kyc_completed,
        kyc_completion_days,
        first_transaction_days,
        CAST(monthly_revenue_aed AS NUMERIC(10,2)) AS monthly_revenue_aed,
        CAST(tenure_months AS INTEGER)          AS tenure_months,
        CAST(ltv_aed AS NUMERIC(12,2))          AS ltv_aed,
        CAST(is_active AS INTEGER)              AS is_active,
        nationality,
        CASE
            WHEN cac_aed > 0 AND monthly_revenue_aed > 0
            THEN ROUND(
                CAST(cac_aed AS NUMERIC)
                / CAST(monthly_revenue_aed AS NUMERIC)
            , 1)
            ELSE NULL
        END                                     AS payback_months
    FROM source
    WHERE customer_id IS NOT NULL
)

SELECT * FROM cleaned