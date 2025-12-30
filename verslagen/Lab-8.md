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