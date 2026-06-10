
### 1. cloudflared 에 로그인

[cloudflare.com](https://www.cloudflare.com/)

### 2. 아래 문서를 참고해서 설정을 해준다.

[Google 문서](https://docs.google.com/document/d/1xvrG1ID6UX4EHSmgzQNVXwbasBE0yJkPuV84q7-tAc0/edit?usp=sharing)

### 3. terraform.tfvars 파일을 만들고 tailscale 과 cloudflared 인증 정보를 넣어준다.

```
# terraform.tfvars 파일에 작성할 변수의 목록

# Tailscale을 설치할 마스터 노드의 호스트 이름
host_name = "swarm-master"

# Tailscale 관리자 계정 이메일 또는 Tailnet 이름
tailnet_name = "input your tailscale account email (or tailnet name)"

# Tailscale API 토큰 (Settings -> Keys에서 발급)
tailscale_api_key = "input your tailscale_api_key (tskey-api-...)"

# Tailscale 기기 자동 인증용 일회성 키 (Settings -> Keys에서 발급)
tailscale_auth_key = "input your tailscale_auth_key (tskey-auth-...)"

# Cloudflare API 토큰 (Edit zone DNS, Zone Settings, Cloudflare Tunnel 권한 필요)
cloudflare_api_token = "input your cloudflare_api_token (cfut_...)"

# Cloudflare 대시보드 도메인 개요(Overview) 화면 우측 하단에서 확인 가능
cloudflare_zone_id = "input your cloudflare_zone_id"

# Cloudflare 대시보드 도메인 개요(Overview) 화면 우측 하단에서 확인 가능
cloudflare_account_id = "input your cloudflare_account_id"

# Cloudflare에 등록된, 연결할 최종 외부 도메인 주소 (예: example.com)
domain_name = "input your domain_name"
```

### 4. terraform 을 실행해서 인프라를 프로비저닝 한다.

```bash
terrform init
terraform plan
terraform apply
```