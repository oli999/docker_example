
### writable db 와  replica db (read ony) 만들어서 테스트 하기 

```bash

# 네트워크 생성
docker network create db-net
# volume 2개 생성
docker volume create pg-main-volume
docker volume create pg-replica-volume

# pg-main db 컨테이너 생성
# replica 가 동작하기 위해서는 외부 port 를 변경해야 한다 5431
# wal_level=replica : 일기장(log) 를 상세하게 쓰기
# max_wal_senders=10 : 복제 DB 를 최대 몇개를 생성할것인지 
# archive_mode=on : 로그가 유실되지 않도록 많이 쌓이면 압축해서 보관하도록 
docker run -d \
    -p 5431:5432 \
    -e POSTGRES_USER=scott \
    -e POSTGRES_PASSWORD=tiger \
    -e POSTGRES_DB=scott_db \
    -v pg-main-volume:/var/lib/postgresql/data \
    --network db-net \
    --name pg-main \
    postgres:15 \
    postgres -c wal_level=replica -c max_wal_senders=10 -c archive_mode=on 

# 외부 접속 관련 설정 바꾸기 
docker exec -i pg-main bash -c "echo 'host replication scott 0.0.0.0/0 md5' >> /var/lib/postgresql/data/pg_hba.conf"

# 위의 설정이 적용되는데 약간의 시간이 필요함으로 잠시 기다린다 
sleep 10

# 바뀐 방화벽 설정 즉시 적용 (엔진 재시작 없이 설정만 리로드!)
docker exec -i pg-main psql -U scott -d scott_db -c "SELECT pg_reload_conf();"

# 복제한 replica db 가 사용할 데이터를 pg-main 으로 부터 가져와서 임시 폴더에 저장 
docker exec -i pg-main pg_basebackup -d "host=pg-main user=scott password=tiger" -D /tmp/replica_data -Fp -Xs -P -R

# 임시 폴더에 있는 내용을  host 의 ./replica_snapshot 폴더에 copy 한다.
docker cp pg-main:/tmp/replica_data ./replica_snapshot

# replica db 가 사용할 볼륨에 미리 넣어둔다
sudo cp -r ./replica_snapshot/*  /var/lib/docker/volumes/pg-replica-volume/_data/

# replica db container 실행하기 5433 port 
docker run -d \
    -p 5433:5432 \
    -v pg-replica-volume:/var/lib/postgresql/data \
    --network db-net \
    --name pg-replica \
    postgres:15

# sample 데이터를 pg-main 에 넣어주기
docker exec -i pg-main psql -U scott -d scott_db <<-EOF
    CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
    INSERT INTO member (name, addr) VALUES('kim', 'seoul');
    INSERT INTO member (name, addr) VALUES('lee', 'pusan');
EOF

# pg-replica 에 해당 데이터가 존재하는지 확인하기
docker exec -i pg-replica psql -U scott -d scott_db -c "SELECT * FROM member;"

# pg-main 에 row 하나 더 추가하고 
docker exec -i pg-main psql -U scott -d scott_db <<-EOF
    INSERT INTO member (name, addr) VALUES('ohh', 'inchon');
EOF

# 다시 pg-replica 에서 select 해보기 
docker exec -i pg-replica psql -U scott -d scott_db -c "SELECT * FROM member;"

# clear
docker container rm -f $(docker ps -aq)
docker network rm db-net
docker volume rm pg-main-volume pg-replica-volume
rm -rf ./replica_snapshot

```