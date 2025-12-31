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
push "route 172.30.0.0 255.255.0.0"
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

TODO: starten en testen VPN verbinding