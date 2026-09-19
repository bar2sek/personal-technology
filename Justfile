# ==============================================================================
# Talos AWS Homelab - Central Command Runner (just)
# ==============================================================================

# Default recipe: List available commands
default:
    @just --list

# ------------------------------------------------------------------------------
# 1. Talos Linux Cluster Administration
# ------------------------------------------------------------------------------

# Check health of the Talos Linux control plane (sm-node-01, sm-node-02, sm-node-03)
talos-health:
    talosctl --nodes 10.10.20.131 health

# List all Talos cluster members and roles
talos-members:
    talosctl --nodes 10.10.20.131 get members

# Check etcd cluster status and quorum
talos-etcd:
    talosctl --nodes 10.10.20.131 service etcd

# Inspect physical node reboot / uptime statistics
talos-uptime:
    talosctl --nodes 10.10.20.131,10.10.20.120,10.10.20.199,10.10.20.20,10.10.20.111 version

# ------------------------------------------------------------------------------
# 2. Kubernetes Cluster Operations
# ------------------------------------------------------------------------------

# List all Kubernetes nodes with internal IPs and OS versions
k8s-nodes:
    kubectl get nodes -o wide

# Check status of all pods across all cluster namespaces
k8s-pods:
    kubectl get pods -A -o wide

# Check Rook-Ceph storage cluster health and pool capacity
ceph-status:
    kubectl -n rook-ceph exec -it deploy/rook-ceph-operator -- ceph status || kubectl -n rook-ceph get cephcluster

# Check Cloudflare Tunnel pods status
tunnel-status:
    kubectl -n cloudflare-system get pods -o wide

# Check status of the monitoring stack (Prometheus, Grafana, Alertmanager, Node-Exporter)
monitoring-status:
    @echo "===> Monitoring Pods & PVCs:"
    kubectl -n monitoring get pods,pvc -o wide
    @echo "\n===> Ceph ServiceMonitor:"
    kubectl -n rook-ceph get servicemonitor

# Retrieve Grafana admin credentials
grafana-password:
    @echo "Grafana Admin User: admin"
    @echo -n "Grafana Admin Password: "
    @kubectl -n monitoring get secret grafana-admin-credentials -o jsonpath="{.data.admin-password}" | base64 --decode && echo ""

# Check status of Authentik Identity stack (Server, Worker, DB, Redis, Ingress)
authentik-status:
    @echo "===> Identity Pods & PVCs:"
    kubectl -n identity get pods,pvc -o wide
    @echo "\n===> Identity Ingress:"
    kubectl -n identity get ingress -o wide

# Stream Authentik server logs
authentik-logs:
    kubectl -n identity logs -l app.kubernetes.io/name=authentik-server -f



# Launch interactive terminal into the in-cluster Antigravity Dev Workspace
ssh-dev:
    @echo "Connecting to Antigravity Dev Workspace on sm-node-03..."
    ssh antigravity-dev

# ------------------------------------------------------------------------------
# 3. Terraform Infrastructure as Code
# ------------------------------------------------------------------------------

# Plan all 4 Terraform roots (unifi, cloudflare, aws, aws_organization)
tf-plan-all:
    @echo "===> Planning UniFi Network..."
    cd terraform/unifi && terraform plan
    @echo "===> Planning Cloudflare Tunnels & Access..."
    cd terraform/cloudflare && terraform plan
    @echo "===> Planning AWS Foundation Resources..."
    cd terraform/aws && terraform plan
    @echo "===> Planning AWS Organization & Accounts..."
    cd terraform/aws_organization && terraform plan

# Run Terraform plan in a specific directory (usage: just tf-plan unifi)
tf-plan dir:
    cd terraform/{{ dir }} && terraform plan {{ if dir == "unifi" { "-parallelism=1" } else { "" } }}

# Run Terraform apply in a specific directory (usage: just tf-apply unifi)
tf-apply dir:
    cd terraform/{{ dir }} && terraform apply {{ if dir == "unifi" { "-parallelism=1" } else { "" } }}


# ------------------------------------------------------------------------------
# 4. Ansible Automation
# ------------------------------------------------------------------------------

# Run automated Bazzite Gaming VM post-install configuration (NVIDIA, Sunshine, Flatpaks)
bazzite-setup:
    cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/configure-bazzite-vm.yml

# Ping Bazzite Gaming VM over SSH
bazzite-ping:
    cd ansible && ansible -i inventory/hosts.ini gaming_vms -m ping

# Force restart frozen Bazzite Gaming VM via KubeVirt
bazzite-restart:
    virtctl restart --force --grace-period=0 bazzite-gaming-vm -n vms

# ------------------------------------------------------------------------------
# 5. Local AI (Apple MLX / oMLX on macOS)
# ------------------------------------------------------------------------------

# Launch dual-port local MLX servers (:8081 for Tab Autocomplete, :8080 for Chat)
serve-ai:
    @echo "Starting Tab Autocomplete (:8081) and Deep Chat (:8080)..."
    @uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit --port 8081 --chat-template-name chatml & \
     uvx --from mlx-lm mlx_lm.server --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit --port 8080 --chat-template-name chatml

# ------------------------------------------------------------------------------
# 6. Workstation Management (nix-darwin)
# ------------------------------------------------------------------------------

# Rebuild and apply the active nix-darwin configuration
switch:
    sudo -H darwin-rebuild switch --flake ~/.config/nix-darwin#MacBook-Pro

# Update nix flake lockfile to latest package versions and rebuild
update:
    nix flake update --flake ~/.config/nix-darwin
    sudo -H darwin-rebuild switch --flake ~/.config/nix-darwin#MacBook-Pro

