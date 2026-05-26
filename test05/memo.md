

### container 안에 있는 특정 파일을 bind mount 한곳에 copy 해서 사용할때도 있다.

```bash

# 임시 컨테이너를 실행해서 
docker run -d --name tmp-nginx nginx:latest

# 특정 폴더 안에 있는 내용을 복사해 온다.
docker cp tmp-nginx:/usr/share/nginx/html ./nginx-html

# 임시 컨테이너를 삭제
docker container rm -f tmp-nginx

# 복사해온 파일을 사용하는 container 를 다시 실행한다.
docker run -d -p 80:80 -v ./nginx-html:/usr/share/nginx/html --name my-nginx  nginx:latest

# ./nginx-html 안의 내용을 확인하고

# index.html 을 수정하면서 container 의 동작을 확인하기 

```