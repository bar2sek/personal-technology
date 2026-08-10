# Mealie Self-Hosted Recipe Manager & Meal Planner

This guide outlines the architecture and Kubernetes deployment manifest for **[Mealie](https://mealie.io/)** — the premier open-source recipe management, meal planning, and automated shopping list platform.

---

## 🍳 Why Mealie?

- **Automatic Recipe Web Scraping**: Simply paste a URL from any cooking blog or recipe website, and Mealie automatically extracts title, prep time, ingredients, step-by-step instructions, nutrition, and photos!
- **Interactive Weekly Meal Planner**: Schedule meals on a calendar for your household.
- **Smart Grocery / Shopping Lists**: Automatically aggregates ingredients from your planned meals into an organized grocery shopping list categorized by supermarket aisle.
- **OCR Cookbook Scanning**: Snap a photo of a physical cookbook page or handwritten recipe card to import it directly into your digital collection.
- **Household & Multi-User Support**: Share meal plans and live grocery lists across your household on Web and Mobile (PWA).

---

## 📦 Mealie Kubernetes Manifest (`mealie.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mealie
---
# Persistent Storage backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mealie-data-pvc
  namespace: mealie
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 10Gi
---
# Mealie Server Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mealie
  namespace: mealie
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mealie
  template:
    metadata:
      labels:
        app: mealie
    spec:
      containers:
        - name: mealie
          image: ghcr.io/mealie-meals/mealie:v1.12.0
          env:
            - name: ALLOW_SIGNUP
              value: "true"
            - name: PUID
              value: "1000"
            - name: PGID
              value: "1000"
            - name: TZ
              value: "America/Chicago"
            - name: BASE_URL
              value: "https://mealie.homelab.local"
          ports:
            - containerPort: 9000
              name: http
          volumeMounts:
            - mountPath: /app/data
              name: mealie-data
      volumes:
        - name: mealie-data
          persistentVolumeClaim:
            claimName: mealie-data-pvc
---
# Service Exposure
apiVersion: v1
kind: Service
metadata:
  name: mealie-service
  namespace: mealie
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 9000
      name: http
  selector:
    app: mealie
```
