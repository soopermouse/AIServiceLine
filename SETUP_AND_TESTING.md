Car Sales Price Prediction Pipeline: Setup and Testing GuideThis document provides a complete, step-by-step guide to set up and test an event-driven, serverless pipeline on AWS for preprocessing car sales data and training a machine learning model to estimate car prices. The pipeline processes CSV files uploaded to an S3 landing zone, stores preprocessed data in a curated zone, and uses a Jupyter Notebook to train and evaluate a model.Architecture OverviewS3 Landing Zone: Stores raw CSV files (e.g., ml_sample_data_snapsoft.csv).
S3 Curated Zone: Stores preprocessed CSV files.
AWS Lambda: Processes CSV files by removing unusable attributes (e.g., car_ID, ownername) and rows with missing significant attributes (e.g., CarName, fueltype), while retaining rows with imputable attributes (e.g., horsepower).
IAM Roles: Grants Lambda access to S3 and CloudWatch Logs.
Pandas Layer: Provides Pandas for Lambda data processing.
Jupyter Notebook: Trains a Random Forest Regressor to predict car prices, slightly underestimating them, and evaluates performance.

PrerequisitesBefore starting, ensure you have:AWS CLI: Installed and configured with credentials (IAM user with permissions for S3, Lambda, IAM, and CloudWatch).
Terraform: Installed (version 1.0 or later).
Python 3.8+: Installed for running the notebook and creating the Pandas layer.
Jupyter Notebook: Installed for running train_evaluate_model.ipynb.
Dependencies: Python packages (pandas, numpy, sklearn, joblib, boto3) for the notebook.
Sample Data: The provided ml_sample_data_snapsoft.csv file (or equivalent dataset).

Setup ProcessStep 1: Prepare the Project DirectoryCreate a project directory:bash

mkdir car_sales_pipeline
cd car_sales_pipeline

Save the following files in the directory (provided in the deliverables):main.tf
variables.tf
lambda_function.py
train_evaluate_model.ipynb
This file (SETUP_AND_TESTING.md)

Step 2: Create the Pandas Lambda LayerThe Lambda function requires Pandas for data processing. Create a custom Lambda layer as follows:Create a python directory and install Pandas:bash

mkdir python
pip install pandas -t python/

Zip the python directory:bash

zip -r pandas_layer.zip python

Place pandas_layer.zip in the car_sales_pipeline directory.
Verify the ZIP file size is approximately 50-100 MB, depending on dependencies.

Step 3: Package the Lambda FunctionThe Lambda function code (lambda_function.py) needs to be zipped for deployment:Create the ZIP file:bash

zip lambda_function.zip lambda_function.py

Ensure lambda_function.zip is in the car_sales_pipeline directory.

Step 4: Deploy AWS Infrastructure with TerraformThe Terraform files (main.tf, variables.tf) define the AWS resources. Deploy them as follows:Initialize Terraform:bash

terraform init

This downloads the AWS provider and sets up the Terraform environment.

Review the planned resources:bash

terraform plan

Verify that two S3 buckets, an IAM role, a Lambda function, a Lambda layer, and an S3 notification are planned.

Apply the configuration:bash

terraform apply -auto-approve

This creates the resources, including buckets with names like car-sales-landing-zone-<suffix> and car-sales-curated-zone-<suffix>, where <suffix> is a random string.

Capture the Terraform output:bash

terraform output

Note the landing_zone and curated_zone bucket names (e.g., car-sales-landing-zone-abc12345, car-sales-curated-zone-abc12345).

Step 5: Configure the Lambda FunctionThe Lambda function requires the curated zone bucket name as an environment variable:Open the AWS Management Console and navigate to Lambda > Functions > preprocess_car_sales.
Go to Configuration > Environment variables.
Add a variable:Key: CURATED_BUCKET
Value: The curated zone bucket name (e.g., car-sales-curated-zone-abc12345) from Terraform output.

Save the changes.
(Optional) Alternatively, update the lambda_function.py file to hardcode the bucket name by replacing car-sales-curated-zone-<suffix> with the actual name, re-zip the function, and update the Lambda function code via the AWS CLI:bash

zip lambda_function.zip lambda_function.py
aws lambda update-function-code --function-name preprocess_car_sales --zip-file fileb://lambda_function.zip

Step 6: Install Notebook DependenciesThe Jupyter Notebook requires Python dependencies for training the model:Install the required packages:bash

pip install pandas numpy scikit-learn joblib boto3

Verify Jupyter Notebook is installed:bash

jupyter notebook --version

If not installed, run pip install jupyter.

Step 7: Update the NotebookThe notebook (train_evaluate_model.ipynb) needs the curated zone bucket name:Open train_evaluate_model.ipynb in Jupyter Notebook.
In the first code cell, replace the bucket variable value (car-sales-curated-zone-<suffix>) with the actual curated zone bucket name from Terraform output.
Save the notebook.

Testing ProcessStep 8: Test the Data Processing PipelineTest the event-driven pipeline by uploading the sample CSV file and verifying the output:Upload the Sample Data:Use the AWS Management Console or AWS CLI to upload ml_sample_data_snapsoft.csv to the landing zone bucket.
Via AWS CLI:bash

aws s3 cp ml_sample_data_snapsoft.csv s3://car-sales-landing-zone-<suffix>/

Replace <suffix> with the random suffix from Terraform output.

Verify Lambda Execution:Navigate to Lambda > Functions > preprocess_car_sales in the AWS Console.
Check the CloudWatch Logs (under Monitor > Logs) for execution logs.
Look for a log entry indicating success, e.g., Successfully processed ml_sample_data_snapsoft.csv and uploaded to car-sales-curated-zone-<suffix>/processed/ml_sample_data_snapsoft.csv.

Verify Output in Curated Zone:Navigate to S3 > car-sales-curated-zone-<suffix> in the AWS Console.
Check for a file at processed/ml_sample_data_snapsoft.csv.
Download the file and verify its contents:Columns like car_ID, ownername, owneremail, dealershipaddress, saledate, and iban should be removed.
Rows missing significant attributes (e.g., CarName, fueltype) should be deleted (e.g., rows with car_ID 40, 47, 62, 63, etc., should be absent).
Rows with missing numerical attributes (e.g., horsepower in row 40 of the original data) should be retained if significant attributes are present.
The processed file should have approximately 230-235 rows (from the original 245) due to row deletions.

Step 9: Test the Machine Learning ModelRun the Jupyter Notebook to train and evaluate the model:Launch Jupyter Notebook:bash

jupyter notebook

Open train_evaluate_model.ipynb in the browser.

Run All Cells:Execute all cells in the notebook.
The notebook will:Download the processed CSV from the curated zone.
Impute missing numerical values (e.g., mean for horsepower, cylindernumber) and categorical values (e.g., most frequent for color).
Train a Random Forest Regressor on features like fueltype, aspiration, wheelbase, etc., to predict Price.
Scale predictions by 0.95 to slightly underestimate prices.
Output evaluation metrics (Mean Absolute Error and Root Mean Squared Error).
Save the trained model as car_price_model.pkl.
Display a sample prediction.

Verify Outputs:Check for reasonable evaluation metrics (e.g., MAE ~2000-4000, RMSE ~3000-6000, depending on the random split).
Confirm the car_price_model.pkl file is created in the project directory.
Ensure the sample prediction is reasonable (e.g., a price between $5000 and $40,000, reflecting the dataset’s range).

Test Model Predictions:Create a test CSV file with a single row of data (e.g., copy a row from the processed CSV, ensuring all required columns are present).
Load the saved model and predict:python

import joblib
import pandas as pd
model = joblib.load('car_price_model.pkl')
test_data = pd.read_csv('test_row.csv')
predicted_price = model.predict(test_data) * 0.95
print(f'Predicted Price: {predicted_price[0]:.2f}')

Verify the predicted price is slightly lower than expected (due to the 0.95 scaling).

Step 10: Validate End-to-End FunctionalityPerform an end-to-end test to ensure the pipeline and model work together:Upload a New CSV:Modify ml_sample_data_snapsoft.csv (e.g., add a new row or create a smaller test CSV with the same structure).
Upload it to the landing zone:bash

aws s3 cp test_data.csv s3://car-sales-landing-zone-<suffix>/

Check Preprocessing:Confirm the processed file appears in the curated zone (processed/test_data.csv).
Verify the file has the correct columns and rows (no car_ID, no rows with missing CarName, etc.).

Update and Run Notebook:Update the key variable in train_evaluate_model.ipynb to processed/test_data.csv.
Re-run the notebook and confirm it processes the new file, trains the model, and produces reasonable metrics.

Check Underestimation:Compare a few predicted prices from the notebook to actual prices in the original data (if available). Predictions should be slightly lower (e.g., ~5% below actual prices).

Troubleshooting Terraform Errors:If terraform apply fails, check AWS credentials and ensure the IAM user has permissions for S3, Lambda, and IAM.
Verify pandas_layer.zip and lambda_function.zip are in the project directory.

- **Lambda Errors**:
  - If the Lambda function fails, check CloudWatch Logs for details (e.g., missing `CURATED_BUCKET` variable or Pandas import issues).
  - Ensure the `pandas_layer.zip` includes all required dependencies (run `pip list` in the `python` directory to verify `pandas` is installed).
  - Confirm the `CURATED_BUCKET` environment variable matches the curated zone bucket name exactly.
- **S3 Issues**:
  - If the processed file doesn’t appear in the curated zone, verify the S3 event notification is enabled (check **S3** > `car-sales-landing-zone-<suffix>` > **Properties** > **Event notifications**).
  - Ensure the Lambda function has the correct IAM permissions (defined in `main.tf`).
- **Notebook Errors**:
  - If the notebook fails to download the file, verify the AWS CLI is configured with the same credentials used for Terraform deployment.
  - Check that the curated zone bucket contains the processed file at the expected path (`processed/ml_sample_data_snapsoft.csv`).
  - If model performance is poor (e.g., MAE > 5000), consider increasing the number of trees in the Random Forest Regressor (edit `n_estimators` in the notebook) or checking for data inconsistencies.

## Cleanup (Optional)
To avoid incurring AWS costs after testing, destroy the infrastructure:
1. Run:
   ```bash
   terraform destroy -auto-approve



