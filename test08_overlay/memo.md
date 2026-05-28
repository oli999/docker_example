
### custom overlay network 만들어 보기  10.10.10.0/24 대역 


```bash
# ns1 이라는 격리된 network namespace 만들기
sudo ip netns add ns1
# ns2 이라는 격리된 network namespace 만들기
sudo ip netns add ns2
# 랜선 veth 만들기
sudo ip link add veth1 type veth peer name veth2

# veth1 은 ns1 에 연결
sudo ip link set veth1 netns ns1
# veth2 는 ns2 에 연결
sudo ip link set veth2 netns ns2

# ns1 에 들어가서 veth1 설정하기
sudo ip netns exec ns1 ip addr add 10.10.10.1/24 dev veth1 # ip 대역과 주소 설정 
sudo ip netns exec ns1 ip link set veth1 up # 활성화 

# ns2 에 들어가서 veth2 설정하기 
sudo ip netns exec ns2 ip addr add 10.10.10.2/24 dev veth2 # ip 대역과 주소 설정 
sudo ip netns exec ns2 ip link set veth2 up # 활성화 

# ns1 에 들어가서 ns2 로 ping 날려보기
sudo ip netns exec ns1 ping 10.10.10.2 -c 5

# ns2 에 들어가서 ns1 로 ping 날려보기
sudo ip netns exec ns2 ping 10.10.10.1 -c 5

# network namespace 목록
ip netns list
# veth 목록 (link)
ip link show

# 삭제 
sudo ip netns del ns1
sudo ip netns del ns2
```