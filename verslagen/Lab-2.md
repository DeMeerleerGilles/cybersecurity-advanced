# Verslag labo 2 firewalls

Op het domein: http://www.cybersec.internal/cmd draait een terminal sessie.

Commandos die ik heb uitgevoerd met hun resultaten:

1. `id`
    - Resultaat: `uid=0(root) gid=0(root) groups=0(root) context=system_u:system_r:unconfined_service_t:s0`
2. `uname -a`
    - Resultaat: `Linux web 5.14.0-570.12.1.el9_6.x86_64 #1 SMP PREEMPT_DYNAMIC Tue May 13 06:11:55 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux`
3. `ls -la`
    - Resultaat: Lijst van bestanden en mappen in de huidige directory met gedetailleerde informatie.

```bash
total 28
dr-xr-xr-x.  19 root    root     250 Sep 26 13:45 .
dr-xr-xr-x.  19 root    root     250 Sep 26 13:45 ..
dr-xr-xr-x.   2 root    root       6 Oct  2  2024 afs
lrwxrwxrwx.   1 root    root       7 Oct  2  2024 bin -> usr/bin
dr-xr-xr-x.   5 root    root    4096 May 22 13:03 boot
drwxr-xr-x.  18 root    root    3120 Oct 14 10:38 dev
drwxr-xr-x. 102 root    root    8192 Oct 14 10:38 etc
drwxr-xr-x.   3 root    root      21 May 22 13:04 home
lrwxrwxrwx.   1 root    root       7 Oct  2  2024 lib -> usr/lib
lrwxrwxrwx.   1 root    root       9 Oct  2  2024 lib64 -> usr/lib64
drwxr-xr-x.   2 root    root       6 Oct  2  2024 media
drwxr-xr-x.   2 root    root       6 Oct  2  2024 mnt
drwxr-xr-x.   5 root    root      73 Sep 26 14:18 opt
dr-xr-xr-x. 196 root    root       0 Oct 14 10:38 proc
dr-xr-x---.   4 root    root     117 Sep 26 14:17 root
drwxr-xr-x.  28 root    root     900 Oct 14 10:38 run
lrwxrwxrwx.   1 root    root       8 Oct  2  2024 sbin -> usr/sbin
drwxr-xr-x.   2 root    root       6 Oct  2  2024 srv
dr-xr-xr-x.  13 root    root       0 Oct 14 10:38 sys
drwxrwxrwt.  12 root    root    4096 Oct 14 10:38 tmp
drwxr-xr-x.  12 root    root     144 May 22 13:01 usr
drwxrwxrwx.   1 vagrant vagrant 4096 Oct  6 12:37 vagrant
drwxr-xr-x.  20 root    root    4096 Sep 26 14:17 var
```

4. `cat /etc/passwd`
    - Resultaat: Lijst van gebruikersaccounts op het systeem.

```bash
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
nobody:x:65534:65534:Kernel Overflow User:/:/sbin/nologin
systemd-coredump:x:999:999:systemd Core Dumper:/:/sbin/nologin
dbus:x:81:81:System message bus:/:/sbin/nologin
tss:x:59:59:Account used for TPM access:/:/usr/sbin/nologin
sssd:x:998:998:User for sssd:/:/sbin/nologin
chrony:x:997:997:chrony system user:/var/lib/chrony:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/usr/share/empty.sshd:/usr/sbin/nologin
vagrant:x:1000:1000::/home/vagrant:/bin/bash
rpc:x:32:32:Rpcbind Daemon:/var/lib/rpcbind:/sbin/nologin
polkitd:x:996:995:User for polkitd:/:/sbin/nologin
rpcuser:x:29:29:RPC Service User:/var/lib/nfs:/sbin/nologin
tcpdump:x:72:72::/:/sbin/nologin
vboxadd:x:995:1::/var/run/vboxadd:/bin/false
rtkit:x:172:172:RealtimeKit:/:/sbin/nologin
apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin
pipewire:x:994:992:PipeWire System Daemon:/run/pipewire:/usr/sbin/nologin
geoclue:x:993:991:User for geoclue:/var/lib/geoclue:/sbin/nologin
flatpak:x:992:990:Flatpak system helper:/:/usr/sbin/nologin
```

### Nmap default scan

Ik heb een nmap default scan uitgevoerd op alle machines in het netwerk met het commando:

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -v 172.30.20.0/24
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 04:44 EST
Initiating Ping Scan at 04:44
Scanning 256 hosts [4 ports/host]
Completed Ping Scan at 04:45, 3.55s elapsed (256 total hosts)
Initiating Parallel DNS resolution of 4 hosts. at 04:45
Completed Parallel DNS resolution of 4 hosts. at 04:45, 0.00s elapsed
Nmap scan report for 172.30.20.0 [host down]
Nmap scan report for 172.30.20.1 [host down]
Nmap scan report for 172.30.20.2 [host down]
Nmap scan report for 172.30.20.3 [host down]
Nmap scan report for 172.30.20.255 [host down]
Initiating SYN Stealth Scan at 04:45
Scanning 4 hosts [1000 ports/host]
Discovered open port 3306/tcp on 172.30.20.15
Discovered open port 53/tcp on 172.30.20.4
Discovered open port 22/tcp on 172.30.20.15
Discovered open port 22/tcp on 172.30.20.123
Discovered open port 111/tcp on 172.30.20.254
Discovered open port 22/tcp on 172.30.20.4
Discovered open port 22/tcp on 172.30.20.254
Discovered open port 2222/tcp on 172.30.20.254
Completed SYN Stealth Scan against 172.30.20.15 in 0.16s (3 hosts left)
Completed SYN Stealth Scan against 172.30.20.123 in 0.16s (2 hosts left)
Completed SYN Stealth Scan against 172.30.20.4 in 0.17s (1 host left)
Completed SYN Stealth Scan at 04:45, 0.17s elapsed (4000 total ports)
Nmap scan report for 172.30.20.4
Host is up (0.00033s latency).
Not shown: 998 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh
53/tcp open  domain

Nmap scan report for 172.30.20.15
Host is up (0.00064s latency).
Not shown: 998 closed tcp ports (reset)
PORT     STATE SERVICE
22/tcp   open  ssh
3306/tcp open  mysql

Nmap scan report for 172.30.20.123
Host is up (0.00065s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh

Nmap scan report for 172.30.20.254
Host is up (0.00020s latency).
Not shown: 997 closed tcp ports (reset)
PORT     STATE SERVICE
22/tcp   open  ssh
111/tcp  open  rpcbind
2222/tcp open  EtherNetIP-1

Read data files from: /usr/share/nmap
Nmap done: 256 IP addresses (4 hosts up) scanned in 3.82 seconds
           Raw packets sent: 6021 (252.748KB) | Rcvd: 4012 (160.620KB)
```

Banner grab scan:

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -sV -p 22,53,80,3306,8000 172.30.20.0/24
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 04:48 EST
Nmap scan report for 172.30.20.4
Host is up (0.00062s latency).

PORT     STATE  SERVICE  VERSION
22/tcp   open   ssh      OpenSSH 9.3 (protocol 2.0)
53/tcp   open   domain   ISC BIND 9.18.37
80/tcp   closed http
3306/tcp closed mysql
8000/tcp closed http-alt

Nmap scan report for 172.30.20.15
Host is up (0.00046s latency).

PORT     STATE  SERVICE  VERSION
22/tcp   open   ssh      OpenSSH 9.3 (protocol 2.0)
53/tcp   closed domain
80/tcp   closed http
3306/tcp open   mysql    MariaDB 5.5.5-10.11.11
8000/tcp closed http-alt

Nmap scan report for 172.30.20.123
Host is up (0.00068s latency).

PORT     STATE  SERVICE  VERSION
22/tcp   open   ssh      OpenSSH 9.3 (protocol 2.0)
53/tcp   closed domain
80/tcp   closed http
3306/tcp closed mysql
8000/tcp closed http-alt

Nmap scan report for 172.30.20.254
Host is up (0.00040s latency).

PORT     STATE  SERVICE  VERSION
22/tcp   open   ssh      OpenSSH 9.2p1 Debian 2+deb12u3 (protocol 2.0)
53/tcp   closed domain
80/tcp   closed http
3306/tcp closed mysql
8000/tcp closed http-alt
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 256 IP addresses (4 hosts up) scanned in 9.87 seconds
```

Scan op de database server:

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -sV -sC 172.30.20.15
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 04:47 EST
Nmap scan report for 172.30.20.15
Host is up (0.00068s latency).
Not shown: 998 closed tcp ports (reset)
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 9.3 (protocol 2.0)
| ssh-hostkey: 
|   256 a6:f5:68:ed:ff:72:b1:c8:50:a0:62:ad:57:fa:08:2d (ECDSA)
|_  256 75:99:6b:07:14:ee:04:6b:20:a8:05:60:32:14:03:d8 (ED25519)
3306/tcp open  mysql   MariaDB 5.5.5-10.11.11
| mysql-info: 
|   Protocol: 10
|   Version: 5.5.5-10.11.11-MariaDB
|   Thread ID: 4
|   Capabilities flags: 63486
|   Some Capabilities: FoundRows, LongColumnFlag, IgnoreSpaceBeforeParenthesis, ODBCClient, Speaks41ProtocolNew, Support41Auth, Speaks41ProtocolOld, InteractiveClient, DontAllowDatabaseTableColumn, ConnectWithDatabase, SupportsTransactions, IgnoreSigpipes, SupportsLoadDataLocal, SupportsCompression, SupportsMultipleResults, SupportsMultipleStatments, SupportsAuthPlugins
|   Status: Autocommit
|   Salt: 48^San)|Vy!2w$K+6l@9
|_  Auth Plugin Name: mysql_native_password

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 5.79 seconds
```

Er draait een MySQL 5.5.5-10.11.11-MariaDB server op de database server.

### Brute force van de database server

Try to search for a nmap script to brute-force the database. Another (even easier tool) is called hydra (https://github.com/vanhauser-thc/thc-hydra). Search online for a good wordlist. For example "rockyou" or https://github.com/danielmiessler/SecLists We suggest to try the default username of the database software and attack the database machine. Another interesting username worth a try is "toor".

Ik gebruikte het volgende commando:

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -p 3306 --script mysql-brute --script-args userdb=/usr/share/wordlists/nmap.lst,passdb=/usr/share/wordlists/rockyou.txt 172.30.20.15
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 04:55 EST
Nmap scan report for 172.30.20.15
Host is up (0.00077s latency).

PORT     STATE SERVICE
3306/tcp open  mysql
| mysql-brute: 
|   Accounts: No valid accounts found
|   Statistics: Performed 201204 guesses in 247 seconds, average tps: 840.2
|_  ERROR: The service seems to have failed or is heavily firewalled...

Nmap done: 1 IP address (1 host up) scanned in 263.89 seconds                                                              
```
Het lukt niet om in te breken op de database server met de gebruikte lijsten.

Ik probeerde ook met hydra, hierbij kreeg ik echter een ban door mysql:

```bash
└─$ hydra -l root -P /usr/share/wordlists/rockyou.txt 172.30.20.15 mysql

Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2026-01-08 03:52:01
[INFO] Reduced number of tasks to 4 (mysql does not like many parallel connections)
[DATA] max 4 tasks per 1 server, overall 4 tasks, 14344398 login tries (l:1/p:14344398), ~3586100 tries per task
[DATA] attacking mysql://172.30.20.15:3306/
[STATUS] 6629.00 tries/min, 6629 tries in 00:01h, 14337769 to do in 36:03h, 4 active
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
[ERROR] Host '192.168.62.110' is blocked because of many connection errors; unblock with 'mariadb-admin flush-hosts'
```

Proberen om te ssh verbinden van de red machine naar een andere machine met vagrant/vagrant:

```bash
──(vagrant㉿red)-[~]
└─$ ssh vagrant@192.168.62.42          
The authenticity of host '192.168.62.42 (192.168.62.42)' can't be established.
ED25519 key fingerprint is SHA256:tVgSkWqegBlTs+mcUNdtVa1PitC6LZF18Qu921xy9cw.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.62.42' (ED25519) to the list of known hosts.
vagrant@192.168.62.42's password: 
Permission denied, please try again.
vagrant@192.168.62.42's password: 
Last failed login: Mon Oct 20 12:20:43 UTC 2025 from 192.168.62.110 on ssh:notty
There was 1 failed login attempt since the last successful login.
Last login: Mon Oct  6 07:26:42 2025 from 192.168.62.254
[vagrant@db ~]$ 
```

Dit is mogelijk.

Kijken welke versie er op de webserver draait:

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -sV -p80,443 172.30.10.10  
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 05:02 EST
Nmap scan report for 172.30.10.10
Host is up (0.00084s latency).

PORT    STATE SERVICE  VERSION
80/tcp  open  http     Apache httpd 2.4.62 ((AlmaLinux) OpenSSL/3.5.1)
443/tcp open  ssl/http Apache httpd 2.4.62 ((AlmaLinux) OpenSSL/3.5.1)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.47 seconds
```

De webserver draait Apache httpd 2.4.62 op (AlmaLinux).

### Gebruik -sC optie met nmap, wat is het?

-sC voert de default NSE scripts uit (Nmap Scripting Engine) een set van scripts die vaak basale informatie en checks uitvoeren (vulnerability checks, banners, http-enum, etc.). Het is handig voor een snelle extra laag informatieverzameling.

```bash
┌──(vagrant㉿red)-[~]
└─$ nmap -sV -sC -p80,443 172.30.10.10
Starting Nmap 7.95 ( https://nmap.org ) at 2026-01-04 05:09 EST
Nmap scan report for 172.30.10.10
Host is up (0.00079s latency).

PORT    STATE SERVICE  VERSION
80/tcp  open  http     Apache httpd 2.4.62 ((AlmaLinux) OpenSSL/3.5.1)
|_http-server-header: Apache/2.4.62 (AlmaLinux) OpenSSL/3.5.1
|_http-title: Did not follow redirect to https://www.cybersec.internal/
443/tcp open  ssl/http Apache httpd 2.4.62 ((AlmaLinux) OpenSSL/3.5.1)
|_http-title: Welcome to Example Test Environment
| http-methods: 
|_  Potentially risky methods: TRACE
| ssl-cert: Subject: commonName=www.cybersec.internal
| Subject Alternative Name: DNS:www.cybersec.internal, DNS:services.cybersec.internal
| Not valid before: 2025-12-28T11:00:50
|_Not valid after:  2028-04-01T11:00:50
|_http-server-header: Apache/2.4.62 (AlmaLinux) OpenSSL/3.5.1

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.71 seconds
```

De output toont dat de webserver mogelijk risicovolle HTTP-methoden zoals TRACE toestaat, wat een potentiëel beveiligingsrisico kan zijn.

## Netwerksegmentatie

Wat wordt bedoeld met de term attack vector?

Een attack vector is het pad of de methode waarmee een aanvaller toegang kan krijgen tot een systeem of netwerk. Door het netwerk op te splitsen in segmenten en verkeer tussen die zones te beperken, verklein je het aantal mogelijke aanvalspaden. Ook heb je een kleiner broadcast domein, wat de impact van bepaalde aanvallen (zoals ARP spoofing) kan verminderen.

Is er al network segmentation gedaan op het huidige (interne) bedrijfennetwerk?

Nee, nog niet.
Momenteel bevinden alle interne hosts (web, database, dns, employee) zich in hetzelfde subnet 172.30.0.0/16 zonder filtering of zones.
Ook is het “fake internet” rechtstreeks verbonden met het bedrijf via de companyrouter, zonder firewallregels die inkomend verkeer beperken.

Wat is een DMZ en welke machines horen daarin?

Een DMZ (Demilitarized Zone) is een netwerkzone tussen het interne LAN en het internet.
Ze bevat systemen die zowel door interne gebruikers als externe bezoekers moeten kunnen worden bereikt.

Client ↔ server communicatie kan geblokkeerd worden door de firewall.
Bijvoorbeeld:

De webserver kan geen verbinding meer maken met de database.

Interne werknemers kunnen geen DNS-resolutie meer doen als de firewall te streng is.

Configuratie van de companyrouter met nieuwe subnetten voor het intern LAN en de firewallregels:

```bash
sudo tee /etc/nftables.conf > /dev/null <<'EOF'
#!/usr/sbin/nft -f

flush ruleset

# ----------------------------
# 1. Definities & Variabelen
# ----------------------------
define WAN = "eth0"
define EXTERNAL = "eth1"
define DMZ_IF = "eth2"
define INT_IF = "eth3"

# Netwerken
define fake_internet = 192.168.62.0/24
define dmz_net = 172.30.10.0/24
define intranet_net = 172.30.20.0/24

# Hosts
define webserver = 172.30.10.10
define dns_server = 172.30.20.4
define siem_server = 172.30.20.50
define db_server = 172.30.20.15

table inet filter {
    # ----------------------------
    # 2. Input Chain (Verkeer NAAR de router, dus ook Jumpstation logins)
    # ----------------------------
    chain input {
        type filter hook input priority 0; policy drop;

        # Accepteer localhost en bestaande connecties
        iif lo accept
        ct state established,related accept

        # ICMP (Ping) naar de router zelf toestaan
        ip protocol icmp accept

        # --- FIX: SSH (22) EN VAGRANT (2222) ---
        # Dit zorgt dat je erin komt via zowel standaard SSH als Vagrant
        ip saddr { $fake_internet, $intranet_net, $dmz_net } tcp dport { 22, 2222 } accept
    }

    # ----------------------------
    # 3. Forward Chain (Verkeer DOOR de router)
    # ----------------------------
    chain forward {
        type filter hook forward priority 0; policy drop;

        # A. BASIS & PING
        ct state established,related accept
        
        # ICMP (Ping) doorlaten (Zodat je test.sh werkt!)
        ip protocol icmp accept

        # B. SSH DOORVOEREN (Ook hier 2222 voor de zekerheid toegestaan)
        meta l4proto tcp tcp dport { 22, 2222 } accept

        # C. DNS (Cruciaal voor alles)
        ip daddr $dns_server udp dport 53 accept
        ip daddr $dns_server tcp dport 53 accept
        # DNS Server mag naar buiten
        ip saddr $dns_server oifname { $WAN, $EXTERNAL } udp dport 53 accept
        ip saddr $dns_server oifname { $WAN, $EXTERNAL } tcp dport 53 accept

        # D. WEBSERVER (Bereikbaar vanaf overal)
        ip daddr $webserver tcp dport { 80, 443, 8000, 9200 } accept

        # E. WAZUH SIEM (Logs ontvangen)
        ip daddr $siem_server tcp dport { 1514, 1515 } accept
        ip daddr $siem_server udp dport { 1514, 1515 } accept

        # F. VPN PASSTHROUGH
        udp dport 1194 accept
        udp dport { 500, 4500 } accept
        ip protocol esp accept

        # G. UITGAAND VERKEER (Internet toegang)
        iifname $INT_IF oifname { $WAN, $EXTERNAL } accept
        iifname $DMZ_IF oifname { $WAN, $EXTERNAL } accept

        # H. INTERNE TRAFFIC
        # Intranet -> DMZ (Volledig toegang)
        iifname $INT_IF oifname $DMZ_IF accept
        
        # DMZ -> Intranet (Beperkt: Webserver -> DB)
        ip saddr $webserver ip daddr $db_server tcp dport 3306 accept
    }

    # ----------------------------
    # 4. Output Chain (Verkeer VANUIT de router)
    # ----------------------------
    chain output {
        type filter hook output priority 0; policy accept;
    }
}

# ----------------------------
# 5. NAT
# ----------------------------
table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;
        oifname { $WAN, $EXTERNAL } masquerade
    }
}
EOF
```

ik herstart de nftables service:

```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
sudo nft list ruleset
```

Ook moest ik de router nog de nieuwe subnetten meegeven:

```bash
[vagrant@companyrouter ~]$ 
sudo ip addr add 172.30.10.254/24 dev eth2
sudo ip addr add 172.30.20.254/24 dev eth2
```

Ook ipv4 forwarding moest nog ingeschakeld worden.

```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Nu teste ik de connectiviteit van de verschillende hosts met een scriptje:

Vanaf de router:
![alt text](<img/Schermafbeelding 2026-01-04 120158.png>)

Vanaf de webserver (DMS):
![alt text](<img/Schermafbeelding 2026-01-04 121243.png>)

Vanaf de database server (Internal LAN):
![alt text](<img/Schermafbeelding 2026-01-04 122146.png>)

De SIEM en windows stonden uit tijdens de tests ivm resources.

### Poortstatussen in nmap

nmap -p 22,80,666 172.30.10 -sV -Pn gaf:

22/tcp — open (OpenSSH 8.7)

80/tcp — open (Apache httpd 2.4.62)

666/tcp — closed (geen service luistert; host stuurt RST)

1) Wat betekent dit

open: er luistert een service die reageert op connecties (SYN → SYN/ACK). Nmap kan conversatie afhandelen en identificeert de service (SSH, HTTP).

closed: het host-systeem is bereikbaar en reageert, maar er luistert geen service op die poort; de host stuurt een RST. Nmap weet dus zeker dat poort gesloten is.

filtered (wat je eerder zag): er komt geen antwoord terug — meestal omdat een firewall het pakket dropt; nmap kan niet vaststellen of er een service luistert.