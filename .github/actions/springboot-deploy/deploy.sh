#!/bin/bash
set -e

echo "Starting Deployment..."

# Ensure environment variables are set
if [[ -z "$EC2_SSH_KEY" || -z "$EC2_USER" || -z "$EC2_HOST" ]]; then
  echo "Error: EC2_SSH_KEY, EC2_USER, or EC2_HOST not set."
  exit 1
fi

# Save key to a file
echo "$EC2_SSH_KEY" | tr -d '\r' > ec2-key.pem
chmod 600 ec2-key.pem

echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST "echo SSH connection successful"

# Find the JAR file in myapp/target
JAR_FILE=$(ls myapp/target/*.jar 2>/dev/null | grep -v 'sources\|javadoc')
if [ -z "$JAR_FILE" ]; then
  echo "Error: JAR file not found in myapp/target/"
  exit 1
fi
echo "Uploading $JAR_FILE to $EC2_USER@$EC2_HOST..."
scp -o StrictHostKeyChecking=no -i ec2-key.pem "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

echo "Starting Spring Boot app on EC2..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST << EOF
  pkill -f 'java -jar' || true
  nohup java -jar /home/$EC2_USER/app.jar > /home/$EC2_USER/app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
