-- UAE FinPay Neobank â€” Transaction Staging Layer
-- Source: PaySim 100k sample with UAE staging layer
-- Cleans and standardises raw transaction data

WITH source AS (
    SELECT * FROM {{ source('raw', 'transactions') }}
),

cleaned AS (
    SELECT
        transaction_id,
        customer_id,
        CAST(transaction_date AS TIMESTAMP)     AS transaction_date,
        DATE(transaction_date)                   AS transaction_date_only,
        TO_CHAR(transaction_date, 'YYYY-MM')    AS transaction_month,
        EXTRACT(MONTH FROM transaction_date)    AS month_number,
        EXTRACT(YEAR FROM transaction_date)     AS year_number,
        CAST(amount_aed AS NUMERIC(12,2))       AS amount_aed,
        UPPER(emirate)                           AS emirate,
        LOWER(payment_channel)                  AS payment_channel,
        LOWER(product_type)                     AS product_type,
        CAST(is_fraud AS INTEGER)               AS is_fraud
    FROM source
    WHERE transaction_id IS NOT NULL
      AND customer_id    IS NOT NULL
      AND amount_aed     > 0
)

SELECT * FROM cleaned
