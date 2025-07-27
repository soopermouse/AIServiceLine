import json
import boto3
import pandas as pd
import urllib.parse
import os

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Get the S3 bucket and file name from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    
    # Download the file from S3
    local_file = '/tmp/input.csv'
    s3_client.download_file(bucket, key, local_file)
    
    # Read CSV
    df = pd.read_csv(local_file)
    
    # Columns to delete (unusable for ML)
    columns_to_drop = ['car_ID', 'ownername', 'owneremail', 'dealershipaddress', 'saledate', 'iban']
    df = df.drop(columns=[col for col in columns_to_drop if col in df.columns])
    
    # Significant columns (delete rows with missing values)
    significant_columns = ['CarName', 'fueltype', 'carbody', 'aspiration', 'doornumber', 'drivewheel', 'enginelocation']
    df = df.dropna(subset=[col for col in significant_columns if col in df.columns])
    
    # Save processed file to curated zone
    curated_bucket = os.environ.get('CURATED_BUCKET', 'car-sales-curated-zone-<suffix>') # Replace <suffix> with actual suffix
    output_key = f"processed/{key.split('/')[-1]}"
    output_file = '/tmp/output.csv'
    df.to_csv(output_file, index=False)
    
    # Upload to curated zone
    s3_client.upload_file(output_file, curated_bucket, output_key)
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully processed {key} and uploaded to {curated_bucket}/{output_key}')
    }