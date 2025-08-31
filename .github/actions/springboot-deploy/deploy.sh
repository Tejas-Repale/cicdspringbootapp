#!/bin/bash
set -e

echo "Starting automated deployment..."

# Write SSH key from secret into a file
echo "$EC2_SSH_KEY" > private_key.pem
chmod 600 private_key.pem

JAR_FILE="target/myapp-0.0.1-SNAPSHOT.jar"

echo "Uploading $JAR_FILE to EC2..."
scp -o StrictHostKeyChecking=no -i private_key.pem $JAR_FILE $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

echo "Restarting app on EC2..."
ssh -o StrictHostKeyChecking=no -i private_key.pem $EC2_USER@$EC2_HOST << 'EOF'
  pkill -f 'java -jar' || true
  nohup java -jar /home/$EC2_USER/app.jar > app.log 2>&1 &
EOF
