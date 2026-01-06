# Lab 9: VPN

Ik begon met openvpn te installeren op de companyrouter. 

```bash
sudo dnf install epel-release -y
sudo dnf install --assumeyes openvpn easy-rsa
```

Vervolgens controleerde ik of de installatie gelukt was:

```bash
[vagrant@companyrouter ~]$ openvpn --version
OpenVPN 2.5.11 x86_64-redhat-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Jul 18 2024
library versions: OpenSSL 3.2.2 4 Jun 2024, LZO 2.10
Originally developed by James Yonan
Copyright (C) 2002-2022 OpenVPN Inc <sales@openvpn.net>
```

```bash
[vagrant@companyrouter ~]$ sudo /usr/share/easy-rsa/3/easyrsa --version
EasyRSA Version Information
Version:     3.2.1
Generated:   Fri Sep 13 13:04:18 CDT 2024
SSL Lib:     OpenSSL 3.2.2 4 Jun 2024 (Library: OpenSSL 3.2.2 4 Jun 2024)
Git Commit:  3f60a68702713161ab44f9dd80ce01f588ca49ac
Source Repo: https://github.com/OpenVPN/easy-EasyRSA
```

## PKI opzetten

Hierna initalieerde ik de PKI omgeving:

```bash
/usr/share/easy-rsa/3/easyrsa init-pki
```

Ik maakte een nieuwe CA aan:

```bash
/usr/share/easy-rsa/3/easyrsa build-ca nopass
```

Als hij om een naam vroeg klikte ik gewoon op enter zodat hij de standaard naam gebruikte.

Vervolgens maakte ik een server certificaat aan:

```bash
/usr/share/easy-rsa/3/easyrsa gen-req server nopass
/usr/share/easy-rsa/3/easyrsa sign-req server server
```

Daarna genereerde ik het client certificaat:

```bash
/usr/share/easy-rsa/3/easyrsa gen-req client nopass
/usr/share/easy-rsa/3/easyrsa sign-req client client
```

Hierna maakte ik de Diffie-Hellman parameters aan zodat de sleutels veilig uitgewisseld konden worden:

```bash
/usr/share/easy-rsa/3/easyrsa gen-dh
```

## Server configureren

Ik kopieerde het voorbeeldconfiguratiebastand naar de /etc/openvpn map:

```bash
sudo cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf /etc/openvpn/server.conf
```

We openen het bestand met nano:

```bash
sudo nano /etc/openvpn/server.conf
```

We zoeken met CTRL+W naar de volgende regels en passen ze aan zodat ze er als volgt uitzien:

```conf
;local a.b.c.d
```

Dit vervangen we door:

```conf
local 192.168.62.253
```

Ik zette ook de paden naar de certificaten en sleutels goed:

```conf
ca /home/vagrant/pki/ca.crt
cert /home/vagrant/pki/issued/server.crt
key /home/vagrant/pki/private/server.key
dh /home/vagrant/pki/dh.pem
```

Daarna stelde ik nog de routes in op basis van mijn netwerkopstelling.

Ik veranderde de volgende regel:

```conf
;push "route 192.168.10.0 255.255.255.0"
```

Naar:

```conf
push "route 172.30.10.0 255.255.255.0"
push "route 172.30.20.0 255.255.255.0"
```

Voor topology haalde ik ook nog de punt komma weg, dit zorgt dat clients een IP adres krijgen uit hetzelfde subnet als de server:

```conf
topology subnet
```

## CLient configureren

Ik begon met openvpn te installeren op de client machine:

```bash
sudo dnf install epel-release -y
sudo dnf install openvpn
```

Op de companyrouter gaf ik de juiste permissies aan de client key zodat de client deze ook kon lezen

```bash
sudo chmod 644 /home/vagrant/pki/private/client.key
```

Op de remote employee machine maakte ik een map aan voor de vpn bestanden:

```bash
mkdir ~/openvpn
cd ~/openvpn
```

Daarna kopieerde ik de volgende bestanden van de companyrouter naar de remote employee machine:

```bash
scp vagrant@192.168.62.253:/home/vagrant/pki/ca.crt .
scp vagrant@192.168.62.253:/home/vagrant/pki/issued/client.crt .
scp vagrant@192.168.62.253:/home/vagrant/pki/private/client.key .
```

Hierna kopieerde ik de voorbeeldconfiguratie naar de map:

```bash
cp /usr/share/doc/openvpn/sample/sample-config-files/client.conf ~/openvpn/client.conf
```

Ik paste de volgende regels aan in het configuratiebestand:

```conf
remote my-server-1 1194
```

Deze veranderde ik naar het IP adres van de companyrouter:

```conf
remote 192.168.62.253 1194
```

Ik zette ook de paden naar de certificaten en sleutels goed:

```conf
ca /home/vagrant/openvpn/ca.crt
cert /home/vagrant/openvpn/client.crt
key /home/vagrant/openvpn/client.key
```

Ik voegde ook nog de regel:

```conf
auth-user-pass
```

en zette de volgende regel uit:

```conf
;tls-auth ta.key 1
```

## VPN starten

Op de companyrouter startte ik de openvpn server:

```bash
cd /etc/openvpn
sudo openvpn server.conf
```

De VPN server is nu gestart.

```bash
[vagrant@companyrouter openvpn]$ sudo openvpn server.conf
2026-01-01 09:46:39 DEPRECATED OPTION: --cipher set to 'AES-256-CBC' but missing in --data-ciphers (AES-256-GCM:AES-128-GCM). Future OpenVPN version will ignore --cipher for cipher negotiations. Add 'AES-256-CBC' to --data-ciphers or change --cipher 'AES-256-CBC' to --data-ciphers-fallback 'AES-256-CBC' to silence this warning.
2026-01-01 09:46:39 OpenVPN 2.5.11 x86_64-redhat-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Jul 18 2024
2026-01-01 09:46:39 library versions: OpenSSL 3.2.2 4 Jun 2024, LZO 2.10
2026-01-01 09:46:39 net_route_v4_best_gw query: dst 0.0.0.0
2026-01-01 09:46:39 net_route_v4_best_gw result: via 10.0.2.2 dev eth0
2026-01-01 09:46:39 Diffie-Hellman initialized with 2048 bit key
2026-01-01 09:46:39 TUN/TAP device tun0 opened
2026-01-01 09:46:39 net_iface_mtu_set: mtu 1500 for tun0
2026-01-01 09:46:39 net_iface_up: set tun0 up
2026-01-01 09:46:39 net_addr_v4_add: 10.8.0.1/24 dev tun0
2026-01-01 09:46:39 Could not determine IPv4/IPv6 protocol. Using AF_INET
2026-01-01 09:46:39 Socket Buffers: R=[212992->212992] S=[212992->212992]
2026-01-01 09:46:39 UDPv4 link local (bound): [AF_INET]192.168.62.253:1194
2026-01-01 09:46:39 UDPv4 link remote: [AF_UNSPEC]
2026-01-01 09:46:39 MULTI: multi_init called, r=256 v=256
2026-01-01 09:46:39 IFCONFIG POOL IPv4: base=10.8.0.2 size=253
2026-01-01 09:46:39 IFCONFIG POOL LIST
2026-01-01 09:46:39 Initialization Sequence Completed
```

Op de remote employee machine startte ik de openvpn client:

```bash
cd ~/openvpn
sudo openvpn client.conf
```

Voor de authenticatie vulde ik de volgende gegevens in:


Username: vagrant
Password: vagrant


De VPN client is nu gestart. Ik opende een nieuwe terminal op de remote employee. Als ik nu mijn IP adres opvroeg zag ik dat ik een IP adres uit het VPN subnet had gekregen:

```bash
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 10.8.0.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::e8d4:2af5:8cbf:1ab5/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
```

Als we nu een ping doen naar de dns server in het interne netwerk zien we dat de VPN verbinding werkt:

```bash
[vagrant@remote-employee ~]$ ping 172.30.20.15
PING 172.30.20.15 (172.30.20.15) 56(84) bytes of data.
64 bytes from 172.30.20.15: icmp_seq=1 ttl=63 time=0.921 ms
64 bytes from 172.30.20.15: icmp_seq=2 ttl=63 time=1.22 ms
64 bytes from 172.30.20.15: icmp_seq=3 ttl=63 time=1.07 ms
^C
--- 172.30.20.15 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.921/1.070/1.220/0.122 ms
```

In wireshark zien we dit dan als openvpn verkeer.


![alt text](<img/Schermafbeelding 2026-01-06 160158.png>)