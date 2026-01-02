# Overzicht van de subnetten

| Subnet                 | subnet 1                      | subnet 2                      |
| ---------------------- | ----------------------------- | ----------------------------- |
| Netwerk                | 172.30.10.0/24                | 172.30.20.0/24                |
| Subnetmasker           | 255.255.255.0                 | 255.255.255.0                 |
| Range beschikbare IP's | 172.30.10.1 t/m 172.30.10.254 | 172.30.20.1 t/m 172.30.20.254 |
| Naam                   | DMZ                           | Internal LAN                  |
| Welke hosts            | webserver                     | clients, db                   |
| Router IP              | 172.30.10.254                 | 172.30.20.254                 |

IP-adressen per toestel:

| toestel           | IP-adres       |
| ----------------- | -------------- |
| webserver         | 172.30.10.10   |
| dns               | 172.30.20.4    |
| db                | 172.30.20.15   |
| SIEM              | 172.30.20.50   |
| Windows client    | 172.30.20.51   |
| employee          | 172.30.20.123  |
| isp router        | 192.168.62.254 |
| companyrouter     | 192.168.62.253 |
| companyrouter DMZ | 192.30.10.254  |
| companyrouter     | 172.30.20.254  |
| homerouter        | 192.168.62.42  |
| kali              | 192.168.62.110 |
| remote-employee   | 172.10.10.123  |

Routes die moeten ingesteld worden:

Alles in .20.X krijgt route

sudo ip route add 192.168.62.0/24 via 172.30.255.254 dev eth1

Alles in 172.30.10.X krijgt route

sudo ip route add 192.168.62.0/24 via 172.30.255.254 dev eth1

op de remote-employee:
sudo ip route add 172.30.0.0/16 via 172.10.10.254
