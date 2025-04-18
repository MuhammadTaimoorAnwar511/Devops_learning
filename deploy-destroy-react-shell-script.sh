#!/bin/bash

# Configuration
GIT_REPO="<github-link>"
BUILD_DIR="build"
S3_BUCKET="<unique-name>"
AWS_REGION="<region-name>"

# Clone the repository
echo "Cloning repository..."
git clone $GIT_REPO
cd react-app

# Install dependencies
echo "Installing dependencies..."
npm install

# Create production build
echo "Creating build..."
npm run build

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3 mb s3://$S3_BUCKET --region $AWS_REGION

# Modify public access block settings
echo "Updating public access block configuration..."
aws s3api put-public-access-block \
	--bucket $S3_BUCKET \
	--public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Configure bucket for static website hosting
echo "Configuring static website hosting..."
aws s3 website s3://$S3_BUCKET --index-document index.html --error-document index.html

# Set bucket policy for public access
echo "Setting bucket policy..."
cat > bucket-policy.json << EOF
{
	"Version": "2012-10-17",
	"Statement": [
    	{
        	"Sid": "PublicReadGetObject",
        	"Effect": "Allow",
        	"Principal": "*",
        	"Action": "s3:GetObject",
        	"Resource": "arn:aws:s3:::$S3_BUCKET/*"
    	}
	]
}
EOF
aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file://bucket-policy.json

# Deploy to S3
echo "Deploying files to S3..."
aws s3 sync $BUILD_DIR/ s3://$S3_BUCKET --delete

# Clean up
echo "Cleaning up..."
rm -rf bucket-policy.json

echo "Deployment complete!"
echo "Access your site at: http://$S3_BUCKET.s3-website.$AWS_REGION.amazonaws.com"
================
#!/bin/bash

# Configuration (must match deploy.sh)
S3_BUCKET="<bucket-name>"
AWS_REGION="<region-name>"

# Safety confirmation
read -p "🔥 This will PERMANENTLY DELETE all resources. Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

echo "Starting destruction of AWS resources..."

# Delete S3 bucket and contents
echo "Checking for S3 bucket: $S3_BUCKET"
if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
    # Remove bucket policy first
    echo "Removing bucket policy..."
    aws s3api delete-bucket-policy --bucket $S3_BUCKET
    
    # Empty bucket including versions
    echo "Emptying S3 bucket completely..."
    aws s3api delete-objects \
        --bucket $S3_BUCKET \
        --delete "$(aws s3api list-object-versions \
        --bucket $S3_BUCKET \
        --output=json \
        --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null
    
    # Delete bucket
    echo "Removing S3 bucket..."
    aws s3 rb "s3://$S3_BUCKET" --force
    echo "✅ S3 bucket $S3_BUCKET deleted successfully"
else
    echo "ℹ️ S3 bucket $S3_BUCKET not found or already deleted"
fi

# Remove local files
echo "Cleaning local files..."
rm -rf react-app 

echo "🏁 Destruction complete!"
