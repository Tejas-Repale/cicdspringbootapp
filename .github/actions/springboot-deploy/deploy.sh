#!/bin/bash
set -e

EC2_HOST=$1
EC2_USER=$2
EC2_KEY=$3

echo "Starting automated deployment"

# Save SSH key
echo "$EC2_KEY" > ec2-key.pem
chmod 600 ec2-key.pem

# Find JAR file in myapp/target/
JAR_FILE=$(ls myapp/target/*.jar | head -n 1)

if [ -z "$JAR_FILE" ]; then
  echo "ERROR: No JAR file found in myapp/target/"
  exit 1
fi

echo "Uploading $JAR_FILE to EC2"
scp -i ec2-key.pem -o StrictHostKeyChecking=no "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

echo "Restarting app on EC2"
ssh -i ec2-key.pem -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'EOF'
  pkill -f "java -jar" || true
  nohup java -jar app.jar > app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
