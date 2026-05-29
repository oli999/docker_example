
### postgres db 백업 및 복구 예제 

```bash

# clear
docker container rm -f my-postgres 2>/dev/null
docker volume rm  pgdata 2>/dev/null

# 외부 볼륨 생성
docker volume create pgdata

# container 실행
docker run -d \
    -p 5432:5432 \
    -e POSTGRES_USER=scott \
    -e POSTGRES_PASSWORD=tiger \
    -e POSTGRES_DB=scott_db \
    -v pgdata:/var/lib/postgresql/data \
    --name my-postgres \
    postgres:15

# sample data 적재
docker exec -i my-postgres psql -U scott -d scott_db <<-EOF
    CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
    INSERT INTO member (name, addr) VALUES('kim', 'seoul');
    INSERT INTO member (name, addr) VALUES('lee', 'pusan');
EOF

# 백업
docker exec -i my-postgres pg_dump -U scott scott_db > ./backup.sql

# container 와 volume 삭제 
docker container rm -f my-postgres
docker volume rm pgdata

# 복구
docker volume create pgdata
# 컨테이너를 다시 실행
docker run -d \
    -p 5432:5432 \
    -e POSTGRES_USER=scott \
    -e POSTGRES_PASSWORD=tiger \
    -e POSTGRES_DB=scott_db \
    -v pgdata:/var/lib/postgresql/data \
    --name my-postgres \
    postgres:15 

# 백업 장부를 밀어 넣기
docker exec -i my-postgres psql -U scott -d scott_db < ./backup.sql

# 확인
docker exec -i my-postgres psql -U scott -d scott_db -c "SELECT * FROM member;"
```
