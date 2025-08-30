#!/bin/bash
set -e

EC2_HOST=$1
EC2_USER=$2
EC2_KEY_BASE64=$3

echo "Starting automated deployment..."

# Save EC2 key
echo "$EC2_KEY_BASE64" | base64 --decode > ec2-key.pem
chmod 600 ec2-key.pem

# Upload JAR to EC2
scp -i ec2-key.pem -o StrictHostKeyChecking=no target/*.jar $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

# SSH into EC2 and restart app
ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
  echo "Stopping old app if running..."
  pkill -f 'java -jar' || true

  echo "Starting new app..."
  nohup java -jar /home/$EC2_USER/app.jar > app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
