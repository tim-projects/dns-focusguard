#!/bin/bash

# Adaptive DDoS Protection for DNS
THRESHOLD=150
BAN_TIME=1800

while true; do
  CONNS=$(ss -nup state connected sport = :53 | awk '{print $6}' | cut -d: -f1 | sort | uniq -c)
  
  echo "$CONNS" | while read -r line; do
    count=$(echo $line | awk '{print $1}')
    ip=$(echo $line | awk '{print $2}')
    
    if [ -n "$ip" ] && [ $count -gt $THRESHOLD ]; then
      if ! iptables -C INPUT -s $ip -p udp --dport 53 -j DROP 2>/dev/null; then
        echo "[$(date)] Blocking $ip ($count queries/min)"
        iptables -A INPUT -s $ip -p udp --dport 53 -j DROP
        
        (sleep $BAN_TIME && iptables -D INPUT -s $ip -p udp --dport 53 -j DROP) &
      fi
    fi
  done
  
  sleep 60
done
