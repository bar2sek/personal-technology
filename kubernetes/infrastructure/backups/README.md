# 💾 Offsite Cloud & On-Premises Backup Architecture

This directory defines the automated backup infrastructure for the hybrid homelab cluster, implementing tiered disaster recovery that balances cost against data durability.

---

## 🎯 Tiered Backup Strategy

| Tier | Target Data | Engine & Frequency | Destination | Status & Durability |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Control Plane & Cluster State** | Declarative K8s State (CRDs, PVs, namespaces, secrets, workloads) | `backup-cluster-state` CronJob (Daily 03:00 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/cluster-state/`) | **Active**: ~$0.01 / month |
| **Tier 2: Relational Databases** | Authentik (active) & TeslaMate (when deployed) PostgreSQL dumps | `backup-postgres-databases` CronJob (Daily 03:30 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/postgres/`) | **Active**: ~$0.01 / month |
| **Tier 3: Bulk Media & Large PVCs** | Home Assistant & application volumes | Synology NAS via NFS/rsync (Garage 1GbE Pipeline) | Garage Synology NAS | **Planned (Hardware Backlog)**. Current local state: Ceph replicated storage (`reclaimPolicy: Retain`). |

> [!IMPORTANT]
> **Data Protection Invariant (`reclaimPolicy: Retain`)**: All production Ceph storage classes (`rook-ceph-block`, `rook-ceph-block-nvme`, `rook-ceph-hdd-bulk`, `rook-ceph-filesystem`) are explicitly configured with `reclaimPolicy: Retain`. If an application namespace or PersistentVolumeClaim is deleted, the underlying Ceph volume is preserved in `Released` state rather than purged.

---

1. **Create Least-Privilege IAM User & Access Keys**:
   The backup jobs authenticate via static AWS IAM credentials scoped strictly to the offsite backup bucket. You can provision this user via the AWS CLI:

   ```bash
   # 1. Create IAM user
   aws iam create-user --user-name svc-homelab-backup-uploader

   # 2. Attach least-privilege policy (S3 PutObject strictly scoped to backup bucket)
   cat << 'EOF' > /tmp/backup-policy.json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowBackupUploadsOnly",
         "Effect": "Allow",
         "Action": [
           "s3:PutObject",
           "s3:ListBucket",
           "s3:GetObject"
         ],
         "Resource": [
           "arn:aws:s3:::s3-aws-backups-prod-use2-001",
           "arn:aws:s3:::s3-aws-backups-prod-use2-001/*"
         ]
       }
     ]
   }
   EOF

   aws iam put-user-policy \
     --user-name svc-homelab-backup-uploader \
     --policy-name HomelabBackupsPolicy \
     --policy-document file:///tmp/backup-policy.json

   # 3. Generate access key
   aws iam create-access-key --user-name svc-homelab-backup-uploader
   ```

2. **Deploy S3 Credentials to Kubernetes**:
   Copy [`backup-credentials.example.yaml`](backup-credentials.example.yaml) to `backup-credentials.yaml`, insert the generated Access Key ID & Secret Access Key:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f backup-credentials.yaml
   ```

3. **Deploy CronJobs & RBAC**:
   ```bash
   kubectl apply -f cronjob-cluster-state.yaml
   kubectl apply -f cronjob-postgres.yaml
   ```
   > [!NOTE]
   > `cronjob-postgres.yaml` configures a dedicated `postgres-backup-sa` ServiceAccount and fine-grained `Role` and `RoleBinding` objects in the `identity` namespace. This grants the backup runner read-only access to `authentik-secrets` directly via the Kubernetes API, preventing credential duplication while keeping AWS S3 credentials restricted to `backups`. (TeslaMate backup RBAC is configured alongside its app manifest when deployed).

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

# If client-side encryption was enabled, decrypt the .enc archive:
# openssl enc -d -aes-256-cbc -pbkdf2 -in <archive-name>.tar.gz.enc -out <archive-name>.tar.gz -pass pass:<YOUR_PASSPHRASE>

mkdir -p restore && tar -xzf <archive-name>.tar.gz -C restore

# 2. Re-apply CRDs and cluster-scoped resources (StorageClasses, PVs, RBAC)
kubectl apply -f restore/cluster-scoped/crds.json
kubectl apply -f restore/cluster-scoped/cluster-resources.json

# 3. Re-apply declarative namespaced workloads
for ns in restore/namespaces/*; do
  if [ -f "$ns/declarative-resources.json" ]; then
    echo "Restoring declarative workloads in namespace: $(basename "$ns")..."
    kubectl apply -f "$ns/declarative-resources.json"
  fi
done
```

### B. Restoring PostgreSQL Databases
```bash
# --- Authentik Database Restore (Active Production) ---
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/authentik/<authentik-dump>.sql.gz .
gunzip <authentik-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n identity deploy/authentik-db -- psql -U authentik -d authentik < <authentik-dump>.sql

# --- TeslaMate Database Restore (When Deployed) ---
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/teslamate/<teslamate-dump>.sql.gz .
gunzip <teslamate-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n teslamate deploy/teslamate-db -- psql -U teslamate -d teslamate < <teslamate-dump>.sql
```
