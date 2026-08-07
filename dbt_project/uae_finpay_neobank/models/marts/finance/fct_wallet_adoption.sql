-- Business Problem 7: Wallet Adoption Rate
-- Card vs wallet vs bank transfer trend by emirate

WITH transactions AS (
    SELECT * FROM {{ ref("stg_transactions") }}
),

channel_stats AS (
    SELECT
        transaction_month,
        emirate,
        payment_channel,
        COUNT(*)                                AS transaction_count,
        SUM(amount_aed)                         AS total_volume_aed,
        COUNT(DISTINCT customer_id)             AS unique_customers,
        ROUND(AVG(amount_aed)::NUMERIC, 2)     AS avg_transaction_aed
    FROM transactions
    GROUP BY transaction_month, emirate, payment_channel
),

with_share AS (
    SELECT
        *,
        ROUND(
            transaction_count::NUMERIC
            / SUM(transaction_count) OVER (
                PARTITION BY transaction_month, emirate
            ) * 100
        , 2)                                    AS channel_share_pct,
        ROUND(
            total_volume_aed::NUMERIC
            / SUM(total_volume_aed) OVER (
                PARTITION BY transaction_month, emirate
            ) * 100
        , 2)                                    AS volume_share_pct
    FROM channel_stats
)

SELECT * FROM with_share
ORDER BY transaction_month, emirate, payment_channel
