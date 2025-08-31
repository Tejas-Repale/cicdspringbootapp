#!/bin/bash
set -e

echo "Starting Deployment..."

# Check variables
if [ -z "$EC2_SSH_KEY" ] || [ -z "$EC2_USER" ] || [ -z "$EC2_HOST" ]; then
  echo " ERROR: One or more required environment variables are missing!"
  echo "EC2_SSH_KEY=$EC2_SSH_KEY"
  echo "EC2_USER=$EC2_USER"
  echo "EC2_HOST=$EC2_HOST"
  exit 1
fi

# Save private key
echo "$EC2_SSH_KEY" > ec2_key.pem
chmod 600 ec2_key.pem

echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -i ec2_key.pem $EC2_USER@$EC2_HOST "echo SSH connection successful"

echo "Uploading JAR file..."
scp -i ec2_key.pem target/*.jar $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

echo "Starting Spring Boot app on EC2..."
ssh -i ec2_key.pem $EC2_USER@$EC2_HOST "nohup java -jar /home/$EC2_USER/app.jar > app.log 2>&1 &"

echo " Deployment Completed Successfully!"
