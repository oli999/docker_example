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

resource "tailscale_tailnet_key" "ec2_join_key" {
  reusable      = true
  ephemeral     = true  #이 키를 사용해서 EC2가 Tailscale 네트워크에 처음 '가입(Join)'하는 행위는 1시간 안에만 가능합니다.
  preauthorized = true
  expiry        = 3600
}

# ==========================================================
# 1. 대장 (Master) 노드
# ==========================================================
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
    until ping -c 1 8.8.8.8 &> /dev/null; do sleep 5; done        
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

# ==========================================================
# 2. Tailscale 라우팅 승인 (타이밍 이슈 해결)
# ==========================================================
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

# 테라폼에게 60초 강제 휴식 부여 (EC2 내부 tailscale up 대기)
resource "time_sleep" "wait_for_tailscale_sync" {
  depends_on      = [aws_instance.my_ec2]
  create_duration = "60s" 
}

data "tailscale_device" "my_ec2_device" {
  hostname   = var.host_name
  wait_for   = "180s" 
  depends_on = [time_sleep.wait_for_tailscale_sync] # 60초 쉰 다음에 기기 찾기
}

resource "tailscale_device_subnet_routes" "approve_vpc_routes" {
  device_id = data.tailscale_device.my_ec2_device.id
  routes    = [aws_vpc.main.cidr_block]
}

# ==========================================================
# 3. 워커 (Worker) 노드
# ==========================================================
resource "aws_instance" "swarm_workers" {
  count                   = var.worker_count 
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
    until ping -c 1 8.8.8.8 &> /dev/null; do sleep 5; done        
    echo "Worker Setup Complete!"
  EOF
  tags = { Name = "swarm-worker-${count.index + 1}" }
}