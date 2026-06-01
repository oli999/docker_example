#!/bin/bash
# change-main.sh
# 실행권한 부여하기 
# chmod +x ./change-main.sh

# 장애가 발생했다고 가정
# pg-main 컨테이너 삭제
docker rm -f pg-main

# pg-replica2 를 새로운 대장으로 승격(promote) 시킨다
docker exec -i -u postgres pg-replica2 pg_ctl promote -D /var/lib/postgresql/data

# 잠시 대기
sleep 3

# 애플리케이션 및 다른 DB 와의 연결 유지를 위해 이름을 pg-main 으로 변경
docker rename pg-replica2 pg-main

# 남아 있는 1호기(pg-replica)  를 새로운 대장과 동기화 
docker rm -f pg-replica
docker volume rm pg-replica-volume
docker volume create pg-replica-volume

# 새로운 대장(pg-main) 으로 부터 새로운 스냅샷 추출 및 연결 
docker exec -i pg-main pg_basebackup -d "host=pg-main user=scott password=tiger" -D /tmp/replica_data -Fp -Xs -P -R

#  폴더를 선제 철거
sudo rm -rf ./replica_snapshot

# 임시 폴더 복사 및 볼륨 이식 
docker cp pg-main:/tmp/replica_data ./replica_snapshot
sudo cp -r ./replica_snapshot/* /var/lib/docker/volumes/pg-replica-volume/_data/
sudo rm -rf ./replica_snapshot

# 1호기(pg-replica) 다시 가동 (5433 포트)
docker run -d \
    -p 5433:5432 \
    -v pg-replica-volume:/var/lib/postgresql/data \
    --network db-net \
    --name pg-replica \
    postgres:15

# 스트리밍 동기화 안정화 대기
sleep 5

echo "failover 완료! 새로운 대장(pg-main) 에 쓰기 테스트 진행"

# 새 대장에 새로운 데이터 삽입
docker exec -i pg-main psql -U scott -d scott_db <<-EOF
    INSERT INTO member (name, addr) VALUES ('choi', 'jeju');
EOF

# 데이터 교차 검증
echo "--- [새 대장(구 2호기)] 장부 상태 ---"
docker exec -i pg-main psql -U scott -d scott_db -c "SELECT * FROM member;"

echo "--- [재구성된 1호기] 복제 반영 상태 ---"
docker exec -i pg-replica psql -U scott -d scott_db -c "SELECT * FROM member;"