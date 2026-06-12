# 프론트엔드 웹 서버용 BASE 이미지 지정
FROM nginx:latest

# 컨테이너 내에서 작업할 기본 디렉토리 지정 
WORKDIR /usr/share/nginx/html

# 기본으로 들어있는 Nginx 안내 페이지(index.html) 삭제 (충돌 방지)
RUN rm -rf ./*

# 로컬의 src 폴더 안에 있는 모든 파일(index.html, js, css 등)을 현재 경로(/usr/share/nginx/html)로 복사
COPY src/ .

# 80 port 를 사용한다고 명시하기 (Nginx 기본 포트)
EXPOSE 80

