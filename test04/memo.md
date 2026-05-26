
### container 에서 사용할 폴더를 bind mount 해서 제공하기

```bash

# bind mount 할 폴더를 미리 만들어 둔다 ./nginx-index
# container 가 사용할 파일도 미리 만들어 둘수 있다.  ./nginx-index/index.html

# -v 옵션을 이용해서 저장공간(volume) 을 제공할수 있다.
#  -v <host 의 경로> : <container 의 경로>
docker run -d -p 80:80 -v ./nginx-index:/usr/share/nginx/html --name my-nginx  nginx:latest

```