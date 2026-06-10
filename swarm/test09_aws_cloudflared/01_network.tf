resource "aws_vpc" "main" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "lecture-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "lecture-igw"}
}

data "aws_availability_zones" "available"{
  state = "available"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.1.0/24" 
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true 
  tags = { Name = "lecture-public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.2.0/24" 
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true 
  tags = { Name = "lecture-public-subnet-2" }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.3.0/24" 
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false 
  tags = { Name = "lecture-private-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource  "aws_route_table_association" "public_a_1" {
  subnet_id      = aws_subnet.public_subnet_1.id 
  route_table_id = aws_route_table.public_rt.id 
}
resource  "aws_route_table_association" "public_a_2" {
  subnet_id      = aws_subnet.public_subnet_2.id 
  route_table_id = aws_route_table.public_rt.id 
}

data "aws_ami" "latest_al2023" {
  most_recent   = true
  owners        = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] 
  }
}

# NAT 인스턴스
resource "aws_instance" "nat_ec2" {
  ami                    = data.aws_ami.latest_al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  key_name               = aws_key_pair.kp.key_name
  source_dest_check      = false  

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nat.conf
    sysctl -p /etc/sysctl.d/99-nat.conf
    dnf install -y iptables iptables-services
    systemctl enable --now iptables
    iptables -P FORWARD ACCEPT
    iptables -I FORWARD -j ACCEPT
    iptables -t nat -A POSTROUTING -s ${aws_vpc.main.cidr_block} -j MASQUERADE
    service iptables save
  EOF
  tags = { Name = "nat-instance" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_ec2.primary_network_interface_id
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}