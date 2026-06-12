
### Restful API 

#### 요청방식
- GET -> 컨텐츠를 가져오기 위한 목적
- POST -> 컨텐츠를 전송 하기 위한 목적
- PATCH -> 컨텐츠를 일부 수정 하기 위한 목적
- PUT -> 컨텐츠를 전체 수정하기 위한 목적
- DELETE -> 컨텐츠를 삭제하기 위한 목적

#### 요청 방식과 요청경로를 같이 조합해서 정리해 보자
GET     /members    -> 회원전체 목록 가져오기
GET     /members/1  -> 1 번 회원의 정보 가져오기
POST    /members    -> 회원정보 추가하기
PATCH   /members/1  -> 1 번 회원정보 일부 수정하기
PUT     /members/1  -> 1 번 회원정보 전체 수정하기
DELETE  /members/1  -> 1 번 회원정보 삭제하기




```bash
# 이미지를 빌드하고 docker hub 에 올리기
docker build -t <도커허브아이디>/memeber-app:1.1 .
docker build -t myoli999/member-app:1.1 .

docker push <도커허브아이디>/memeber-app:1.1
docker push myoli999/member-app:1.1

```