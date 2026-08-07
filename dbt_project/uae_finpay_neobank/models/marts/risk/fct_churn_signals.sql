-- Business Problem 4: Customer Churn Signals
-- RFM segmentation and churn risk scoring

WITH churn AS (
    SELECT * FROM {{ ref('stg_churn_signals') }}
),

churn_scored AS (
    SELECT
        customer_id,
        emirate,
        tenure_months,
        monthly_revenue_aed,
        has_wallet,
        has_savings,
        has_investment,
        feature_adoption_count,
        is_churned,
        customer_lifecycle_stage,
        contract_type,
        CASE
            WHEN tenure_months <= 3  THEN 5
            WHEN tenure_months <= 6  THEN 4
            WHEN tenure_months <= 12 THEN 3
            WHEN tenure_months <= 24 THEN 2
            ELSE 1
        END AS recency_score,
        CASE
            WHEN monthly_revenue_aed >= 500 THEN 1
            WHEN monthly_revenue_aed >= 300 THEN 2
            WHEN monthly_revenue_aed >= 150 THEN 3
            WHEN monthly_revenue_aed >= 50  THEN 4
            ELSE 5
        END AS monetary_score,
        CASE
            WHEN feature_adoption_count >= 3 THEN 1
            WHEN feature_adoption_count = 2  THEN 2
            WHEN feature_adoption_count = 1  THEN 3
            ELSE 4
        END AS engagement_score
    FROM churn
),

rfm_final AS (
    SELECT
        *,
        recency_score + monetary_score + engagement_score AS churn_risk_score,
        CASE
            WHEN recency_score + monetary_score + engagement_score >= 10
            THEN 'HIGH_CHURN_RISK'
            WHEN recency_score + monetary_score + engagement_score >= 7
            THEN 'MEDIUM_CHURN_RISK'
            ELSE 'LOW_CHURN_RISK'
        END AS churn_risk_tier,
        CASE
            WHEN monthly_revenue_aed >= 300
             AND (recency_score + monetary_score + engagement_score) >= 8
            THEN 'HIGH_VALUE_AT_RISK'
            ELSE 'STANDARD'
        END AS priority_flag
    FROM churn_scored
)

SELECT * FROM rfm_final
ORDER BY churn_risk_score DESC