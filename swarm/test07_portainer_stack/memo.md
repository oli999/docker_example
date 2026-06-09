
### swarm cluster 용 potainer stack 다운로드 및 설치

```bash
# 1. 공식 Portainer Swarm 스택 파일 다운로드
curl -L https://downloads.portainer.io/ce2-21/portainer-agent-stack.yml -o portainer-agent-stack.yml

# 2. 다운받은 파일로 스택 배포
docker stack deploy -c portainer-agent-stack.yml portainer

# https://172.16.8.200:9443 으로 접속해서 로그인 한다. (위의 명령어를 실행하고 5분 이내에 접속)

```