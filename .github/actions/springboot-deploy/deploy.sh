#!/bin/bash
set -e

echo "Starting Deployment..."

# Ensure .ssh directory exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Write private key from secret
echo "$EC2_SSH_KEY" > ~/.ssh/ec2-key.pem

# Fix possible Windows/formatting issues automatically
# 1. Remove CRLF if present
sed -i 's/\r$//' ~/.ssh/ec2-key.pem
# 2. Ensure correct permissions
chmod 600 ~/.ssh/ec2-key.pem

# Verify key validity before continuing
if ! ssh-keygen -l -f ~/.ssh/ec2-key.pem >/dev/null 2>&1; then
  echo "Invalid SSH key format. Please check EC2_SSH_KEY secret."
  exit 1
fi

# Test SSH connection before deploying
echo "Testing SSH connection..."
if ! ssh -o StrictHostKeyChecking=no -i ~/.ssh/ec2-key.pem $EC2_USER@$EC2_HOST "echo 'SSH connection successful'"; then
  echo "SSH connection failed. Check EC2_USER, EC2_HOST, or key."
  exit 1
fi

# Copy JAR file to EC2
echo "Uploading JAR file..."
scp -o StrictHostKeyChecking=no -i ~/.ssh/ec2-key.pem target/*.jar $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

# Run the app on EC2
echo "Starting Spring Boot app on EC2..."
ssh -o StrictHostKeyChecking=no -i ~/.ssh/ec2-key.pem $EC2_USER@$EC2_HOST << 'EOF'
  pkill -f "java -jar" || true
  nohup java -jar /home/$EC2_USER/app.jar > app.log 2>&1 &
  echo "Spring Boot app started"
EOF
# Upload JAR file
scp -o StrictHostKeyChecking=no -i "$KEY_FILE" myapp/target/*.jar $USER@$HOST:/home/$USER/app.jar
