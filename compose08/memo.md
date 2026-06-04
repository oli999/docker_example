

```bash
# service 를 띄우고
docker compose up -d

# pg-main 에 sample 데이터 넣어두고 
docker compose exec -T pg-main psql -U scott -d scott_db <<-EOF
    CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
    INSERT INTO member (name, addr) VALUES('kim', 'seoul');
    INSERT INTO member (name, addr) VALUES('lee', 'pusan');
EOF

# 복제 pg-replica 가 동작하는지 확인해 보기 
docker compose exec -T pg-replica psql -U scott -d scott_db <<-EOF
    SELECT * FROM member;
EOF

docker compose exec -T pg-main psql -U scott -d scott_db <<-EOF
    INSERT INTO member (name, addr) VALUES('OH','Kang Nam');
EOF

docker compose exec -T pg-replica psql -U scott -d scott_db <<-EOF
    SELECT * FROM member;
EOF
```