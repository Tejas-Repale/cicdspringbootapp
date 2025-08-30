#!/bin/bash
set -e

echo "Starting automated deployment..."

# Decode base64 EC2 key
echo "$EC2_KEY" | base64 --decode > ec2-key.pem
chmod 600 ec2-key.pem

# SSH: install Java if missing, stop old app
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST << 'EOF'
  echo "Installing Java if missing..."
  if ! java -version &>/dev/null; then
    sudo apt update
    sudo apt install -y openjdk-17-jdk
  fi

  echo "Stopping old app if running..."
  pkill -f 'java -jar' || true
EOF

# Copy JAR from the correct folder (myapp/target)
JAR_FILE=$(ls myapp/target/*.jar | grep -v 'sources\|javadoc')
if [ -z "$JAR_FILE" ]; then
  echo "Error: JAR file not found in myapp/target/"
  exit 1
fi

echo "Copying $JAR_FILE to $EC2_USER@$EC2_HOST..."
scp -o StrictHostKeyChecking=no -i ec2-key.pem "$JAR_FILE" $EC2_USER@$EC2_HOST:/home/$EC2_USER/app.jar

# SSH: create systemd service for auto-start
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $EC2_USER@$EC2_HOST << EOF
  echo "Creating systemd service..."
  cat << EOT | sudo tee /etc/systemd/system/myapp.service
[Unit]
Description=Spring Boot MyApp
After=network.target

[Service]
User=$EC2_USER
ExecStart=/usr/bin/java -jar /home/$EC2_USER/app.jar
SuccessExitStatus=143
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

  sudo systemctl daemon-reload
  sudo systemctl enable myapp
  sudo systemctl restart myapp
EOF

echo "Deployment completed successfully!"
