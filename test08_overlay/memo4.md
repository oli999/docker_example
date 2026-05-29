
### custom overlay network 만들어 보기  10.10.10.0/24 대역 


### 172.16.8.200 mgmt node 에서 실행할 코드 
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

# br0 스위치 본체에 gateway ip 부여하기
sudo ip addr add 10.10.10.254/24 dev br0

# ns1, ns2 방에 밖으로 나갈때는 br0 라는 gateway 로 나가라는 이정표 세우기
sudo ip netns exec ns1 ip route add default via 10.10.10.254
sudo ip netns exec ns2 ip route add default via 10.10.10.254

# VXLAN 설정
# id 100 은 상대편 node 에서도 동일하게 부여해야 한다. (마음대로 정하는값 -> 일치하기만 하면된다)
# dstport 4789  는 vxlan 기본 udp port 번호 
sudo ip link add vxlan0 type vxlan id 100 remote 172.16.8.201 local 172.16.8.200 dev ens160 dstport 4789
# 생성한 vxlan0 를 br0 스위치에 종속(연결)
sudo ip link set vxlan0 master br0
# vxlan0 를 켜기 
sudo ip link set vxlan0 up


# 외부로 나갈때 host 의 공인 ip (172.16.8.200) 나가도록 하기(NAT)
# -j MASQUERADE (host 의 가면을 쓰고 밖으로 jump 하도록)
sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o ens160 -j MASQUERADE

# rocky01 의 ns1 으로 ping
sudo ip netns exec ns1 ping 10.10.10.3 -c 5
# rocky01 의 ns2 로 ping 
sudo ip netns exec ns2 ping 10.10.10.4 -c 5

# clear
sudo ip netns del ns1
sudo ip netns del ns2
sudo ip link del br0
sudo ip link del vxlan0
# iptables 설정도 되돌리기 
# 추가했던 문장에서 -A 만 -D 로 바꿔서 실행 (A 는 append D 는 delete)
sudo iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o ens160 -j MASQUERADE

```

### 172.16.8.201 rocky01 node 에서 실행할 코드 
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
sudo ip netns exec ns1 ip addr add 10.10.10.3/24 dev veth1_b
sudo ip netns exec ns1 ip link set veth1_b up

# ns2 방에 veth2_b 설정 및 활성화
sudo ip netns exec ns2 ip addr add 10.10.10.4/24 dev veth2_b
sudo ip netns exec ns2 ip link set veth2_b up

# br0 스위치 본체에 gateway ip 부여하기
sudo ip addr add 10.10.10.254/24 dev br0

# ns1, ns2 방에 밖으로 나갈때는 br0 라는 gateway 로 나가라는 이정표 세우기
sudo ip netns exec ns1 ip route add default via 10.10.10.254
sudo ip netns exec ns2 ip route add default via 10.10.10.254

# VXLAN 설정
# id 100 은 상대편 node 에서도 동일하게 부여해야 한다. (마음대로 정하는값 -> 일치하기만 하면된다)
# dstport 4789  는 vxlan 기본 udp port 번호 
sudo ip link add vxlan0 type vxlan id 100 remote 172.16.8.200 local 172.16.8.201 dev ens160 dstport 4789
# 생성한 vxlan0 를 br0 스위치에 종속(연결)
sudo ip link set vxlan0 master br0
# vxlan0 를 켜기 
sudo ip link set vxlan0 up


# 외부로 나갈때 host 의 공인 ip (172.16.8.201) 나가도록 하기(NAT)
# -j MASQUERADE (host 의 가면을 쓰고 밖으로 jump 하도록)
sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o ens160 -j MASQUERADE

# mgmt 의 ns1 으로 ping
sudo ip netns exec ns1 ping 10.10.10.1 -c 5
# mgmt 의 ns2 로 ping 
sudo ip netns exec ns2 ping 10.10.10.2 -c 5


# clear
sudo ip netns del ns1
sudo ip netns del ns2
sudo ip link del br0
sudo ip link del vxlan0
# iptables 설정도 되돌리기 
# 추가했던 문장에서 -A 만 -D 로 바꿔서 실행 (A 는 append D 는 delete)
sudo iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o ens160 -j MASQUERADE

```