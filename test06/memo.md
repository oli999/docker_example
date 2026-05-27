
### docker volume 을 미리 만들어 두고 사용하기 

```bash

# docker 가 관리하는 독립형 볼륨을 미리 만든다
docker volume create nginx-vol

# 만들어진 volume 확인
docker volume ls

# 미리 만든 volume 을 사용하도록 container 를 실행하기
#  -v <volume 이름>:<container 경로>

# case1 -> nginx-vol 폴더가 비어 있고 : /usr/share/nginx/html 폴더에 파일이 있다면 
# /usr/share/nginx/html 폴더에 있는 모든 파일이 nginx-vol 폴더로 복사가 된다.

# case2 -> nginx-vol 에 파일이 있으면  nginx-vol 의 모든 파일이 /usr/share/nginx/html 폴더로 덮어 쓰기가 된다.

docker run -d -p 80:80 -v nginx-vol:/usr/share/nginx/html --name my-nginx nginx:latest

# 만들어진 volume (관리형 volume ) 의 위치
# /var/lib/docker/volumes/<volume 이름>/_data

sudo ls /var/lib/docker/volumes/nginx-vol/_data

# 만들어진 volume 은 따로 지우지 않는 이상 container 를 삭제해도 유지가 된다.

# volume 삭제하는 방법
# docker volume rm <volume 이름>

```