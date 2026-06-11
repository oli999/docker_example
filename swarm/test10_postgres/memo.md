
### postgres main 과 replica 를 swarm 클러스터에 만들기

#### 1. nfs 서버에 공유 폴더를 생성한다
```bash

# nfs 서버에서 실행
./make-nfs.sh postgres_main
./make-nfs.sh postgres_replica

```

#### 2. postgres DB 를 배포 

```bash
# db-app 이라는 이름으로 docker-stack.yaml 배포하기 
docker stack deploy -c docker-stack.yaml  db-app

```