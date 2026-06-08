# version 명시하기 
terraform {
  required_version = "~>1.14.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
    tailscale = {
        source = "tailscale/tailscale"
        version = "0.17.2"
    }
  }
}

# tailscale api 키와 tailnet_name 등록하기
provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = var.tailnet_name
}

resource "tailscale_tailnet_key" "ec2_join_key" {
  reusable = true
  ephemeral = true  # [수정] 찌꺼기 방지를 위해 true 권장
  preauthorized = true
  expiry = 3600
}

provider "aws" {
    region = "ap-northeast-2" # 서울 리전 
}

# ==========================================================
# 1. VPC 및 네트워크 서브넷 재설계 (ALB 고가용성 대응)
# ==========================================================
resource "aws_vpc" "main" {
    cidr_block           = "10.100.0.0/16"
    enable_dns_hostnames = true
    tags                 = { Name = "lecture-vpc" }
}

resource "aws_internet_gateway" "igw" {
    vpc_id  = aws_vpc.main.id
    tags    = { Name = "lecture-igw"}
}

data "aws_availability_zones" "available"{
    state = "available"
}

# [수정] Public Subnet 1 (10.100.1.0/24 - AZ: a) -> NAT 인스턴스 및 ALB 위치
resource "aws_subnet" "public_subnet_1" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.100.1.0/24" 
    availability_zone       = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true 
    tags = { Name = "lecture-public-subnet-1" }
}

# [추가] Public Subnet 2 (10.100.2.0/24 - AZ: c) -> ALB 고가용성 보장용
resource "aws_subnet" "public_subnet_2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.100.2.0/24" 
    availability_zone       = data.aws_availability_zones.available.names[1] # 다른 AZ 할당
    map_public_ip_on_launch = true 
    tags = { Name = "lecture-public-subnet-2" }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# 2개의 Public Subnet 모두 Public 라우팅 테이블에 연결
resource  "aws_route_table_association" "public_a_1" {
    subnet_id      = aws_subnet.public_subnet_1.id 
    route_table_id = aws_route_table.public_rt.id 
}
resource  "aws_route_table_association" "public_a_2" {
    subnet_id      = aws_subnet.public_subnet_2.id 
    route_table_id = aws_route_table.public_rt.id 
}

# [수정] Private Subnet (10.100.3.0/24) -> Swarm 클러스터 위치
resource "aws_subnet" "private_subnet" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.100.3.0/24" 
    availability_zone       = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = false 
    tags = { Name = "lecture-private-subnet" }
}

# ==========================================================
# 2. NAT 인스턴스 세팅
# ==========================================================
resource "aws_security_group" "nat_sg" {
  name   = "nat-instance-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = [aws_vpc.main.cidr_block] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "latest_al2023" {
    most_recent   = true
    owners        = ["amazon"]
    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"] 
    }
}

resource "aws_instance" "nat_ec2" {
    ami                    = data.aws_ami.latest_al2023.id
    instance_type          = "t3.micro"
    # [수정] NAT 인스턴스를 public_subnet_1 에 명시적으로 배치
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
        cidr_block     = "0.0.0.0/0"
        network_interface_id = aws_instance.nat_ec2.primary_network_interface_id
    }
}

resource "aws_route_table_association" "private_a" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}

# ==========================================================
# 3. ALB 전용 보안 그룹 추가
# ==========================================================
resource "aws_security_group" "alb_sg" {
  name        = "lecture-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================================
# 4. Swarm 노드용 보안 그룹 (ALB 연동 포함)
# ==========================================================
resource "tls_private_key" "pk" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
    key_name   = "lecture-key"
    public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
    filename        = "${path.module}/lecture-key.pem"
    content         = tls_private_key.pk.private_key_pem
    file_permission = "0600" 
}

resource "aws_security_group" "ssh_sg" {
    name   = "allow-ssh-and-swarm" 
    vpc_id = aws_vpc.main.id

    ingress {
        from_port   = 22 
        to_port     = 22 
        protocol    = "tcp" 
        cidr_blocks = ["0.0.0.0/0"] 
    }
    
    # [핵심 추가] ALB로부터 들어오는 80번 웹 트래픽을 허용!
    ingress {
        description     = "Allow traffic from ALB"
        from_port       = 80 
        to_port         = 80 
        protocol        = "tcp" 
        security_groups = [aws_security_group.alb_sg.id] # ALB의 보안그룹 지정
    }

    # 스웜 통신 포트
    ingress {
        from_port   = 2377
        to_port     = 2377
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.main.cidr_block] 
        self        = true 
    }
    ingress {
        from_port   = 7946
        to_port     = 7946
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.main.cidr_block]
        self        = true
    }
    ingress {
        from_port   = 7946
        to_port     = 7946
        protocol    = "udp"
        cidr_blocks = [aws_vpc.main.cidr_block]
        self        = true
    }
    ingress {
        from_port   = 4789
        to_port     = 4789
        protocol    = "udp"
        cidr_blocks = [aws_vpc.main.cidr_block]
        self        = true
    }
    ingress {
        description = "Allow Ping from VPC internal"
        from_port   = -1   
        to_port     = -1   
        protocol    = "icmp"
        cidr_blocks = [aws_vpc.main.cidr_block] 
    }
    egress {
        from_port   = 0  
        to_port     = 0  
        protocol    = "-1"  
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ==========================================================
# 5. Swarm 클러스터 EC2 생성 (Master & Workers)
# ==========================================================
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 대장 (Master) 노드
resource "aws_instance" "my_ec2" {
    ami                     = data.aws_ami.ubuntu_24_04.id 
    instance_type           = "t3.micro" 
    subnet_id               = aws_subnet.private_subnet.id       
    vpc_security_group_ids  = [aws_security_group.ssh_sg.id] 
    key_name                = aws_key_pair.kp.key_name  
    source_dest_check       = false  
    
    user_data = <<-EOF
        #!/bin/bash
        exec > >(tee -a /var/log/user_data_final.log) 2>&1
        hostnamectl set-hostname "${var.host_name}"
        echo "127.0.0.1 ${var.host_name}" >> /etc/hosts
        until ping -c 1 8.8.8.8 &> /dev/null; do
            sleep 5
        done        
        curl -fsSL https://tailscale.com/install.sh | sh
        systemctl enable --now tailscaled
        
        cat <<EOT > /etc/sysctl.d/99-tailscale.conf
        net.ipv4.ip_forward = 1
        net.ipv6.conf.all.forwarding = 1
        EOT
        sysctl -p /etc/sysctl.d/99-tailscale.conf 

        tailscale up --authkey=${tailscale_tailnet_key.ec2_join_key.key} \
                     --advertise-routes=${aws_vpc.main.cidr_block} \
                     --accept-routes \
                     --hostname=${var.host_name} 
    EOF
    tags = { Name = "my-ec2" }
}

# Tailscale 라우팅 승인 연동
resource "aws_route" "to_onpremise_public" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "172.16.8.0/24"
  network_interface_id   = aws_instance.my_ec2.primary_network_interface_id
}
resource "aws_route" "to_onpremise_private" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "172.16.8.0/24"
  network_interface_id   = aws_instance.my_ec2.primary_network_interface_id
}
# [추가됨] 테라폼에게 60초 강제 휴식 부여 (EC2 내부 tailscale up 명령어 완료 대기)
resource "time_sleep" "wait_for_tailscale_sync" {
  depends_on      = [aws_instance.my_ec2]
  create_duration = "60s" 
}

# [수정됨] EC2가 아니라 60초 휴식이 끝난 후 기기를 찾도록 변경
data "tailscale_device" "my_ec2_device" {
  hostname   = var.host_name
  wait_for   = "180s" 
  depends_on = [time_sleep.wait_for_tailscale_sync] 
}
resource "tailscale_device_subnet_routes" "approve_vpc_routes" {
  device_id = data.tailscale_device.my_ec2_device.id
  routes    = [aws_vpc.main.cidr_block]
}

# 워커 (Worker) 노드
resource "aws_instance" "swarm_workers" {
    count = var.worker_count 
    ami                     = data.aws_ami.ubuntu_24_04.id 
    instance_type           = "t3.micro" 
    subnet_id               = aws_subnet.private_subnet.id       
    vpc_security_group_ids  = [aws_security_group.ssh_sg.id] 
    key_name                = aws_key_pair.kp.key_name  
    source_dest_check       = true  
    
    user_data = <<-EOF
        #!/bin/bash
        exec > >(tee -a /var/log/user_data_final.log) 2>&1
        hostnamectl set-hostname "swarm-worker-${count.index + 1}"
        echo "127.0.0.1 swarm-worker-${count.index + 1}" >> /etc/hosts
        until ping -c 1 8.8.8.8 &> /dev/null; do
            sleep 5
        done        
        echo "Worker Setup Complete!"
    EOF
    tags = { Name = "swarm-worker-${count.index + 1}" }
}

# ==========================================================
# 6. ALB (Load Balancer) 구축 및 연결 설정
# ==========================================================
resource "aws_lb" "web_alb" {
    name               = "lecture-alb"
    internal           = false 
    load_balancer_type = "application" 
    security_groups    = [aws_security_group.alb_sg.id] 
    # [핵심] 고가용성을 위해 분리한 2개의 Public 서브넷 지정
    subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    tags = { Name = "lecture-alb" }
}

resource "aws_lb_target_group" "web_tg" {
    name     = "lecture-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id
    
    health_check {
        enabled             = true           
        path                = "/"            
        port                = "traffic-port" 
        protocol            = "HTTP"         
        healthy_threshold   = 5  
        unhealthy_threshold = 2  
        timeout             = 5  
        interval            = 30 
    }    
}

# [핵심 수정] 마스터 노드 연결
resource "aws_lb_target_group_attachment" "master_attach" {
    target_group_arn = aws_lb_target_group.web_tg.arn
    port             = 80
    target_id        = aws_instance.my_ec2.id
}

# [핵심 수정] 모든 워커 노드 연결 (스웜의 라우팅 메쉬 활용)
resource "aws_lb_target_group_attachment" "workers_attach" {
    count            = var.worker_count
    target_group_arn = aws_lb_target_group.web_tg.arn
    port             = 80
    target_id        = aws_instance.swarm_workers[count.index].id
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ==========================================================
# 7. Ansible 인벤토리 및 출력
# ==========================================================
resource "local_file" "ansible_inventory"{
    filename = "${path.module}/inventory.yml"
    content = yamlencode({
        all = {
            children = {
                master = {
                    hosts = {
                        "${aws_instance.my_ec2.private_ip}" = {
                            ansible_user = "ubuntu"
                            ansible_ssh_private_key_file = "${path.module}/lecture-key.pem"
                        }
                    }
                }
                workers = {
                    hosts = {
                        for worker in aws_instance.swarm_workers :
                        worker.private_ip => {
                            ansible_user = "ubuntu"
                            ansible_ssh_private_key_file = "${path.module}/lecture-key.pem"
                        }
                    }
                }
            }
        }
    })
}

resource "local_file" "ansible_config"{
    filename = "${path.module}/ansible.cfg"
    content = <<-EOF
        [defaults]
        inventory = ./inventory.yml
        host_key_checking = False
    EOF
}

resource "terraform_data" "wait_for_instance"{
    depends_on = [
        aws_instance.my_ec2, 
        aws_instance.swarm_workers, 
        local_file.ansible_inventory, 
        local_file.ansible_config
    ]
    triggers_replace = {
        master_id = aws_instance.my_ec2.id
        worker_ids = join(",", aws_instance.swarm_workers[*].id)
    }
    provisioner "local-exec" {
        command = "sleep 240"
    }
}

resource "terraform_data" "ansible_run"{
    depends_on = [ terraform_data.wait_for_instance ]
    triggers_replace = {
        instance_id = aws_instance.my_ec2.id
        always_run  = "${timestamp()}" 
    }
    provisioner "local-exec" {
      command = "ANSIBLE_SSH_PIPELINING=1 ansible-playbook site.yml"
      #command = "echo 'tailscale success!' "
    }
    provisioner "local-exec" {
      command = "ANSIBLE_SSH_PIPELINING=1 ansible-playbook swarm.yml"
    }
}

output "instance_private_ip"{
    description = "마스터 노드 Private IP"
    value = aws_instance.my_ec2.private_ip
}

output "alb_dns_name" {
  description = "여기로 접속하세요! (웹 서비스 접속 주소)"
  value       = aws_lb.web_alb.dns_name
}

variable "host_name" { 
    type = string
    default = "swarm-master"  
}
variable "worker_count" {
    description = "생성할 스웜 워커 노드의 개수"
    type        = number
    default     = 2
}
variable "tailnet_name"{ type = string }
variable "tailscale_auth_key"{ 
    type = string 
    sensitive = true 
}
variable "tailscale_api_key"{ 
    type = string 
    sensitive = true 
}