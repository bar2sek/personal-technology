# Home Assistant Smart Home & IoT Automation Platform

This guide outlines the resource capacity, integration architecture, and Kubernetes deployment manifest for **[Home Assistant](https://www.home-assistant.io/)** — the premier open-source smart home automation platform.

---

## ⚡ Cluster Capacity Analysis

Does our cluster have room for Home Assistant? **YES! You have massive unused headroom.**

| Resource | Total Cluster Capacity | Home Assistant Requirement | % of Cluster Used |
| :--- | :--- | :--- | :--- |
| **System Memory (RAM)** | **320 GB** | ~0.5 GB | **< 0.15%** |
| **CPU Compute** | **72 vCPU Threads** | ~0.2 vCPU | **< 0.3%** |
| **Storage (Ceph SSD)** | **16.0 TB** | 10.0 GB | **< 0.06%** |

---

## 🔗 Powerful Ecosystem Integrations in Our Cluster

Running Home Assistant inside our Talos cluster unlocks incredible cross-application automations:

1. **TeslaMate + Home Assistant (via MQTT)**:
   - Real-time Tesla battery levels, charging state, climate control, and door locks feed directly into Home Assistant.
   - *Example Automation*: *"If Tesla battery is below 50% and home electricity rates enter off-peak at 11 PM, start charging automatically."*
2. **UniFi Network Presence Detection**:
   - Integrates natively with your UniFi Dream Machine Pro / USW switches to track family smartphones joining home Wi-Fi for instant **Home vs Away** presence detection.
   - *Example Automation*: *"When all phones leave home Wi-Fi, turn off lights, set HVAC to eco mode, and arm cameras."*
3. **Mealie Integration**:
   - Displays tonight's planned meal and recipe instructions on wall-mounted smart home dashboards or TV screens.

---

## 📦 Home Assistant Kubernetes Manifest (`home-assistant.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: home-automation
---
# Persistent Storage backed by Rook-Ceph SSD Pool
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: home-assistant-config-pvc
  namespace: home-automation
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 10Gi
---
# Home Assistant Core Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: home-assistant
  namespace: home-automation
spec:
  replicas: 1
  selector:
    matchLabels:
      app: home-assistant
  template:
    metadata:
      labels:
        app: home-assistant
    spec:
      hostNetwork: true # Allows mDNS & SSDP local device discovery
      containers:
        - name: home-assistant
          image: ghcr.io/home-assistant/home-assistant:stable
          env:
            - name: TZ
              value: "America/Chicago"
          volumeMounts:
            - mountPath: /config
              name: config-storage
      volumes:
        - name: config-storage
          persistentVolumeClaim:
            claimName: home-assistant-config-pvc
```
