#!/bin/bash
set -e

echo "Starting Deployment..."

# Save EC2 key from GitHub secret (plain text)
echo "$EC2_SSH_KEY" > ec2-key.pem
chmod 600 ec2-key.pem

# Test SSH connection
echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST "echo SSH connection successful"

# Find the JAR file
JAR_FILE=$(find myapp/target -maxdepth 1 -name "*.jar" | grep -v "sources\|javadoc")
if [ -z "$JAR_FILE" ]; then
    echo "Error: JAR file not found. Build the project first!"
    exit 1
fi

echo "Uploading JAR file..."
scp -o StrictHostKeyChecking=no -i ec2-key.pem "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

# Start the Spring Boot app on EC2
echo "Starting Spring Boot app on EC2..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST << 'EOF'
pkill -f 'java -jar' || true
nohup java -jar /home/$USER/app.jar > app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
