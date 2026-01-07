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

cd /etc/httpd/conf.d/

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
# Verplaats deze regels naar de bovenkant (buiten de VirtualHost)
SSLSessionCache shmcb:/var/cache/httpd/ssl_scache(512000)
SSLSessionCacheTimeout 300
Listen 443 https

<VirtualHost *:443>
    ServerName www.cybersec.internal

    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/webserver_tls13.crt
    SSLCertificateKeyFile /etc/pki/tls/private/webserver_tls13.key

    # TLS configuratie: TLSv1.2 + TLSv1.3
    SSLProtocol -all TLSv1.3

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
depth=0 CN=www.cybersec.internal
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN=www.cybersec.internal
verify error:num=21:unable to verify the first certificate
verify return:1
depth=0 CN=www.cybersec.internal
verify return:1
---
Certificate chain
 0 s:CN=www.cybersec.internal
   i:C=BE, ST=Vlaanderen, L=Gent, O=HOGENT, CN=cybersec.internal
   a:PKEY: RSA, 2048 (bit); sigalg: sha256WithRSAEncryption
   v:NotBefore: Dec 28 13:50:05 2025 GMT; NotAfter: Apr  1 13:50:05 2028 GMT
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIEjTCCAnWgAwIBAgIUEllrsujVPdc7jLhc4FcGBfcUgqIwDQYJKoZIhvcNAQEL
BQAwXjELMAkGA1UEBhMCQkUxEzARBgNVBAgMClZsYWFuZGVyZW4xDTALBgNVBAcM
BEdlbnQxDzANBgNVBAoMBkhPR0VOVDEaMBgGA1UEAwwRY3liZXJzZWMuaW50ZXJu
YWwwHhcNMjUxMjI4MTM1MDA1WhcNMjgwNDAxMTM1MDA1WjAgMR4wHAYDVQQDDBV3
d3cuY3liZXJzZWMuaW50ZXJuYWwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQCsjGzKWm7Vq6XdDlveMbtokQur0VCYjxngfOTwmwKXZgTenGR1Iuw2E+ti
IXjxuopFv+LNAzKhwJMtoi4VBVhaTx7x/Vd8C+JJGaWfuF2xBf/WHHUn9Fp0AbYD
3rGtGcFsgYTNLxG3yw4MlgHLjLTU+AehUgEvl9QAVr5FA0rzWJbXNfj7DdUSZ5I5
C4WlEKeH5PIwZveX/1cljuULUxc+yxR9dxf7/5ymEfJIpdE1HUNg9fLD4yt+qjXo
VwB/qhXUp/bcKTaT8yhjzX+8iFtwC5EM+rq6dpzTMhdlCAMCzPP55pa2AWSqo+VV
L02WL1GQuKPCwvXkPSNW50ARoZB/AgMBAAGjgYAwfjA8BgNVHREENTAzghV3d3cu
Y3liZXJzZWMuaW50ZXJuYWyCGnNlcnZpY2VzLmN5YmVyc2VjLmludGVybmFsMB0G
A1UdDgQWBBQcMf3A4gk+8hrzMMBAfZFTqwgH1jAfBgNVHSMEGDAWgBSYljRjAG4X
hfk7uv5KS3imPIbEkTANBgkqhkiG9w0BAQsFAAOCAgEAGtVpINlyNSFnTEky71bc
q5o1xXdIsDW1pwquwOG5BLsV68Cm51WzVgYKFX+O06wkGdVZ/xpsEtwaKOpcg6wh
VllvN994B1nC2Y4/6xfMSgUrqlt/uDVAaGUiO9JVHOW+dWlWg2Er3uUrKKpnpaEq
d/qhbZ1XJG9kWraRC/tlFoLvutuidUq2O6YKdUPSHw4a+RvmZZbqkf2wIEOZFkcN
shp5G20qtMvu/Hu20Vnh2OGNiNGcNM7dc1JfHnJLCAhlDMceKzPox8UyyUfXAjKn
YfeusWJq+yBNtXAC9CzFnbijmdF/PIaBmli0ujrStumldzlYVJNJnj8Pb7uw482A
ri09b9KnhoEqiRQXSTfw9ffUyTRAU7t95VglPGOFw3JpnVhKh/eyVNOG25G7A2N6
YHlCefmOAq2E29l3wVb0llZQ3TRMX5Pngsy8YVaowiZAmlSFisHvZsjNJQSyYsgY
dSEb3acQjumNJ3rqA0y0Jpt3WEBV8xx3J8jHZOAEtvEjAXPE+tlI8TgK45Tldlor
QORTGxQOoyZOQnQmC+dFEdeybVdNUueb95nb/I2lNT513TkHc9MaJSTg8x/uOM90
QfajqMlaBnlWeJs9dHuCxl8Vgv8xsOlGTBCBTr6RLRUH0SOniQBuGsE+kTFv2Bgy
xh4rHqQxP1AOD/9FhMzqui0=
-----END CERTIFICATE-----
subject=CN=www.cybersec.internal
issuer=C=BE, ST=Vlaanderen, L=Gent, O=HOGENT, CN=cybersec.internal
---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: rsa_pss_rsae_sha256
Peer Temp Key: X25519, 253 bits
---
SSL handshake has read 1729 bytes and written 342 bytes
Verification error: unable to verify the first certificate
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Protocol: TLSv1.3
Server public key is 2048 bit
This TLS version forbids renegotiation.
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 21 (unable to verify the first certificate)
---
---
Post-Handshake New Session Ticket arrived:
SSL-Session:
    Protocol  : TLSv1.3
    Cipher    : TLS_AES_256_GCM_SHA384
    Session-ID: 2C6BF10FD69EE91CC0432538FF34C7C8408477270C15E86089DD4F7563DDA006
    Session-ID-ctx:
    Resumption PSK: D288DCF9A2DFAE1DA80E27D003ABA85CA44057F2698CF8B12A1F9C2AEF857417AFD6A953B88A486708236A7F3D99B1FA
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - 2a 78 80 03 bf 8d 1a f2-b9 3c e2 2a 4b 75 52 0f   *x.......<.*KuR.
    0010 - 0b b3 61 a5 d2 b0 58 7a-64 d5 9b f4 d7 88 29 36   ..a...Xzd.....)6
    0020 - 05 16 2e 8f fe a9 12 c5-ac 9d 54 89 a4 6e 31 56   ..........T..n1V
    0030 - 4e 7d 88 f4 7e a1 91 21-e3 79 95 cd dd f2 a9 0b   N}..~..!.y......
    0040 - 18 84 0c a0 70 e3 0b 72-93 a8 2e b9 e5 25 f9 91   ....p..r.....%..
    0050 - 94 77 d0 41 77 e4 5a 27-92 5c d2 73 9b 63 9c ad   .w.Aw.Z'.\.s.c..
    0060 - 4e f6 db 23 ba 19 2b 99-3a 8f bd 27 cd b8 8f 25   N..#..+.:..'...%
    0070 - 65 7e 61 6e ce 44 b1 bb-4a e8 37 71 0f 06 f9 12   e~an.D..J.7q....
    0080 - f0 57 6c 88 32 06 35 a9-79 16 7f 3a 02 e5 f3 ff   .Wl.2.5.y..:....
    0090 - b4 d1 6a 19 fa c4 00 9b-94 b6 3b e1 af 2b c4 ee   ..j.......;..+..
    00a0 - 75 bf f7 c4 5b 81 4c d5-59 09 8b 76 36 d2 5a 9b   u...[.L.Y..v6.Z.
    00b0 - 90 e2 ea 4c bd e5 c4 37-fe 0b 6c 18 d6 4a 9e da   ...L...7..l..J..
    00c0 - c5 cb 2d 0f 9c 91 1a 9d-cc ea e3 27 cb 31 d2 5f   ..-........'.1._
    00d0 - c4 0a e1 99 5d a8 4a 35-04 f1 a7 ac 99 44 71 74   ....].J5.....Dqt
    00e0 - b5 c5 e4 e8 82 d2 0d c5-6c 11 79 c2 92 e0 ba fc   ........l.y.....
    00f0 - 7c 9d 67 d8 f4 3d 36 ac-d8 d2 45 72 ea 02 88 2e   |.g..=6...Er....

    Start Time: 1767686388
    Timeout   : 7200 (sec)
    Verify return code: 21 (unable to verify the first certificate)
    Extended master secret: no
    Max Early Data: 0
---
read R BLOCK
---
Post-Handshake New Session Ticket arrived:
SSL-Session:
    Protocol  : TLSv1.3
    Cipher    : TLS_AES_256_GCM_SHA384
    Session-ID: DD46246CF2004F948DDE738278ADF5B9E68847E983A3E35B6CF037D3CF2134D4
    Session-ID-ctx:
    Resumption PSK: EC4762BFECACF508E4B72897AE974B798A524E2031FA2C9A9C1F1F8A8F1BBC9148D7EBE37C258A0E7EFEACF99859C12F
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - 2a 78 80 03 bf 8d 1a f2-b9 3c e2 2a 4b 75 52 0f   *x.......<.*KuR.
    0010 - 29 22 d1 92 98 ec 8c 51-41 f2 3c 52 8d 73 d5 5b   )".....QA.<R.s.[
    0020 - 9b 84 f3 e4 1c 0a 44 d6-3a 83 a8 06 d4 35 07 44   ......D.:....5.D
    0030 - 75 88 e3 23 4f 0a 31 db-0f 38 34 0d 62 35 01 13   u..#O.1..84.b5..
    0040 - 46 63 e4 83 60 ad 85 51-2b 4d d9 f6 3c 98 12 f1   Fc..`..Q+M..<...
    0050 - 3b 8c 8e 34 96 f9 5e c0-bb f3 97 df 7d 5a 3f 13   ;..4..^.....}Z?.
    0060 - b2 f4 ab ff 36 dd 63 bd-e6 12 60 7b fc bd ee ba   ....6.c...`{....
    0070 - d5 f1 ea c9 a8 00 f4 02-72 47 d1 03 cc 92 dc 3d   ........rG.....=
    0080 - 70 3d f2 d0 8f a3 0d 31-ea 98 12 0b 17 49 dc 18   p=.....1.....I..
    0090 - d2 c6 07 d7 8d be 70 b3-53 d6 74 4f a0 d4 02 f1   ......p.S.tO....
    00a0 - 32 2b 81 7f f2 96 85 92-62 04 43 ff 7b 59 5a ac   2+......b.C.{YZ.
    00b0 - 31 c6 97 f6 7f cf db c2-4e 02 ca 4a 11 d9 af 51   1.......N..J...Q
    00c0 - cd d5 d6 bb 36 41 29 3e-ca aa d1 8b 69 e1 34 7d   ....6A)>....i.4}
    00d0 - f9 e0 62 de 45 22 6f b7-93 ed 08 de bc f2 31 a2   ..b.E"o.......1.
    00e0 - ae 21 c9 bb 60 71 e5 65-60 24 83 74 ca cc 34 0a   .!..`q.e`$.t..4.
    00f0 - 7d 44 ed ba 97 b1 33 5c-a4 b8 f1 f3 a9 00 07 2e   }D....3\........

    Start Time: 1767686388
    Timeout   : 7200 (sec)
    Verify return code: 21 (unable to verify the first certificate)
    Extended master secret: no
    Max Early Data: 0
---
read R BLOCK
closed
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