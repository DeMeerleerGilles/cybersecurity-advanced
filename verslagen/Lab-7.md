# Labo 7: SIEM

Ik begon met een nieuwe map te maken voor de vagrantfile van dit labo in te zetten. In deze map heb ik dan een vagrantfile aangemaakt waarin ik de machine definieer. Ik heb in het provisioningstuk de nodige commando's toegevoegd om Wazuh te installeren. Daarnaast heb ik ook de interne adapter een vast IP-adres gegeven in het subnet van de companyrouter.

Ik voegde de machine toe aan de ssh config file op mijn laptop zodat ik makkelijk kan inloggen op de machine via ssh zonder telkens het hele commando te moeten intypen. 

Ik testte nog even of ik alle services zag draaien:

```bash
[vagrant@wazuh-server ~]$ sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard
● wazuh-manager.service - Wazuh manager
     Loaded: loaded (/usr/lib/systemd/system/wazuh-manager.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:50:09 UTC; 18min ago
    Process: 836 ExecStart=/usr/bin/env /var/ossec/bin/wazuh-control start (code=exited, status=0/SUC>
      Tasks: 153 (limit: 22767)
     Memory: 1.2G (peak: 1.3G)
        CPU: 1min 13.054s
     CGroup: /system.slice/wazuh-manager.service
             ├─6295 /var/ossec/framework/python/bin/python3 /var/ossec/api/scripts/wazuh_apid.py      
             ├─6309 /var/ossec/framework/python/bin/python3 /var/ossec/api/scripts/wazuh_apid.py      
             ├─6319 /var/ossec/framework/python/bin/python3 /var/ossec/api/scripts/wazuh_apid.py      

● wazuh-indexer.service - wazuh-indexer
     Loaded: loaded (/usr/lib/systemd/system/wazuh-indexer.service; enabled; preset: disabled)        
     Active: active (running) since Mon 2025-12-29 09:50:33 UTC; 17min ago
       Docs: https://documentation.wazuh.com
   Main PID: 829 (java)
      Tasks: 73 (limit: 22767)
     Memory: 1.5G (peak: 1.5G)
        CPU: 1min 3.412s
     CGroup: /system.slice/wazuh-indexer.service
             └─829 /usr/share/wazuh-indexer/jdk/bin/java -Xshare:auto -Dopensearch.networkaddress.cac>


● wazuh-dashboard.service - wazuh-dashboard
● wazuh-dashboard.service - wazuh-dashboard
     Loaded: loaded (/etc/systemd/system/wazuh-dashboard.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:49:38 UTC; 18min ago
● wazuh-dashboard.service - wazuh-dashboard
     Loaded: loaded (/etc/systemd/system/wazuh-dashboard.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:49:38 UTC; 18min ago
   Main PID: 730 (node)
      Tasks: 11 (limit: 22767)
● wazuh-dashboard.service - wazuh-dashboard
     Loaded: loaded (/etc/systemd/system/wazuh-dashboard.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:49:38 UTC; 18min ago
   Main PID: 730 (node)
      Tasks: 11 (limit: 22767)
     Memory: 274.9M (peak: 337.2M)
        CPU: 12.346s
     CGroup: /system.slice/wazuh-dashboard.service
             └─730 /usr/share/wazuh-dashboard/node/bin/node /usr/share/wazuh-dashboard/src/cli/dist   

Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
lines 1-17...skipping...
● wazuh-dashboard.service - wazuh-dashboard
     Loaded: loaded (/etc/systemd/system/wazuh-dashboard.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:49:38 UTC; 18min ago
   Main PID: 730 (node)
      Tasks: 11 (limit: 22767)
     Memory: 274.9M (peak: 337.2M)
        CPU: 12.346s
     CGroup: /system.slice/wazuh-dashboard.service
             └─730 /usr/share/wazuh-dashboard/node/bin/node /usr/share/wazuh-dashboard/src/cli/dist   

Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:55:01 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:55>
lines 1-18...skipping...
● wazuh-dashboard.service - wazuh-dashboard
     Loaded: loaded (/etc/systemd/system/wazuh-dashboard.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-12-29 09:49:38 UTC; 18min ago
   Main PID: 730 (node)
      Tasks: 11 (limit: 22767)
     Memory: 274.9M (peak: 337.2M)
        CPU: 12.346s
     CGroup: /system.slice/wazuh-dashboard.service
             └─730 /usr/share/wazuh-dashboard/node/bin/node /usr/share/wazuh-dashboard/src/cli/dist   

Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:49 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:50:50 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:50>
Dec 29 09:55:01 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:55>
Dec 29 09:55:01 wazuh-server opensearch-dashboards[730]: {"type":"log","@timestamp":"2025-12-29T09:55>
```

We kunnen het wazuh dashboard bereiken door in een browser naar het IP-adres van de SIEM server:

![alt text](<img/Schermafbeelding 2025-12-29 111519.png>)

Ik melde mij aan met het admin account en het wachtwoord dat werd aangemaakt tijdens de installatie.

Ik kreeg het dashboard te zien:

![alt text](<img/Schermafbeelding 2025-12-29 112016.png>)

TzGHeQOZyZ0rmcBL?43oykJyEFuzfxmP

Hierna begon ik met het toevoegen van de agents aan alle almalinux machines. Dit deed ik door in het dashboard naar server management te gaan en daar op add agent te klikken. Ik volgde de stappen in de wizard om de agent te installeren op de verschillende machines. Na het toevoegen van de agents kon ik in het dashboard zien dat ze verbonden waren.

Voorbeeld op de companyrouter:

![alt text](<img/Schermafbeelding 2025-12-29 113747.png>)

Op de homerouter voerde ik dan nog de volgende commando's uit om de agent te installeren en te verbinden met de SIEM server:

```bash
curl -o wazuh-agent-4.9.2-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.9.2-1.x86_64.rpm && sudo WAZUH_MANAGER='172.30.20.50' WAZUH_AGENT_NAME='Homerouter' rpm -ihv wazuh-agent-4.9.2-1.x86_64.rpm
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

Ik zag deze meteen verschijnen in het dashboard:

![alt text](<img/Schermafbeelding 2025-12-29 114909.png>)