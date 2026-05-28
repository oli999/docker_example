
### custom overlay network 만들어 보기  10.10.10.0/24 대역 

#### bridge switch 도 추가하기 

```bash
# ns1 이라는 격리된 network namespace 만들기
sudo ip netns add ns1
# ns2 이라는 격리된 network namespace 만들기
sudo ip netns add ns2

# br0 라는 이름의 가상 스위치 생성 
sudo ip link add name br0 type bridge
# br0 스위치 up (활성화)
sudo ip link set br0 up

# 1번 랜선 셋트 
sudo ip link add veth1_a type veth peer name veth1_b

# veth1_a 는 br0 에 연결
sudo ip link set veth1_a master br0  # br0 에 종속(master) 이 되도록 하겠다
# veth1_a 켜기  
sudo ip link set veth1_a up

# veth1_b 는 ns1 에 연결
sudo ip link set veth1_b netns ns1

# 2번 랜선 셋트 
sudo ip link add veth2_a type veth peer name veth2_b

# veth2_a 는 br0 에 연결
sudo ip link set veth2_a master br0  # br0 에 종속(master) 이 되도록 하겠다
# veth2_a 켜기  
sudo ip link set veth2_a up

# veth2_b 는 ns2 에 연결
sudo ip link set veth2_b netns ns2

# ns1 방에 veth1_b 설정 및 활성화
sudo ip netns exec ns1 ip addr add 10.10.10.1/24 dev veth1_b
sudo ip netns exec ns1 ip link set veth1_b up

# ns2 방에 veth2_b 설정 및 활성화
sudo ip netns exec ns2 ip addr add 10.10.10.2/24 dev veth2_b
sudo ip netns exec ns2 ip link set veth2_b up

# ns1 -> ns2 로 ping 날리기
sudo ip netns exec ns1 ping 10.10.10.2 -c 5
# ns2 -> ns1 로 ping 날리기 
sudo ip netns exec ns2 ping 10.10.10.1 -c 5

# ns1 내부 (격리된 network) 환경으로 진입해서 명령어 날리기
sudo nsenter --net=/var/run/netns/ns1 bash
ping 10.10.10.2 -c 5
# 정말 격리된 network 인지 확인!
ip a # veth1_b 만 보인다 
# 탈출
exit


```