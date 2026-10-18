# Actual Budget Self-Hosted Finance Platform

This guide outlines the architecture, bank sync integration, and Kubernetes deployment manifest for **[Actual Budget](https://actualbudget.org/)** — our selected self-hosted personal finance platform.

---

## 💡 Why Actual Budget?

- **Zero-Based / Envelope Budgeting**: Gives every dollar a job (identical to YNAB).
- **100% Local-First & End-to-End Encrypted**: All financial data is encrypted client-side on your devices before syncing to your homelab server.
- **Automated US/Canada Bank Sync**: Native integration with **SimpleFIN Bridge** to automatically pull bank accounts, credit cards, and investment transactions.
- **Multi-Device Support**: Native web interface, PWA mobile app for iOS/Android, and desktop apps.
- **Lightweight Kubernetes Pod**: Runs in a minimal Node.js/SQLite container backed by **Rook-Ceph SSD PersistentVolumeClaims**.

---

## 🏦 Step-by-Step Setup: Automated Bank Sync (SimpleFIN)

1. Sign up for a [SimpleFIN Bridge](https://bridge.simplefin.org/) token ($15/year for unlimited bank connections).
2. Connect your bank accounts (Chase, Bank of America, Fidelity, Capital One, etc.) in SimpleFIN.
3. Open Actual Budget Settings > **Bank Sync**.
4. Paste your SimpleFIN access token. Actual Budget will automatically pull your daily transactions and auto-categorize expenses!

---

## 📦 Actual Budget Kubernetes Manifest (`actual-budget.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: finance
---
# Persistent Storage backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: actual-budget-data-pvc
  namespace: finance
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 5Gi
---
# Actual Budget Server Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: actual-budget
  namespace: finance
spec:
  replicas: 1
  selector:
    matchLabels:
      app: actual-budget
  template:
    metadata:
      labels:
        app: actual-budget
    spec:
      containers:
        - name: actual-server
          image: actualbudget/actual-server:latest
          ports:
            - containerPort: 5006
              name: http
          volumeMounts:
            - mountPath: /data
              name: actual-data
      volumes:
        - name: actual-data
          persistentVolumeClaim:
            claimName: actual-budget-data-pvc
---
# Service Exposure
apiVersion: v1
kind: Service
metadata:
  name: actual-budget-service
  namespace: finance
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 5006
      name: http
  selector:
    app: actual-budget
```

> [!NOTE]
> The manifest above is an early snapshot. `kubernetes/apps/finance/actual-budget.yaml` and `actual-budget-backup.yaml` are the source of truth.

---

## 📍 Node Placement & Backups (2026-10-18)

The Deployment **prefers non-control-plane nodes** (`nodeAffinity` on `node-role.kubernetes.io/control-plane DoesNotExist`), so it runs on pc-node-04 or pc-node-05.

**Why:** the backup CronJobs mount the app's RWO Ceph volume, so `podAffinity` pins them to whichever node runs the app. While the app ran on sm-node-03, the 2026-10-18 S3 backup was **evicted three times** for `ephemeral-storage`. The sm nodes boot from 16 GB SuperDOMs with a 12.5 GiB `/var`, and sm-node-03 had 7.5 GiB of it filled with container images; pulling the `aws-cli` image tipped it over the kubelet's eviction threshold. The backup itself is tiny (about 37 KiB encrypted), so moving its scratch space to Ceph would not have helped. Container images always live on the node's own disk, so the fix is to keep the pod off the small disks.

> [!TIP]
> **Run a backup on demand** (for example after a failed night):
> ```bash
> kubectl -n finance create job --from=cronjob/backup-actual-budget backup-actual-budget-manual-$(date +%m%d)
> kubectl -n finance logs job/backup-actual-budget-manual-$(date +%m%d) --all-containers | tail -3
> ```
> A failed Job keeps `KubeJobFailed` firing until the Job object is deleted (`kubectl -n finance delete job <name>`), even after a later run succeeds.
