#!/bin/bash

usage() {
  echo -e "$0 OPTIONS"
  echo -e "-d|--delete\t\t Delete all the network namespaces"
  echo -e "-c|--create TYPE\t Create a specified topology"
  echo -E "TYPE could be one of \"direct\" \"switch\" \"route\""
  exit 0
}

err_exit() {
  echo "Error: $1"
  exit 1
}

delete_all_ns() {
  for ns in $(ip netns list | awk '{print $1}'); do
    ip netns del $ns || err_exit "delete ns:$ns failed"
  done

  for dev in $(ip link list type veth | sed -n 's/^.*\(veth[1-9]-[1-9]\).*$/\1/p'); do
    ip link show $dev > /dev/null 2>&1
    if [[ $? == 0 ]]; then 
      ip link del $dev || err_exit "delete dev:$dev failed"
    fi
  done

  for dev in $(ip link list type bridge | sed -n 's/^.*\(sw[1-9]\+\).*$/\1/p'); do
    ip link show $dev > /dev/null 2>&1
    if [[ $? == 0 ]]; then
      ip link set $dev down 
      brctl delbr $dev || err_exit "delete dev:$dev failed"
    fi
  done

}

create_topology() {
  case $1 in
    direct)
      ip netns add pc1 || err_exit "create pc1 ns failed"
      ip link add veth1-1 type veth peer name veth1-2 || err_exit "add veth1 pair failed"
      ip link set veth1-1 netns pc1 || err_exit "ip link set veth1-1 failed"
      ip -n pc1 addr add 192.168.1.101/24 dev veth1-1 || err_exit "set ip for pc1 veth1-1 failed"
      ip addr add 192.168.1.102/24 dev veth1-2 || err_exit "set ip for host veth1-2 failed"
      ip -n pc1 link set veth1-1 up || err_exit "veth1-1 link up failed"
      ip link set veth1-2 up || err_exit "veth1-2 link up failed"
      ;;
    switch)
      ip netns add pc1 || err_exit "create pc1 ns failed"
      ip netns add pc2 || err_exit "create pc2 ns failed"
      ip link add veth1-1 type veth peer name veth1-2 || err_exit "add veth1 pair failed"
      ip link add veth2-1 type veth peer name veth2-2 || err_exit "add veth2 pair failed"
      brctl addbr sw1 || err_exit "create sw1 failed"
      ip link set veth1-1 netns pc1 || err_exit "ip link set veth1-1 failed"
      ip link set veth2-1 netns pc2 || err_exit "ip link set veth2-1 failed"
      brctl addif sw1 veth1-2 || err_exit "sw1 addif veth1-2 failed"
      brctl addif sw1 veth2-2 || err_exit "sw1 addif veth2-2 failed"
      ip -n pc1 addr add 192.168.1.101/24 dev veth1-1 || err_exit "set ip for pc1 veth1-1 failed"
      ip -n pc2 addr add 192.168.1.102/24 dev veth2-1 || err_exit "set ip for pc2 veth1-1 failed"
      ip -n pc1 link set veth1-1 up || err_exit "veth1-1 link up failed"
      ip -n pc2 link set veth2-1 up || err_exit "veth2-1 link up failed"
      ip link set veth1-2 up || err_exit "veth1-2 link up failed"
      ip link set veth2-2 up || err_exit "veth2-2 link up failed"
      ip link set sw1 up || err_exit "sw1 link up failed"
      ;;
    router)
      ip netns add pc1 || err_exit "create pc1 ns failed"
      ip netns add pc2 || err_exit "create pc2 ns failed"
      ip link add veth1-1 type veth peer name veth1-2 || err_exit "add veth1 pair failed"
      ip link add veth2-1 type veth peer name veth2-2 || err_exit "add veth2 pair failed"
      brctl addbr sw1 || err_exit "create sw1 failed"
      ip link set veth1-1 netns pc1 || err_exit "ip link set veth1-1 failed"
      ip link set veth2-1 netns pc2 || err_exit "ip link set veth2-1 failed"
      brctl addif sw1 veth1-2 || err_exit "sw1 addif veth1-2 failed"
      brctl addif sw1 veth2-2 || err_exit "sw1 addif veth2-2 failed"
      ip -n pc1 addr add 192.168.1.101/24 dev veth1-1 || err_exit "set ip for pc1 veth1-1 failed"
      ip -n pc2 addr add 192.168.1.102/24 dev veth2-1 || err_exit "set ip for pc2 veth1-1 failed"
      ip -n pc1 link set veth1-1 up || err_exit "veth1-1 link up failed"
      ip -n pc2 link set veth2-1 up || err_exit "veth2-1 link up failed"
      ip link set veth1-2 up || err_exit "veth1-2 link up failed"
      ip link set veth2-2 up || err_exit "veth2-2 link up failed"
      ip link set sw1 up || err_exit "sw1 link up failed"

      ip netns add pc3 || err_exit "create pc3 ns failed"
      ip netns add pc4 || err_exit "create pc4 ns failed"
      ip link add veth3-1 type veth peer name veth3-2 || err_exit "add veth3 pair failed"
      ip link add veth4-1 type veth peer name veth4-2 || err_exit "add veth4 pair failed"
      brctl addbr sw2 || err_exit "create sw2 failed"
      ip link set veth3-1 netns pc3 || err_exit "ip link set veth3-1 failed"
      ip link set veth4-1 netns pc4 || err_exit "ip link set veth4-1 failed"
      brctl addif sw2 veth3-2 || err_exit "sw1 addif veth3-2 failed"
      brctl addif sw2 veth4-2 || err_exit "sw1 addif veth4-2 failed"
      ip -n pc3 addr add 192.168.10.101/24 dev veth3-1 || err_exit "set ip for pc3 veth1-1 failed"
      ip -n pc4 addr add 192.168.10.102/24 dev veth4-1 || err_exit "set ip for pc4 veth1-1 failed"
      ip -n pc3 link set veth3-1 up || err_exit "veth3-1 link up failed"
      ip -n pc4 link set veth4-1 up || err_exit "veth4-1 link up failed"
      ip link set veth3-2 up || err_exit "veth3-2 link up failed"
      ip link set veth4-2 up || err_exit "veth4-2 link up failed"
      ip link set sw2 up || err_exit "sw2 link up failed"

      ip link add veth5-1 type veth peer name veth5-2 || err_exit "add veth5 pair failed"
      ip link add veth6-1 type veth peer name veth6-2 || err_exit "add veth6 pair failed"
      brctl addif sw1 veth5-2 || err_exit "sw1 addif veth5-2 failed"
      brctl addif sw2 veth6-2 || err_exit "sw2 addif veth6-2 failed"
      ip add add 192.168.1.1/24 dev veth5-1 || err_exit "set ip for router veth5-1 failed"
      ip add add 192.168.10.1/24 dev veth6-1 || err_exit "set ip for router veth6-1 failed"
      ip link set veth5-1 up || err_exit "veth5-1 link up failed"
      ip link set veth6-1 up || err_exit "veth6-1 link up failed"
      ip link set veth5-2 up || err_exit "veth5-2 link up failed"
      ip link set veth6-2 up || err_exit "veth6-2 link up failed"

      ip -n pc1 route add default via 192.168.1.1 dev veth1-1 || err_exit "add default route for pc1 failed"
      ip -n pc2 route add default via 192.168.1.1 dev veth2-1 || err_exit "add default route for pc2 failed"
      ip -n pc3 route add default via 192.168.10.1 dev veth3-1 || err_exit "add default route for pc3 failed"
      ip -n pc4 route add default via 192.168.10.1 dev veth4-1 || err_exit "add default route for pc4 failed"

      cat > /etc/sysctl.d/30-ipforward.conf <<EOL
net.ipv4.ip_forward=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
EOL

      sysctl -p /etc/sysctl.d/30-ipforward.conf > /dev/null 2>&1 || err_exit "sysctl forward params failed"
      ;;	    
    *)
      usage
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  param="$1"

  case $param in
    -d|--delete)
      delete_all_ns
      break;;
    -c|--create)
      TOPOLOGY="$2"
      create_topology $TOPOLOGY
      break;;
    *)
      usage
      break;;
  esac
done

