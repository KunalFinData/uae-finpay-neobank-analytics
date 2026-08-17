-- ML Churn Predictions from Python AI Model
-- Reads from raw.ml_churn_predictions
-- Feeds directly into Power BI churn dashboard

WITH predictions AS (
    SELECT * FROM {{ source('raw', 'ml_churn_predictions') }}
)

SELECT
    customer_id,
    emirate,
    ROUND(churn_probability_pct::NUMERIC, 2)   AS churn_probability_pct,
    predicted_churn_flag,
    ROUND(monthly_revenue_aed::NUMERIC, 2)     AS monthly_revenue_aed,
    segment_label,
    CASE
        WHEN churn_probability_pct >= 70  THEN 'CRITICAL'
        WHEN churn_probability_pct >= 50  THEN 'HIGH'
        WHEN churn_probability_pct >= 30  THEN 'MEDIUM'
        ELSE                                   'LOW'
    END                                        AS churn_alert_level,
    CASE
        WHEN predicted_churn_flag = 1
        THEN ROUND(monthly_revenue_aed::NUMERIC, 2)
        ELSE 0
    END                                        AS revenue_at_risk_aed
FROM predictions
ORDER BY churn_probability_pct DESC