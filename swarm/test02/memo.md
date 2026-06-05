

### cluster 환경에 배포할 이미지는 docker container 레지스트리 (docker hub 등) 에 미리 등록이 되어 있어야 한다.

```bash

# 클러스터에서 사용할 이미지를 빌드해서
#docker build -t myoli999/swarm-fastapi:1.0  .
docker build -t myoli999/swarm-fastapi:1.1  .

# docker hub 에 미리 올려 놓기
#docker push  myoli999/swarm-fastapi:1.0
docker push  myoli999/swarm-fastapi:1.1
```

### docker stack 실행하기

```bash
# 배포하기 
docker stack deploy -c docker-stack.yaml my-app

```