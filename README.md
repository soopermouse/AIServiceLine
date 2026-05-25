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

   ## Trademark Notice

"AI Service Line" and associated branding, naming, logos, and platform identity are claimed as trademarks and may not be used commercially without explicit written permission from the project owner.

Trademark rights are asserted by the project author and maintained under applicable intellectual property laws.

---

## Copyright

Copyright (c) 2026 Simona Thrussell PhD / NXD Tech

All rights reserved unless otherwise specified.

---

## License

Source code licensing terms are defined separately within this repository.

No rights are granted to use the project name, branding, visual identity, or associated trademarks outside the scope of the applicable software license.

---

## Contributions

Unless explicitly agreed otherwise in writing, all contributions submitted to this repository are provided with a perpetual, worldwide, non-exclusive right for inclusion within the project and related commercial derivatives.

---
