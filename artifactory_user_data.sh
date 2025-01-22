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
  artifactory-service:
    image: docker.bintray.io/jfrog/artifactory-oss:7.49.6
    container_name: artifactory
    restart: always
    networks:
      - ci_net
    ports:
      - 8081:8081
      - 8082:8082
    volumes:
      - artifactory:/var/opt/jfrog/artifactory
volumes:
  artifactory:
networks:
  ci_net:
EOF

cd /home/ubuntu
sudo docker-compose up -d
