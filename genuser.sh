#!/bin/bash
#
if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as sudo"
   	exit 1
else
#
mkdir -v /etc/openvpn/server/clients/$1
cd /etc/openvpn/server/easy-rsa
./easyrsa --batch --req-cn=$1 gen-req $1 nopass
./easyrsa --batch --req-cn=$1 sign-req client $1
cd pki
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/$1.pem
cp -v ca.crt ../../clients/$1
cp -v issued/$1.crt ../../clients/$1
cp -v private/$1.key ../../clients/$1
cp -v private/$1.pem ../../clients/$1
#
cd ../../clients/$1
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
    $1.crt \
    <(echo -e '</cert>\n<key>') \
    $1.key \
    <(echo -e '</key>\n<tls-crypt-v2>') \
    $1.pem \
    <(echo -e '</tls-crypt-v2>') \
    > $1.ovpn
 )}
 chown emperor:emperor $1.ovpn
 fi
