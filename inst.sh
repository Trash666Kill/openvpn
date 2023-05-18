#!/bin/bash
apt install openvpn easy-rsa -y
mkdir /etc/openvpn/server/easy-rsa
ln -s /usr/share/easy-rsa/* /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/server/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa --batch sign-req server server
./easyrsa --batch gen-dh
cd pki/
openvpn --genkey tls-crypt-v2-server private/server.pem
cp ca.crt dh.pem ../../
cp private/server.key ../../
cp private/server.pem ../../
cp issued/server.crt ../../
cd ../
{(
echo "port 2944
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.15.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 9.9.9.9"
push "dhcp-option DNS 149.112.112.112"
#push "block-outside-dns"
duplicate-cn
keepalive 10 120
cipher AES-256-GCM
user nobody
group nogroup
persist-key
persist-tun
verb 3
crl-verify crl.pem
explicit-exit-notify
" > ../server.conf
)}
#
sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.ip_forward
