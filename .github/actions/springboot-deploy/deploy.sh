#!/bin/bash
set -e

EC2_HOST=$1
EC2_USER=$2
EC2_KEY=$3

echo "Starting automated deployment"

JAR_FILE="myapp/target/myapp-0.0.1-SNAPSHOT.jar"

if [[ ! -f "$JAR_FILE" ]]; then
  echo "Error: JAR file not found at $JAR_FILE"
  exit 1
fi

echo "Uploading $JAR_FILE to EC2"
scp -i "$EC2_KEY" -o StrictHostKeyChecking=no "$JAR_FILE" "$EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar"

echo "Restarting app on EC2"
ssh -i "$EC2_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << 'EOF'
  pkill -f 'java -jar' || true
  nohup java -jar /home/$USER/app.jar > app.log 2>&1 &
EOF

echo "Deployment completed successfully"
