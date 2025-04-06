#!/bin/bash
#
if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as sudo"
   	exit 1
else
#

TARGET_USER=$(grep 1001 /etc/passwd | cut -f 1 -d ":")

(
apt install openvpn easy-rsa -y
adduser --system --no-create-home --group openvpn
mkdir -v /etc/openvpn/server/easy-rsa
mkdir -pv /etc/openvpn/server/clients/"$TARGET_USER"
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
chmod 400 /etc/openvpn/server/{server.key,server.crt,ca.crt}
{(
printf 'port 2944
proto udp
dev tun
allow-compression no
ca ca.crt
cert server.crt
key server.key
tls-crypt-v2 server.pem
dh dh.pem
topology subnet
server 10.8.11.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 9.9.9.9"
push "dhcp-option DNS 149.112.112.112"
push "block-outside-dns"
keepalive 10 120
cipher AES-256-GCM
ccd-exclusive
client-config-dir ccd
duplicate-cn
user openvpn
group openvpn
persist-key
persist-tun
verb 4
explicit-exit-notify 1' > ../../server.conf
chmod 640 /etc/openvpn/server/server.conf
)}
#
sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.ip_forward
iptables -t nat -A POSTROUTING -s 10.8.15.0/24 -o enp1s0 -j MASQUERADE
echo "iptables -t nat -A POSTROUTING -s 10.8.15.0/24 -o enp1s0 -j MASQUERADE &" >> /etc/rc.local
#
cd ../
./easyrsa --batch --req-cn="$TARGET_USER" gen-req "$TARGET_USER" nopass
./easyrsa --batch --req-cn="$TARGET_USER" sign-req client "$TARGET_USER"
cd pki
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/"$TARGET_USER".pem
cp -v ca.crt ../../clients/"$TARGET_USER"
cp -v issued/"$TARGET_USER".crt ../../clients/"$TARGET_USER"
cp -v private/"$TARGET_USER".key ../../clients/"$TARGET_USER"
cp -v private/"$TARGET_USER".pem ../../clients/"$TARGET_USER"
#
cd ../../clients/"$TARGET_USER"
{(
cat <(echo -e 'client') \
<(echo -e 'proto udp') \
<(echo -e 'dev tun') \
<(echo -e 'remote vps24410.frlfryiwad7efpapvov5wnqzbf.com.br 2944') \
<(echo -e 'resolv-retry infinite') \
<(echo -e 'nobind') \
<(echo -e 'persist-key') \
<(echo -e 'persist-tun') \
<(echo -e 'remote-cert-tls server') \
<(echo -e 'cipher AES-256-GCM') \
<(echo -e '#user nobody') \
<(echo -e '#group nobody') \
<(echo -e 'redirect-gateway def1') \
<(echo -e 'verb 3') \
    <(echo -e '<ca>') \
    ca.crt \
    <(echo -e '</ca>\n<cert>') \
    "$TARGET_USER".crt \
    <(echo -e '</cert>\n<key>') \
    "$TARGET_USER".key \
    <(echo -e '</key>\n<tls-crypt-v2>') \
    "$TARGET_USER".pem \
    <(echo -e '</tls-crypt-v2>') \
    > "$TARGET_USER".ovpn
 printf 'push "route 10.8.11.1 255.255.255.255"' > ../../ccd/"$TARGET_USER"
 )}
 chown "$TARGET_USER":"$TARGET_USER" "$TARGET_USER".ovpn
 ) 2>&1 | tee outputfile
#
fi