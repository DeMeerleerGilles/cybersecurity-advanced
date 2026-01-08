# Overzicht van de subnetten

SSH moet werken tussen alle machines over alle subnetten heen. De webserver in de DMZ moet bereikbaar zijn vanaf overal. De wazuh SIEM moet ook alle logs kunnen ontvangen van alle machines. DNS moet werken voor alle servers en clients. IP sec en openvpn moeten ook doorgelaten worden.

| Subnet                 | subnet 1                      | subnet 2                      |
| ---------------------- | ----------------------------- | ----------------------------- |
| Netwerk                | 172.30.10.0/24                | 172.30.20.0/24                |
| Subnetmasker           | 255.255.255.0                 | 255.255.255.0                 |
| Range beschikbare IP's | 172.30.10.1 t/m 172.30.10.254 | 172.30.20.1 t/m 172.30.20.254 |
| Naam                   | DMZ                           | Internal LAN                  |
| Welke hosts            | webserver                     | clients, db                   |
| Router IP              | 172.30.10.254                 | 172.30.20.254                 |

IP-adressen per toestel:

| toestel           | IP-adres       | Services        |
| ----------------- | -------------- | --------------- |
| webserver         | 172.30.10.10   | HTTP, HTTPS     |
| dns               | 172.30.20.4    | DNS             |
| db                | 172.30.20.15   | MySQL           |
| SIEM              | 172.30.20.50   | wazuh           |
| Windows client    | 172.30.20.51   |                 |
| employee          | 172.30.20.123  | VPN             |
| isp router        | 192.168.62.254 |                 |
| companyrouter     | 192.168.62.253 | SSH bastion     |
| companyrouter DMZ | 172.30.10.254  |                 |
| companyrouter     | 172.30.20.254  |                 |
| homerouter        | 192.168.62.42  | IPsec & OpenVPN |
| kali              | 192.168.62.110 |                 |
| remote-employee   | 172.10.10.123  |                 |

SIEM wachtwoord: TzGHeQOZyZ0rmcBL?43oykJyEFuzfxmP
