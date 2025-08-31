#!/bin/bash
set -e

echo "Starting Deployment..."

# Decode EC2 key
echo "$EC2_SSH_KEY" | base64 --decode > ec2-key.pem
chmod 600 ec2-key.pem

# Test SSH connection
echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST "echo SSH connection successful"

# Determine JAR file path
JAR_FILE=$(ls myapp/target/*.jar | grep -v 'sources\|javadoc')
if [ -z "$JAR_FILE" ]; then
  echo "Error: JAR file not found in myapp/target/"
  exit 1
fi

echo "Uploading $JAR_FILE to EC2..."
scp -o StrictHostKeyChecking=no -i ec2-key.pem "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

echo "Starting Spring Boot app on EC2..."
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST << EOF
  pkill -f 'java -jar' || true
  nohup java -jar /home/$EC2_USER/app.jar > app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
