#!/usr/bin/env bash
set -e

# Generate SSH host keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[entrypoint] Generating SSH host keys..."
    ssh-keygen -A
fi

# Ensure authorized_keys exists with proper permissions
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Ensure config directories exist
mkdir -p /root/.config/antigravity /workspace

echo "[entrypoint] Antigravity Dev Container Initialized."
exec "$@"
