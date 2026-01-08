# Verslag labo 3: Secure Shell (SSH)

## SSH Client config

Ik begon met het kopiëren van de publieke sleutel van mijn laptop naar alle verschillende VMs met het commando:
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh vagrant@172.30.10.10 "cat >> .ssh/authorized_keys"

### What files are transferred to what machines?

De publieke sleutel van mijn laptop (~/.ssh/id_rsa.pub) is gekopieerd naar de authorized_keys bestanden van alle machines in het netwerk (webserver, database, dns, employee workstation, companyrouter).

De private key (~/.ssh/id_rsa) blijft op mijn laptop staan en wordt niet gekopieerd. Als deze sleutel zou lekken, zou iedereen die deze heeft toegang kunnen krijgen tot de machines waar de publieke sleutel is toegevoegd.

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@172.30.20.50
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.10.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.4  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.15 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.123 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Opmerking: later heb ik ook de public key van de companyrouter zelf gekopieerd naar dezelfde hosts zodat de router zonder wachtwoord naar de interne machines kan inloggen.

In de ssh/config van mijn windows laptop heb ik het volgende gezet zodat ik niet van alle machines het ip elke keer moest opzoeken:

```bash
# === Bastion / companyrouter ===
Host companyrouter
    HostName 192.168.62.253
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    Port 22
    ServerAliveInterval 60
    ForwardAgent no

# === DMZ / Webserver (via bastion) ===
Host web
    HostName 172.30.10.10
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ProxyJump companyrouter

# === Database (via bastion) ===
Host db
    HostName 172.30.20.15
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ProxyJump companyrouter

# === DNS (via bastion) ===
Host dns
    HostName 172.30.20.4
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ProxyJump companyrouter

# === Employee workstation (via bastion) ===
Host employee1
    HostName 172.30.20.123
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ProxyJump companyrouter

# === Kali (direct op 192.168.62.x netwerk) ===
Host kali
    HostName 192.168.62.110
    User vagrant
    IdentityFile ~/.ssh/id_rsa

# === ISP router (direct) ===
Host isprouter
    HostName 192.168.62.254
    User vagrant
    IdentityFile ~/.ssh/id_rsa

# === Shortcut: directe sessie naar companyrouter ===
Host companyrouter-ssh
    HostName 192.168.62.253
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
```

Hierna heb ik de verschillende ssh verbindingen uitgetest door vanaf mijn host

```bash
ssh db
ssh web
ssh companyrouter
...
```

Indien we dit nog extra veilig willen maken kunnen we een nieuwe gebruiker instellen naast de vagrant gebruiker. Ik schakelde ook de wachtwoord authenticatie uit in /etc/ssh/sshd_config door PasswordAuthentication op no te zetten.

### SSH port forwarding:

Webserver bekijken op je laptop Je stuurt poort 8080 op je laptop door naar poort 80 van de webserver via de router.

```bash
# Formule: ssh -L [lokale_poort]:[doel_ip]:[doel_poort] [bastion_host]
ssh -L 8080:172.30.10.10:80 companyrouter
```

Als we nu in onze browser naar localhost:8080 gaan, krijgen we de webpagina van de webserver te zien. We krijgen wel een error doordat er geen DNS server is ingesteld op mijn laptop die de site kent.

Database bereikbaar maken op de router Iemand op het 'fake internet' kan dan verbinden met de router op poort 3306 en wordt doorgezet naar de DB.

```bash
# Formule: ssh -R [poort_op_router]:[doel_ip]:[doel_poort] [bastion_host]
ssh -R 3306:172.30.20.15:3306 companyrouter
```

Je wilt je laptop zo instellen dat al je browserverkeer via de router loopt, zodat je alle interne IP-adressen direct kunt intypen.

```bash
ssh -D 9090 companyrouter
# Dan in je browser de proxy instellen op localhost:9090
```

## SSH Port Forwarding vragen

### Waarom is dit interessant vanuit security oogpunt?

Het stelt je in staat om firewall-restricties te omzeilen door verkeer te "tunnellen" door een reeds toegestane SSH-verbinding (meestal poort 22). Hierdoor kun je diensten bereiken die niet direct aan het internet zijn blootgesteld, wat zowel handig is voor beheer als voor aanvallers.

### Wanneer gebruik je Local Port Forwarding (-L)?

Wanneer je vanaf je lokale machine toegang wilt tot een dienst in het remote netwerk.

Voorbeeld: Je wilt de database op een interne server bekijken in een tool op je eigen laptop.

### Wanneer gebruik je Remote Port Forwarding (-R)?

Wanneer je een dienst op je lokale machine (of jouw netwerk) beschikbaar wilt maken voor de remote server.

Voorbeeld: Je wilt dat een server in de cloud tijdelijk toegang krijgt tot een webserver die op jouw laptop draait (vaak gebruikt bij malware C2-callbacks of het omzeilen van NAT).

### Welke is gebruikelijker in security?

Local Port Forwarding (-L) is de standaard voor systeembeheer en tunneling. Echter, in red teaming/hacking is Remote Port Forwarding (-R) cruciaal voor het opzetten van reverse shells en het exfiltreren van data vanuit afgeschermde netwerken.

### Waarom de "Poor man's VPN"?

Omdat SSH-tunneling een versleutelde verbinding (tunnel) creëert tussen twee netwerken zonder dat je complexe VPN-software (zoals OpenVPN of IPsec) hoeft te configureren. Het biedt encryptie en toegang tot interne resources, maar mist de geavanceerde routing- en managementfuncties van een echte VPN.