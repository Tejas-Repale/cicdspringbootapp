#!/bin/bash
set -e

echo "Starting Deployment..."

# Create private key file from GitHub secret
echo "$EC2_KEY" > ec2-key.pem
chmod 600 ec2-key.pem

# Variables
JAR_FILE="target/myapp.jar"
REMOTE_PATH="/home/$EC2_USER/app"

# Copy JAR to EC2
scp -i ec2-key.pem $JAR_FILE $EC2_USER@$EC2_HOST:$REMOTE_PATH/

# Restart application
ssh -i ec2-key.pem $EC2_USER@$EC2_HOST << EOF
  pkill -f "java -jar" || true
  nohup java -jar $REMOTE_PATH/myapp.jar > app.log 2>&1 &
EOF

echo "Deployment Finished!"
