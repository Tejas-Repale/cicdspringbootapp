#!/bin/bash
set -e

echo "Starting automated deployment..."

# Save key
echo "$1" | base64 --decode > ec2-key.pem
chmod 600 ec2-key.pem

# SSH and install Java if missing, create systemd service for auto-start
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $2@$3 << 'EOF'
  echo "Installing Java if missing..."
  if ! java -version &>/dev/null; then
    sudo apt update
    sudo apt install -y openjdk-17-jdk
  fi

  echo "Stopping old app if running..."
  pkill -f 'java -jar' || true
EOF

# Copy JAR
scp -o StrictHostKeyChecking=no -i ec2-key.pem target/*.jar $2@$3:~/app.jar

# SSH and create systemd service for auto-start
ssh -o StrictHostKeyChecking=no -i ec2-key.pem $2@$3 << EOF
  echo "Creating systemd service..."
  cat << EOT | sudo tee /etc/systemd/system/myapp.service
[Unit]
Description=Spring Boot MyApp
After=network.target

[Service]
User=$2
ExecStart=/usr/bin/java -jar /home/$2/app.jar
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
