# KubeVirt Windows Gaming VM with NVIDIA RTX 4070 GPU Passthrough

This document outlines the architecture, kernel configuration, and deployment workflow to run a **Windows 11 Cloud Gaming Virtual Machine** with **NVIDIA RTX 4070 VFIO PCIe Passthrough** inside our bare-metal Talos Linux Kubernetes cluster using **KubeVirt**.

---

## 🎯 Architecture Overview

```
 +--------------------------------------------------------------------------------+
 |                           pc-node-05 (Talos Linux Node)                        |
 |                                                                                |
 |  +--------------------------------------------------------------------------+  |
 |  |                             KubeVirt Operator                            |  |
 |  +--------------------------------------------------------------------------+  |
 |                                      |                                         |
 |  +--------------------------------------------------------------------------+  |
 |  |                    Windows 11 Gaming VirtualMachine                      |  |
 |  |                                                                          |  |
 |  |   - OS: Windows 11 Pro (KubeVirt VirtIO Drivers)                          |  |
 |  |   - Direct PCIe Passthrough: NVIDIA GeForce RTX 4070 (12GB VRAM)          |  |
 |  |   - Remote Streaming Server: Sunshine / Parsec (4K @ 120Hz / AV1 NVENC)  |  |
 |  |   - Storage: High-IOPS NVMe PersistentVolumeClaim (Rook-Ceph / Local)    |  |
 |  +--------------------------------------------------------------------------+  |
 |                                      |                                         |
 |                         NVIDIA RTX 4070 (VFIO-PCI)                             |
 +--------------------------------------------------------------------------------+
                                        | 2.5GbE / 10GbE Network Stream
                                        v
                       +----------------------------------+
                       |  Moonlight Client Devices        |
                       |  (MacBook, Apple TV, iPad, PC)   |
                       +----------------------------------+
```

---

## 🛠 Step 1: Talos Linux Kernel Configuration (`pc-node-05`)

To enable VFIO GPU Passthrough on the AMD Ryzen 5 7600 (AM5 B650I platform), we configure Talos kernel arguments in the machine config:

```yaml
machine:
  kernel:
    args:
      - amd_iommu=on
      - iommu=pt
      - vfio-pci.ids=10de:2786,10de:22bc # Vendor:Device IDs for RTX 4070 Audio & Video
```

- **`amd_iommu=on iommu=pt`**: Enables IOMMU hardware isolation for PCIe devices.
- **`vfio-pci.ids`**: Tells Talos to bind the RTX 4070 to `vfio-pci` at boot so host drivers do not claim it.

---

## 🚀 Step 2: Deploy KubeVirt & Device Plugins

1. Install **KubeVirt Operator** via Helm or `kubectl`:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.2.0/kubevirt-operator.yaml
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.2.0/kubevirt-cr.yaml
   ```
2. Enable GPU & HostDevice Passthrough in KubeVirt configuration:
   ```yaml
   apiVersion: kubevirt.io/v1
   kind: KubeVirt
   metadata:
     name: kubevirt
     namespace: kubevirt
   spec:
     configuration:
       developerConfiguration:
         featureGates:
           - GPU
           - HostDevices
       permittedHostDevices:
         gpus:
           - resourceName: "nvidia.com/RTX_4070"
             selectors:
               - vendorId: "10de"
                 deviceId: "2786"
   ```

---

## 🎮 Step 3: Windows 11 VirtualMachine Manifest

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: windows11-gaming-vm
  namespace: vms
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: windows11-gaming-vm
    spec:
      domain:
        cpu:
          cores: 6
          threads: 2
        resources:
          requests:
            memory: 24Gi
          limits:
            memory: 24Gi
        devices:
          gpus:
            - name: rtx4070
              deviceName: nvidia.com/RTX_4070
          disks:
            - name: win-boot
              disk:
                bus: virtio
            - name: virtio-drivers
              cdrom:
                bus: sata
      volumes:
        - name: win-boot
          persistentVolumeClaim:
            claimName: windows11-nvme-pvc
        - name: virtio-drivers
          containerDisk:
            image: kubevirt/virtio-container-disk
```

---

## 📡 Step 4: High-Performance Remote Streaming (Sunshine + Moonlight)

1. **Sunshine Server**: Installed inside the Windows 11 VM to capture the RTX 4070 NVENC frame buffer with zero latency.
2. **Moonlight Client**: Connect from your Mac, TV, or phone over your **2.5GbE / 10GbE UniFi network** for smooth 4K 120 FPS gaming!
