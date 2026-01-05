# Labo 6: CA HTTPS

Eerst moeten we de webserversoftware analyseren, we doen dit met de volgende commando's:

```bash
ps aux | egrep 'nginx|apache|httpd'
systemctl status httpd
```

What webserver software is being used on the webserver? (apache, nginx, iis, ...)
We zien dat httpd (Apache) draait.

How is the webserver configured as a reverse proxy? Where is this defined? What config file?
De reverse proxy is geconfigureerd in de httpd.conf file, deze bevindt zich in /etc/httpd/conf/httpd.conf.

Wat we hieruit kunnen afleiden:

```bash
ProxyPass "/services" "http://localhost:9200"
ProxyPassReverse "/services" "http://localhost:9200"
ProxyPass "/cmd" "http://localhost:8000/"
ProxyPassReverse "/cmd" "http://localhost:8000/"
ProxyPass "/assets" "http://localhost:8000/assets"
ProxyPassReverse "/assets" "http://localhost:8000/assets"
ProxyPass "/exec" "http://localhost:8000/exec"
ProxyPassReverse "/exec" "http://localhost:8000/exec"
```

/cmd and /services are both (systemd) services running on the webserver. In other words it is not the webserver software that is hosting this. What are the names of these (systemd) services, what programming languages are used and on what port is each service listening for incoming requests? Can you find the files that are needed by each of the services?

We kunnen de services vinden met het volgende commando:

```bash
systemctl list-units --type=service
```

De services zijn als volgt:

| Service Name           | Status | Description              | Port                | Language/Framework |
| ---------------------- | ------ | ------------------------ | ------------------- | ------------------ |
| httpd.service          | active | Apache HTTP Server       | 80/443 (HTTP/HTTPS) | Apache             |
| insecurewebapp.service | active | Java app (start script)  | 9200                | Java (app.jar)     |
| flaskapp.service       | failed | Flask app (start script) | 8000                | Python/Flask       |


De cmd service draait op poort 8000 en is geschreven in Python met het Flask framework. De /services service draait op poort 9200 en is geschreven in Java.

De bestanden voor de cmd service bevinden zich in /opt/flaskapp/ en voor de services service in /opt/insecurewebapp/.

## HTTPS

We gaan in dit labo onze isprouter configureren als een Certificate Authority (CA) en zorgen ervoor dat onze webserver HTTPS gebruikt. 

Eerst installeren we de benodigde pakketten op de alpine linux machine (isprouter):

```bash
apk add openssl ca-certificates
```

Vervolgens genereren we de private key voor onze CA:

```bash
openssl genrsa -out ca.key 4096
```

Hierna maken we het self-signed root certificate aan:

```bash
openssl req -x509 -new -nodes \
-key ca.key \
-sha256 -days 3650 \
-out ca.crt
```

We kunnen nu het certificaat bekijken:

```bash
openssl x509 -in ca.crt -noout -text
```

Nu genereren we de private key voor de webserver:

```bash
openssl genrsa -out webserver.key 2048
```

### CRS: Certificate Signing Request

We stellen eerst de SAN (Subject Alternative Name) configuratie in:

```bash
sudo vi san.cnf
```

Met de volgende inhoud:

```ini
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = www.cybersec.internal

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = www.cybersec.internal
DNS.2 = services.cybersec.internal
```

Vervolgens maken we de CSR aan:

```bash
openssl req -new \
-key webserver.key \
-out webserver.csr \
-config san.cnf
```

Nu ondertekenen we de CSR met onze CA om een certificaat voor de webserver te maken:

```bash
openssl x509 -req \
-in webserver.csr \
-CA ca.crt \
-CAkey ca.key \
-CAcreateserial \
-out webserver.crt \
-days 825 \
-sha256 \
-extfile san.cnf \
-extensions req_ext
```

Nu is ons webserver certificaat ondertekend door onze eigen CA.

Hierna paste ik de apache webserver aan om HTTPS te gebruiken.

```bash
sudo vi /etc/httpd/conf.d/ssl-tls12.conf
```

Met de volgende aanpassingen:

```apache
<VirtualHost *:443>
    ServerName www.cybersec.internal

    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/webserver.crt
    SSLCertificateKeyFile /etc/pki/tls/private/webserver.key

    SSLProtocol TLSv1.2
    SSLCipherSuite RSA+AES256-SHA
    SSLHonorCipherOrder on
    SSLSessionTickets off

    ProxyPass /cmd http://localhost:8000/
    ProxyPassReverse /cmd http://localhost:8000/

    ProxyPass /services http://localhost:9200/
    ProxyPassReverse /services http://localhost:9200/
</VirtualHost>

<VirtualHost *:80>
    ServerName www.cybersec.internal
    Redirect permanent / https://www.cybersec.internal/
</VirtualHost>
```

We testen de configuratie en herstarten apache:

```bash
sudo apachectl configtest
sudo systemctl restart httpd
```

Na een dig test zien we dat alles correct is ingesteld:

```bash
──(vagrant㉿red)-[~/Desktop]
└─$ dig www.cybersec.internal

; <<>> DiG 9.20.11-4+b1-Debian <<>> www.cybersec.internal
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 17112
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: ac079fe1330aa15601000000695131f40832601b90735ef3 (good)
;; QUESTION SECTION:
;www.cybersec.internal.         IN      A

;; ANSWER SECTION:
www.cybersec.internal.  86400   IN      A       172.30.10.10

;; Query time: 4 msec
;; SERVER: 172.30.20.4#53(172.30.20.4) (UDP)
;; WHEN: Sun Dec 28 08:34:46 EST 2025
;; MSG SIZE  rcvd: 94

```

Hierna kopieerde ik de certificaten en sleutels naar de juiste locaties op de isprouter:

```bash
sudo mkdir -p /etc/ssl/certs
sudo mkdir -p /etc/ssl/private
```

```bash
isprouter:~$ sudo cp ~/webserver.crt /etc/ssl/certs/
sudo cp ~/webserver.key /etc/ssl/private/
```

```bash
isprouter:~$ sudo chown root:root /etc/ssl/certs/webserver.crt /etc/ssl/private/webserver.key
sudo chmod 644 /etc/ssl/certs/webserver.crt
sudo chmod 600 /etc/ssl/private/webserver.key
```

Op de isp router moest ik ook nog het verkeer toestaan in de firewall:

```bash
sudo nft add rule inet filter input tcp dport 443 accept
sudo nft add rule inet filter input tcp dport 80 accept
```

Hierna is de website bereikbaar via HTTPS:

![alt text](<img/Schermafbeelding 2025-12-26 173416.png>)

CA trusten op de kali machine:

Om de CA te trusten op de kali machine, kopieerde ik het ca.crt bestand naar de kali machine en voegde ik het toe aan de vertrouwde certificaten:

```bash
sudo cp ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

We zien nu een mooi slotje in de browser:

![alt text](<img/Schermafbeelding 2025-12-26 175349.png>)

## Wireshark capture

Om het verkeer met wireshark te bekijken hebben we nood aan de private key van de webserver. We importeren deze in wireshark.


![alt text](<img/Schermafbeelding 2025-12-28 143408.png>)

## HTTPS TLS 1.3

Om TLS 1.3 te configureren, maakte ik een nieuwe private key aan op de isprouter:

```bash
openssl genrsa -out webserver_tls13.key 2048
```

Vervolgens maakte ik een nieuwe CSR aan:

```bash
openssl req -new \
-key webserver_tls13.key \
-out webserver_tls13.csr \
-config san.cnf
```
Hierna ondertekende ik de CSR met onze CA om een certificaat voor TLS 1.3 te maken:

```bash
openssl x509 -req \
-in webserver_tls13.csr \
-CA ca.crt \
-CAkey ca.key \
-CAcreateserial \
-out webserver_tls13.crt \
-days 825 \
-sha256 \
-extfile san.cnf \
-extensions req_ext
```

Ik plaatste alles in de juiste mappen:

```bash
# Certificaten verplaatsen naar de juiste map
sudo cp webserver_tls13.crt /etc/ssl/certs/
sudo cp webserver_tls13.key /etc/ssl/private/

# Permissies correct instellen
sudo chown root:root /etc/ssl/certs/webserver_tls13.crt /etc/ssl/private/webserver_tls13.key
sudo chmod 644 /etc/ssl/certs/webserver_tls13.crt
sudo chmod 600 /etc/ssl/private/webserver_tls13.key
```

Op de webserver paste ik de apache configuratie aan om TLS 1.3 te gebruiken:

```bash
sudo vi /etc/httpd/conf.d/ssl-tls13.conf
```

Met de volgende inhoud:

```apache
<VirtualHost *:443>
    ServerName www.cybersec.internal

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/webserver_tls13.crt
    SSLCertificateKeyFile /etc/ssl/private/webserver_tls13.key

    SSLProtocol TLSv1.3
    # Cipher suites voor TLS 1.3 worden automatisch gekozen
    # Je hoeft SSLCipherSuite niet aan te passen tenzij je wil beperken

    ProxyPass /cmd http://localhost:8000/
    ProxyPassReverse /cmd http://localhost:8000/

    ProxyPass /services http://localhost:9200/
    ProxyPassReverse /services http://localhost:9200/
</VirtualHost>

<VirtualHost *:80>
    ServerName www.cybersec.internal
    Redirect permanent / https://www.cybersec.internal/
</VirtualHost>
```

Hierna testte ik de configuratie en herstartte ik apache:

```bash
sudo apachectl configtest
sudo systemctl restart httpd
```

We kunnen nu controleren of TLS 1.3 actief is met het volgende commando:

```bash
[vagrant@web ~]$ openssl s_client -connect www.cybersec.internal:443 -tls1_3
Connecting to 127.0.2.1
CONNECTED(00000003)
40C7904F467F0000:error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:ssl/record/rec_layer_s3.c:916:SSL alert number 70
---
no peer certificate available
---
No client certificate CA names sent
Negotiated TLS1.3 group: <NULL>
---
SSL handshake has read 7 bytes and written 262 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
Protocol: TLSv1.3
This TLS version forbids renegotiation.
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
```

We zien dat TLSv1.3 actief is.

## SSLKEYLOGFILE

SSLKEYLOGFILE laat een client (browser) de gebruikte sessiesleutels wegschrijven naar een bestand zodat tools zoals Wireshark HTTPS-verkeer kunnen ontsleutelen, zelfs bij TLS 1.3.

We kunnen dit op onze kali machine doen door de volgende stappen te volgen:

Eerst killen we alle open browsers:

```bash
pkill firefox
```

Vervolgens stellen we de omgevingsvariabele in:

```bash
export SSLKEYLOGFILE=/home/kali/sslkeys.log
```

Nu starten we de browser vanuit dezelfde terminal:

```bash
firefox &
```

We bezoeken de website:

Afbeelding van de website met HTTPS

We sluiten de browser en stellen het bestand met de sessiesleutels veilig:

```bash
cp ~/sslkeys.log ~/sslkeys_copy.log

```
Helaas heb ik dit niet kunnen exporteren naar het bestand; ik kreeg steeds een leeg bestand.

```bash
┌──(vagrant㉿red)-[~/Desktop]
└─$ Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.

[1]  + terminated  firefox https://www.cybersec.internal
┌──(vagrant㉿red)-[~/Desktop]
└─$ ls -l /home/vagrant/Desktop/sslkeys.log

ls: cannot access '/home/vagrant/Desktop/sslkeys.log': No such file or directory
                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ echo $HOME

/home/vagrant
                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ pkill -9 firefox

                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ touch /home/vagrant/Desktop/sslkeys.log
chmod 600 /home/vagrant/Desktop/sslkeys.log
ls -l /home/vagrant/Desktop/sslkeys.log

-rw------- 1 vagrant vagrant 0 Dec 28 09:22 /home/vagrant/Desktop/sslkeys.log
                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ SSLKEYLOGFILE=/home/vagrant/Desktop/sslkeys.log firefox https://www.cybersec.internal &

[1] 34246
                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ pkill firefox

                                                                                                                                                                                                                                           
┌──(vagrant㉿red)-[~/Desktop]
└─$ Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.
Exiting due to channel error.

[1]  + terminated  SSLKEYLOGFILE=/home/vagrant/Desktop/sslkeys.log firefox 
┌──(vagrant㉿red)-[~/Desktop]
└─$ ls -l /home/vagrant/Desktop/sslkeys.log
head /home/vagrant/Desktop/sslkeys.log

-rw------- 1 vagrant vagrant 0 Dec 28 09:22 /home/vagrant/Desktop/sslkeys.log
```

## Vragen bij het labo:

Does the CA uses a private key?

De CA gebruikt een private key, deze is gegenereerd met het commando `openssl genrsa -out ca.key 4096`.

Does the CA uses a certificate?

De CA gebruikt een self-signed certificate, deze is gegenereerd met het commando `openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt`.

Does the web server uses a private key?

De webserver gebruikt een private key, deze is gegenereerd met het commando `openssl genrsa -out webserver.key 2048`.

Does the web server uses a certificate?

De webserver gebruikt een certificate, dit is gegenereerd met het commando `openssl x509 -req -in webserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out webserver.crt -days 825 -sha256 -extfile san.cnf -extensions req_ext`.

When using openssl commands to generate files, are you able to easily spot the function/goal of each file?

Ja, de functie/goal van elk bestand kan worden afgeleid uit de naam en het type van het bestand. Bijvoorbeeld:
- ca.key: private key van de Certificate Authority
- ca.crt: self-signed certificate van de Certificate Authority
- webserver.key: private key van de webserver
- webserver.csr: Certificate Signing Request van de webserver

How can you view a certificate using openssl?

Je kunt een certificate bekijken met het commando `openssl x509 -in <certificate_file> -noout -text`.

Does the webserver need a specific configuration change to allow HTTPS traffic?

Ja, de webserver moet worden geconfigureerd om HTTPS verkeer toe te staan. Dit omvat het instellen van de juiste poort (meestal 443) en het specificeren van de locaties van het certificaat en de private key in de webserver configuratiebestanden.

What is meant by a CSR? 
Tip: Do not forget the SAN (Subject Alternative Name) attribute!

Een certificate signing request (CSR) is een gecodeerd bericht dat wordt verzonden naar een Certificate Authority om een digitaal certificaat aan te vragen. Het bevat informatie zoals de openbare sleutel, organisatiegegevens en de domeinnaam waarvoor het certificaat wordt aangevraagd.

De SAN (Subject Alternative Name) is een extensie in het certificaat die extra domeinnamen of IP-adressen specificeert waarvoor het certificaat geldig is. Dit is belangrijk voor het ondersteunen van meerdere domeinen of subdomeinen met één certificaat.

What is a wildcard certificate?

Een wildcard certificate is een type SSL/TLS-certificaat dat kan worden gebruikt om meerdere subdomeinen van een hoofddomein te beveiligen met één enkel certificaat. Het wordt aangeduid met een asterisk (*) in de domeinnaam, bijvoorbeeld *.example.com, wat betekent dat het certificaat geldig is voor alle subdomeinen van example.com, zoals www.example.com, mail.example.com, enzovoort.

What file(s) did you add to the browser (or computer) and how?

Om de CA-certificaat toe te voegen aan de browser of computer, heb ik het bestand `ca.crt` geïmporteerd in de vertrouwde rootcertificaten van het besturingssysteem of de browserinstellingen.

Can you easily retrieve your certificates after adding them?

Ja, nadat de certificaten zijn toegevoegd, kunnen ze gemakkelijk worden opgehaald via de certificaatbeheerder van het os of de browser.

Can you review and explain all the files from the OpenVPN lab (see later on in this course) and what they represent? CA? Keys? Certificates?

Ja, in het OpenVPN-labo zijn er verschillende bestanden die elk een specifieke rol spelen:
- ca.crt: Dit is het certificaat van de Certificate Authority (CA) die wordt gebruikt om de identiteit van de VPN-server en -client te verifiëren.
- server.crt: Dit is het certificaat van de VPN-server, ondertekend door de CA.
- server.key: Dit is de private key van de VPN-server, die geheim moet worden gehouden.
- client.crt: Dit is het certificaat van de VPN-client, ondertekend door de CA.