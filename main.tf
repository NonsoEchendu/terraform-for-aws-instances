resource "aws_vpc" "main_vpc" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    Name = "javaVPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "javaVpcInternetGateway"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "javaPublicRouteTable"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "javaPublicSubnet"
  }
}

# Public Route Table Association with Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT GAteway
resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NatGateway"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "javaPrivateRouteTable"
  }
}

# Route for NAT GAteway in Private RouteTable
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_nat.id
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "javaPrivateSubnet"
  }
}

# Private Route Table Association with Private Subnet
resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------- EC2 Instances -----------#

# -------------------- For Jenkins -------------------------- #

# Security Group for Jenkins Instance
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins_sg"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "jenkins_sg"
  }
}

# Jenkins Security Group Inbound Rule 1
resource "aws_vpc_security_group_ingress_rule" "jenkins_sg_inbound_rule1" {
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Jenkins Security Group Inbound Rule 2
resource "aws_vpc_security_group_ingress_rule" "jenkins_sg_inbound_rule2" {
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

# Jenkins Security Group Outbound Rule 1

resource "aws_vpc_security_group_egress_rule" "outbound_rule1" {
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EC2 instance for Jenkins
resource "aws_instance" "jenkins_server" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = "new-test-key-pair"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_subnet.id
  user_data              = filebase64("user-data-scripts/jenkins_user_data.sh")

  tags = {
    Name = "JenkinsServer"
  }
}

# -------------------- For Bastion -------------------------- #

# Bastion Group for Jenkins Instance
resource "aws_security_group" "bastion_sg" {
  name   = "bastion_sg"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "bastion_sg"
  }
}

# Bastion Security Group Inbound Rule 1
resource "aws_vpc_security_group_ingress_rule" "bastion_sg_inbound_rule1" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Bastion Security Group Outbound Rule 1
resource "aws_vpc_security_group_egress_rule" "bastion_outbound_rule1" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# Bastion Security Group HTTPS Outbound Rule 
resource "aws_vpc_security_group_egress_rule" "bastion_outbound_https" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# EC2 Instance for Bastion
resource "aws_instance" "bastion_host" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = "new-test-key-pair"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public_subnet.id

  tags = {
    Name = "bastion_host"
  }
}

# --------------- For Artifactory -------------------- #

# Security Group for Artifactory Instance
resource "aws_security_group" "artifactory_sg" {
  name   = "artifactory_sg"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "artifactory_sg"
  }
}

# Artifactory Security Group Inbound Rule 1
resource "aws_vpc_security_group_ingress_rule" "artifactory_sg_inbound_rule1" {
  security_group_id            = aws_security_group.artifactory_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion_sg.id
}

# Artifactory Security Group Inbound Rule 2
resource "aws_vpc_security_group_ingress_rule" "artifactory_sg_inbound_rule2" {
  security_group_id            = aws_security_group.artifactory_sg.id
  from_port                    = 8081
  ip_protocol                  = "tcp"
  to_port                      = 8081
  referenced_security_group_id = aws_security_group.jenkins_sg.id
}

# Artifactory Security Group Inbound Rule 3
resource "aws_vpc_security_group_ingress_rule" "artifactory_sg_inbound_rule3" {
  security_group_id            = aws_security_group.artifactory_sg.id
  from_port                    = 8082
  ip_protocol                  = "tcp"
  to_port                      = 8082
  referenced_security_group_id = aws_security_group.jenkins_sg.id
}

# Artifactory Security Group Outbound Rule 
resource "aws_vpc_security_group_egress_rule" "artifactory_https_outbound_rule" {
  security_group_id = aws_security_group.artifactory_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "artifactory_dns_outbound_rule" {
  security_group_id = aws_security_group.artifactory_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

# EC2 instance for Artifactory
resource "aws_instance" "artifactory_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.medium"
  key_name                    = "new-test-key-pair"
  vpc_security_group_ids      = [aws_security_group.artifactory_sg.id]
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  user_data                   = filebase64("user-data-scripts/artifactory_user_data.sh")

  tags = {
    Name = "ArtifactoryServer"
  }

  depends_on = [aws_nat_gateway.main_nat]
}

# --------------- For Sonarqube -------------------- #

# Security Group for Sonarqube Instance
resource "aws_security_group" "sonarqube_sg" {
  name   = "sonarqube_sg"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "sonarqube_sg"
  }
}

# sonarqube Security Group Inbound Rule 1
resource "aws_vpc_security_group_ingress_rule" "sonarqube_sg_inbound_rule1" {
  security_group_id            = aws_security_group.sonarqube_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion_sg.id
}

# Sonarqube Security Group Inbound Rule 2
resource "aws_vpc_security_group_ingress_rule" "sonarqube_sg_inbound_rule2" {
  security_group_id            = aws_security_group.sonarqube_sg.id
  from_port                    = 9000
  ip_protocol                  = "tcp"
  to_port                      = 9000
  referenced_security_group_id = aws_security_group.jenkins_sg.id
}

# Sonarqube Security Group Outbound Rule 
resource "aws_vpc_security_group_egress_rule" "sonarqube_https_outbound_rule" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "sonarqube_dns_outbound_rule" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

# EC2 instance for Sonarqube
resource "aws_instance" "sonarqube_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.medium"
  key_name                    = "new-test-key-pair"
  vpc_security_group_ids      = [aws_security_group.sonarqube_sg.id]
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  user_data                   = filebase64("user-data-scripts/sonarqube_user_data.sh")

  tags = {
    Name = "SonarqubeServer"
  }

  depends_on = [aws_nat_gateway.main_nat]
}
