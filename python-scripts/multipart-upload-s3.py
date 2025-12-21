import boto3
import os
import time

# Initialize Session with your AWS profile
# session = boto3.Session(profile_name='eks-siva.bapatlas.site')
session = boto3.Session()
# Create S3 client using the profile from the session
s3 = session.client('s3')

# Configuration
bucket_name = 'videos-konka'
file_name = input('Enter the file name to upload: ').strip()

# Validate the file name
if not file_name:
    raise ValueError("❌ File name cannot be empty. Please provide a valid file name.")

# Use a raw string (r"") to handle Windows file paths
file_path = rf"C:\Users\sivar\Videos\{file_name}"
object_key = f'k8s/{file_name}'  
part_size = 5 * 1024 * 1024  # 5 MB per part

# Validate if the file exists
if not os.path.exists(file_path):
    raise FileNotFoundError(f"❌ File not found at path: {file_path}")

# Step 1: Initiate Multipart Upload
response = s3.create_multipart_upload(Bucket=bucket_name, Key=object_key)
upload_id = response['UploadId']
parts = []

# Get the total file size for progress calculation
total_file_size = os.path.getsize(file_path)
uploaded_size = 0

# Start the timer for total upload time
start_time = time.time()

# Step 2: Upload Parts
try:
    with open(file_path, 'rb') as file:
        part_number = 1
        while chunk := file.read(part_size):
            part_start_time = time.time()
            response = s3.upload_part(
                Bucket=bucket_name,
                Key=object_key,
                PartNumber=part_number,
                UploadId=upload_id,
                Body=chunk
            )
            part_end_time = time.time()
            part_time = part_end_time - part_start_time
            
            parts.append({'PartNumber': part_number, 'ETag': response['ETag']})
            uploaded_size += len(chunk)

            # Calculate and print progress
            progress = (uploaded_size / total_file_size) * 100
            elapsed_time = part_end_time - start_time
            estimated_remaining_time = (elapsed_time / (progress / 100)) - elapsed_time
            print(f"✅ Uploaded part {part_number}, Progress: {progress:.2f}%, Time taken for part: {part_time:.2f}s")
            print(f"⏳ Elapsed time: {elapsed_time:.2f}s, Estimated remaining time: {estimated_remaining_time:.2f}s")

            part_number += 1

    # Step 3: Complete Multipart Upload
    s3.complete_multipart_upload(
        Bucket=bucket_name,
        Key=object_key,
        UploadId=upload_id,
        MultipartUpload={'Parts': parts}
    )

    # Calculate total time taken
    end_time = time.time()
    total_upload_time = end_time - start_time
    total_upload_time_minutes = total_upload_time / 60  # Convert to minutes
    print(f"✅ Upload completed successfully!")
    print(f"⏱️ Total time taken for upload: {total_upload_time_minutes:.2f} minutes")

except Exception as e:
    s3.abort_multipart_upload(Bucket=bucket_name, Key=object_key, UploadId=upload_id)
    print(f"❌ Upload failed: {e}")
