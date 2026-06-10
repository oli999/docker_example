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
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}
variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}
variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}
variable "domain_name" {
  description = "연결할 외부 도메인"
  type        = string
}