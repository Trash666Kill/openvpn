#!/bin/bash
apt install openvpn easy-rsa -y
mkdir -v /etc/openvpn/server/easy-rsa
mkdir -pv /etc/openvpn/server/clients/emperor
mkdir -p /etc/openvpn/server/ccd
ln -s /usr/share/easy-rsa/* /etc/openvpn/server/easy-rsa
cd /etc/openvpn/server/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa --batch sign-req server server
./easyrsa --batch gen-dh
cd pki/
openvpn --genkey tls-crypt-v2-server private/server.pem
cp -v ca.crt dh.pem ../../
cp -v private/server.key ../../
cp -v private/server.pem ../../
cp -v issued/server.crt ../../
cd ../
{(
echo "port 2944
proto udp
dev tun
allow-compression no
ca ca.crt
cert server.crt
key server.key
tls-crypt-v2 server.pem
dh dh.pem
topology subnet
server 10.8.15.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 9.9.9.9"
push "dhcp-option DNS 149.112.112.112"
#push "block-outside-dns"
keepalive 10 120
cipher AES-256-GCM
client-config-dir ccd
user nobody
group nogroup
persist-key
persist-tun
verb 4
explicit-exit-notify 1
" > ../server.conf
)}
#
sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.ip_forward
#
./easyrsa --batch gen-req emperor nopass
./easyrsa --batch sign-req client emperor
cd pki
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/emperor.pem
cp -v ca.crt ../../clients/emperor
cp -v issued/emperor.crt ../../clients/emperor
cp -v private/emperor.key ../../clients/emperor
cp -v private/emperor.pem ../../clients/emperor
#
