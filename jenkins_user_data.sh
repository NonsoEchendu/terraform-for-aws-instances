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
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    command: >
      sh -c "
        apt-get update &&
        apt-get install -y sudo &&
        chown -R 1000:1000 /var/jenkins_home &&
        apt-get -y install docker.io &&
        groupadd -f docker &&
        usermod -aG docker jenkins &&
        echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers &&
        chown jenkins:jenkins /var/run/docker.sock &&
        chmod 666 /var/run/docker.sock &&
        su jenkins -c /usr/local/bin/jenkins.sh"
volumes:
  jenkins_home:
EOF


cd /home/ubuntu
sudo docker-compose up -d
