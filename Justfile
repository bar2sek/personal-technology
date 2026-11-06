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

# Deploy Headlamp, the tailnet-only Kubernetes web UI (docs/113)
headlamp-apply:
    kubectl apply -f kubernetes/infrastructure/headlamp/headlamp.yaml
    kubectl -n headlamp rollout status deploy/headlamp

# Printed once, stored nowhere. Paste it into the Headlamp login screen.
# Mint a read-only Headlamp login token (default 30 days)
headlamp-token duration="720h":
    kubectl -n headlamp create token headlamp-viewer --duration={{duration}}

# `kubectl auth can-i --as` is unreliable through the Omni proxy (it reports
# your own rights). A SubjectAccessReview asks the API server's authorizer
# directly and stores nothing.
# Verify Headlamp RBAC: viewer reads but can't touch Secrets; pod SA has nothing
headlamp-rbac-check:
    #!/usr/bin/env bash
    set -euo pipefail
    sar() { # <sa> <verb> <resource[/subresource]> <expected>
      local res=${3%%/*} sub="" got
      [[ $3 == */* ]] && sub=",\"subresource\":\"${3#*/}\""
      got=$(printf '{"apiVersion":"authorization.k8s.io/v1","kind":"SubjectAccessReview","spec":{"user":"system:serviceaccount:headlamp:%s","groups":["system:serviceaccounts","system:serviceaccounts:headlamp","system:authenticated"],"resourceAttributes":{"namespace":"identity","verb":"%s","resource":"%s"%s}}}' "$1" "$2" "$res" "$sub" \
        | kubectl create -f - -o jsonpath='{.status.allowed}')
      got=${got:-false}
      [[ $got == "$4" ]] && mark=ok || { mark=FAIL; FAILED=1; }
      printf '%-4s %-16s %-7s %-20s allowed=%s\n' "$mark" "$1" "$2" "$3" "$got"
    }
    FAILED=0
    sar headlamp-viewer list   nodes             true
    sar headlamp-viewer get    pods/log          true
    sar headlamp-viewer list   persistentvolumes true
    sar headlamp-viewer list   secrets           false
    sar headlamp-viewer delete pods              false
    sar headlamp        list   pods              false
    sar headlamp        list   secrets           false
    exit $FAILED

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

# Generates the database password once and never rotates it: Postgres keeps the
# password it was initialized with, so a new one would lock Immich out.
# Deploy Immich: manifests, the Secret if missing, then wait for rollouts (docs/504)
immich-apply:
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl apply -f kubernetes/apps/immich/immich.yaml
    if ! kubectl -n immich get secret immich-secrets >/dev/null 2>&1; then
      kubectl -n immich create secret generic immich-secrets --from-literal=db-password="$(openssl rand -hex 24)"
    fi
    for d in immich-postgres immich-valkey immich-machine-learning immich-server; do
      kubectl -n immich rollout status "deploy/$d" --timeout=10m
    done

# Check Immich pods, volumes and ingresses
immich-status:
    kubectl -n immich get pods,pvc,ingress

# Deploy Home Assistant (docs/505)
ha-apply:
    kubectl apply -f kubernetes/apps/home-assistant/home-assistant.yaml
    kubectl -n home-automation rollout status deploy/home-assistant --timeout=10m

# Check Home Assistant pods, volume and ingresses
ha-status:
    kubectl -n home-automation get pods,pvc,ingress

# One-time backup setup: copy the upload key into the namespace, create the NAS folder
ha-backup-bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    # `create`, not `apply`: apply would keep a second copy of the secret in an annotation.
    if kubectl -n home-automation get secret s3-backup-credentials >/dev/null 2>&1; then
      echo "Upload key already present."
    else
      kubectl -n backups get secret s3-backup-credentials -o json \
        | jq '{apiVersion, kind, type, data, metadata: {name: .metadata.name, namespace: "home-automation"}}' \
        | kubectl create -f - >/dev/null
      echo "Upload key copied."
    fi
    # NFS can't mount a missing folder, so make it through the whole-share mount in `backups`.
    kubectl -n backups delete job ha-nas-folder --ignore-not-found >/dev/null
    kubectl create -f - >/dev/null <<'EOF'
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: ha-nas-folder
      namespace: backups
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 300
      ttlSecondsAfterFinished: 600
      template:
        spec:
          restartPolicy: Never
          automountServiceAccountToken: false
          containers:
            - name: mkdir
              image: alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6
              command: ["mkdir", "-p", "/nas/apps/home-assistant"]
              volumeMounts:
                - name: nas
                  mountPath: /nas
          volumes:
            - name: nas
              persistentVolumeClaim:
                claimName: pvc-synology-nfs-backups
    EOF
    kubectl -n backups wait --for=condition=complete job/ha-nas-folder --timeout=5m
    echo "NAS folder ready."

# Deploy the Home Assistant backup CronJobs (run ha-backup-bootstrap first)
ha-backup-apply:
    kubectl apply -f kubernetes/apps/home-assistant/home-assistant-backup.yaml
    kubectl -n home-automation get cronjob,pvc

# Run both Home Assistant backups now and show their logs
ha-backup-run:
    #!/usr/bin/env bash
    set -uo pipefail
    STAMP=$(date +%s)
    STATUS=0
    for CJ in backup-home-assistant backup-home-assistant-nas; do
      JOB="$CJ-manual-$STAMP"
      kubectl -n home-automation create job "$JOB" --from="cronjob/$CJ" >/dev/null
      kubectl -n home-automation wait --for=condition=complete "job/$JOB" --timeout=15m || STATUS=1
      kubectl -n home-automation logs "job/$JOB" --all-containers --prefix --tail=-1
    done
    exit "$STATUS"

# Restore the newest S3 backup into a throwaway namespace and check it. boot=yes also
# starts it: only safe with no devices connected, or it would talk to them (docs/505).
ha-restore-drill boot="no" identity="~/homelab-backups.identity.age":
    #!/usr/bin/env bash
    set -euo pipefail
    NS=restore-drill
    BUCKET=s3-aws-backups-prod-use2-001
    IDENTITY="{{identity}}"
    IDENTITY="${IDENTITY/#\~/$HOME}"
    IMAGE=$(kubectl -n home-automation get deploy home-assistant -o jsonpath='{.spec.template.spec.containers[0].image}')
    trap 'kubectl delete namespace "$NS" --ignore-not-found --wait=false >/dev/null' EXIT
    LATEST=$(aws s3 ls "s3://$BUCKET/apps/home-assistant/" | awk '{print $4}' | grep '\.age$' | sort | tail -1)
    [ -n "$LATEST" ] || { echo "No backups found in S3." >&2; exit 1; }
    echo "Restoring $LATEST"
    kubectl create namespace "$NS" >/dev/null
    kubectl -n "$NS" create -f - >/dev/null <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: ha-drill
    spec:
      automountServiceAccountToken: false
      enableServiceLinks: false
      containers:
        - name: ha
          image: $IMAGE
          command: ["sleep", "3600"]
          env:
            - name: TZ
              value: America/Chicago
          volumeMounts:
            - name: config
              mountPath: /config
      volumes:
        - name: config
          emptyDir: {}
    EOF
    kubectl -n "$NS" wait --for=condition=ready pod/ha-drill --timeout=5m >/dev/null
    # Plaintext only passes through this pipe. age asks for the identity passphrase here.
    aws s3 cp "s3://$BUCKET/apps/home-assistant/$LATEST" - \
      | age -d -i "$IDENTITY" \
      | kubectl -n "$NS" exec -i ha-drill -- tar xzf - -C /config
    kubectl -n "$NS" exec ha-drill -- python3 -c '
    import json, os, sqlite3
    db = sqlite3.connect("/config/home-assistant_v2.db")
    print("integrity:", db.execute("PRAGMA integrity_check").fetchone()[0])
    print("schema version:", db.execute("SELECT MAX(schema_version) FROM schema_changes").fetchone()[0])
    for table in ("states", "statistics", "statistics_short_term"):
        print(table + ":", db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0], "rows")
    for path in ("configuration.yaml", ".storage/auth", ".storage/http", ".storage/core.config_entries"):
        print(path + ":", "present" if os.path.exists("/config/" + path) else "MISSING")
    users = json.load(open("/config/.storage/auth"))["data"]["users"]
    print("owner account:", any(u["is_owner"] for u in users))
    '
    if [ "{{boot}}" = "yes" ]; then
      echo "Booting the restored copy (first boot can take a few minutes)..."
      kubectl -n "$NS" exec ha-drill -- sh -c 'nohup python3 -m homeassistant --config /config >/tmp/ha.log 2>&1 &'
      kubectl -n "$NS" exec ha-drill -- python3 -c '
    import json, time, urllib.error, urllib.request
    # Once onboarding is complete, Home Assistant stops serving this endpoint: 404 is
    # the good answer. A 200 listing unfinished steps means the accounts did not restore.
    for _ in range(60):
        try:
            steps = json.load(urllib.request.urlopen("http://127.0.0.1:8123/api/onboarding", timeout=5))
            finished = all(s["done"] for s in steps)
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise SystemExit(f"ERROR: unexpected HTTP {error.code} from the restored copy")
            finished = True
        except OSError:
            time.sleep(5)
            continue
        print("onboarding finished:", finished)
        if not finished:
            raise SystemExit("ERROR: the restored copy wants onboarding again")
        break
    else:
        raise SystemExit("ERROR: restored Home Assistant did not start in 5 minutes")
    '
    fi
    echo "Drill passed. Deleting $NS."

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

# Asks before each irreversible step; LAB_YES=1 skips the prompts.
# Cold-stop the whole cluster: silence, stop apps, freeze Ceph, power off (docs/112)
lab-down:
    #!/usr/bin/env bash
    set -euo pipefail
    REPLICAS=homelab.bar2sek.com/lab-down-replicas
    SUSPENDED=homelab.bar2sek.com/lab-down-suspended
    ceph() { kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph "$@"; }
    am() { kubectl -n monitoring exec alertmanager-kube-prometheus-stack-alertmanager-0 -c alertmanager -- amtool --alertmanager.url=http://localhost:9093 "$@"; }
    step() { printf '\n===> %s\n' "$*"; }
    confirm() {
      [[ ${LAB_YES:-} == 1 ]] && return 0
      read -rp "$1 [y/N] " a
      [[ $a == [yY] ]] || { echo "Stopped here; earlier steps stay done (just lab-up undoes them)." >&2; exit 1; }
    }

    step "1/8 Pre-checks"
    HEALTH=$(ceph health)
    echo "Ceph: $HEALTH"
    kubectl get nodes
    # Node IPs now: once the control plane is down, kubectl can't answer.
    ips() { kubectl get nodes -l "$1" -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{" "}{end}'; }
    WORKERS=$(ips '!node-role.kubernetes.io/control-plane')
    CONTROL=$(ips 'node-role.kubernetes.io/control-plane')
    echo "Workers: $WORKERS"
    echo "Control plane: $CONTROL"
    [[ $HEALTH == HEALTH_OK* ]] || confirm "Ceph is not HEALTH_OK. Continue anyway?"
    confirm "Power down the whole cluster?"

    step "2/8 Silencing all alerts until lab-up (30 days max)"
    am silence add --duration=30d --comment=lab-down 'alertname=~".+"'

    step "3/8 Stopping the gaming VM (if running)"
    if kubectl -n vms get vmi bazzite-gaming-vm >/dev/null 2>&1; then
      virtctl stop bazzite-gaming-vm -n vms
      kubectl -n vms wait --for=delete vmi/bazzite-gaming-vm --timeout=5m
    else
      echo "Not running."
    fi

    step "4/8 Suspending CronJobs (one catch-up run each after lab-up)"
    kubectl get cronjobs -A -o json \
      | jq -r '.items[] | select(.spec.suspend != true) | "\(.metadata.namespace) \(.metadata.name)"' \
      | while read -r ns name; do
          kubectl -n "$ns" annotate cronjob "$name" "$SUSPENDED=true" --overwrite >/dev/null
          kubectl -n "$ns" patch cronjob "$name" --type merge -p '{"spec":{"suspend":true}}'
        done

    step "5/8 Scaling every workload with a Ceph volume to 0"
    # Pods (not Jobs or VMs) mounting a rook-ceph PVC -> the object that owns
    # their replica count: Deployment, StatefulSet, or for operator-managed
    # StatefulSets the Prometheus/Alertmanager resource above them.
    PVCS=$(kubectl get pvc -A -o json | jq -c '[.items[] | select((.spec.storageClassName // "") | startswith("rook-ceph")) | "\(.metadata.namespace)/\(.metadata.name)"]')
    TARGETS=$(kubectl get pods -A -o json | jq -r --argjson pvcs "$PVCS" '
        .items[] | .metadata.namespace as $ns
        | select(any(.spec.volumes[]?; .persistentVolumeClaim.claimName as $c | $c != null and ($pvcs | index("\($ns)/\($c)")) != null))
        | (.metadata.ownerReferences // [])[0]
        | select(. != null and (.kind == "ReplicaSet" or .kind == "StatefulSet"))
        | "\($ns) \(.kind)/\(.name)"' | sort -u \
      | while read -r ns obj; do
          owner=$(kubectl -n "$ns" get "$obj" -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}')
          [[ $owner == / ]] && owner=$obj
          echo "$ns $owner"
        done | sort -u)
    echo "$TARGETS"
    while read -r ns obj; do
      [[ -z $ns ]] && continue
      n=$(kubectl -n "$ns" get "$obj" -o jsonpath='{.spec.replicas}')
      kubectl -n "$ns" annotate "$obj" "$REPLICAS=${n:-1}" --overwrite >/dev/null
      case ${obj%%/*} in
        Deployment|StatefulSet|ReplicaSet) kubectl -n "$ns" scale "$obj" --replicas=0 ;;
        *) kubectl -n "$ns" patch "$obj" --type merge -p '{"spec":{"replicas":0}}' ;;
      esac
    done <<< "$TARGETS"

    echo "Waiting for Ceph volumes to detach..."
    attached() { kubectl get volumeattachments -o json | jq '[.items[] | select(.spec.attacher | startswith("rook-ceph"))] | length'; }
    for _ in $(seq 60); do
      n=$(attached)
      [[ $n == 0 ]] && break
      echo "  $n still attached"
      sleep 10
    done
    [[ $(attached) == 0 ]] || confirm "Ceph volumes still attached after 10 min. Continue anyway?"

    step "6/8 Freezing Ceph and pausing the Rook operator"
    # The operator would otherwise fail over the monitor of any node that is
    # slow to come back (10 min) during lab-up.
    for f in noout norebalance nobackfill norecover; do ceph osd set "$f"; done
    kubectl -n rook-ceph scale deploy/rook-ceph-operator --replicas=0

    step "7/8 Powering off workers: $WORKERS"
    confirm "Last check before nodes go off. Proceed?"
    # --force skips cordon/drain: the apps are already stopped, and a drain
    # needs the API server, which disappears with the control plane.
    for ip in $WORKERS; do talosctl -n "$ip" shutdown --force; done

    step "8/8 Powering off control plane: $CONTROL"
    for ip in $CONTROL; do talosctl -n "$ip" shutdown --force; done

    printf '\nCluster is off. Network, omni-server and the Synology stay on.\nStart it again with: just lab-up\n'

# Cold-start the cluster after lab-down: wait for nodes, thaw Ceph, restore apps
lab-up:
    #!/usr/bin/env bash
    set -euo pipefail
    REPLICAS=homelab.bar2sek.com/lab-down-replicas
    SUSPENDED=homelab.bar2sek.com/lab-down-suspended
    ceph() { kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph "$@"; }
    am() { kubectl -n monitoring exec alertmanager-kube-prometheus-stack-alertmanager-0 -c alertmanager -- amtool --alertmanager.url=http://localhost:9093 "$@"; }
    step() { printf '\n===> %s\n' "$*"; }
    # wait_for <seconds> <what> <command...>: poll every 10 s until it succeeds
    wait_for() {
      local limit=$1 what=$2 t=0; shift 2
      until "$@" >/dev/null 2>&1; do
        (( t >= limit )) && { echo "Timed out after ${limit}s waiting for $what" >&2; return 1; }
        sleep 10; t=$((t + 10)); echo "  waiting for $what (${t}s)"
      done
    }
    START=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    step "1/6 Power on the nodes"
    echo "Control plane first: sm-node-01..03 (IPMI https://10.10.10.11-13 or the power button),"
    echo "then pc-node-04 and pc-node-05. This waits for them."
    wait_for 1800 "the Kubernetes API" kubectl get --raw /readyz

    step "2/6 Waiting for every node to report Ready"
    # Status left over from before the shutdown can still say Ready, so require
    # a heartbeat newer than the start of this recipe.
    fresh() {
      kubectl get nodes -o json | jq -e --arg t "$START" \
        'all(.items[]; any(.status.conditions[]; .type == "Ready" and .status == "True" and .lastHeartbeatTime > $t))'
    }
    wait_for 1800 "all nodes Ready" fresh
    kubectl get nodes

    step "3/6 Resuming the Rook operator; waiting for every OSD"
    kubectl -n rook-ceph scale deploy/rook-ceph-operator --replicas=1
    wait_for 600 "the Ceph toolbox" kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
    osds_up() { ceph osd stat -f json | jq -e '.num_osds > 0 and .num_up_osds == .num_osds'; }
    wait_for 1200 "all OSDs up" osds_up
    ceph osd stat

    step "4/6 Thawing Ceph; waiting for all PGs active+clean"
    for f in norecover nobackfill norebalance noout; do ceph osd unset "$f"; done
    # active+clean+scrubbing(+deep) counts as clean: after days off, overdue
    # scrubs run for a long time and would otherwise hit the timeout.
    clean() { ceph pg stat -f json | jq -e '.pg_summary | .num_pgs == ([.num_pg_by_state[] | select(.name | test("^active\\+clean(\\+scrubbing(\\+deep)?)?$")) | .num] | add // 0)'; }
    wait_for 1800 "all PGs active+clean" clean
    ceph health

    step "5/6 Restoring workloads, then CronJobs once the workloads are ready"
    # Process substitution, not a pipe: the loop must run in this shell so
    # ROLLOUTS survives it.
    ROLLOUTS=()
    while read -r ns obj n; do
      case ${obj%%/*} in
        Deployment|StatefulSet) kubectl -n "$ns" scale "$obj" --replicas="$n"; ROLLOUTS+=("$ns $obj") ;;
        ReplicaSet) kubectl -n "$ns" scale "$obj" --replicas="$n" ;;
        *) kubectl -n "$ns" patch "$obj" --type merge -p "{\"spec\":{\"replicas\":$n}}" ;;
      esac
      kubectl -n "$ns" annotate "$obj" "$REPLICAS-" >/dev/null
    done < <(
      for kind in deployments statefulsets replicasets prometheuses.monitoring.coreos.com alertmanagers.monitoring.coreos.com; do
        kubectl get "$kind" -A -o json \
          | jq -r --arg a "$REPLICAS" '.items[] | select(.metadata.annotations[$a] != null) | "\(.metadata.namespace) \(.kind)/\(.metadata.name) \(.metadata.annotations[$a])"'
      done
    )
    # Resuming a CronJob fires its catch-up run immediately. Started before the
    # databases are up, the Postgres backups burn their retries and fail
    # (2026-11-03). On timeout, warn and resume anyway: one failed catch-up run
    # is better than backups left suspended, and step 6 must still run.
    NOT_READY=()
    # ${a[@]+...}: an empty array is "unbound" under set -u in macOS bash 3.2
    for r in ${ROLLOUTS[@]+"${ROLLOUTS[@]}"}; do
      read -r ns obj <<<"$r"
      kubectl -n "$ns" rollout status "$obj" --timeout=5m || NOT_READY+=("$ns/$obj")
    done
    if (( ${#NOT_READY[@]} )); then
      echo "WARNING: not ready after 5 min: ${NOT_READY[*]}. Resuming CronJobs anyway; check their catch-up jobs." >&2
    fi
    kubectl get cronjobs -A -o json \
      | jq -r --arg a "$SUSPENDED" '.items[] | select(.metadata.annotations[$a] != null) | "\(.metadata.namespace) \(.metadata.name)"' \
      | while read -r ns name; do
          kubectl -n "$ns" patch cronjob "$name" --type merge -p '{"spec":{"suspend":false}}'
          kubectl -n "$ns" annotate cronjob "$name" "$SUSPENDED-" >/dev/null
        done

    step "6/6 Expiring the lab-down alert silence"
    wait_for 600 "Alertmanager" kubectl -n monitoring wait --for=condition=Ready pod/alertmanager-kube-prometheus-stack-alertmanager-0 --timeout=10s
    IDS=$(am silence query -o json | jq -r '.[] | select(.comment == "lab-down") | .id')
    if [[ -n $IDS ]]; then am silence expire $IDS; else echo "None found."; fi

    printf '\nPods not Running/Completed (should settle within a few minutes):\n'
    kubectl get pods -A --no-headers | grep -vE 'Running|Completed' || echo "  none"
    printf '\nCluster is up. The gaming VM stays off: just bazzite-start\n'

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

# Start the gaming VM (runStrategy Manual: nothing starts it automatically)
bazzite-start:
    virtctl start bazzite-gaming-vm -n vms
    until kubectl -n vms get vmi bazzite-gaming-vm >/dev/null 2>&1; do sleep 2; done
    kubectl -n vms wait --for=condition=Ready vmi/bazzite-gaming-vm --timeout=10m

# Shut the gaming VM down (ACPI power-off from inside the guest)
bazzite-stop:
    virtctl stop bazzite-gaming-vm -n vms

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

