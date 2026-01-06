# Demo IP sec

Ik toon eerst dat verkeer zonder IPsec afluisterbaar is via een MITM-aanval, en daarna dat hetzelfde verkeer met IPsec volledig versleuteld wordt.

Op de homerouter:

```bash
ip route
traceroute 172.30.20.4
traceroute to 172.30.20.4 (172.30.20.4), 30 hops max, 60 byte packets
 1  _gateway (192.168.62.254)  0.192 ms  0.174 ms  0.130 ms
 2  192.168.62.253 (192.168.62.253)  0.406 ms  0.351 ms  0.304 ms
 3  172.30.20.4 (172.30.20.4)  0.694 ms  0.654 ms  0.615 ms
```

## Tonen dat dit verkeer afluisterbaar is

Ping van remote-employee naar webserver:

```bash
ping 172.30.10.10
```

Op de kali een ettercap sessie starten:

```bash
sudo ettercap -Tq -i eth0 -M arp:remote /192.168.62.42// /192.168.62.253//
```

En wireshark openen

```bash
sudo wireshark &
```

Filteren op ICMP en het ping verkeer zien. We kunnen dit verkeer zien. Een aanvaller kan hier perfect zien wie met wie communiceert.

## IPsec activeren

Op de homerouter het script runnen:

```bash
./script
```

Op de companyrouter het script runnen:

```bash
./script
```

Hierna kunnen we de ping bekijken in wireshark. Hetzelfde ping verkeer is nu volledig versleuteld met IPsec ESP. Een aanvaller kan hier niets meer uit afleiden.

## Decryption

Ze onder edit > preferences > protocols > ESP decryptie aan of af.