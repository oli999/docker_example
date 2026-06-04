
### docker swarm 클러스터 구성하기 

```bash

# master node 에서 실행
docker swarm init --advertise-addr 172.16.8.200

    #  worker node 로 설정하고 싶은 노드 (rocky01, rocky02) 에서 실행
    docker swarm join --token SWMTKN-1-06etmgta1pp8epksqk25bnp9jt995alaw72iglqx26ph7knvhz-ev43z1y67t92edt86gnyjxltm 172.16.8.200:2377

# 클러스터의 상태 조회
docker node ls

# 클러스터에 테스트로 nginx 컨테이너 3 개 배포하기 
docker service create --name my-web --replicas 3 -p 8080:80 nginx

# 서비스 확인 
docker service ls

# 어디에 떠 있는지 확인
docker service ps my-web

# 서비스 제거
docker service rm my-web

```
