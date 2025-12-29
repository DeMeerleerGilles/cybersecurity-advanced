# Verslag labo 3: Secure Shell (SSH)

## 1. Essentiële Elementen voor Juiste SSH-Configuratie

Om SSH correct en veilig te configureren, zijn de volgende elementen onmisbaar, met de nadruk op sleutelgebaseerde authenticatie:

| Element               | Locatie                                    | Functie                                                                                                                                                                                                                                                                                                                                                       |
| :-------------------- | :----------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Inloggen met Keys** | Client (Private Key) & Server (Public Key) | Maakt gebruik van een **cryptografisch sleutelpaar** (privé en openbaar) in plaats van een wachtwoord. De authenticatie is gebaseerd op cryptografie (wat je _hebt_), wat veel veiliger is dan op kennis (wat je _weet_).                                                                                                                                     |
| **`authorized_keys`** | Server: `~/.ssh/authorized_keys`           | Dit bestand op de externe server bevat de **publieke sleutels** van alle gebruikers die gemachtigd zijn om in te loggen op dat specifieke gebruikersaccount. De SSH-daemon controleert of de client de privé-sleutel bezit die overeenkomt met een van de opgeslagen publieke sleutels.                                                                       |
| **`known_hosts`**     | Client: `~/.ssh/known_hosts`               | Dit bestand op de client slaat de **hostsleutels** (publieke sleutels) op van alle servers waarmee u verbinding hebt gemaakt. Dit voorkomt **Man-in-the-Middle (MITM) aanvallen**, omdat de client de identiteit van de server kan verifiëren. Als de hostsleutel van een server onverwacht verandert, wordt de verbinding geweigerd en wordt u gewaarschuwd. |
| **SSH Client Config** | Client: `~/.ssh/config`                    | Dit lokale configuratiebestand maakt het mogelijk om aliassen en specifieke instellingen per host te definiëren. Dit vervangt lange commando's en maakt automatische verbindingen mogelijk. **Voorbeeld:**                                                                                                                                                    |

    ```
    Host web
        Hostname 192.168.1.50
        User deployer
        IdentityFile ~/.ssh/id_rsa_web
    ```
    Hiermee kunt u inloggen op de webserver met de verkorte opdracht `ssh web`.

---

## 2. Passphrase op Sleutel vs. Gebruiker/Wachtwoord

Het verschil in beveiliging ligt in de aard van de authenticatie:

-   **Gebruiker/Wachtwoord:** Dit is een authenticatie op basis van _kennis_. De veiligheid is volledig afhankelijk van de complexiteit van het wachtwoord en de resistentie tegen brute-force aanvallen.
-   **SSH-Sleutel (zonder Passphrase):** Authenticatie op basis van _bezit_ (de private key). De cryptografische sterkte (vaak 4096-bit) maakt het extreem veilig. Als de privésleutel echter wordt gestolen, heeft de aanvaller onmiddellijke toegang.
-   **Passphrase op Sleutel:** Dit combineert _bezit_ met _kennis_ en is de meest veilige methode. De passphrase **versleutelt** de private key op uw lokale schijf. Zelfs als een aanvaller uw private key-bestand weet te bemachtigen, is deze waardeloos zonder de passphrase om deze te decoderen. Dit fungeert als een vorm van **tweestapsbeveiliging** voor de sleutel zelf.

---

## 3. Jump/Bastion Host: Definitie en Bedrijfsgebruik

### Wat is een Jump/Bastion Host?

Een **Bastion Host** (of Jump Host/Jump Server) is een speciaal geconfigureerde en **geharde** server die fungeert als de enige, gecontroleerde toegangspoort tot een intern, beveiligd netwerk. Deze server bevindt zich meestal in een **DMZ (Demilitarized Zone)** en is het enige systeem in de beveiligde omgeving dat directe toegang heeft tot het onveilige netwerk (internet).

### Waarom zou een Bedrijf dit Gebruiken?

Een bedrijf gebruikt een Bastion Host voornamelijk om de **aanvalsperimeter** te verkleinen en de beveiliging te centraliseren:

1.  **Vermindering van het Aanvalsoppervlak (Reduced Attack Surface):** In plaats van tientallen of honderden applicatie- en databaseservers bloot te stellen aan het internet (elk met een open SSH-poort), hoeft slechts één server (de Bastion Host) publiek toegankelijk te zijn. Dit minimaliseert de potentiële ingangspunten voor aanvallers.
2.  **Gecentraliseerde Controle en Auditing:** Alle administratieve toegang (via SSH) verloopt via deze ene host. Dit maakt het mogelijk om elke verbinding, elke inlogsessie en elke uitgevoerde opdracht gedetailleerd te **loggen en te auditen**, wat essentieel is voor naleving (compliance).
3.  **Netwerksegmentatie:** Het fungeert als een vertrouwde tussenpersoon tussen het externe netwerk en de kritieke interne infrastructuur. De interne servers accepteren alleen verbindingen vanaf het IP-adres van de Bastion Host.

## 4. Verschil tussen Local en Remote Port Forwarding

Beide vormen van port forwarding creëren een **veilige, versleutelde tunnel** door een bestaande SSH-verbinding, maar ze werken in tegengestelde richtingen.

| Kenmerk              | Local Port Forwarding (Client-to-Server)                                                   | Remote Port Forwarding (Server-to-Client)                                                                |
| :------------------- | :----------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| **Commando Vlag**    | `-L` (Local)                                                                               | `-R` (Remote)                                                                                            |
| **Verkeersrichting** | Stuurt verkeer van een **lokale poort** naar een **externe bestemming** via de SSH-server. | Stuurt verkeer van een **externe poort** (op de SSH-server) naar een **lokale bestemming** op de client. |
| **Doel**             | Krijg toegang tot een externe dienst alsof deze lokaal draait.                             | Maak een lokale dienst extern toegankelijk.                                                              |

### Use Case: Local Port Forwarding (`-L`)

**Scenario:** U wilt veilig verbinding maken met een PostgreSQL-database (`DB-Server`) op poort `5432`. De `DB-Server` staat in een privénetwerk en is alleen bereikbaar via uw SSH-server (`SSH-Server`).

1.  **Commando:** `ssh -L 54320:DB-Server:5432 user@SSH-Server`
2.  **Verklaring:** De SSH-client opent lokale poort `54320`. Elk verkeer naar deze poort wordt versleuteld en door de SSH-tunnel gestuurd. De `SSH-Server` stuurt het verkeer vervolgens door naar `DB-Server` op poort `5432`.
3.  **Resultaat:** U kunt nu lokaal een databaseclient configureren om verbinding te maken met **`localhost:54320`**, wat veilig in de database op de externe server terechtkomt.

### Use Case: Remote Port Forwarding (`-R`)

**Scenario:** U heeft een webapplicatie op uw lokale laptop draaien op poort `8080` en u wilt een collega (`Collega-PC`) op afstand toegang geven om deze te testen, zonder uw lokale firewall aan te passen.

1.  **Commando:** `ssh -R 8080:localhost:8080 user@SSH-Server`
2.  **Verklaring:** De SSH-client vertelt de `SSH-Server` om poort `8080` te openen. Elk verkeer dat de `SSH-Server` op poort `8080` ontvangt, wordt versleuteld en door de SSH-tunnel naar de lokale laptop gestuurd, waar het wordt doorgestuurd naar `localhost:8080` (uw webapplicatie).
3.  **Resultaat:** Uw collega kan nu de webapplicatie testen door te navigeren naar **`SSH-Server:8080`**. De lokale dienst is tijdelijk extern bereikbaar.

---

## 5. Het SOCKS-Protocol en Gebruiksscenario

### Conceptueel: Wat is SOCKS?

**SOCKS (Socket Secure)**, met name SOCKS5, is een **algemeen proxyprotocol** dat fungeert op de **sessielaag** (OSI Laag 5).

In tegenstelling tot een HTTP-proxy, die alleen HTTP/HTTPS-verkeer kan interpreteren en doorsturen, is een SOCKS-proxy **protocol-agnostisch**. Dit betekent dat het elk type verkeer kan doorsturen (TCP en UDP), ongeacht het applicatieprotocol (web, e-mail, FTP, etc.).

SSH gebruikt SOCKS door middel van **Dynamic Port Forwarding (`-D`)**. Dit creëert een lokale SOCKS-server op de client, die vervolgens al het netwerkverkeer (van welke applicatie dan ook) dynamisch door de versleutelde SSH-tunnel naar de externe SSH-server stuurt.

### Voorbeeld en Wanneer het Interessant is

**Use Case: Volledig Versleutelde Netwerktoegang op Onveilig Netwerk**

SOCKS via SSH is interessant wanneer een gebruiker volledige, versleutelde netwerktoegang wil tot een veilige omgeving, zoals:

1.  **Browsen op een Openbare Wi-Fi Hotspot:** Een gebruiker op een onveilig openbaar Wi-Fi-netwerk wil voorkomen dat lokaal netwerkverkeer wordt afgeluisterd.
2.  **Geoblokkades Omzeilen:** Een gebruiker in land A wil toegang tot diensten die alleen beschikbaar zijn in land B.

**Actie (SSH-commando):**
`ssh -D 8888 user@remote_vps_in_land_B`

-   De SSH-client opent lokale poort `8888` en configureert deze als een SOCKS-proxyserver.
-   De gebruiker configureert vervolgens de netwerkinstellingen van zijn browser of besturingssysteem om alle verkeer via de SOCKS-proxy op `localhost:8888` te sturen.
-   **Resultaat:** Al het uitgaande netwerkverkeer van de gebruiker (inclusief DNS-verzoeken) wordt **versleuteld** door de SSH-tunnel gestuurd. De remote VPS handelt het verkeer af en voor de buitenwereld lijkt het alsof de gebruiker het IP-adres van de VPS gebruikt. Dit biedt zowel **versleuteling** als **IP-maskering** voor alle netwerkactiviteiten.

## Uitwerking labo

### SSH Client config

Ik begon met het kopieren van de publieke sleutel van mijn laptop naar alle verschillende VMs met het commando:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@172.30.20.50
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.10.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.4  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.15 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh vagrant@172.30.20.123 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Opmerking: later heb ik ook de public key van de companyrouter zelf gekopieerd naar dezelfde hosts zodat de router zonder wachtwoord naar de interne machines kan inloggen (handig voor automatische taken of wanneer de router tunnel-initiatie moet doen).

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
    User admin        # pas aan als gebruiker anders is (root, admin, etc.)
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

### SSH port forwarding:

Webserver forwarden naar poort 8080 van de host.

```bash
ssh companyrouter -L 8080:172.30.10.10:80
```

vragen: 
    Why is this an interesting approach from a security point-of-view?
    Het versleutelt verkeer tussen host en client, waardoor data veilig over onveilige netwerken kan worden gestuurd.
    When would you use local port forwarding?
    Om lokaal toegang te krijgen tot een service op een remote server die normaal niet direct bereikbaar is.
    When would you use remote port forwarding?
    Om lokaal toegang te krijgen tot een service op een remote server die normaal niet direct bereikbaar is.
    Which of the two are more "common" in security?
    Local port forwarding is vaker gebruikt.
    Some people call SSH port forwarding also a "poor man's VPN". Why?
    Omdat het verkeer kan tunnelen via SSH, vergelijkbaar met een VPN, zonder extra VPN-software te installeren.
