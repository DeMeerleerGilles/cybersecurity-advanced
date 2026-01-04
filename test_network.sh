#!/bin/bash

# Kleurcodes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Associatieve array met toestellen en IP-adressen
declare -A hosts=(
    ["webserver"]="172.30.10.10"
    ["dns"]="172.30.20.4"
    ["db"]="172.30.20.15"
    ["SIEM"]="172.30.20.50"
    ["Windows client"]="172.30.20.51"
    ["employee"]="172.30.20.123"
    ["isp router"]="192.168.62.254"
    ["companyrouter"]="192.168.62.253"
    ["companyrouter DMZ"]="172.30.10.254"
    ["companyrouter INT"]="172.30.20.254"
    ["homerouter"]="192.168.62.42"
    ["kali"]="192.168.62.110"
    ["remote-employee"]="172.10.10.123"
)

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   Netwerk Connectiviteit Rapport - $(hostname)     ${NC}"
echo -e "${BLUE}====================================================${NC}"
printf "%-20s | %-15s | %-10s\n" "Toestel" "IP-adres" "Status"
echo "----------------------------------------------------"

for name in "${!hosts[@]}"; do
    ip=${hosts[$name]}
    
    # Ping uitvoeren (1 pakket, 1 seconde timeout)
    ping -c 1 -W 1 $ip > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        printf "%-20s | %-15s | [${GREEN} BEREIKBAAR ${NC}]\n" "$name" "$ip"
    else
        printf "%-20s | %-15s | [${RED} MISLUKT    ${NC}]\n" "$name" "$ip"
    fi
done

echo "----------------------------------------------------"