#!/bin/bash

# Update system packages
sudo apt-get update -y

# Install Docker
sudo apt-get install docker.io -y

# Add docker to usergroup
sudo usermod -aG docker $USER

# Install Docker Compose
DOCKER_COMPOSE_VERSION=1.29.2
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create the docker-compose.yml file
cat <<EOF > /home/ubuntu/docker-compose.yml
version: "3.8"
services:
  sonarqube:
    image: sonarqube:lts
    container_name: sonarqube
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    restart: always
volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
EOF

cd /home/ubuntu
sudo docker-compose up -d