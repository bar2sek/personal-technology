# TeslaMate Vehicle Telemetry & Analytics Platform

This guide outlines the architecture and Kubernetes deployment manifest for **[TeslaMate](https://github.com/teslamate-org/teslamate)** — the premier open-source, self-hosted Tesla data logger and analytics platform.

---

## 🏎 Why TeslaMate?

- **100% Self-Hosted & Private**: Your vehicle location, driving telemetry, and charging history remain stored exclusively in your homelab.
- **Pre-Built Grafana Dashboards**: Includes 20+ detailed dashboards:
  - **Battery Health & Capacity Degradation Curve**
  - **Drive Log & Trip Maps** (Speed, elevation, ambient temp, consumption Wh/km)
  - **Charge Log & Cost Tracker** (Track exact $ spent per charge session)
  - **Vampire Drain Analytics** (Sleep mode vs active drain monitoring)
  - **Lifetime Mileage & Efficiency Breakdown**
- **Home Assistant / MQTT Integration**: Publishes real-time vehicle status (charging state, battery %, climate control, doors, tire pressure) to Mosquitto MQTT.

---

## 🏗 Architecture Blueprint

```
                      +---------------------------------------+
                      |         Tesla Fleet API / Car         |
                      +---------------------------------------+
                                          | HTTPS / Telemetry API
                                          v
                      +---------------------------------------+
                      |           TeslaMate Pod               |
                      |  (Elixir/Erlang Realtime Service)     |
                      +---------------------------------------+
                        /                 |                 \
     +-----------------------+ +-----------------------+ +-----------------------+
     | PostgreSQL Database   | | Mosquitto MQTT        | | Grafana Dashboards    |
     | (Rook-Ceph SSD PVC)   | | (Home Assistant Bus)| | (Visual Analytics)   |
     +-----------------------+ +-----------------------+ +-----------------------+
```

---

## 📦 Kubernetes Manifest (`teslamate.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: teslamate
---
# PostgreSQL PVC backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: teslamate-db-pvc
  namespace: teslamate
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 20Gi
---
# PostgreSQL Database Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: teslamate-db
  namespace: teslamate
spec:
  replicas: 1
  selector:
    matchLabels:
      app: teslamate-db
  template:
    metadata:
      labels:
        app: teslamate-db
    spec:
      containers:
        - name: postgres
          image: postgres:16-alpine
          env:
            - name: POSTGRES_USER
              value: teslamate
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: teslamate-secrets
                  key: db-password
            - name: POSTGRES_DB
              value: teslamate
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: db-storage
      volumes:
        - name: db-storage
          persistentVolumeClaim:
            claimName: teslamate-db-pvc
---
# TeslaMate Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: teslamate
  namespace: teslamate
spec:
  replicas: 1
  selector:
    matchLabels:
      app: teslamate
  template:
    metadata:
      labels:
        app: teslamate
    spec:
      containers:
        - name: teslamate
          image: teslamate/teslamate:latest
          env:
            - name: DATABASE_USER
              value: teslamate
            - name: DATABASE_PASS
              valueFrom:
                secretKeyRef:
                  name: teslamate-secrets
                  key: db-password
            - name: DATABASE_NAME
              value: teslamate
            - name: DATABASE_HOST
              value: teslamate-db
            - name: MQTT_HOST
              value: mosquitto
          ports:
            - containerPort: 4000
              name: http
```
