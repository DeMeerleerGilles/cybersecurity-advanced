# Labo 5: backups

Om dit labo te voltooien volgde ik de stappen uit de opdracht:

```bash
[vagrant@web ~]$ mkdir important-files
[vagrant@web ~]$ cd !$
[vagrant@web important-files]$ curl --remote-name-all https://video.blender.org/download/videos/bf1f3fb5-b119-4f9f-9930-8e20e892b898-720.mp4 https://www.gutenberg.org/ebooks/100.txt.utf-8 https://www.gutenberg.org/ebooks/996.txt.utf-8 https://upload.wikimedia.org/wikipedia/commons/4/40/Toreador_song_cleaned.ogg
[vagrant@web important-files]$ mv 100.txt.utf-8 100.txt # Optional
[vagrant@web important-files]$ mv 996.txt.utf-8 996.txt # Optional
[vagrant@web important-files]$ ll
total 109992
-rw-r--r--. 1 vagrant vagrant       300 Nov  4 12:37 100.txt
-rw-r--r--. 1 vagrant vagrant       300 Nov  4 12:37 996.txt
-rw-r--r--. 1 vagrant vagrant   1702187 Nov  4 12:37 Toreador_song_cleaned.ogg
-rw-r--r--. 1 vagrant vagrant 110916740 Nov  4 12:37 bf1f3fb5-b119-4f9f-9930-8e20e892b898-720.mp4
```

We controleerden of we de bestanden konden openen:

```bash
[vagrant@web important-files]$ ls
100.txt  996.txt  bf1f3fb5-b119-4f9f-9930-8e20e892b898-720.mp4  Toreador_song_cleaned.ogg
```

Hierna maakte ik op de DB een map backups aan om de backups in op te slaan:

```bash
mkdir backups
```

We controlleerden of borgbackup in de dnf package manager stond en installeerden het indien nodig:

```bash
No matches found.
```

Dit gaf helaas geen matches. We moesten dus eerst de EPEL repository toevoegen:

```bash
sudo dnf install epel-release
sudo dnf update
sudo dnf search borgbackup
```

Op de alpine:

```bash
apk update
apk add borgbackup
```

Nu moesten we de repository initialiseren:

```bash
borg init --encryption=repokey vagrant@172.30.20.15:~/backups
```

Passphrase: test

Om met keys te werken, moesten we eerst een SSH key genereren op de webserver:

```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id vagrant@172.30.20.15
```

Nu exporteren we de borg-keyfile:

```bash
borg key export ~/borg-keyfile vagrant@172.30.20.15:~/backups
```

Met borg --version controleren we of alles correct is geïnstalleerd:

```bash
borg --version
borg 1.2.7
```

Nu stellen we de borg key veilig:

```bash
borg key export vagrant@172.30.20.15:~/backups ~/borg-key.txt
```

Eerste backup maken:

```bash
borg create \
vagrant@172.30.20.15:~/backups::first \
/home/vagrant/important-files
```

De repository info bekijken:

```bash
[vagrant@web important-files]$ borg info vagrant@172.30.20.15:~/backups
Enter passphrase for key ssh://vagrant@172.30.20.15/~/backups: 
Repository ID: ddfe327a44b883e5ba50899fa89a27b15f9f7ac8af80081aa41c11e3a7b03e65
Location: ssh://vagrant@172.30.20.15/~/backups
Encrypted: Yes (repokey)
Cache: /home/vagrant/.cache/borg/ddfe327a44b883e5ba50899fa89a27b15f9f7ac8af80081aa41c11e3a7b03e65
Security dir: /home/vagrant/.config/borg/security/ddfe327a44b883e5ba50899fa89a27b15f9f7ac8af80081aa41c11e3a7b03e65
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:                    0 B                  0 B                  0 B

                       Unique chunks         Total chunks
Chunk index:                       0                    0
```

## Tweede backup maken na een wijziging:

We maken een extra bestand aan in de map important-files:

```bash
echo "Hello world" > ~/important-files/test.txt
```

Nu maken we een tweede backup:

```bash
borg create \
vagrant@172.30.20.15:~/backups::second \
/home/vagrant/important-files
```

Backups en hun inhoud bekijken:

```bash
borg list vagrant@172.30.20.15:~/backups
```

Per backup de inhoud bekijken:

```bash
borg list vagrant@172.30.20.15:~/backups::first
borg list vagrant@172.30.20.15:~/backups::second
```

## Grootte van de backups vergelijken:

```bash
du -h ~/important-files
du -h --si ~/important-files
1.7M    /home/vagrant/important-files
1.8M    /home/vagrant/important-files
```

grootte van de backup op de server bekijken:

```bash
[vagrant@web ~]$ du -h ~/important-files
du -h --si ~/important-files
1.7M    /home/vagrant/important-files
1.8M    /home/vagrant/important-files
```

We moeten ook regelmatig de integriteit van de repository controleren:

```bash
borg check vagrant@172.30.20.15:~/backups
```

Optioneel kan je er ook voor kiezen om een volledige check te doen:

```bash
borg check --verify-data --verbose vagrant@172.30.20.15:~/backups
```

## Data verwijderen en terugzetten

Nu gaan we de data in de map important-files verwijderen:

```bash
rm -rf ~/important-files
```

Deze is nu leeg:

```bash
[vagrant@web important-files]$ ls
[vagrant@web important-files]$ 
```

We gaan nu de data terugzetten vanuit de eerste backup:

```bash
[vagrant@web ~]$ borg extract vagrant@172.30.20.15:~/backups::first --strip-components 3
Enter passphrase for key ssh://vagrant@172.30.20.15/~/backups:
[vagrant@web ~]$ ls
100.txt  bf1f3fb5-b119-4f9f-9930-8e20e892b898-720.mp4  test.txt
996.txt  borg-key.txt                                  Toreador_song_cleaned.ogg
```

De bestanden zijn succesvol teruggezet!

## Backup script

We maken een script aan met touch borg-backup.sh en voegen de volgende inhoud toe: 

```bash
#!/bin/bash
REPO="vagrant@172.30.20.15:~/backups"
SOURCE="/home/vagrant/important-files"

borg create \
  --stats \
  --compression lz4 \
  $REPO::'{now:%Y-%m-%d_%H:%M}' \
  $SOURCE

borg prune \
  --keep-minute=12 \
  --keep-hourly=24 \
  --keep-daily=7 \
  --keep-monthly=6 \
  $REPO

borg compact $REPO
```

Nu maken we het script uitvoerbaar:

```bash
chmod +x borg-backup.sh
```

We maken er een systemd service van en zetten er een timer op:

```bash
sudo vi /etc/systemd/system/borg-backup.service
```

Met de volgende inhoud: 

```ini
[Unit]
Description=Borg Backup

[Service]
Type=oneshot
ExecStart=/home/vagrant/borg-backup.sh
```

De timer zetten we als volgt op: 

```bash
sudo vi /etc/systemd/system/borg-backup.timer
```

Met de volgende inhoud: 

```ini
[Unit]
Description=Run Borg backup every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

We activeren en starten alles met de volgende commando's: 

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now borg-backup.timer
```

We zien nu dat hij draait: 

```bash
[vagrant@web ~]$ systemctl list-timers | grep borg
Tue 2025-12-23 09:51:12 UTC 4min 54s left Tue 2025-12-23 09:46:12 UTC 5s ago       borg-backup.timer      
      borg-backup.service
```

Borg compact verwijdert onnodige data uit de repository om ruimte te besparen.

