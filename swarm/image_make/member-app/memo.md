
```bash
# 이미지를 빌드하고 docker hub 에 올리기
docker build -t <도커허브아이디>/memeber-app:1.0 .
docker build -t myoli999/member-app:1.0 .

docker push <도커허브아이디>/memeber-app:1.0
docker push myoli999/member-app:1.0

```