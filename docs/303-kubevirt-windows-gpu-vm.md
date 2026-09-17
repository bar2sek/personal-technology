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

1. Install **KubeVirt Operator v1.9.0** & CRDs:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.9.0/kubevirt-operator.yaml
   kubectl apply -f kubernetes/infrastructure/kubevirt/kubevirt-cr.yaml
   ```
2. Enable GPU & HostDevice Passthrough in [`kubernetes/infrastructure/kubevirt/kubevirt-cr.yaml`](file:///kubernetes/infrastructure/kubevirt/kubevirt-cr.yaml):
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
           - VMPersistentState
           - HotplugVolumes
       permittedHostDevices:
         pciHostDevices:
           - pciVendorSelector: "10DE:2786"
             resourceName: "nvidia.com/RTX_4070"
           - pciVendorSelector: "10DE:22BC"
             resourceName: "nvidia.com/RTX_4070_Audio"
     vmStateStorageClass: rook-ceph-filesystem
   ```

---

## 🎮 Step 3: Windows 11 VirtualMachine Manifest

The production manifest is defined in [`kubernetes/infrastructure/kubevirt/windows11-vm.yaml`](file:///kubernetes/infrastructure/kubevirt/windows11-vm.yaml):

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: windows11-gaming-vm
  namespace: vms
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        app: windows11-gaming
        kubevirt.io/domain: windows11-gaming-vm
    spec:
      nodeSelector:
        kubernetes.io/hostname: pc-node-05
      domain:
        cpu:
          model: host-passthrough
          cores: 12
          threads: 1
          sockets: 1
        resources:
          requests:
            memory: 16Gi
          limits:
            memory: 16Gi
        devices:
          gpus:
            - name: rtx4070
              deviceName: nvidia.com/RTX_4070
            - name: rtx4070-audio
              deviceName: nvidia.com/RTX_4070_Audio
          disks:
            - name: install-iso
              bootOrder: 1
              cdrom:
                bus: sata
            - name: rootdisk
              bootOrder: 2
              disk:
                bus: virtio
            - name: virtio-drivers
              cdrom:
                bus: sata
            - name: sysprep
              cdrom:
                bus: sata
          tpm:
            persistent: true
        features:
          acpi: {}
          apic: {}
          hyperv:
            relaxed: {}
            vapic: {}
            spinlocks:
              spinlocks: 8191
            synic: {}
            synictimer:
              direct: {}
            reset: {}
            frequencies: {}
            reenlightenment: {}
            tlbflush: {}
            ipi: {}
          smm:
            enabled: true
        firmware:
          bootloader:
            efi:
              secureBoot: false
      volumes:
        - name: rootdisk
          persistentVolumeClaim:
            claimName: windows-gaming-nvme-pvc
        - name: install-iso
          persistentVolumeClaim:
            claimName: win11-ltsc-iso
        - name: virtio-drivers
          containerDisk:
            image: quay.io/kubevirt/virtio-container-disk:v1.9.0
        - name: sysprep
          sysprep:
            configMap:
              name: windows11-sysprep-config
```

---

## 📡 Step 4: High-Performance Remote Streaming (Sunshine + Moonlight)

1. **Dedicated LAN VIP (`10.10.20.55`)**: MetalLB exposes ports `47984-48010` (Sunshine HTTP/RTSP/UDP streams), `5985/5986` (WinRM for Ansible), and `3389` (RDP).
2. **Local Split-Horizon DNS (`gaming.bar2sek.com`)**: Managed declaratively in [`terraform/unifi/dns.tf`](file:///terraform/unifi/dns.tf) pointing to `10.10.20.55`.
3. **Sunshine Server**: Installed inside the Windows 11 VM via Ansible (`ansible/playbooks/configure-gaming-vm.yml`) to capture the RTX 4070 NVENC frame buffer with zero latency.
4. **Moonlight Client**: Connect from your MacBook Pro over the **2.5GbE / 10GbE UniFi network** for smooth 4K 120 FPS gaming with AV1/HEVC encoding!

