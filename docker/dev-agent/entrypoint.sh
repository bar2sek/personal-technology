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
mkdir -p /root/.config/antigravity /root/.config/code-server /workspace

# Configure code-server defaults (auth: none for LAN / Cloudflare Zero Trust handles WAN auth)
AUTH_METHOD="${CODE_SERVER_AUTH:-none}"
cat <<EOF > /root/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8080
auth: ${AUTH_METHOD}
cert: false
disable-telemetry: true
EOF

echo "[entrypoint] Antigravity Dev Container Initialized."

if [ "$1" = "start" ]; then
    echo "[entrypoint] Starting OpenSSH Server on port 22..."
    /usr/sbin/sshd

    echo "[entrypoint] Starting code-server on 0.0.0.0:8080 serving /workspace..."
    exec code-server --bind-addr 0.0.0.0:8080 --auth "${AUTH_METHOD}" /workspace
fi

exec "$@"

