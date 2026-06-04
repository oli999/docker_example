
## 1단계: NFS 서버 설정 (ubuntu01 / 172.16.8.203)

```bash

# 1. 패키지 업데이트 및 NFS 서버 도구 설치
sudo apt update
sudo apt install nfs-kernel-server -y
sudo systemctl enable --now nfs-kernel-server

# 2. 공유할 폴더 생성 및 권한 개방 (실습용 777)
sudo mkdir -p /nfs/shared/pg_init
sudo chmod 777 /nfs/shared/pg_init

# 3. 공유 설정 등록 (172.16.8.101 => 클라이언트 IP)
# rw: 읽기쓰기
# sync: 즉시 동기화 (데이터 꼬임 방지)
# no_root_squash: 클라이언트의 root를 서버에서도 root로 인정 (도커 권한 에러 방지)
# no_subtree_check: 하위 폴더 검사 생략 (성능 향상 및 파일명 변경 오류 방지)
# /nfs/shared/pg_init *(rw,sync,no_root_squash,no_subtree_check)  -> 모든 ip 허용
# 아래는 172.16.8.0/24 네트워크만 접근이 가능하도록 한다 
echo "/nfs/shared/pg_init 172.16.8.0/24(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports

# 4. 설정 적용 (캐시 초기화 및 완벽 반영)
# -ra 는 re-export all (/etc/exports 의 정보를 찌꺼기 없이 모두 다시 반영)
sudo exportfs -ra 

# 5. 방화벽 내리고 (이미 내려가 있음)
# sudo ufw allow nfs

# 6. 상태확인 
sudo exportfs -v

```

### 2단계: NFS 클라이언트 설정 (mgmt, rocky01)

```bash

# 1. NFS 도구 설치
sudo dnf install nfs-utils -y

# 2. 국룰 위치(/mnt/)에 직관적인 이름으로 빈 폴더 생성
sudo mkdir -p /mnt/nfs/pg_init

# 3. 부팅 시에도 자동 마운트되도록 안전 옵션과 함께 등록
echo "172.16.8.203:/nfs/shared/pg_init  /mnt/nfs/pg_init  nfs  \
defaults,_netdev,x-systemd.automount 0 0" | sudo tee -a /etc/fstab

# 4. 리눅스 시스템 매니저에게 fstab의 최신 변경사항을 완전히 반영 (메모리 갱신)
sudo systemctl daemon-reload

# 5. fstab에 적힌 대로 알아서 마운트 하라고 지시 (명령어 길게 칠 필요 없음!)
sudo mount -a

```

<img src="./assets/image01.png">

```bash

# nfs 에 연결된 폴더에 init.sql 파일을 복사해 넣는다.
cp ./init.sql /mnt/nfs/pg_init
# copy 된 파일 확인
sudo ls -al /mnt/nfs/pg_init

# ubuntu01 에서도 확인하기
sudo ls -al /nfs/shared/pg_init

# 저장된 데이터 select 해보기 
docker compose exec -T my-postgres psql -U scott -d scott_db <<-EOF
    SELECT * FROM member;
EOF

```