# Automated Windows Gaming VM Provisioning with Ansible & Chocolatey

This guide outlines how to use **Ansible** (via WinRM / OpenSSH) and **Chocolatey** to automatically configure our **KubeVirt Windows 11 Gaming Virtual Machine**, installing NVIDIA drivers, Steam, Battle.net, Sunshine, and gaming software without manual intervention.

---

## 🤖 Ansible on Windows

**YES! Absolutely.** 

While the Ansible control node (where `ansible-playbook` runs) executes inside Linux/containers or a GitHub Actions ARC runner, Ansible has **first-class native support for managing Windows target hosts**.

### Connection Protocols:
- **WinRM (Windows Remote Management)**: HTTPS (Port 5986) or HTTP (Port 5985).
- **Win32 OpenSSH**: Native SSH service on Windows 10/11.

---

## 🛠 Unattended Windows Boot Configuration (`Unattend.xml`)

When KubeVirt boots a fresh Windows 11 VM image, a `sysprep` `Unattend.xml` script automatically enables WinRM and configures the Administrator credentials on first boot:

```powershell
# PowerShell snippet executed during Windows sysprep boot
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Service\Auth\Basic $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted $true
New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -LocalPort 5985,5986 -Protocol TCP -Action Allow
```

---

## 📦 Ansible Playbook (`configure-gaming-vm.yml`)

This Ansible playbook automatically installs **Chocolatey** (the Windows package manager) and deploys our full gaming software stack:

```yaml
---
- name: Automate Windows 11 Gaming VM Setup
  hosts: gaming_vms
  gather_facts: true
  vars:
    ansible_user: Administrator
    ansible_password: "{{ vault_win_admin_password }}"
    ansible_connection: winrm
    ansible_winrm_server_cert_validation: ignore

  tasks:
    - name: Ensure Chocolatey Package Manager is Installed
      win_chocolatey:
        name: chocolatey
        state: present

    - name: Install NVIDIA Display Drivers
      win_chocolatey:
        name: nvidia-display-driver
        state: present

    - name: Install Gaming Launchers & Essential Software
      win_chocolatey:
        name: "{{ item }}"
        state: present
      loop:
        - steam
        - battle-net
        - sunshine # High-performance Moonlight streaming server
        - discord
        - 7zip
        - vlc

    - name: Ensure Sunshine Remote Gaming Service is Running
      win_service:
        name: SunshineService
        start_mode: auto
        state: started
```

---

## 🏆 Resume & Enterprise Automation Value

Using **Ansible + WinRM + Chocolatey** to provision KubeVirt Windows VMs demonstrates:
1. **Multi-OS Automation**: Mastery of both Linux (Talos) and Windows (WinRM / PowerShell) configuration management.
2. **Zero-Touch VM Provisioning**: Full lifecycle automation from KubeVirt CRD creation -> Windows sysprep boot -> Ansible software installation.
