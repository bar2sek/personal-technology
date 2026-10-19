---
title: "Storage Reshuffle: Hardware Checklist"
date: 2026-10-18
tags:
  - homelab/hardware
  - homelab/ceph
  - runbook
status: in-progress
aliases:
  - Basement checklist
  - Disk swap checklist
---

# Storage Reshuffle: Hardware Checklist

The physical steps of [[110-ephemeral-var-migration|the /var migration & storage reshuffle]], written to be followed at the rack. Each hardware wave has three parts: **before** (done at the terminal, must be green before touching anything), **hands-on**, and **after** (terminal again).

> [!IMPORTANT]
> **Never pull a disk that Ceph still uses.** Every disk below is drained and wiped in Wave 0 before it moves. If a terminal checkpoint is not green, stop.

---

## 🧰 Bring

- Phillips #2 screwdriver (caddy and case screws)
- Masking tape and a marker: label every drive as it comes out (short serial + destination)
- The 2.5"→3.5" adapters that come out of sm-node-03's caddies: **keep one** for the 250 GB MX500 going into sm-node-03
- Phone with ntfy (alerts are silenced per window, but a surprise alert means stop)
- For Wave 3: the new case, its 3.5" bays/screws, two SATA data cables

---

## 🏷️ Drive register

| Short ID | Model (on label) | Serial | Now | Goes to | Ceph today |
|---|---|---|---|---|---|
| **MX-DE1D** | CT2000MX500SSD1 (2 TB) | `2137E5D2DE1D` | sm-node-03 | **pc-node-04** | osd.12 |
| **MX-DE26** | CT2000MX500SSD1 (2 TB) | `2137E5D2DE26` | sm-node-03 | **pc-node-04** | osd.13 |
| **MX-684D** | CT2000MX500SSD1 (2 TB) | `2253E698684D` | sm-node-03 | **pc-node-04** | osd.4 |
| ⛔ **MX-6843** | CT2000MX500SSD1 (2 TB) | `2253E6986843` | sm-node-03 | **STAYS in sm-node-03** | osd.7 |
| **IW-H5S** | ST4000VN008 (IronWolf 4 TB) | `ZGY91H5S` | pc-node-04 | sm-node-03 | osd.11 |
| **IW-RSJ** | ST4000VN008 (IronWolf 4 TB) | `ZDH9HRSJ` | pc-node-04 | sm-node-03 | osd.14 |
| **IW-65H** | ST4000VN008 (IronWolf 4 TB) | `ZGY9165H` | pc-node-04 | pc-node-05 | osd.15 |
| **IW-889** | ST4000VN008 (IronWolf 4 TB) | `ZGY91889` | pc-node-04 | pc-node-05 | osd.16 |
| **MX250** | CT250MX500SSD1 (250 GB) | `2228E6489822` | pc-node-04 | sm-node-03 (`/var`) | unused |
| **WD-GREEN** | WDC WD15EADS (1.5 TB) | `WD-WCAVY1095334` | pc-node-04 | **retire** | osd.18 |

> [!WARNING]
> **`…684D` leaves, `…6843` stays.** The two serials differ only in the last two characters. In sm-node-03, identify bays by the activity-LED method in Wave 1, never by guessing bay order.

Which IronWolf goes where does not matter technically (all four are equivalent); the register just fixes it so labels and docs agree.

**Not moving:** pc-node-04's boot SSD (Intel 320 80 GB), NVMe, ST3000DM007 3 TB, ST2000NM0033 2 TB, the two ST3100052xAS 1 TB, and the two Intel 335 180 GB spares; sm-node-03's two SuperDOMs; everything in sm-node-01/02.

---

## Wave 1: pull three MX500s from sm-node-03 (running, hot-swap)

**Before (terminal):** Wave 0 done (done 2026-10-18: osd.12/13/4 purged and their disks wiped); `ceph status` HEALTH_OK; `ceph osd tree` shows **only osd.7** under sm-node-03. As a precaution (in case the wrong bay is pulled), silence and set `noout` for sm-node-03:
```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd set-group noout sm-node-03
```

**How to find the right bay:** a continuous read of one disk keeps **its** bay's activity LED lit; the other bays only blink with normal background I/O.

**Hands-on, once per drive: MX-DE1D (`2137E5D2DE1D`), then MX-DE26 (`2137E5D2DE26`), then MX-684D (`2253E698684D`).** Set `ID` to that drive first:
```bash
ID=ata-CT2000MX500SSD1_2137E5D2DE1D    # then …2137E5D2DE26, then …2253E698684D
```
1. **Light its LED** (runs until Ctrl-C):
   ```bash
   kubectl debug node/sm-node-03 -n kube-system --profile=sysadmin -it --image=alpine:3.24 -- sh -c \
     "D=\$(readlink -f /host/dev/disk/by-id/$ID); echo Reading \$D - watch for the steady LED, Ctrl-C to stop; \
      while true; do dd if=\$D of=/dev/null bs=1M count=2000 iflag=direct status=none; done"
   ```
   Note which bay is lit, then press **Ctrl-C**.
2. **Detach it from Linux** (so the kernel is not surprised by the pull):
   ```bash
   kubectl debug node/sm-node-03 -n kube-system --profile=sysadmin -it --image=alpine:3.24 -- sh -c \
     "D=\$(readlink -f /host/dev/disk/by-id/$ID); N=\$(basename \$D); echo 1 > /host/sys/block/\$N/device/delete && echo detached \$N"
   ```
   Expect `detached sdX`. The bay's LED goes dark.
3. At the rack: press the caddy release on **that bay only**, pull the caddy out.
4. Read the serial on the drive label. **If it is not the expected serial, stop:** slide it back in and check at the terminal (`ceph osd tree`, `talosctl -n sm-node-03 get disks`).
5. Label it with tape (e.g. "MX-DE1D → pc-04").
6. Check: `kubectl get node sm-node-03` → `Ready`; `ceph osd tree` → osd.7 `up`.

Clean up the debug pods afterwards: `kubectl -n kube-system get pods -o name | grep node-debugger | xargs kubectl -n kube-system delete`.

> [!TIP]
> **If no LED lights** (some backplanes do not show SSD activity): detach all three drives first (step 2 for each), then watch the bays: the one that **still** blinks holds osd.7 (MX-6843) and stays. Pull the other three and confirm each label.

**After:** one caddy (MX-6843) still in sm-node-03, three empty bays. `ceph osd unset-group noout sm-node-03`. Take the three MX500s out of their caddies (4 screws each); **keep at least one 2.5" adapter** for MX250.

---

## Wave 2: pc-node-04 window (about 30 minutes)

**Before (terminal):** (done 2026-10-18) osd.11/14/15/16/18 re-purged and their **label offsets zeroed and verified** (they had been re-activated from backup BlueStore labels after Wave 0; see [[110-ephemeral-var-migration|docs/110]] Phase A caution). Then silence + pause Rook operator + `noout` for pc-node-04 + `kubectl drain` + `talosctl shutdown`. Wait for the terminal's "powered off" checkpoint, then switch the PSU off and unplug.

**Hands-on:**
1. **Out**, labelling each as it comes out (models are printed on the labels, so there is no ambiguity):
   - all **four** IronWolf ST4000VN008: IW-H5S, IW-RSJ → tape "sm-03"; IW-65H, IW-889 → tape "pc-05"
   - **WD-GREEN** (WD15EADS) → tape "RETIRE"
   - **MX250** (CT250MX500SSD1) → tape "sm-03 /var"
2. **In:** the three MX500 2 TB from Wave 1 (MX-DE1D, MX-DE26, MX-684D), in 2.5" mounts or adapters. Any of the freed SATA ports and power leads; Talos and Ceph identify disks by serial, not by port.
3. Check every cable is seated (a loose SATA cable caused the osd.5 fault on 2026-10-17). Close up, plug in, power on.

**After (terminal):** node `Ready`; the three MX500s visible to Talos; add them to pc-node-04 in `cluster.yaml`; new OSDs up; resume the operator; unset `noout`; `HEALTH_OK`; uncordon; expire the silence.

---

## Wave 3: pc-node-05 re-case (a few hours)

**Before buying/starting:** confirm on the B650I EDGE two free **onboard SATA ports** (the RTX 4070 occupies the only PCIe slot, so no add-in controller), two **SATA power** leads on the PSU, and two **3.5" bays** in the new case.

**Before (terminal):** silence; stop the gaming VM (`virtctl stop bazzite-gaming-vm -n vms`); pause the Rook operator (mon.h); `noout` for pc-node-05; drain; `talosctl shutdown`. Power off and unplug.

**Hands-on:**
1. Move the motherboard **with both M.2 NVMe still installed** (Sabrent = boot + gaming-VM disk, Crucial P3 = Ceph osd.0), CPU cooler, RAM, GPU and PSU into the new case. Do not swap M.2 slots.
2. Mount **IW-65H** and **IW-889** in the 3.5" bays; SATA data to two onboard ports; SATA power.
3. Reconnect the SFP+/network cable to the same switch port; HDMI/DP from the 4070 if a monitor is used.
4. Power on.

**After (terminal):** node `Ready`; IronWolfs visible; add to pc-node-05 in `cluster.yaml`; cap their `osd_memory_target` to 2 GiB; resume operator; unset `noout`; `HEALTH_OK`; start the VM and check Moonlight; expire the silence.

---

## Wave 4: sm-node-03 disks in + `/var` re-provision (about 1 hour)

**Before (terminal):** Omni patch for EPHEMERAL on MX250 synced; silence; `noout` for sm-node-03. The MX250 still carries a `zfs_member` signature from pc-node-04: wipe it (`sgdisk --zap-all` + `wipefs -a` + `blkdiscard` from a debug pod) while sm-node-03 runs, before the Omni *Destroy*.

> [!NOTE]
> 2026-10-18: the MX250 and IW-H5S / IW-RSJ were hot-inserted into sm-node-03 right after Wave 2, ahead of the rest of this wave. Talos sees them; they are unused until the steps below.

**Hands-on (sm-node-03 may stay powered on; the bays are hot-swap):**
1. **MX250** into a 2.5"→3.5" adapter, into a caddy (2.5" screws through the adapter), into a free bay.
2. **IW-H5S** and **IW-RSJ** each into a caddy (3.5" screws in the bottom holes), into the two remaining bays.
3. ⛔ Do not touch the bay holding **MX-6843**.

**After (terminal):** Omni *Destroy* → maintenance mode → template sync re-adds the node; check `/var` is on MX250; add the IronWolfs to sm-node-03 in `cluster.yaml`; unset `noout`; `HEALTH_OK`; expire the silence.

---

## Waves 0, 5, 6, 7, 8

Software only, nothing physical: see [[110-ephemeral-var-migration|docs/110]] *Execution waves*.

## Retired hardware

| Drive | Reason | Where it went |
|---|---|---|
| WD15EADS 1.5 TB `WD-WCAVY1095334` | 644 reallocated sectors, 40,131 h (2026-10-18) | Wipe before disposal (Wave 0 wipes its Ceph data) |
