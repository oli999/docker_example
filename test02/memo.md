# memo.md 파일 

## 제목2

### Dockerfile 을 이용해서 이미지 만들고 container 실행 및 테스트

#### docker 명령어
- build
- images
- run
- exec

```bash

# Dockerfile 을 현재 경로에 만들어 놓고

# python-app2:latest 이미지 만들기 (. 은 현재 경로의 Dockerfile 을 이용해서 만들겠다는 의미)
docker build -t python-app2  .

# 만들어진 이미지 확인 
docker images

# 만들어진 이미지를 이용해서 container 실행 
# host 의 8001 port 를 container 의 8000 port 에 연결 
docker run -d -p 8001:8000 --name python-app2  python-app2:latest

# container 의 자세한 정보 조회
docker inspect  python-app2 

# container 의 ip 주소 확인후 요청해보기
curl  172.17.0.3:8000

# 실행중인 container 조회
docker container ls 

# container 안으로 들어가 보기 ( -it 는 인터렉티브 하게 container 직접 들어가서 작업할때 사용한다 )
docker exec -it python-app2  /bin/bash

# container 정지
docker container stop python-app2

# container 제거 (정지된 container 를 제거 할수 있다)
docker container rm python-app2

# 중지되지 않은 container 도 강제로 제거하기  -f
docker container rm -f python-app2

# 중지된 containe 포함 모든 container 의 목록 조회
docker container ls -a

```