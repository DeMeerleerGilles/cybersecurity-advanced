# Overzicht van de subnetten

| subnet 1  | subnet 2     |
| --------- | ------------ |
| DMZ       | Internal LAN |
| webserver | clients, db  |

IP-adressen per toestel:

| toestel         | IP-adres       |
| --------------- | -------------- |
| webserver       | 172.30.10.10   |
| dns             | 172.30.20.4    |
| db              | 172.30.20.15   |
| SIEM            | 172.30.20.50   |
| employee1       | 172.30.20.123  |
| isp router      | 192.168.62.254 |
| companyrouter   | 192.168.62.253 |
| companyrouter   | 172.30.255.254 |
| homerouter      | 192.168.62.42  |
| kali            | 192.168.62.110 |
| remote-employee | 172.10.10.123  |

Routes die moeten ingesteld worden:

Alles in .20.X krijgt route

sudo ip route add 192.168.62.0/24 via 172.30.255.254 dev eth1

Alles in 172.30.10.X krijgt route

sudo ip route add 192.168.62.0/24 via 172.30.255.254 dev eth1
