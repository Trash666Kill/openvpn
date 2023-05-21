#
cd /etc/openvpn/server/easy-rsa
./easyrsa --batch gen-req emperor nopass
./easyrsa --batch sign-req client emperor
cd pki
openvpn --tls-crypt-v2 private/server.pem --genkey tls-crypt-v2-client private/emperor.pem
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
