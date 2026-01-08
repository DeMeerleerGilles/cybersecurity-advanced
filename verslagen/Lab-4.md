# Verslag labo 4: Honeypots

## Wat is een honeypot?

Een honeypot is een beveiligingsmechanisme dat is ontworpen om aanvallers aan te trekken, te detecteren en te analyseren door een ogenschijnlijk kwetsbaar of waardevol systeem, dienst of resource aan te bieden. Het doel van een honeypot is om kwaadwillende activiteiten te lokken en te observeren zonder dat deze daadwerkelijk schade kunnen aanrichten aan het echte netwerk of systeem.

## Uitwerking LABO

Why is companyrouter, in this environment, an interesting device to configure with a SSH honeypot? What could be a good argument to NOT configure the router with a honeypot service?

Het is een centraal netwerkapparaat, dus aanvallers zullen dit vaak scannen of proberen binnen te geraken.

Dat maakt het een realistisch doelwit → de honeypot gaat effectief aanvallen aantrekken.

Het router IP is meestal default gateway, dus makkelijk vindbaar.

Argument tegen:

Een router moet stabiel en veilig blijven. Een honeypot draaien op dezelfde machine verhoogt de risico’s → extra software, extra attack surface.

Als de honeypot crasht of misbruikt wordt, kan dit impact hebben op de routerfunctie.

### SSH verschuiven van poort 22 -> 2222

Op de companyrouter openen we de SSH config. Dit doen we met het commando:

```bash
sudo nano /etc/ssh/sshd_config
```

Nu zoeken we de lijn waarop de poort gedeclareerd wordt. Deze staat in commentaar dus we halen de hash weg en maken er 2222 van. Hierna paste ik deze poort ook nog aan in de ssh config van mijn gebruiker op mijn host zodat het commando ssh companyrouter meteen op de juiste poort probeert te verbinden.

### Installeren van cowrie

Hierna installeerde ik cowrie op de VM, voor het gemak deed ik dit via docker.

Ik moest hiervoor uiteraard eerst docker installeren op de VM, dit deed ik met de volgende commandos:

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
```

```bash
sudo systemctl enable --now docker
```

Gebruiker toevoegen aan de docker groep zodat er geen sudo meer nodig is:

```bash
sudo usermod -aG docker vagrant
```

Nu kunnen we beginnen aan de cowrie installatie.

```bash
sudo mkdir /opt/cowrie
sudo mkdir /opt/cowrie/log
sudo mkdir /opt/cowrie/data
sudo mkdir /opt/cowrie/etc
```

```bash
sudo curl -o /opt/cowrie/etc/cowrie.cfg \
    https://raw.githubusercontent.com/cowrie/cowrie/master/cowrie.cfg.dist
```

```bash
sudo docker run -d \
  --name cowrie \
  -p 22:2222 \
  -v /opt/cowrie/log:/cowrie/var/log/cowrie \
  -v /opt/cowrie/data:/cowrie/var/lib/cowrie \
  -v /opt/cowrie/etc/cowrie.cfg:/cowrie/etc/cowrie.cfg \
  cowrie/cowrie:latest
```

Om de container automatisch te laten starten bij het opstarten van de VM:

```bash
sudo docker update --restart unless-stopped cowrie
```

cowrie draait nu op de ssh poort. We kunnen verbinding maken met de router.

via het ssh commando: `ssh root@192.168.62.253`

What credentials work? Do you find credentials that don't work?

Je kunt met eender welk wachtwoord inloggen. Op een paar wachtwoorden na:
root - root werkt bijvoorbeeld niet. Dit is blijkbaar gedaan om het realistisch te laten zijn. De aanvaller krijgt de indruk dat het een correct beveiligd systeem is, maar kan hij alsnog verder proberen met andere combinaties.

Do you get a shell?

We krijgen een shell, maar dit is geen echte shell, we zien ook een verschil aan de structuur tov de normale alma shell. Het is een emulated environment die Cowrie voorziet.

Are your commands logged? Is the IP address of the SSH client logged? If this is the case, where?

Ja, alle ingegeven commando’s worden gelogd, inclusief:

-   Het IP-adres van de aanvaller
-   De ingegeven username en password
-   Alle commando’s die worden uitgevoerd
-   Eventuele bestanden die geprobeerd worden te downloaden of uploaden

Can an attacker perform malicious things?
Are the actions, in other words, the commands, logged to a file? Which file?

Deze komen in het logbestand cowrie.json te staan, dit bestand is terug te vinden in de docker volume op de host:

```bash
sudo cat /var/lib/docker/volumes/0ba09fa5d96ac103633bbe1a1f25b002b3218dd6a4e305cac89c363efd60bd3b/_data/log/cowrie/cowrie.json | jq .
```

Deel van de output:

```json
 "message": "SSH client hassh fingerprint: 701158e75b508e76f0410d5d22ef9df0",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:08.907586Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.login.success",
  "username": "root",
  "password": "hhdd",
  "message": "login attempt [root/hhdd] succeeded",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:10.972102Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.client.size",
  "width": 102,
  "height": 14,
  "message": "Terminal Size: 102 14",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:11.052099Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.session.params",
  "arch": "linux-x64-lsb",
  "message": [],
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:11.053932Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.command.input",
  "input": "curl localhost",
  "message": "CMD: curl localhost",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:17.495586Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.command.input",
  "input": "ls",
  "message": "CMD: ls",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:13:29.512887Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
{
  "eventid": "cowrie.session.closed",
  "duration": "200.5",
  "message": "Connection lost after 200.5 seconds",
  "sensor": "1b264fc3979f",
  "uuid": "5c16120c-e619-11f0-a404-7eb184fd5be4",
  "timestamp": "2026-01-02T11:16:29.355355Z",
  "src_ip": "192.168.62.0",
  "session": "e9c7ef908578",
  "protocol": "ssh"
}
```

We kunnen ook de logs in real-time bekijken met:

```bash
sudo docker logs -f cowrie
```

Nee, een aanvaller kan geen echte schade aanrichten. Alles gebeurt binnen de geëmuleerde omgeving:

-   Ze kunnen geen echte systeemwijzigingen doorvoeren
-   Ze kunnen geen netwerkscans van het echte systeem uitvoeren
-   Ze kunnen geen bestanden aanpassen buiten de Cowrie-container
-   Zelfs commando’s zoals rm -rf / of wget zijn fake en worden enkel gelogd

Cowrie vangt alle acties op en logt ze, maar voert niets echt uit op het hostsysteem.
Dit is exact het doel van een honeypot: aanvallers bezig houden en observeren zonder risico.

If you are an experienced hacker, how would/can you realize this is not a normal environment?

Het valt af te leiden uit een aantal zaken, bijvoorbeeld:

-   Veel standaardtools (vim, nano, top, iptables, systemctl, …) ontbreken of geven rare output.

-   Directory-inhoud klopt niet met een echte Linux-installatie, of bepaalde paden zijn leeg.

-   Commando’s zoals ls, uname, df of cat /etc/passwd geven hardcoded output.

-   Zelfs bij zware commando’s blijft het systeem reageren zonder CPU-load.

-   Commando’s zoals ping, wget, of curl lijken te werken, maar er gebeurt niets effectiefs.

-   ps toont een heel beperkt procesoverzicht.

## Critical thinking (security) when using "Docker as a service"

Wanneer je beslist om Cowrie (of gelijk welke service) te draaien in Docker, kies je voor een bepaalde deployment-architectuur. Dit heeft voor- en nadelen, zeker in een beveiligingscontext.

### Voordelen van services draaien in Docker

Een container draait geïsoleerd van het host-systeem.

Minder risico dat een kwetsbaarheid in het honeypot-proces de hele host infecteert. Je kan eenvoudig testen, experimenteren en dingen stukmaken zonder je basis OS te breken.

### Een nadeel van services draaien in Docker

De Docker daemon (dockerd) draait standaard als root.

Als een aanvaller kan uitbreken uit de container (container escape)
→ dan heeft hij toegang tot de hele host met root-privileges.

Containers worden vaak gezien als mini-VM’s, maar in realiteit delen ze dezelfde kernel.

Voor een honeypot verhoogt dit risico:
de honeypot moet kwetsbaar lijken, maar je wil niet dat een kwetsbaarheid in Cowrie de hele host besmet.

### Wat betekent “Docker uses a client-server architecture”?

Docker bestaat uit:

-   docker daemon (dockerd) → de server
-   draait achtergrondprocessen
-   maakt containers aan
-   beheert volumes, netwerken, images
-   draait meestal als root

docker CLI → de client

-   het programma docker dat jij uitvoert in de terminal
-   stuurt opdrachten naar de Docker daemon
-   communiceert meestal via /var/run/docker.sock

Dus:
Je CLI voert zelf niets uit. De Docker daemon doet al het werk. Jij stuurt enkel API-calls.

### Onder welke user draait de Docker daemon?

Volgens de officiële documentatie draait de Docker daemon standaard als root.

### What could be an advantage of running a honeypot inside a virtual machine compared to running it inside a container?

Sterkere isolatie

Een VM heeft een volledig aparte kernel, hardware-abstractie en geheugenruimte.

Als een aanvaller: Cowrie probeert te misbruiken, een exploit uitvoert, privilege escalation doet of een container escape vindt dan geraakt hij in het ergste geval enkel in de honeypot-VM, niet op de fysieke host.

Voor een honeypot is dit veel veiliger, want je laat bewust "kwetsbare of misleidende" software draaien.

Conclussie: Een VM is veiliger dan een container

## Docker deep dive

Waarom wordt /var/run/docker.sock gemount?

Omdat dit het communicatiekanaal is tussen de Docker CLI en de Docker daemon. We hebben dit nodig zodat de container opdrachten kan sturen naar de host Docker daemon.

-   containers te starten/stoppen
-   images te pullen
-   volumes/netwerken te beheren
-   logs op te vragen
-   statistieken op te vragen

Wat is docker.sock precies?

een UNIX domain socket bestand, de lokale API endpoint van de Docker daemon (dockerd)te vinden op /var/run/docker.sock

Waarom brengt dit ernstige security risico’s?

Mounten van /var/run/docker.sock in een container ≈ container volledige root-toegang geven tot je host.

Met toegang tot de Docker API kan een aanvaller:

-   een privileged container starten
-   een container starten met -v /:/host → volledige host filesystem
-   bestanden aanpassen op de host
-   persistente malware installeren
-   netwerken aanpassen
-   logs uitlezen met gevoelige informatie
-   environment variables en secrets van andere containers zien

“Access to docker.sock = root access to the host.”

Daarom is dit een high-impact security risk.

## Other honeypot types

Wat voor type honeypot is honeyup?

Honeyup is een:

An uploader honeypot designed to look like poor website security.


Wat is het idee achter OpenCanary?

OpenCanary is een: lightweight host-based honeypot dat nep-services aanbiedt zoals:

-   FTP
-   SSH
-   HTTP
-   Redis
-   SMB
-   RDP
-   etc.

Het doel is intruders detecteren, niet te “foppen”.

Idee:

Je draait nep-services die nooit in normale werking gebruikt worden.
Als iemand ermee verbindt → onmiddellijke alarmmelding.

Is a HTTP(S) honeypot a good idea? Why or why not?

Ja én nee, afhankelijk van de context.

Voordelen:

-   Simuleert een realistische aanvalsvector
-   Je kan exploit attempts, payloads, bots en scans zien
-   Geen echte schade want de backend is nep

Nadelen:

-   HTTP(S) verkeer is enorm → veel ruis

-   Veel false positives (bots, scrapers)
-   aanvallers zien soms te snel dat het een honeypot is
-   HTTPS vergt certificaatmanagement

Conclusie:

Goed idee voor research of threat intel, maar niet ideaal als primaire security measure.

Ons /cmd endpoint als honeypot: hoe commands loggen?

Je kan alle input die gebruikers posten loggen.
Voorbeeld:

```python
@app.route('/cmd', methods=['POST'])
def cmd():
    command = request.form.get("command")
    with open("/var/log/cmd_honeypot.log", "a") as logfile:
        logfile.write(f"{datetime.now()} - {command}\n")
    return "OK"
```

Is dit haalbaar?

Ja, zelfs heel eenvoudig.
Alles wat binnenkomt via een form POST kan je gewoon dumpen naar:

- een logfile
- een database
- syslog
- Elasticsearch/Grafana Loki

Zo heb je een volledig overzicht van alle gebruikte commando’s door aanvallers.

