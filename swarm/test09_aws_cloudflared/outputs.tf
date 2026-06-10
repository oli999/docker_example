output "instance_private_ip"{
    description = "마스터 노드 Private IP"
    value = aws_instance.my_ec2.private_ip
}
