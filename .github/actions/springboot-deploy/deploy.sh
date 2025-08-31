#!/bin/bash
set -e

echo "Starting Deployment..."

# Decode base64 SSH key and set permissions
echo "$EC2_SSH_KEY" | base64 --decode > ec2-key.pem
chmod 600 ec2-key.pem

# Build the Spring Boot project (myapp folder)
echo "Building Maven project..."
cd myapp
mvn clean package -DskipTests

# Find JAR
JAR_FILE=$(ls target/*.jar | grep -v 'sources\|javadoc')
if [ -z "$JAR_FILE" ]; then
  echo "Error: JAR file not found in myapp/target/"
  exit 1
fi

echo "Uploading $JAR_FILE to EC2..."
scp -o StrictHostKeyChecking=no -i ../ec2-key.pem "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

# SSH into EC2 and start app
echo "Starting Spring Boot app on EC2..."
ssh -o StrictHostKeyChecking=no -i ../ec2-key.pem $EC2_USER@$EC2_HOST << EOF
  pkill -f 'java -jar' || true
  nohup java -jar /home/$EC2_USER/app.jar > /home/$EC2_USER/app.log 2>&1 &
EOF

echo "Deployment completed successfully!"
