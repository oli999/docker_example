
### fastapi container 와 postgres container 를 동시에 만들어서 동일한 network 에서 동작하게 하기

```bash

# 필요한 network 와 volume 을 만들어 준다.
docker network create my-net
docker volume create pgdata

# 위에서 생성한 network 와 volume 을 사용하는 postgres db 컨테이너를 실행한다
docker run -d \
    -p 5432:5432 \
    -e POSTGRES_USER=scott \
    -e POSTGRES_PASSWORD=tiger \
    -e POSTGRES_DB=scott_db \
    -v pgdata:/var/lib/postgresql/data \
    --network my-net \
    --name my-postgres \
    postgres:15

# 생성된 container 에 접속해서 table 생성및 sample 데이터 넣기
# docker exec -i my-postgres psql -U scott -d scott_db -c "실행할 sql 문"
docker exec -i my-postgres psql -U scott -d scott_db <<-EOF
    CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
    INSERT INTO member (name, addr) VALUES('kim', 'seoul');
    INSERT INTO member (name, addr) VALUES('lee', 'pusan');
EOF

# Dockerfile 을 이용해서 my-fastapi:1.0  이미지 만들기
docker build -t my-fastapi:1.0 .
# 빌드된 image 확인
docker image ls 

# fast api 컨테이너 실행하기 (위에 있는 db 컨테이너의 이름 참조)
docker run -d \
    -p 8000:8000 \
    -e DB_URL=postgresql://scott:tiger@my-postgres:5432/scott_db \
    --network my-net \
    --name my-fastapi \
    my-fastapi:1.0
```