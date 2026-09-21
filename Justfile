# ==============================================================================
# Talos AWS Homelab - Central Command Runner (just)
# ==============================================================================

# Default recipe: List available commands
default:
    @just --list

# ------------------------------------------------------------------------------
# 1. Talos Linux Cluster Administration
# ------------------------------------------------------------------------------

# Check health of the Talos Linux control plane (sm-node-01, sm-node-02, sm-node-03 via HA VIP)
talos-health:
    talosctl --nodes 10.10.20.10 health

# List all Talos cluster members and roles
talos-members:
    talosctl --nodes 10.10.20.10 get members

# Check etcd cluster status and quorum
talos-etcd:
    talosctl --nodes 10.10.20.10 service etcd

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



# Check status of Azure Arc agents and connected cluster pods
arc-status:
    @echo "===> Azure Arc Pods & Deployments:"
    kubectl -n azure-arc get pods,daemonset,deploy -o wide

# Stream Azure Arc clusterconnect agent logs
arc-logs:
    kubectl -n azure-arc logs -l app.kubernetes.io/name=clusterconnect-agent -f

# Launch interactive terminal into the in-cluster Antigravity Dev Workspace
ssh-dev:
    @echo "Connecting to Antigravity Dev Workspace on sm-node-03..."
    ssh antigravity-dev

# ------------------------------------------------------------------------------
# 3. Terraform Infrastructure as Code
# ------------------------------------------------------------------------------

# Plan all On-Prem & Cloud Bootstrap roots
tf-plan-all:
    @echo "===> Planning UniFi Network (On-Prem Terraform)..."
    cd terraform/unifi && terraform plan -parallelism=1
    @echo "===> Planning Cloudflare Tunnels & Access (On-Prem Terraform)..."
    cd terraform/cloudflare && terraform plan
    @echo "===> Planning GitHub Multi-Cloud GitOps (Bootstrap)..."
    cd bootstrap/github && terraform plan
    @echo "===> Planning AWS OIDC & State Storage (Bootstrap)..."
    cd bootstrap/aws && terraform plan
    @echo "===> Planning AWS Organization & Accounts (Bootstrap)..."
    cd bootstrap/aws_organization && terraform plan
    @echo "===> Planning Azure Infrastructure & Entra ID (Bootstrap)..."
    cd bootstrap/azure && terraform plan

# Run Terraform plan in a specific directory (usage: just tf-plan unifi or just tf-plan azure)
tf-plan dir:
    @if [ -d "terraform/{{ dir }}" ]; then \
        cd terraform/{{ dir }} && terraform plan {{ if dir == "unifi" { "-parallelism=1" } else { "" } }}; \
    elif [ -d "bootstrap/{{ dir }}" ]; then \
        cd bootstrap/{{ dir }} && terraform plan; \
    else \
        echo "Error: Directory terraform/{{ dir }} or bootstrap/{{ dir }} not found"; exit 1; \
    fi

# Run Terraform apply in a specific directory (usage: just tf-apply unifi or just tf-apply azure)
tf-apply dir:
    @if [ -d "terraform/{{ dir }}" ]; then \
        cd terraform/{{ dir }} && terraform apply {{ if dir == "unifi" { "-parallelism=1" } else { "" } }}; \
    elif [ -d "bootstrap/{{ dir }}" ]; then \
        cd bootstrap/{{ dir }} && terraform apply; \
    else \
        echo "Error: Directory terraform/{{ dir }} or bootstrap/{{ dir }} not found"; exit 1; \
    fi

# Quick shortcuts for On-Premise Homelab roots
tf-plan-unifi:
    cd terraform/unifi && terraform plan -parallelism=1

tf-apply-unifi:
    cd terraform/unifi && terraform apply -parallelism=1

tf-plan-cloudflare:
    cd terraform/cloudflare && terraform plan

tf-apply-cloudflare:
    cd terraform/cloudflare && terraform apply

# Quick shortcuts for Day-0 Cloud & CI/CD Bootstrap roots
tf-plan-github:
    cd bootstrap/github && terraform plan

tf-apply-github:
    cd bootstrap/github && terraform apply

tf-plan-aws:
    cd bootstrap/aws && terraform plan

tf-apply-aws:
    cd bootstrap/aws && terraform apply

tf-plan-aws-org:
    cd bootstrap/aws_organization && terraform plan

tf-apply-aws-org:
    cd bootstrap/aws_organization && terraform apply

tf-plan-azure:
    cd bootstrap/azure && terraform plan

tf-apply-azure:
    cd bootstrap/azure && terraform apply


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

