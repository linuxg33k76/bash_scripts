#!/bin/bash
KNOWN="/tmp/known_outbound.txt"
EMAIL="linuxg33k@protonmail.me"
HOSTNAME="$(hostname)"
ss -tupn > $KNOWN

while true; do
    CURRENT=$(mktemp)
    ss -tupn > $CURRENT
    NEW=$(comm -13 <(sort $KNOWN) <(sort $CURRENT))
    echo "$NEW"
    if [[ ! -z "$NEW" ]]; then
        # Console alert
        echo "[ALERT] New outbound connections detected for $HOSTNAME" 
        echo "Type: $(echo "$NEW" | awk '{print $1}')"
        echo "Source: $(echo "$NEW" | awk '{print $5}')"
        echo "Outbound Destination: $(echo "$NEW" | awk '{print $6}' | cut -d ':' -f 1)"
        echo "Outbound Port: $(echo "$NEW" | awk '{print $6}' | cut -d ':' -f 2)"
        echo "User: $(echo "$NEW" | awk '{print $7}')"
        WHOIS=$(whois $(echo "$NEW" | awk '{print $6}' | cut -d ':' -f 1))
        echo "$(echo "$WHOIS" | grep -E 'OrgName:')"
        echo "$(echo "$WHOIS" | grep -E 'City:')"
        echo "$(echo "$WHOIS" | grep -E 'Country:')"
        echo "$(echo "$WHOIS" | grep -E 'OrgAbuse')"
        echo "*************************************************************************"
        echo
    fi
    mv $CURRENT $KNOWN
    sleep 20
done
