#!/bin/bash
(
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
cd pki
openvpn --genkey tls-crypt-v2-server private/server.pem
cp -v ca.crt dh.pem ../../
cp -v private/server.key ../../
cp -v private/server.pem ../../
cp -v issued/server.crt ../../
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
" > ../../server.conf
)}
#
sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.ip_forward
iptables -t nat -A POSTROUTING -s 10.8.15.0/24 -o enp1s0 -j MASQUERADE
echo "iptables -t nat -A POSTROUTING -s 10.8.15.0/24 -o enp1s0 -j MASQUERADE &" >> /etc/rc.local
#
cd ../
./easyrsa --batch gen-req emperor nopass
./easyrsa --batch sign-req client emperor
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/emperor.pem
cd pki
cp -v ca.crt ../../clients/emperor
cp -v issued/emperor.crt ../../clients/emperor
cp -v private/emperor.key ../../clients/emperor
cp -v private/emperor.pem ../../clients/emperor
#
cd ../../clients/emperor
{(
cat <(echo -e 'client') \
<(echo -e 'proto udp') \
<(echo -e 'dev tun') \
<(echo -e 'remote strychnine.duckdns.org 2944') \
<(echo -e 'resolv-retry infinite') \
<(echo -e 'nobind') \
<(echo -e 'persist-key') \
<(echo -e 'persist-tun') \
<(echo -e 'remote-cert-tls server') \
<(echo -e 'cipher AES-256-GCM') \
<(echo -e '#user nobody') \
<(echo -e '#group nobody') \
<(echo -e '#redirect-gateway def1') \
<(echo -e 'verb 3') \
    <(echo -e '<ca>') \
    ca.crt \
    <(echo -e '</ca>\n<cert>') \
    emperor.crt \
    <(echo -e '</cert>\n<key>') \
    emperor.key \
    <(echo -e '</key>\n<tls-crypt-v2>') \
    emperor.pem \
    <(echo -e '</tls-crypt-v2>') \
    > emperor.ovpn
 )}
 chown emperor:emperor emperor.ovpn
 ) 2>&1 | tee outputfile
#
