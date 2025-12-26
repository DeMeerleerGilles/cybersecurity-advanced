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
ProxyPassReverse "/aaa" "http://localhost:8000/"
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

Hierna installeerde ik Nginx op de isprouter:

```bash
sudo apk add nginx
```

Vervolgens configureerden we Nginx om als reverse proxy te fungeren en HTTPS te gebruiken. We bewerkten het configuratiebestand:

```bash
sudo vi /etc/nginx/nginx.conf
```

We starten de nginx service:

```bash
sudo rc-service nginx start
```

Om deze automatisch te laten starten bij het opstarten van de machine:

```bash
sudo rc-update add nginx default
```

Status controleren:

```bash
sudo rc-service nginx status
```

Nu maakten we de configuratie voor tls1.2 aan:

```bash
sudo vi /etc/nginx/http.d/ssl-tls12.conf
```

Met de volgende inhoud:

```nginx
server {
    listen 443 ssl;
    server_name www.cybersec.internal;

    ssl_certificate     /etc/ssl/certs/webserver.crt;
    ssl_certificate_key /etc/ssl/private/webserver.key;

    ssl_protocols TLSv1.2;
    ssl_ciphers RSA+AES256-SHA;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://172.30.10.10:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    return 301 https://$host$request_uri;
}
```

we doen nog een test en een restart van nginx:

```bash
sudo nginx -t
sudo rc-service nginx reload
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
