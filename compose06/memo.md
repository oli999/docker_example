
### docker compose 기반 DB 복구

```bash

# 초기 DB 구동
docker compose up -d

# 백업파일 얻어 내기
docker compose exec -T my-postgres pg_dump -U scott scott_db > ./backup.sql

# 볼륨 포함해서 db 삭제
docker compose down -v

# db 를 ./backup.sql 기반으로 다시 실행하는 yaml 문서 실행하기
docker compose -f db-recover.yaml up -d

# 저장된 데이터 select 해보기 
docker compose exec -T my-postgres psql -U scott -d scott_db <<-EOF
    SELECT * FROM member;
EOF

# db-recover.yaml 문서를 이용해서 만든 서비스를 down 시키기 
docker compose -f db-recover.yaml down -v

```