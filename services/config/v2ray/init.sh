cd $(dirname $0)
# only support debian/ubuntu
ipv6_enable="true"
if [[ "$(whoami)" != "root" ]];then
   echo "should run as root"
   exit 1
fi


ip -o -f inet addr show|grep enp1s0
# 网卡
host_network_card=$(ip -o -f inet route|grep default|awk '{print $5}')
# 网关 192.168.1.1
host_gateway= $(ip -o -f inet route|grep default|awk '{print $3}')
# 子网 192.168.1.0/24
host_subnet=$(ip -o -f inet addr show|grep ${host_network_card}|awk '{print $4}')
#子网掩码 225.225.255.0 
host_netmask=$(ifconfig|grep ${host_network_card} -A 5|grep inet\\s|awk '{print $4}')


echo "当前服务器网卡为${host_network_card},网关为:${host_gateway},子网伪:${host_gateway},子网掩码伪${host_netmask}"
if [[ $ipv6_enable == "true" ]];then
  host_ipv6_subnet=$(ip -o -f inet6 addr show|grep ${host_network_card}|awk '{print $4}')
  host_ipv6_gateway=$(ip -o -f inet6 route|grep default|awk '{print $3}')
  echo "ipv6子网掩码伪${host_ipv6_subnet},网关为${host_ipv6_gateway}"
fi



# clean if run agina
ehco "init and clean settings"
#打开混杂模式（必要）
ip link set ${host_network_card} promisc on||true
modprobe ip6table_filter||true
# 删除配置项
ip link delete v2raynet link ${host_network_card} type macvlan mode bridge||true
docker stop v2ray||true
docker rm v2ray||true
docker network rm v2raynet||true
if [[ -f /etc/network/interface_backup ]];then
    cp /etc/network/interface_backup /etc/network/interface
fi

ehco "clean settings finish"


echo "create v2raynet network"
if [[ $ipv6_enable=="true" ]];then
   docker network create -d macvlan --subnet=${host_subnect} --gateway=${host_gateway} --subnet=${host_ipv6_subnet} --gateway=${host_ipv6_gateway} --ipv6 -o parent=${host_network_card} v2raynet
else
   docker network create -d macvlan --subnet=${host_subnect} --gateway=${host_gateway} -o parent=${host_network_card} v2raynet
fi

echo "v2raynet info:"
docker network inspect v2raynet


# set host
ip link add v2raynet link ${host_network_card} type macvlan mode bridge
ip address add ${host_subnet} dev v2raynet
#ip route add default via 192.168.124.1 dev v2raynet
ip link set v2raynet up
ifconfig v2raynet netmask ${netmask}


docker run mzz2017/v2raya --privileged=true -v ./v2raya:/etc/v2raya/ --network=v2raynet -e V2RAY_ADDRESS=0.0.0.0:2017 --restart=unless-stopped --name=v2ray
export v2rayIp=$(docker exec -ti v2ray  ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)


cp  /etc/network/interfaces /etc/network/interface_backup
echo "
auto v2raynet
iface v2raynet inet static
  address ${host_gateway/1$/0}   # 宿主机静态IP地址
  netmask ${host_netmask}  # 子网掩码
  dns-nameservers 202.141.176.93  # DNS主服务器
  dns-nameservers 2620:0:ccc::2:443  # DNS备用服务器
  pre-up ip link add v2raynet link ${host_network_card} type macvlan mode bridge
  post-down ip link del v2raynet link ${host_network_card} type macvlan mode bridge
" >> /etc/network/interfaces


echo "假如无缝翻墙。修改客户端为静态ip,其他不变，连接网关为:${v2rayIp}"
echo "控制端地址为:http://${v2rayIp}:2017，请配置v2ray后redirect"
