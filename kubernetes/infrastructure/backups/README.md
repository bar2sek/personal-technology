# 💾 Offsite Cloud & On-Premises Backup Architecture

This directory defines the automated backup infrastructure for the hybrid homelab cluster, implementing tiered disaster recovery that balances cost against data durability.

---

## 🎯 Tiered Backup Strategy

| Tier | Target Data | Engine & Frequency | Destination | Cost |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Control Plane State** | Talos / Kubernetes etcd Snapshots | `backup-etcd-snapshot` CronJob (Daily 03:00 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/etcd/`) | ~$0.01 / month |
| **Tier 2: Relational Databases** | Immich & TeslaMate PostgreSQL dumps | `backup-postgres-databases` CronJob (Daily 03:30 UTC) | AWS S3 (`s3-aws-backups-prod-use2-001/postgres/`) | ~$0.01 / month |
| **Tier 3: Bulk Media & PVC Volumes** | Immich Photo Library (500GB+), Home Assistant, persistent volumes | Synology NAS via NFS/iSCSI (Local Backup Pipeline) | Local Synology NAS (10GbE network) | $0.00 cloud cost |

---

## 🚀 Setup & Credentials

1. **Deploy S3 Credentials**:
   Copy [`backup-credentials.example.yaml`](backup-credentials.example.yaml) to `backup-credentials.yaml` and populate with IAM user credentials scoped strictly to `s3-aws-backups-prod-use2-001`:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f backup-credentials.yaml
   ```

2. **Deploy CronJobs**:
   ```bash
   kubectl apply -f cronjob-etcd.yaml
   kubectl apply -f cronjob-postgres.yaml
   ```

3. **Manual Trigger & Test**:
   ```bash
   kubectl create job --from=cronjob/backup-etcd-snapshot etcd-manual-test -n backups
   kubectl logs -n backups -l job-name=etcd-manual-test -f
   ```

---

## 🔄 Disaster Recovery / Restore Runbook

### A. Restoring etcd from Snapshot
```bash
# 1. Download snapshot from S3
aws s3 cp s3://s3-aws-backups-prod-use2-001/etcd/<snapshot-name>.snapshot.gz .
gunzip <snapshot-name>.snapshot.gz

# 2. Recover via Talosctl
talosctl -n 10.10.20.10 etcd recover --snapshot <snapshot-name>.snapshot
```

### B. Restoring PostgreSQL Database
```bash
# 1. Download database dump
aws s3 cp s3://s3-aws-backups-prod-use2-001/postgres/immich/<immich-dump>.sql.gz .
gunzip <immich-dump>.sql.gz

# 2. Restore into pod
kubectl exec -i -n immich deploy/immich-postgres -- psql -U postgres -d immich < <immich-dump>.sql
```
