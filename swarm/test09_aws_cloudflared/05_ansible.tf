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
  }
  provisioner "local-exec" {
    command = "ANSIBLE_SSH_PIPELINING=1 ansible-playbook swarm.yml"
  }
}

# Cloudflared 설치 (Swarm 설치 등이 끝난 후 실행되도록 엮음)
resource "null_resource" "run_ansible_remote" {
  depends_on = [
    cloudflare_tunnel_config.vmware_config,
    cloudflare_record.vmware_dns,
    terraform_data.ansible_run
  ]
  triggers = {
    tunnel_token = cloudflare_tunnel.vmware_tunnel.tunnel_token
  }
  provisioner "local-exec" {
    command = "sleep 15 && ansible-playbook setup.yml --extra-vars 'tunnel_token=${nonsensitive(cloudflare_tunnel.vmware_tunnel.tunnel_token)}'"
  }
}