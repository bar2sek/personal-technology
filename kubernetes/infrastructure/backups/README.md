# 💾 Offsite Cloud & On-Premises Backup Architecture

This directory defines the automated backup infrastructure for the hybrid homelab cluster, implementing tiered disaster recovery that balances cost against data durability.

---

## 🎯 Tiered Backup Strategy

| Tier | Target Data | Engine & Frequency | Destination | Status & Durability |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Control Plane & Cluster State** | Declarative K8s State (CRDs, PVs, namespaces, secrets, workloads) | `backup-cluster-state` CronJob (Daily 03:00 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/cluster-state/`) | **Active**: ~$0.01 / month |
| **Tier 2: Relational Databases** | Immich, TeslaMate & Authentik PostgreSQL dumps | `backup-postgres-databases` CronJob (Daily 03:30 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/postgres/`) | **Active**: ~$0.01 / month |
| **Tier 3: Bulk Media & Large PVCs** | Immich Photo Library (500GB+), Home Assistant, persistent volumes | Synology NAS via NFS/rsync (Garage 1GbE Isolated Pipeline) | Garage Synology NAS via `USW-Lite-8-PoE` | **Planned (Hardware Backlog)**. Current local state: Ceph replicated storage (`reclaimPolicy: Retain`). |

> [!IMPORTANT]
> **Data Protection Invariant (`reclaimPolicy: Retain`)**: All production Ceph storage classes (`rook-ceph-block`, `rook-ceph-block-nvme`, `rook-ceph-hdd-bulk`, `rook-ceph-filesystem`) are explicitly configured with `reclaimPolicy: Retain`. If an application namespace or PersistentVolumeClaim is deleted, the underlying Ceph volume is preserved in `Released` state rather than purged.

---

## 🚀 Setup & Credentials

1. **Deploy S3 Credentials**:
   Copy [`backup-credentials.example.yaml`](backup-credentials.example.yaml) to `backup-credentials.yaml` and populate with IAM user credentials scoped strictly to `s3-aws-backups-prod-use2-001`:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f backup-credentials.yaml
   ```

2. **Deploy CronJobs & RBAC**:
   ```bash
   kubectl apply -f cronjob-cluster-state.yaml
   kubectl apply -f cronjob-postgres.yaml
   ```
   > [!NOTE]
   > `cronjob-postgres.yaml` configures a dedicated `postgres-backup-sa` ServiceAccount and fine-grained `Role` and `RoleBinding` objects in the `immich`, `teslamate`, and `identity` namespaces. This grants the backup runner read-only access to `immich-secrets`, `teslamate-secrets`, and `authentik-secrets` directly via the Kubernetes API, preventing credential duplication while keeping AWS S3 credentials restricted to `backups`.

3. **Manual Trigger & Test**:
   ```bash
   # Test cluster-state backup:
   kubectl create job --from=cronjob/backup-cluster-state cluster-backup-test -n backups
   kubectl logs -n backups -l job-name=cluster-backup-test -f

   # Test PostgreSQL databases backup:
   kubectl create job --from=cronjob/backup-postgres-databases postgres-backup-test -n backups
   kubectl logs -n backups -l job-name=postgres-backup-test -f
   ```

---

## 🔄 Disaster Recovery / Restore Runbook

### A. Restoring Cluster State & Workloads
```bash
# 1. Download cluster state archive from S3
aws s3 cp s3://s3-aws-backups-prod-use2-001/cluster-state/<archive-name>.tar.gz .
mkdir -p restore && tar -xzf <archive-name>.tar.gz -C restore

# 2. Re-apply CRDs and cluster-scoped resources
kubectl apply -f restore/cluster-scoped/crds.yaml
kubectl apply -f restore/cluster-scoped/cluster-resources.yaml

# 3. Re-apply namespaced resources (per namespace or all)
for ns in restore/namespaces/*; do
  kubectl apply -f "$ns/all-resources.yaml"
done
```

### B. Restoring PostgreSQL Databases
```bash
# --- Immich Database Restore ---
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/immich/<immich-dump>.sql.gz .
gunzip <immich-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n immich deploy/immich-postgres -- psql -U postgres -d immich < <immich-dump>.sql

# --- TeslaMate Database Restore ---
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/teslamate/<teslamate-dump>.sql.gz .
gunzip <teslamate-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n teslamate deploy/teslamate-db -- psql -U teslamate -d teslamate < <teslamate-dump>.sql

# --- Authentik Database Restore ---
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/authentik/<authentik-dump>.sql.gz .
gunzip <authentik-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n identity deploy/authentik-db -- psql -U authentik -d authentik < <authentik-dump>.sql
```
