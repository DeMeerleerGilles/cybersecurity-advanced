# Verslag labo 1

Nslookup naar het domein van UGent

```powershell
PS C:\Users\gille> nslookup www.ugent.be
Server:  ns1.hogent.be
Address:  193.190.173.1

Non-authoritative answer:
Name:    www.UGent.be
Address:  157.193.43.50
```

Met een opgegeven server

```powershell
PS C:\Users\gille> nslookup gent.be 8.8.8.8
Server:  dns.google
Address:  8.8.8.8

Non-authoritative answer:
Name:    gent.be
Addresses:  2001:67c:1902:1305::138
          212.123.24.4
```

## Recap Wireshark

In cybersecurity and virtualization we got to know Wireshark. Most captures were relatively small in size. In a more realistic setting, a capture file will have a lot of packets, often unrelated to what you are searching for. Open the capture-lab1.pcap file and try to answer the following questions:

1. What layers of the OSI model are captured in this capturefile?

    Laag 2-4 en een beetje laag 7.

2. Take a look at the conversations. What do you notice?
   Er is heel veel cummunicatie tussen 172.30.128.1O en 172.30.42.2, voor de rest is er een beetje communicatie tussen andere adressen.

3. Take a look at the protocol hierarchy. What are the most "interesting" protocols listed here?
   Heel veel SSH verkeer, een paar windows gerelateerde protocollen zoals LDAP, kerberos. De rest is allemaal ARP, TCP en UDP.

4. Can you spot an SSH session that got established between 2 machines? List the 2 machines. Who was the SSH server and who was the client? What ports were used? Are these ports TCP or UDP?
   Client: 172.30.128.10
   Server: 172.30.42.2
   Port: 22, 37700
   Protocol: TCP

5. Some cleartext data was transferred between two machines. Can you spot the data? Can you deduce what happened here?

    Couldn't find any cleartext data.

6. Someone used a specific way to transfer a png on the wire. Is it possible to export this png easily? 
   
   Is it possible to export other HTTP related stuff?
   It is possible to export the png file because it is transferred over HTTP and thus in the packet capture. Other HTTP related stuff can also be exported.

## Company router

```bash
[vagrant@companyrouter ~]$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether 08:00:27:e8:a5:e1 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:26:49:5e brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 192.168.62.253/24 brd 192.168.62.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe26:495e/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:92:4c:3c brd ff:ff:ff:ff:ff:ff
    altname enp0s9
    inet 172.30.255.254/16 brd 172.30.255.255 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe92:4c3c/64 scope link
       valid_lft forever preferred_lft forever
[vagrant@companyrouter ~]$ ip route show
default via 192.168.62.254 dev eth1 proto static metric 100
172.30.0.0/16 dev eth2 proto kernel scope link src 172.30.255.254 metric 101
192.168.62.0/24 dev eth1 proto kernel scope link src 192.168.62.253 metric 100
```

Interfaces companyrouter:

eth0: down → geen gebruik.

eth1: 192.168.62.253/24 → default gateway gaat via 192.168.62.254. Dit is dus de WAN/ISP-kant.

eth2: 172.30.255.254/16 → intern netwerk. Hier hangen employee, dns, web op.

What did you have to configure on your red machine to have internet and to properly ping the web machine (is the ping working on IP only or also on hostname)?
De default gateway moest ingesteld worden op 192.168.62.254. Daarnaast had ik ook nog een probleem met de DNS. Dit viel op te lossen door:

```bash
 echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

Hierna kon ik alles bereiken vanop de kali.

Bij het uitvoeren van een nmap zien we alle routers staan.
```bash
──(vagrant㉿red)-[~]
└─$ nmap -sn 192.168.62.0/24
Starting Nmap 7.95 ( https://nmap.org ) at 2025-10-06 08:42 EDT
Nmap scan report for 192.168.62.0
Host is up (0.00022s latency).
MAC Address: 0A:00:27:00:00:0A (Unknown)
Nmap scan report for 192.168.62.42
Host is up (0.0012s latency).
MAC Address: 08:00:27:80:13:EC (PCS Systemtechnik/Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.62.253
Host is up (0.00029s latency).
MAC Address: 08:00:27:26:49:5E (PCS Systemtechnik/Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.62.254
Host is up (0.00039s latency).
MAC Address: 08:00:27:46:85:65 (PCS Systemtechnik/Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.62.110
Host is up.
Nmap done: 256 IP addresses (5 hosts up) scanned in 2.32 seconds
```

DNS zone transfer

```bash
┌──(vagrant㉿red)-[~]
└─$ dig axfr @172.30.0.4 cybersec.internal 

; <<>> DiG 9.20.11-4+b1-Debian <<>> axfr @172.30.0.4 cybersec.internal
; (1 server found)
;; global options: +cmd
cybersec.internal.      86400   IN      SOA     dns.cybersec.internal. admin.cybersec.internal. 2023092301 3600 1800 1209600 86400
cybersec.internal.      86400   IN      NS      dns.cybersec.internal.
txt.at.cybersec.internal. 86400 IN      TXT     "Greetings from CSA team!"
dns.cybersec.internal.  86400   IN      A       172.30.0.4
www.cybersec.internal.  86400   IN      A       172.30.0.10
cybersec.internal.      86400   IN      SOA     dns.cybersec.internal. admin.cybersec.internal. 2023092301 3600 1800 1209600 86400
;; Query time: 0 msec
;; SERVER: 172.30.0.4#53(172.30.0.4) (TCP)
;; WHEN: Mon Oct 06 09:08:23 EDT 2025
;; XFR size: 6 records (messages 1, bytes 267)

```
We maken verbinding met de DNS server via ssh en we zoeken uit wat voor DNS server er op deze machine draait:

```bash
dns:~$ sudo netstat -tulpn | grep :53
tcp        0      0 172.30.0.4:53           0.0.0.0:*               LISTEN      1779/named
tcp        0      0 127.0.0.1:53            0.0.0.0:*               LISTEN      1779/named
tcp        0      0 ::1:53                  :::*                    LISTEN      1779/named
tcp        0      0 fe80::a00:27ff:fec2:42d:53 :::*                    LISTEN      1779/named
udp        0      0 172.30.0.4:53           0.0.0.0:*                           1779/named
udp        0      0 127.0.0.1:53            0.0.0.0:*                           1779/named
udp        0      0 ::1:53                  :::*                                1779/named
udp        0      0 fe80::a00:27ff:fec2:42d:53 :::*                                1779/named
```

Dit is BIND. Standaard staat zone transfers open voor iedereen.

We controleren de configuratie:

```bash
sudo cat /etc/bind/named.conf
options {
    directory "/var/bind";
    allow-transfer { any; };  # Allow zone transfers from any machine
    listen-on { any; };       # Listen on all interfaces
    listen-on-v6 { any; };    # Listen on all IPv6 interfaces
    recursion yes;            # Enable recursion for forwarding other queries
    forwarders {
        192.168.62.254;       # Forward all other queries to this DNS server
    };
    allow-query { any; };     # Allow queries from any IP
};

zone "cybersec.internal" {
    type master;
    file "/var/bind/cybersec.internal";
    allow-transfer { any; };  # Allow zone transfers from any machine
```

We veranderen de configuratie van dit:

```conf
options {
    directory "/var/bind";
    allow-transfer { any; };  # ← DIT IS HET PROBLEEM
    listen-on { any; };
    listen-on-v6 { any; };
    recursion yes;
    forwarders {
        192.168.62.254;
    };
    allow-query { any; };
};

zone "cybersec.internal" {
    type master;
    file "/var/bind/cybersec.internal";
    allow-transfer { any; };  # ← EN DIT OOK
};
```

naar dit:

```conf
options {
    directory "/var/bind";
    allow-transfer { none; };  # ← BLOKKEER zone transfers
    listen-on { any; };
    listen-on-v6 { any; };
    recursion yes;
    forwarders {
        192.168.62.254;
    };
    allow-query { any; };
};

zone "cybersec.internal" {
    type master;
    file "/var/bind/cybersec.internal";
    allow-transfer { none; };  # ← BLOKKEER zone transfers
};
```

Herstart de DNS server:

```bash
sudo named-checkconf
sudo /etc/init.d/named restart
```