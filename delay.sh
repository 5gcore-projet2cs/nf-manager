#!/bin/sh

# Usage:
# ./delay.sh [in|out|free] [delay_in_ms] [interface]
# Examples:
# ./delay.sh out 200 wlan0
# ./delay.sh in 100             # uses eth0 by default
# ./delay.sh free wlan0
# ./delay.sh free               # uses eth0 by default

ACTION=$1
DELAY=$2
IFACE=${3:-eth0}

if [ -z "$ACTION" ]; then
  echo "Usage: $0 [in|out|free] [delay_in_ms] [interface]"
  exit 1
fi

if [ "$ACTION" = "free" ]; then
  echo "Removing all traffic control rules from $IFACE"
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  tc qdisc del dev "$IFACE" ingress 2>/dev/null || true
  exit 0
fi

if [ -z "$DELAY" ]; then
  echo "You must specify a delay in milliseconds for 'in' or 'out'"
  exit 1
fi

tc qdisc del dev "$IFACE" root 2>/dev/null || true
tc qdisc del dev "$IFACE" ingress 2>/dev/null || true

if [ "$ACTION" = "out" ]; then
  echo "Applying $DELAY ms delay to outgoing traffic on $IFACE"
  tc qdisc add dev "$IFACE" root handle 1: netem delay "${DELAY}"ms

elif [ "$ACTION" = "in" ]; then
  echo "Applying $DELAY ms delay to incoming traffic on $IFACE"
  tc qdisc add dev "$IFACE" handle ffff: ingress
  tc filter add dev "$IFACE" parent ffff: protocol ip u32 match u32 0 0 \
    action netem delay "${DELAY}"ms

else
  echo "Invalid action: $ACTION. Use 'in', 'out', or 'free'."
  exit 1
fi
