#!/bin/bash
set -e

echo "Starting dazdotdev devbox..."

# Start Tailscale daemon
echo "Starting Tailscale..."
tailscaled --state=/var/lib/tailscale/tailscaled.state &
sleep 2

# Auto-auth if key provided, otherwise manual login needed
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale with provided auth key..."
    tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-dazdotdev}" --ssh
else
    echo "No TAILSCALE_AUTHKEY set - run 'tailscale up' manually after connecting"
fi

# Start SSH daemon
echo "Starting SSH daemon..."
/usr/sbin/sshd

echo "Ready. Connect via: mosh dev@${TAILSCALE_HOSTNAME:-dazdotdev}"

# Keep container alive
exec sleep infinity
