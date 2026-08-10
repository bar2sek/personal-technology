# Immich Self-Hosted Photo & Video Backup Platform

This guide details the features, iOS integration, NVIDIA GPU hardware acceleration, and Kubernetes deployment manifest for **[Immich](https://immich.app/)** — the premier open-source Google Photos / Apple iCloud Photos replacement.

---

## 📸 Immich on iPhone (iOS Integration)

Immich features a native, high-performance iOS app (available on the Apple App Store) that serves as a seamless replacement for iCloud Photos:

### Key iOS Features:

1. **Background Auto-Backup**: Automatically backs up new photos and videos from your iPhone camera roll in full original resolution in the background.
2. **Apple Live Photos Support**: Full native support for Apple Live Photos (preserves the video movement and audio alongside the HEIC photo).
3. **HEIC & HEVC Native Handling**: Stores and renders Apple's high-efficiency HEIC photos and 4K HEVC videos directly.
4. **AI Facial Recognition & Semantic Search**: Server-side AI groups faces, detects objects, and allows natural language searches (e.g. *"sunset at beach"*, *"dog playing in snow"*).
5. **Interactive Map View**: World map visualization based on EXIF GPS metadata.
6. **Multi-User Family Sharing**: Create shared albums for household members with individual user privacy.

---

## ⚡ NVIDIA RTX 4070 GPU Hardware Acceleration (`pc-node-05`)

Immich utilizes Machine Learning (ML) models for face detection, CLIP search, and video transcoding. By deploying the Immich Machine Learning container onto **`pc-node-05`** with our **NVIDIA RTX 4070 GPU**, AI photo indexing and 4K video transcoding complete **instantaneously**!

---

## 📦 Immich Kubernetes Manifest (`immich.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: immich
---
# PostgreSQL PVC backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: immich-postgres-pvc
  namespace: immich
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 20Gi
---
# Immich Media Storage PVC (SATA SSD / HDD Pool)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: immich-library-pvc
  namespace: immich
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 500Gi
---
# Immich Server Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: immich-server
  namespace: immich
spec:
  replicas: 1
  selector:
    matchLabels:
      app: immich-server
  template:
    metadata:
      labels:
        app: immich-server
    spec:
      containers:
        - name: immich-server
          image: ghcr.io/immich-app/immich-server:release
          env:
            - name: DB_HOSTNAME
              value: immich-postgres
            - name: DB_USERNAME
              value: postgres
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: immich-secrets
                  key: db-password
            - name: DB_DATABASE_NAME
              value: immich
            - name: REDIS_HOSTNAME
              value: immich-redis
          ports:
            - containerPort: 2283
              name: http
          volumeMounts:
            - mountPath: /usr/src/app/upload
              name: library-storage
      volumes:
        - name: library-storage
          persistentVolumeClaim:
            claimName: immich-library-pvc
```
