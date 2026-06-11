resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_tunnel" "vmware_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "vmware-local-tunnel"
  secret     = base64encode(random_password.tunnel_secret.result)
}

# https://cloud-study.site  로 접속했을때 
resource "cloudflare_record" "vmware_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# https://dev.cloud-study.site  로 접속했을때 
# resource "cloudflare_record" "vmware_dns2" {
#   zone_id = var.cloudflare_zone_id
#   name    = "dev"
#   content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
#   type    = "CNAME"
#   proxied = true
# }

resource "cloudflare_tunnel_config" "vmware_config" {
  account_id = cloudflare_tunnel.vmware_tunnel.account_id
  tunnel_id  = cloudflare_tunnel.vmware_tunnel.id

  config {
    # dev. 에 관련된 ingress_rule
    # ingress_rule {
    #   hostname = "dev.${var.domain_name}"
    #   # ALB의 DNS나 Master EC2의 localhost 등으로 트래픽 전달
    #   service  = "http://<dev 노드의 ip>:80" 
    # }

    ingress_rule {
      hostname = var.domain_name
      # ALB의 DNS나 Master EC2의 localhost 등으로 트래픽 전달
      service  = "http://localhost:80" 
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}