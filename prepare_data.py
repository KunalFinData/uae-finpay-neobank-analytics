"""
UAE FinPay Neobank — Data Preparation Script
=============================================
Loads 3 datasets into neobank_db PostgreSQL:
1. PaySim sample (100k rows) — transaction behaviour
2. Synthetic neobank onboarding data (50k rows)
3. Telco churn adapted (7k rows) — churn signals

Author: Kunal Sharma
Date: August 2026
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
import warnings
warnings.filterwarnings('ignore')

print("=" * 55)
print("UAE FinPay Neobank Data Preparation")
print("=" * 55)

# Database connection
connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password="Hellboy@0404",
    host="localhost",
    port=5432,
    database="neobank_db"
)
engine = create_engine(connection_url)
print("Database connected successfully")

# ================================================
# DATASET 1 — PaySim Transaction Sample
# ================================================
print("\nStep 1: Loading PaySim dataset...")

paysim_path = 'data/PS_20174392719_1491204439457_log.csv'
df_pay = pd.read_csv(paysim_path)
print(f"PaySim full size: {len(df_pay):,} rows")

# Sample 100k stratified
np.random.seed(42)
fraud_rows = df_pay[df_pay['isFraud'] == 1]
clean_rows = df_pay[df_pay['isFraud'] == 0]
sample = pd.concat([
    fraud_rows.sample(n=min(5000, len(fraud_rows)),
                      random_state=42),
    clean_rows.sample(n=95000, random_state=42)
]).sample(frac=1, random_state=42).reset_index(drop=True)

# Add UAE context
sample['emirate'] = np.random.choice(
    ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'],
    size=len(sample),
    p=[0.45, 0.25, 0.20, 0.10]
)
sample['amount_aed'] = (sample['amount'] * 3.67).round(2)
sample['payment_channel'] = np.random.choice(
    ['card', 'wallet', 'bank_transfer'],
    size=len(sample),
    p=[0.50, 0.35, 0.15]
)
sample['customer_id'] = 'NC_' + sample['nameOrig'].str[-6:]
sample['transaction_date'] = pd.date_range(
    start='2026-01-01', periods=len(sample), freq='5min'
)
sample['transaction_id'] = (
    'TXN_NB_' + sample.index.astype(str)
)
sample['product_type'] = np.random.choice(
    ['payment', 'transfer', 'wallet_top_up'],
    size=len(sample),
    p=[0.60, 0.25, 0.15]
)

txn_final = sample[[
    'transaction_id', 'customer_id', 'transaction_date',
    'amount_aed', 'emirate', 'payment_channel',
    'product_type', 'isFraud'
]].copy()
txn_final.columns = [
    'transaction_id', 'customer_id', 'transaction_date',
    'amount_aed', 'emirate', 'payment_channel',
    'product_type', 'is_fraud'
]

txn_final.to_sql(
    'transactions', schema='raw', con=engine,
    if_exists='replace', index=False, chunksize=5000
)
print(f"Transactions loaded: {len(txn_final):,} rows")

# ================================================
# DATASET 2 — Synthetic Neobank Onboarding Data
# ================================================
print("\nStep 2: Generating synthetic onboarding data...")

np.random.seed(42)
n = 50000

professions = [
    'trader', 'engineer', 'doctor', 'teacher',
    'entrepreneur', 'banker', 'retail_worker',
    'hospitality', 'logistics', 'freelancer'
]
profession_weights = [
    0.10, 0.15, 0.08, 0.07, 0.12,
    0.10, 0.12, 0.10, 0.08, 0.08
]

channels = ['app_store', 'referral', 'social_media',
            'google_ads', 'employer_partnership']
channel_weights = [0.30, 0.25, 0.20, 0.15, 0.10]

emirate_choices = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman']
emirate_weights = [0.45, 0.25, 0.20, 0.10]

signup_dates = pd.date_range(
    start='2025-01-01', end='2026-06-30', periods=n
)

kyc_delay_days = np.random.randint(0, 15, size=n)
first_txn_delay_days = np.random.randint(1, 30, size=n)
kyc_completed = np.random.choice(
    [True, False], size=n, p=[0.78, 0.22]
)

cac_by_channel = {
    'app_store': 45, 'referral': 20,
    'social_media': 60, 'google_ads': 80,
    'employer_partnership': 30
}

acquisition_channel = np.random.choice(
    channels, size=n, p=channel_weights
)
cac_usd = np.array([
    cac_by_channel[ch] + np.random.uniform(-10, 10)
    for ch in acquisition_channel
])

monthly_revenue_usd = np.where(
    kyc_completed,
    np.random.uniform(5, 25, size=n),
    0
)
tenure_months = np.random.randint(1, 19, size=n)
ltv_usd = monthly_revenue_usd * tenure_months

df_onboard = pd.DataFrame({
    'customer_id': ['NC_' + str(100000 + i)
                    for i in range(n)],
    'signup_date': signup_dates,
    'emirate': np.random.choice(
        emirate_choices, size=n, p=emirate_weights),
    'profession': np.random.choice(
        professions, size=n, p=profession_weights),
    'acquisition_channel': acquisition_channel,
    'cac_usd': cac_usd.round(2),
    'cac_aed': (cac_usd * 3.67).round(2),
    'kyc_completed': kyc_completed.astype(int),
    'kyc_completion_days': np.where(
        kyc_completed, kyc_delay_days, None),
    'first_transaction_days': np.where(
        kyc_completed, first_txn_delay_days, None),
    'monthly_revenue_usd': monthly_revenue_usd.round(2),
    'monthly_revenue_aed': (
        monthly_revenue_usd * 3.67).round(2),
    'tenure_months': tenure_months,
    'ltv_usd': ltv_usd.round(2),
    'ltv_aed': (ltv_usd * 3.67).round(2),
    'is_active': np.random.choice(
        [1, 0], size=n, p=[0.72, 0.28]),
    'nationality': np.random.choice(
        ['UAE National', 'Indian', 'Pakistani',
         'British', 'Filipino', 'Other'],
        size=n,
        p=[0.15, 0.28, 0.12, 0.08, 0.10, 0.27])
})

df_onboard.to_sql(
    'onboarding', schema='raw', con=engine,
    if_exists='replace', index=False, chunksize=5000
)
print(f"Onboarding data loaded: {len(df_onboard):,} rows")

# ================================================
# DATASET 3 — Telco Churn Adapted for Neobank
# ================================================
print("\nStep 3: Loading and adapting Telco churn data...")

telco_path = 'data/WA_Fn-UseC_-Telco-Customer-Churn.csv'
df_telco = pd.read_csv(telco_path)
print(f"Telco rows: {len(df_telco):,}")

df_churn = pd.DataFrame({
    'customer_id': ['NC_' + str(200000 + i)
                    for i in range(len(df_telco))],
    'tenure_months': df_telco['tenure'],
    'monthly_revenue_aed': (
        pd.to_numeric(
            df_telco['MonthlyCharges'],
            errors='coerce'
        ).fillna(0) * 3.67
    ).round(2),
    'has_wallet': df_telco['PhoneService'].map(
        {'Yes': 1, 'No': 0}),
    'has_savings': df_telco['MultipleLines'].map(
        {'Yes': 1, 'No': 0, 'No phone service': 0}),
    'has_investment': df_telco['InternetService'].map(
        {'Fiber optic': 1, 'DSL': 0, 'No': 0}),
    'is_churned': df_telco['Churn'].map(
        {'Yes': 1, 'No': 0}),
    'contract_type': df_telco['Contract'],
    'emirate': np.random.choice(
        ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'],
        size=len(df_telco),
        p=[0.45, 0.25, 0.20, 0.10])
})

df_churn.to_sql(
    'churn_signals', schema='raw', con=engine,
    if_exists='replace', index=False, chunksize=5000
)
print(f"Churn signals loaded: {len(df_churn):,} rows")

# ================================================
# VERIFICATION
# ================================================
print("\nVerification:")
for table in ['transactions', 'onboarding', 'churn_signals']:
    result = pd.read_sql(
        f"SELECT COUNT(*) as cnt FROM raw.{table}", engine)
    print(f"  raw.{table}: {result['cnt'][0]:,} rows")

print("\n" + "=" * 55)
print("All data loaded successfully into neobank_db")
print("Open DBeaver to verify: neobank_db → raw")
print("=" * 55)