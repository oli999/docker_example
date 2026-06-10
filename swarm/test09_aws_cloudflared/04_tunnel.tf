resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_tunnel" "vmware_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "vmware-local-tunnel"
  secret     = base64encode(random_password.tunnel_secret.result)
}

resource "cloudflare_record" "vmware_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "vmware_config" {
  account_id = cloudflare_tunnel.vmware_tunnel.account_id
  tunnel_id  = cloudflare_tunnel.vmware_tunnel.id

  config {
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