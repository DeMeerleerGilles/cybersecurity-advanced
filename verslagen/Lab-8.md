# Lab 8: IPsec

Ik begon met het tekenen van een netwerkdiagram om de verschillende componenten en hun verbindingen in het IPsec-lab te visualiseren. Dit hielp me om een duidelijk overzicht te krijgen van hoe de verschillende apparaten met elkaar communiceren.

![alt text](../netwerk-diagram.jpg)

Hierna sshde ik naar de homerouter om de routing aan te zetten. 

Ik maakte ook een route aan naar het fake internet:

```bash
sudo ip route add 172.30.0.0/16 via 192.168.62.253
```

Ik controlleerde ook of het verkeer niet via de ISP-router ging:

```bash
[vagrant@homerouter ~]$ traceroute 172.30.20.4
traceroute to 172.30.20.4 (172.30.20.4), 30 hops max, 60 byte packets
 1  * * *
 2  192.168.62.253 (192.168.62.253)  0.363 ms  0.402 ms  0.381 ms
 3  172.30.20.4 (172.30.20.4)  0.685 ms  0.637 ms  0.619 ms
```

## MitM attack

Hierna startte ik de kali VM op om de Man in the Middle attack uit te voeren. Ik gebruikte hiervoor het volgende commando:

```bash
sudo ettercap -Tq -i eth0 -M arp:remote /192.168.62.42// /192.168.62.253//
```

We starten ook wireshark om het verkeer te monitoren met het commando:

```bash
sudo wireshark &
```

We zetten een filter op:

icmp || esp

en nu pingen we van de remote-employee naar de webserver:

```bash
ping 172.30.10.10 
```

![alt text](<img/Schermafbeelding 2025-12-30 152947.png>)

## IPsec setup

Hierna maakte ik een bestand aan op de homerouter om het script uit de opgave in te plakken en te kunnen uitvoeren op de vm

```bash
#!/usr/bin/env sh

# Manual IPSec

## Clean all previous IPsec stuff

ip xfrm policy flush
ip xfrm state flush

## The first SA vars for the tunnel from homerouter to companyrouter

SPI7=0x007
ENCKEY7=0xFEDCBA9876543210FEDCBA9876543210

## Activate the tunnel from homerouter to companyrouter

### Define the SA (Security Association)

ip xfrm state add \
    src 192.168.62.42 \
    dst 192.168.62.253 \
    proto esp \
    spi ${SPI7} \
    mode tunnel \
    enc aes ${ENCKEY7}

### Set up the SP using this SA

ip xfrm policy add \
    src 172.10.10.0/24 \
    dst 172.30.0.0/16 \
    dir out \
    tmpl \
    src 192.168.62.42 \
    dst 192.168.62.253 \
    proto esp \
    spi ${SPI7} \
    mode tunnel
```

Ik paste dit script aan om het ook op de companyrouter te kunnen uitvoeren:

```bash
#!/usr/bin/env sh

ip xfrm policy flush
ip xfrm state flush

SPI7=0x007
ENCKEY7=0xFEDCBA9876543210FEDCBA9876543210

ip xfrm state add \
    src 192.168.62.42 \
    dst 192.168.62.253 \
    proto esp \
    spi ${SPI7} \
    mode tunnel \
    enc aes ${ENCKEY7}

ip xfrm policy add \
    src 172.10.10.0/24 \
    dst 172.30.0.0/16 \
    dir in \
    tmpl \
    src 192.168.62.42 \
    dst 192.168.62.253 \
    proto esp \
    spi ${SPI7} \
    mode tunnel
```

Na het uitvoeren van deze scripts op beide routers, startte ik opnieuw de ping vanaf de remote-employee naar de webserver:

```bash
[vagrant@remote-employee ~]$ ping 172.30.10.10
PING 172.30.10.10 (172.30.10.10) 56(84) bytes of data.
64 bytes from 172.30.10.10: icmp_seq=1 ttl=61 time=47.7 ms
64 bytes from 172.30.10.10: icmp_seq=2 ttl=61 time=16.5 ms
64 bytes from 172.30.10.10: icmp_seq=3 ttl=61 time=9.89 ms
64 bytes from 172.30.10.10: icmp_seq=4 ttl=61 time=12.5 ms
64 bytes from 172.30.10.10: icmp_seq=5 ttl=61 time=8.74 ms
64 bytes from 172.30.10.10: icmp_seq=6 ttl=61 time=9.96 ms
64 bytes from 172.30.10.10: icmp_seq=7 ttl=61 time=12.7 ms
64 bytes from 172.30.10.10: icmp_seq=8 ttl=61 time=22.5 ms
64 bytes from 172.30.10.10: icmp_seq=9 ttl=61 time=10.1 ms
64 bytes from 172.30.10.10: icmp_seq=10 ttl=61 time=17.8 ms
^C
--- 172.30.10.10 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9017ms
rtt min/avg/max/mdev = 8.740/16.839/47.719/11.087 ms
[vagrant@remote-employee ~]$ ping 172.30.10.10
PING 172.30.10.10 (172.30.10.10) 56(84) bytes of data.
^C
--- 172.30.10.10 ping statistics ---
39 packets transmitted, 0 received, 100% packet loss, time 38912ms
```

Dit werkte niet.