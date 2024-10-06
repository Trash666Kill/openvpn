#!/bin/bash
#
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como sudo"
    exit 1
fi
#
read -p "Digite o nome do usuário: " username
if [[ -z "$username" ]]; then
    echo "Nenhum nome de usuário inserido. Encerrando o script."
    exit 1
fi
#
mkdir -v /etc/openvpn/server/clients/$username
cd /etc/openvpn/server/easy-rsa
./easyrsa --batch --req-cn=$username gen-req $username nopass
./easyrsa --batch --req-cn=$username sign-req client $username
cd pki
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/$username.pem
cp -v ca.crt ../../clients/$username
cp -v issued/$username.crt ../../clients/$username
cp -v private/$username.key ../../clients/$username
cp -v private/$username.pem ../../clients/$username
#
cd ../../clients/$username
{(
cat <(echo -e 'client') \
<(echo -e 'proto udp') \
<(echo -e 'dev tun') \
<(echo -e 'remote shorting.com.br 2944') \
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
    $username.crt \
    <(echo -e '</cert>\n<key>') \
    $username.key \
    <(echo -e '</key>\n<tls-crypt-v2>') \
    $username.pem \
    <(echo -e '</tls-crypt-v2>') \
    > $username.ovpn
printf 'push "route 10.8.11.1 255.255.255.255"' > ../../ccd/$username
)}
chown emperor:emperor $username.ovpn