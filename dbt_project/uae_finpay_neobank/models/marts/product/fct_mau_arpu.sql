-- Business Problem 5: MAU and ARPU Dashboard
-- Monthly Active Users and Average Revenue Per User

WITH transactions AS (
    SELECT * FROM {{ ref("stg_transactions") }}
),

monthly_activity AS (
    SELECT
        transaction_month,
        emirate,
        COUNT(DISTINCT customer_id)            AS mau,
        COUNT(transaction_id)                  AS total_transactions,
        SUM(amount_aed)                        AS total_volume_aed,
        ROUND(AVG(amount_aed)::NUMERIC, 2)    AS avg_transaction_aed
    FROM transactions
    GROUP BY transaction_month, emirate
),

with_arpu AS (
    SELECT
        *,
        ROUND(
            total_volume_aed / NULLIF(mau, 0)
        , 2)                                    AS arpu_aed,
        LAG(mau) OVER (
            PARTITION BY emirate
            ORDER BY transaction_month
        )                                       AS prev_month_mau,
        LAG(total_volume_aed) OVER (
            PARTITION BY emirate
            ORDER BY transaction_month
        )                                       AS prev_month_volume_aed
    FROM monthly_activity
)

SELECT
    transaction_month,
    emirate,
    mau,
    total_transactions,
    ROUND(total_volume_aed::NUMERIC, 2)        AS total_volume_aed,
    avg_transaction_aed,
    arpu_aed,
    prev_month_mau,
    ROUND(
        (mau - prev_month_mau)::NUMERIC
        / NULLIF(prev_month_mau, 0) * 100
    , 2)                                        AS mau_mom_growth_pct,
    ROUND(
        (total_volume_aed - prev_month_volume_aed)::NUMERIC
        / NULLIF(prev_month_volume_aed, 0) * 100
    , 2)                                        AS volume_mom_growth_pct
FROM with_arpu
ORDER BY transaction_month, emirate
