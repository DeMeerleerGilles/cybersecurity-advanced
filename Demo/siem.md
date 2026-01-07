# Demo SIEM

Install and configure a SIEM-server, we suggest Wazuh. Toon dashboard
Perform endpoint detection on a Windows client device.
Install and configure sysmon (and PowerShell logging) on Windows.
Install and configure the (wazuh) agent to send information to the wazuh server.

Perform file-integrity-monitoring (FIM) of a file/folder on a Linux device. Verander het tekstbestand op de companyrouter en toon hoe dit gedetecteerd wordt in Wazuh.

Use the visualisation tools of wazuh to perform investigations.
Toon in Wazuh:

- Threat detection
- File integrity monitoring

See process create events from the windows client device.
See PowerShell cmdlets that are executed on the windows client device.
See events related to FIM on the Linux device.



## Welke SIEM?

Ik heb gekozen voor Wazuh als siem, omdat deze werd aangeraden in de cursus en omdat het open-source is.

## Architectuur

Wazuh agent: dit draait op de te monitoren machines en verzamelt logdata en systeeminformatie.

Wazuh manager: dit is de centrale server die de data van de agents ontvangt, analyseert en opslaat. Staat op een aparte VM (de siem)

Poort waarop Wazuh communiceert: 1514 (UDP/TCP).

## Welke logs worden er verzameld?

Linux logs: /var/log/auth.log
- SSH inlogpogingen
- sudo gebruik
- ...

Windows logs: Security Event Log
- Inlogpogingen
- Account wijzigingen
- ...

## Demo

We gaan eens proberen inloggen met een niet bestaande gebruiker: gilles op de companyrouter via ssh.

```powershell
PS C:\Users\gille\OneDrive\Documents\GitHub\cybersecurity-advanced-lab-template> ssh gilles@companyrouter
gilles@192.168.62.253's password: 
Permission denied, please try again.
gilles@192.168.62.253's password: 
Permission denied, please try again.
gilles@192.168.62.253's password: 
gilles@192.168.62.253: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
```

![alt text](<../verslagen/img/Schermafbeelding 2026-01-07 111720.png>)

## Hoe wordt dit gedetecteerd in Wazuh?

Dit wordt door wazuh gedecteerd via een regel in de ruleset.

Wazuh rule kijkt naar:

aantal failed logins binnen een tijdsvenster vanaf hetzelfde IP of user

Als drempel overschreden wordt:

- rule level stijgt
- alert wordt gegenereerd
