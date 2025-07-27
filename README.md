# AIServiceLine

# Car Sales Price Prediction Pipeline

This project implements an event-driven, serverless pipeline on AWS to preprocess car sales data and train a machine learning model to estimate car prices.

## Architecture
- **S3 Landing Zone**: Stores raw CSV files.
- **S3 Curated Zone**: Stores preprocessed CSV files.
- **AWS Lambda**: Processes CSV files uploaded to the landing zone.
- **IAM Roles**: Grants Lambda access to S3 and CloudWatch Logs.
- **Pandas Layer**: Provides Pandas for Lambda data processing.

## Prerequisites
- AWS CLI configured with appropriate credentials.
- Terraform installed.
- Python 3.8+ for the notebook.
- Pandas layer ZIP file (see below).

## Setup Instructions

### 1. Create Pandas Lambda Layer
1. Create a directory `python` and install Pandas:
   ```bash
   mkdir python
   pip install pandas -t python/