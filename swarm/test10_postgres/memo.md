
### postgres main 과 replica 를 swarm 클러스터에 만들기

#### 1. nfs 서버에 공유 폴더를 생성한다
```bash

# nfs 서버에서 실행
./make-nfs.sh postgres_main
./make-nfs.sh postgres_replica

```

#### 2. postgres DB 와 member-app:1.0 를 배포 

```bash

# db-app 이라는 이름으로 docker-stack.yaml 배포하기 
docker stack deploy -c docker-stack.yaml  db-app

# 웹브라우저에서 아래의 요청 해보기
http://172.16.8.200:8080  
http://172.16.8.200:8080/members 

# mgmt 에서 요청 해보기 
curl http://172.16.8.200:8080
curl http://172.16.8.200:8080/members

# post 방식으로 json 문자열 보내서 회원정보가 추가 되는지 확인하기 
curl -X POST http://172.16.8.200:8080/members \
     -H "Content-Type: application/json" \
     -d '{"name": "park", "addr": "jeju"}'

curl http://172.16.8.200:8080/members

# 웹브라우저에서 아래의 주소를 입력해서 응답되는 swagger UI 를 이용해서 API 테스트를 할수 있다.
http://172.16.8.200:8080/docs

```

