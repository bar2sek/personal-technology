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
