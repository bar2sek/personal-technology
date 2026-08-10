# KubeVirt Arch / Omarchy Linux Virtual Machine

This guide outlines the deployment manifest, `cloud-init` configuration, and SSH/VNC access setup for an **Arch Linux / Omarchy Virtual Machine** running inside our Talos Linux cluster using **KubeVirt**.

---

## 🐧 Arch / Omarchy Linux VM in KubeVirt

- **Bleeding-Edge Linux Environment**: Arch Linux provides rolling-release packages for developing new tools, Linux kernels, and container utilities.
- **Persistent Rook-Ceph Storage**: Root filesystem is stored on high-performance Rook-Ceph NVMe/SSD storage pools.
- **Instant Cloud-Init User Provisioning**: Automatically injects your SSH public key and configures user accounts at boot.

---

## 📦 KubeVirt Arch / Omarchy VM Manifest (`arch-vm.yaml`)

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: omarchy-vm
  namespace: vms
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: omarchy-vm
    spec:
      domain:
        cpu:
          cores: 4
          threads: 2
        resources:
          requests:
            memory: 8Gi
          limits:
            memory: 8Gi
        devices:
          disks:
            - name: arch-disk
              disk:
                bus: virtio
            - name: cloudinitdisk
              cdrom:
                bus: sata
          interfaces:
            - name: default
              masquerade: {}
      networks:
        - name: default
          pod: {}
      volumes:
        - name: arch-disk
          persistentVolumeClaim:
            claimName: omarchy-nvme-pvc
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              hostname: omarchy-vm
              users:
                - name: developer
                  sudo: ALL=(ALL) NOPASSWD:ALL
                  shell: /bin/bash
                  ssh_authorized_keys:
                    - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... developer@homelab
              package_update: true
```

---

## 🔌 Accessing the Arch / Omarchy Testing VM

1. **SSH Access (via Tailscale or Port Forwarding)**:
   ```bash
   virtctl ssh developer@omarchy-vm -n vms
   ```
2. **Web VNC Graphical Console**:
   ```bash
   virtctl vnc omarchy-vm -n vms
   ```
