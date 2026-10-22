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

# Apply monitoring config: custom alert rules, dashboards, then the Helm release (chart version pinned)
monitoring-apply:
    kubectl apply -f kubernetes/infrastructure/monitoring/kube-client-cert-rule.yaml
    kubectl apply -f kubernetes/infrastructure/monitoring/dashboards/
    helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 91.4.1 -n monitoring -f kubernetes/infrastructure/monitoring/values.yaml

# Deploy the Tailscale operator (chart pinned) and the ingress-VIP subnet router.
# Needs the tailnet policy + OAuth Secret from docs/203 first.
tailscale-apply:
    helm repo add tailscale https://pkgs.tailscale.com/helmcharts --force-update
    kubectl apply -f kubernetes/infrastructure/tailscale/namespace.yaml
    helm upgrade --install tailscale-operator tailscale/tailscale-operator --version 1.104.1 -n tailscale -f kubernetes/infrastructure/tailscale/values.yaml --wait
    kubectl apply -f kubernetes/infrastructure/tailscale/connector.yaml

# Writes Secret ntfy/ntfy-auth and the token copy monitoring/ntfy-alertmanager-token.
# Nothing is committed. Users: `ryan` (admin, iPhone app) and `alertmanager`
# (publish-only to homelab-alerts, token auth).
# Create or rotate ntfy logins (prompts for the iPhone app password)
ntfy-auth:
    #!/usr/bin/env bash
    set -euo pipefail
    read -rsp "Password for ntfy user 'ryan' (iPhone app login): " PW; echo
    read -rsp "Confirm: " PW2; echo
    [ "$PW" = "$PW2" ] || { echo "Passwords do not match." >&2; exit 1; }
    # Hash inside the ntfy pod (bcrypt, the format ntfy expects); the password
    # goes over stdin, never onto a command line.
    hash() { printf '%s\n%s\n' "$1" "$1" | kubectl -n ntfy exec -i deploy/ntfy -- ntfy user hash 2>/dev/null | awk '{print $NF}'; }
    RYAN_HASH=$(hash "$PW"); unset PW PW2
    AM_HASH=$(hash "$(openssl rand -base64 24)") # alertmanager only ever uses its token
    AM_TOKEN=$(kubectl -n ntfy exec deploy/ntfy -- ntfy token generate | tr -d '\r\n')
    case "$RYAN_HASH$AM_HASH" in *'$2a$'*'$2a$'*) ;; *) echo "Hashing failed." >&2; exit 1 ;; esac
    kubectl -n ntfy create secret generic ntfy-auth \
      --from-literal=NTFY_AUTH_USERS="ryan:${RYAN_HASH}:admin,alertmanager:${AM_HASH}:user" \
      --from-literal=NTFY_AUTH_ACCESS="alertmanager:homelab-alerts:wo" \
      --from-literal=NTFY_AUTH_TOKENS="alertmanager:${AM_TOKEN}:Alertmanager" \
      --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n monitoring create secret generic ntfy-alertmanager-token \
      --from-literal=token="${AM_TOKEN}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n ntfy rollout restart deploy/ntfy
    kubectl -n ntfy rollout status deploy/ntfy

# Retrieve Grafana admin credentials
grafana-password:
    @echo "Grafana Admin User: admin"
    @echo -n "Grafana Admin Password: "
    @kubectl -n monitoring get secret grafana-admin-credentials -o jsonpath="{.data.admin-password}" | base64 --decode && echo ""

# Admin kubeconfig for the standalone omni-server node. Lives outside the Drive-synced vault (docs/108, Workstation Bootstrap Bundle).
omni_kubeconfig := env_var_or_default("OMNI_KUBECONFIG", env_var("HOME") / ".kube" / "omni-server.kubeconfig")

# Check status of Network UPS Tools (NUT) stack (omni-server daemon & cluster exporter)
nut-status:
    @echo "===> NUT Server on omni-server (10.10.10.5):"
    @kubectl --kubeconfig="{{omni_kubeconfig}}" -n kube-system get pods -l app.kubernetes.io/name=nut-server -o wide 2>/dev/null || echo "Not deployed yet"
    @echo ""
    @echo "===> In-Cluster NUT Exporter (monitoring-ups):"
    @kubectl -n monitoring-ups get pods,svc,servicemonitor,prometheusrule -o wide 2>/dev/null || echo "Not deployed yet"

# Deploy NUT server to omni-server and exporter to homelab-k8s cluster
nut-deploy:
    kubectl --kubeconfig="{{omni_kubeconfig}}" apply -f kubernetes/infrastructure/nut/nut-server-omni.yaml
    kubectl apply -f kubernetes/infrastructure/nut/namespace.yaml
    kubectl apply -f kubernetes/infrastructure/nut/nut-exporter.yaml
    kubectl apply -f kubernetes/infrastructure/nut/servicemonitor.yaml
    kubectl apply -f kubernetes/infrastructure/nut/prometheus-rules.yaml

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

# GitHub Actions Runner Controller (ARC) - self-hosted runners for the PRIVATE
# homelab-ops repo. Prefixed `gha-runners-` to avoid confusion with Azure Arc.
gha_runners_chart_version := "0.15.0"
gha_runners_chart_repo := "oci://ghcr.io/actions/actions-runner-controller-charts"

# Create the GitHub App Secret straight from the downloaded .pem (key never touches the synced vault)
gha-runners-secret app_id installation_id pem:
    kubectl apply -f kubernetes/infrastructure/arc/namespaces.yaml
    kubectl -n arc-runners create secret generic github-app-secret \
        --from-literal=github_app_id={{app_id}} \
        --from-literal=github_app_installation_id={{installation_id}} \
        --from-file=github_app_private_key={{pem}} \
        --dry-run=client -o yaml | kubectl apply -f -
    @echo "Secret created. Now delete the .pem: rm {{pem}}"

# Install/upgrade the ARC controller and the talos-homelab-runner scale set (pinned chart versions)
gha-runners-deploy:
    kubectl apply -f kubernetes/infrastructure/arc/namespaces.yaml
    helm upgrade --install arc {{gha_runners_chart_repo}}/gha-runner-scale-set-controller \
        --version {{gha_runners_chart_version}} --namespace arc-systems \
        -f kubernetes/infrastructure/arc/controller-values.yaml --wait
    helm upgrade --install talos-homelab-runner {{gha_runners_chart_repo}}/gha-runner-scale-set \
        --version {{gha_runners_chart_version}} --namespace arc-runners \
        -f kubernetes/infrastructure/arc/runner-scale-set-values.yaml --wait

# Check ARC controller, listener, scale set registration and runner pods
gha-runners-status:
    @echo "===> Controller & listener (arc-systems):"
    kubectl -n arc-systems get pods -o wide
    @echo "===> Scale set registration (must be the PRIVATE repo):"
    kubectl -n arc-runners get autoscalingrunnerset -o custom-columns=NAME:.metadata.name,URL:.spec.githubConfigUrl,MIN:.spec.minRunners,MAX:.spec.maxRunners
    @echo "===> Runner pods (arc-runners):"
    kubectl -n arc-runners get pods

# Needs Secret frigate/frigate-cameras first (frigate-secrets.example.yaml).
# Deploy Frigate: manifests, then the ConfigMap from config.yml (docs/507)
frigate-apply:
    kubectl apply -f kubernetes/apps/frigate/frigate.yaml
    kubectl -n frigate create configmap frigate-config \
      --from-file=config.yml=kubernetes/apps/frigate/config.yml \
      --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n frigate rollout restart deploy/frigate
    kubectl -n frigate rollout status deploy/frigate --timeout=5m

# Refuses if a camera token appears in plain text instead of {FRIGATE_*}.
# Copy the live Frigate config (after UI edits to zones/masks) back into git
frigate-config-pull:
    #!/usr/bin/env bash
    set -euo pipefail
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT
    kubectl -n frigate exec deploy/frigate -c frigate -- cat /config/config.yml > "$TMP"
    if grep -E ':7441/[^{"[:space:]]' "$TMP"; then
      echo "A Protect token is in plain text above; fix it in the UI before pulling." >&2
      exit 1
    fi
    mv "$TMP" kubernetes/apps/frigate/config.yml
    git diff --stat -- kubernetes/apps/frigate/config.yml

# ------------------------------------------------------------------------------
# 3. Terraform Infrastructure as Code
# ------------------------------------------------------------------------------

# Every recipe below runs Terraform through `_tf`, which keeps `.terraform/`
# out of the Google Drive–synced vault (AGENTS.md §6):
#   * TF_DATA_DIR  -> ~/.terraform-data/personal-technology/<terraform|bootstrap>-<dir>
#                     (one per root: it also holds the backend/module metadata)
#   * TF_PLUGIN_CACHE_DIR -> ~/.terraform.d/plugin-cache, shared by all roots,
#                     so a re-init links the cached binary instead of downloading
#   * auto-runs `terraform init` when the root's data dir has no providers yet
# Local state (terraform.tfstate) is unaffected and stays next to the code.
tf_data_root := env_var_or_default("TF_DATA_ROOT", env_var("HOME") / ".terraform-data") / "personal-technology"

[private]
[positional-arguments]
_tf dir cmd *args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="$1" cmd="$2"; shift 2
    if [ -d "terraform/$dir" ]; then root="terraform/$dir"
    elif [ -d "bootstrap/$dir" ]; then root="bootstrap/$dir"
    else echo "Error: Directory terraform/$dir or bootstrap/$dir not found" >&2; exit 1; fi
    export TF_DATA_DIR="{{ tf_data_root }}/${root//\//-}"
    export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
    # Same default as the nix-mac `terraform` alias (shell aliases don't apply inside just).
    export AWS_PROFILE="${AWS_PROFILE:-terraform}"
    mkdir -p "$TF_DATA_DIR" "$TF_PLUGIN_CACHE_DIR"
    cd "$root"
    if [ "$cmd" != "init" ] && [ ! -d "$TF_DATA_DIR/providers" ]; then
        echo "===> $root: no provider cache in $TF_DATA_DIR, running terraform init"
        terraform init -input=false
    fi
    # UniFi provider crashes on concurrent refresh (see deployment journal): run it serially.
    if [ "$dir" = "unifi" ] && [[ "$cmd" =~ ^(plan|apply|destroy|refresh)$ ]]; then
        set -- -parallelism=1 "$@"
    fi
    terraform "$cmd" "$@"

# Initialise a root outside the vault (usage: just tf-init unifi, just tf-init aws -upgrade)
[positional-arguments]
tf-init dir *args:
    @d="$1"; shift; {{ just_executable() }} _tf "$d" init "$@"

# Run Terraform plan in a specific directory (usage: just tf-plan unifi or just tf-plan azure)
[positional-arguments]
tf-plan dir *args:
    @d="$1"; shift; {{ just_executable() }} _tf "$d" plan "$@"

# Run Terraform apply in a specific directory (usage: just tf-apply unifi or just tf-apply azure)
[positional-arguments]
tf-apply dir *args:
    @d="$1"; shift; {{ just_executable() }} _tf "$d" apply "$@"

# Run any other Terraform subcommand in a root (usage: just tf unifi state list)
[positional-arguments]
tf dir cmd *args:
    @{{ just_executable() }} _tf "$@"

# Print where a root's provider cache lives (usage: just tf-data-dir unifi)
tf-data-dir dir:
    @if [ -d "terraform/{{ dir }}" ]; then echo "{{ tf_data_root }}/terraform-{{ dir }}"; \
    else echo "{{ tf_data_root }}/bootstrap-{{ dir }}"; fi

# Plan all On-Prem & Cloud Bootstrap roots
tf-plan-all: (tf-plan "unifi") (tf-plan "github") (tf-plan "aws") (tf-plan "aws_organization") (tf-plan "azure")

# Quick shortcuts for On-Premise Homelab roots
tf-plan-unifi: (tf-plan "unifi")

tf-apply-unifi: (tf-apply "unifi")

# Quick shortcuts for Day-0 Cloud & CI/CD Bootstrap roots
tf-plan-github: (tf-plan "github")

tf-apply-github: (tf-apply "github")

tf-plan-aws: (tf-plan "aws")

tf-apply-aws: (tf-apply "aws")

tf-plan-aws-org: (tf-plan "aws_organization")

tf-apply-aws-org: (tf-apply "aws_organization")

tf-plan-azure: (tf-plan "azure")

tf-apply-azure: (tf-apply "azure")

# Generate live UniFi network & VLAN topology diagrams (SVG + PNG)
unifi-diagram:
    python3 client-tools/generate_unifi_diagram.py



# ------------------------------------------------------------------------------
# 4. Ansible Automation
# ------------------------------------------------------------------------------

# Run automated Bazzite Gaming VM post-install configuration (NVIDIA, Sunshine, Flatpaks)
bazzite-setup:
    cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/configure-bazzite-vm.yml --ask-become-pass

# Queue the Steam games listed in the playbook's steam_apps (no OS upgrade or reboot)
bazzite-steam-games:
    cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/configure-bazzite-vm.yml --tags steam-games

# Battle.net bootstrap / Blizzard game shortcuts in Steam (no OS upgrade or reboot)
bazzite-blizzard:
    cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/configure-bazzite-vm.yml --tags blizzard --ask-become-pass

# Ping Bazzite Gaming VM over SSH
bazzite-ping:
    cd ansible && ansible -i inventory/hosts.ini gaming_vms -m ping

# Force restart frozen Bazzite Gaming VM via KubeVirt
bazzite-restart:
    virtctl restart --force --grace-period=0 bazzite-gaming-vm -n vms

# ------------------------------------------------------------------------------
# 5. Workstation Management (nix-darwin + home-manager)
# ------------------------------------------------------------------------------

# Sync canonical templates from nix-mac/templates into ~/.config/nix-darwin
sync:
    #!/usr/bin/env bash
    set -euo pipefail
    TPL="{{justfile_directory()}}/nix-mac/templates"
    mkdir -p "$HOME/.config/nix-darwin"
    cp "$TPL/flake.nix" "$TPL/darwin.nix" "$TPL/home.nix" "$TPL/Justfile" "$TPL/p10k.zsh" "$TPL/flake.lock" "$HOME/.config/nix-darwin/"
    echo "✅ Synced nix-mac/templates -> ~/.config/nix-darwin/"

# Sync templates, rebuild, and apply the active nix-darwin + home-manager configuration
switch: sync
    sudo -H darwin-rebuild switch --flake ~/.config/nix-darwin#MacBook-Pro

# Update nix flake lockfile, sync it back to nix-mac/templates, and rebuild
update: sync
    nix flake update --flake ~/.config/nix-darwin
    cp ~/.config/nix-darwin/flake.lock "{{justfile_directory()}}/nix-mac/templates/flake.lock"
    @echo "✅ Synced updated flake.lock -> nix-mac/templates/flake.lock"
    sudo -H darwin-rebuild switch --flake ~/.config/nix-darwin#MacBook-Pro

