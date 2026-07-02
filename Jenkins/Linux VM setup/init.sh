#!/bin/bash

# Log output to file for debugging
exec > >(tee /var/log/jenkins-install.log)
exec 2>&1

echo "Starting Jenkins installation..."

# Update packages
sudo apt update -y

# Install Java 21 (required for Jenkins)
echo "Installing Java 21..."
sudo apt install -y fontconfig openjdk-21-jre

# Verify Java installation
java -version

# Add Jenkins repository key
echo "Adding Jenkins repository..."
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package index
sudo apt update -y

# Install Jenkins
echo "Installing Jenkins..."
sudo apt install -y jenkins

# Enable and start Jenkins service
echo "Starting Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait a few seconds for Jenkins to start
sleep 10

# Check Jenkins status
sudo systemctl status jenkins --no-pager

echo "Jenkins installation completed!"
echo "Initial admin password location: /var/lib/jenkins/secrets/initialAdminPassword"






# ========= install docker =========
# sudo apt-get update
# sudo apt install docker.io -y
# sudo usermod -aG docker $USER jenkins
# sudo apt-get install docker-compose-v2 -y



# #!/bin/bash
# # Update packages
# apt update -y
# apt upgrade -y
# # Install Java 17 (required for Jenkins)
# apt install -y openjdk-17-jdk
# # Add Jenkins repository and key
# wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
# echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
# # Update package index and install Jenkins
# apt update -y
# apt install -y jenkins
# # Start Jenkins service and enable at boot
# systemctl enable jenkins
# systemctl start jenkins
# # Print Jenkins status
# systemctl status jenkins --no-pager

