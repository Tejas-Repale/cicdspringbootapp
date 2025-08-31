#!/bin/bash
set -e

echo "Starting Deployment..."

# Variables
APP_NAME="myapp"
JAR_NAME="myapp-0.0.1-SNAPSHOT.jar"
REMOTE_DIR="/home/$EC2_USER/$APP_NAME"
LOCAL_JAR="myapp/target/$JAR_NAME"

# Copy JAR to EC2
scp -i "$EC2_SSH_KEY" -o StrictHostKeyChecking=no "$LOCAL_JAR" "$EC2_USER@$EC2_HOST:$REMOTE_DIR/"

# Restart Spring Boot app on EC2
ssh -i "$EC2_SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << EOF
  pkill -f $JAR_NAME || true
  nohup java -jar $REMOTE_DIR/$JAR_NAME > $REMOTE_DIR/app.log 2>&1 &
EOF

# Deployment status
if [ $? -eq 0 ]; then
   echo "Deployment successful"
else
   echo "Deployment failed"
   exit 1
fi
