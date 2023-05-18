apt install openvpn easy-rsa
mkdir /etc/openvpn/easy-rsa
ln -s /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa
easyrsa init-pki
easyrsa build-ca nopass
easyrsa build-server-full vpn_server nopass
easyrsa sign-req server vpn_server
easyrsa gen-dh
openvpn --genkey /pki/private/vpn_server.pem
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
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
verb 3
crl-verify crl.pem
explicit-exit-notify
" > server.conf
)}
