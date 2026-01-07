# Cheat sheet

## IP address instellen

Op almalinux:

```bash
[vagrant@companyrouter ~]$ nmcli device status
DEVICE       TYPE      STATE                   CONNECTION    
eth0         ethernet  connected               eth0
eth1         ethernet  connected               System eth1
eth2         ethernet  connected               DMZ-ZONE
eth3         ethernet  connected               INTERNAL-ZONE
docker0      bridge    connected (externally)  docker0
lo           loopback  connected (externally)  lo
vetha11ed80  ethernet  unmanaged               --
```

```bash
nmcli connection modify eth0 \
  ipv4.method manual \
  ipv4.addresses 192.168.1.10/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns 8.8.8.8
  nmcli connection down eth0
nmcli connection up eth0
nmcli connection up eth0
```

Op alpine:

```bash
vi /etc/network/interfaces
```

| CIDR (Prefix) | Subnetmasker    | Wildcardmasker (inverse) |
| ------------- | --------------- | ------------------------ |
| /8            | 255.0.0.0       | 0.255.255.255            |
| /16           | 255.255.0.0     | 0.0.255.255              |
| /24           | 255.255.255.0   | 0.0.0.255                |
| /25           | 255.255.255.128 | 0.0.0.127                |
| /26           | 255.255.255.192 | 0.0.0.63                 |
| /27           | 255.255.255.224 | 0.0.0.31                 |
| /28           | 255.255.255.240 | 0.0.0.15                 |
| /29           | 255.255.255.248 | 0.0.0.7                  |
| /30           | 255.255.255.252 | 0.0.0.3                  |
| /31           | 255.255.255.254 | 0.0.0.1                  |
| /32           | 255.255.255.255 | 0.0.0.0                  |


## Default gateway en DNS server bekijken

```bash
ip route
cat /etc/resolv.conf
```

