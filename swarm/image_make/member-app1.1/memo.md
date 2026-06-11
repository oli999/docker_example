
1. 이미지 내부를 열기 위해 임시 컨테이너 생성 (실행은 안 시킵니다)
docker create --name temp_container myoli999/member-app:1.1

# 2. 컨테이너 내부의 /src/main.py 파일을 현재 리눅스 경로(.)로 복사해오기
docker cp temp_container:/app/main.py ./main.py

# 3. 볼일 다 본 임시 껍데기 컨테이너 삭제
docker rm temp_container