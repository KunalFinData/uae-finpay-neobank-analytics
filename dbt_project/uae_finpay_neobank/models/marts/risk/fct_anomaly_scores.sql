-- ML Anomaly Detection Results from Python
-- Isolation Forest 5 percent contamination threshold
-- Flags unusual transactions without fraud labels

WITH anomalies AS (
    SELECT * FROM {{ source('raw', 'ml_anomaly_scores') }}
)

SELECT
    transaction_id,
    customer_id,
    emirate,
    ROUND(amount_aed::NUMERIC, 2)              AS amount_aed,
    is_anomaly,
    ROUND(anomaly_confidence::NUMERIC, 4)      AS anomaly_confidence,
    CASE
        WHEN is_anomaly = 1
         AND amount_aed >= 10000  THEN 'HIGH_PRIORITY'
        WHEN is_anomaly = 1
         AND amount_aed >= 5000   THEN 'MEDIUM_PRIORITY'
        WHEN is_anomaly = 1       THEN 'LOW_PRIORITY'
        ELSE                           'NORMAL'
    END                                        AS anomaly_priority
FROM anomalies
ORDER BY anomaly_confidence DESC