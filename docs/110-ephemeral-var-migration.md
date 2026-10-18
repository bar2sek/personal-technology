---
title: "Moving Talos /var (EPHEMERAL) off the SuperDOMs"
date: 2026-10-18
tags:
  - homelab/talos
  - homelab/ceph
  - runbook
status: in-progress
aliases:
  - EPHEMERAL migration
  - /var migration
---

# Moving Talos `/var` (EPHEMERAL) off the SuperDOMs

The three Supermicro control-plane nodes boot from 16 GB SATA SuperDOMs. Talos puts its `EPHEMERAL` volume (`/var`: container images, logs, etcd, the Ceph monitor store) on the boot disk by default, which left each node with a **12.5 GiB `/var`**. That caused:

- pod evictions for `ephemeral-storage` (the Actual Budget backup, 2026-10-18),
- `MON_DISK_LOW` whenever a Ceph monitor landed on an sm node,
- etcd write latency up to 2.6 s on sm-node-02, where etcd and a monitor shared the SuperDOM (`KubeAPIErrorBudgetBurn`).

Interim mitigations (soft taint `homelab.bar2sek.com/small-var`, earlier image GC, monitors on the pc nodes) are recorded in [[001-deployment-journal|the journal]], Milestones 16–19. This runbook is the real fix.

---

## 🎯 Target layout (revised 2026-10-18: combined with a disk reshuffle)

Inspecting the hardware changed the plan:
- **The E300s (sm-node-01/02) are full:** no free power header, and their only spare SATA port is the one osd.5's cable was moved off after a fault. No extra disk is possible there, so `/var` shares the NVMe.
- **pc-node-04 has three unused SSDs** (250 GB Crucial MX500, 2 × 180 GB Intel 335), and only 9 HDDs, not 11.
- **sm-node-03's 813M has four 3.5" hot-swap bays**; its MX500s sit in 2.5" adapters, so HDDs fit directly.

| Node | Boot | `/var` (EPHEMERAL) | Ceph OSDs after |
|---|---|---|---|
| sm-node-01 | SuperDOM | 250 GiB on the Sabrent NVMe (`BC7107061E7C02090817`) | NVMe raw partition `r-osd-nvme` (~1.57 TiB) + MX500 × 2 |
| sm-node-02 | SuperDOM | 250 GiB on the Sabrent NVMe (`F2C10719080B00006324`) | Same as sm-node-01 |
| sm-node-03 | SuperDOM (second one stays spare) | **250 GB MX500 from pc-node-04**, dedicated | MX500 × 1 (osd.7) + **2 × 4 TB IronWolf** (from pc-node-04) |
| pc-node-04 | Intel 320 80 GB | unchanged | NVMe + **3 × MX500 2 TB from sm-node-03** (osd.12/13/4 today) + 7 HDDs |
| pc-node-05 | Sabrent 1 TB (also the gaming-VM disk) | unchanged | NVMe |

**Disk moves:** sm-node-03 → pc-node-04: three MX500 2 TB. pc-node-04 → sm-node-03: two ST4000VN008 (IronWolf, 24/7-rated) and the 250 GB MX500. The two Intel 180 GB stay in pc-node-04 as spares.

### Pools afterwards

| Pool | Hosts (raw) | Usable per copy | One host down |
|---|---|---|---|
| SSD, size 3 | sm-01 3.6, sm-02 3.6, sm-03 1.8, **pc-04 5.5** TiB | **~4.5 TiB** (was 3.6) | Keeps running **and rebuilds the third copy** on the remaining hosts (was: degraded until the host returns) |
| NVMe, size 3 | pc-04 0.9, pc-05 0.9, sm-01 1.6, sm-02 1.6 TiB | ~1.6 TiB (was 1.8) | Keeps running and rebuilds |
| HDD, size 2, **`failureDomain: host`**, min_size 1 | pc-04 16.5 TB, **sm-03 8 TB** | ~8 TB (was ~11) | **Survives** (was: lost with pc-node-04) |

### Why
- **A replicated pool fills when its smallest host fills.** With 3 copies on exactly 3 hosts, every host holds a full copy: sm-node-03's extra SSD capacity was unusable (each host held the same 55 GiB on 2026-10-18; sm-node-03's four disks carried about half as much each). Moving three MX500s to pc-node-04 adds a **fourth SSD host**, which raises usable capacity and gives Ceph somewhere to rebuild after a host failure.
- **The HDD pool gets a second host** for the cost of about 3 TB usable; it stays a scratch tier (see *Accepted Trade-offs* in [[104-phase2-rook-ceph-storage|Rook-Ceph]]).
- **etcd on fast, quiet disks:** NVMe on sm-01/02 (shared with an OSD, which NVMe handles well); a dedicated SSD on sm-03.
- **Size 2 was considered for SSD and rejected:** it would make sm-node-03's capacity usable, but a host outage then either blocks writes (`min_size 2`) or risks losing recent writes (`min_size 1`). The SSD pool holds everything that matters.

### Deferred
- **pc-node-05 re-case** (would allow HDDs there: a third HDD host, then size 3 or erasure coding). Only if really needed.
- **pc-node-05 boot on a spare Intel SSD** (whole Sabrent for the gaming VM): rejected for now; the Sabrent's 750 GiB is the VM's disk and moving it means a Bazzite rebuild.

### Open before execution
- SMART of the three spare SSDs in pc-node-04 (the 250 GB MX500 becomes sm-node-03's etcd disk).
- **Order of operations** for the swap (pc-node-04 needs sm-node-03's SSDs and vice versa) with the fewest power-downs and quorum kept throughout.

---

## 🔬 Mechanisms (verified 2026-10-18 on Omni v1.12.0 / Talos 1.13.10)

| Need | How | Source |
|---|---|---|
| Put EPHEMERAL on a chosen disk | `VolumeConfig` named `EPHEMERAL` with `provisioning.diskSelector.match` (CEL, e.g. `disk.serial == "…"`) and `minSize`/`maxSize`/`grow` | Talos docs, *System volumes* |
| Raw partition for Ceph | `RawVolumeConfig` → unformatted partition at `/dev/disk/by-partlabel/r-<name>`. **The name must not contain `ceph`** | Talos docs, *Raw volumes* |
| OSD on a partition | Rook supports raw partitions (no filesystem) given by full udev path in `devices[].name`; not with `encryptedDevice` (ours are unencrypted) | Rook *Prerequisites*, *CephCluster CRD* |
| Re-provision EPHEMERAL | Volume config applies **only when the volume does not exist yet**. Omni blocks `talosctl reset`, but removing a machine from the cluster makes Omni reset it: STATE and EPHEMERAL are wiped, and since Talos 1.12 the partitions themselves are removed (talos#12090), so EPHEMERAL can be created elsewhere when the machine rejoins | Omni docs *Wipe a machine*; Omni v1.10 release notes; siderolabs/talos#12090 |
| Keep the other OSDs | Omni's reset does not erase non-system disks; Rook re-activates their OSDs by UUID when the node returns | Omni docs *Wipe a machine* |
| Wipe the repurposed disk | Must happen **while the node is still running**: `talosctl wipe disk` does not work on Omni-managed machines in maintenance mode (talos#13583) | GitHub issue |

---

## ✅ Pre-flight (before every node)

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status        # HEALTH_OK, all PGs active+clean
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph mon stat      # 3 mons in quorum
talosctl -n sm-node-01,sm-node-02,sm-node-03 etcd members              # 3 members
kubectl get jobs -A | grep -i backup                                   # last night's backups succeeded
```
Also: no other maintenance in progress. Silence the expected alerts first (`CephOSDDownHigh` is critical and fires immediately); the matchers are in [[104-phase2-rook-ceph-storage|Rook-Ceph]], *Taking a Node Offline*. Never have two control-plane nodes down at once.

---

## 🛠️ Per-node procedure (sm-node-02 shown; differences below)

### Phase A: drain and wipe the disk being repurposed
1. **Take the OSD out of Ceph** and wait for its data to move (the NVMe pool is nearly empty, so this is quick):
   ```bash
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd out osd.9
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg stat     # wait for all active+clean
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd safe-to-destroy osd.9
   ```
2. **Remove the disk from `cluster.yaml`** (comment it out under sm-node-02) and apply, so Rook does not recreate the OSD.
3. **Remove the OSD:** scale `rook-ceph-osd-9` to 0, `ceph osd purge 9 --yes-i-really-mean-it`, delete the Deployment.
4. **Wipe the disk** from a privileged debug pod on the node (zap the GPT, clear the BlueStore label, discard):
   ```bash
   kubectl debug node/sm-node-02 -n kube-system --profile=sysadmin -it --image=alpine:3.24 -- sh -c \
     'apk add -q sgdisk util-linux && D=/dev/disk/by-id/nvme-Sabrent_Rocket_Q_F2C10719080B00006324 && \
      sgdisk --zap-all $D && dd if=/dev/zero of=$D bs=1M count=100 oflag=direct && blkdiscard $D && lsblk -f $D'
   ```
   `lsblk -f` must show no filesystem. Delete the `node-debugger-*` pod afterwards.

### Phase B: add the volume config (Omni template)
Add to the sm-node-02 `Machine` patches in `talos/cluster-template.yaml`, run `omnictl cluster template diff`, then `sync`. Nothing changes on the running node: its EPHEMERAL already exists.
```yaml
apiVersion: v1alpha1
kind: VolumeConfig
name: EPHEMERAL
provisioning:
  diskSelector:
    match: disk.serial == "F2C10719080B00006324"
  minSize: 250GiB
  maxSize: 250GiB
  grow: false
---
apiVersion: v1alpha1
kind: RawVolumeConfig
name: osd-nvme # becomes /dev/disk/by-partlabel/r-osd-nvme; must not contain "ceph"
provisioning:
  diskSelector:
    match: disk.serial == "F2C10719080B00006324"
  minSize: 1TiB
  grow: true
```

### Phase C: re-provision the node
1. `kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd set-group noout sm-node-02` (its other OSDs will be down briefly; don't rebalance).
2. **Remove the machine from the cluster** in Omni (cluster view → machine → *Destroy*). Omni removes the etcd member and resets the machine; it reboots into maintenance mode.
3. **Re-add it:** `omnictl cluster template sync -f talos/cluster-template.yaml`. The template still lists it, so Omni adds it back with the new patches. Talos installs to the SuperDOM and provisions EPHEMERAL and `r-osd-nvme` on the NVMe.

### Phase D: verify and bring the OSD back
```bash
talosctl -n sm-node-02 get volumestatus EPHEMERAL r-osd-nvme     # EPHEMERAL on nvme0n1p?, ~250 GiB; raw volume ready
talosctl -n sm-node-02 etcd members                               # back to 3
kubectl get node sm-node-02                                       # Ready
```
Then in `cluster.yaml` set sm-node-02's NVMe entry to `/dev/disk/by-partlabel/r-osd-nvme`, apply, and wait for Rook to create the new OSD. Finally `ceph osd unset-group noout sm-node-02` and wait for `HEALTH_OK`.

### Differences for the other nodes
- **sm-node-03:** combined with the disk swap (see *Target layout*): drain osd.12, osd.13 and osd.4 (they move to pc-node-04); `VolumeConfig` for EPHEMERAL selects the 250 GB MX500 by serial (whole disk, `grow: true`, no `maxSize`), no `RawVolumeConfig`. The order of operations for the swap is still to be written.
- **sm-node-01:** like sm-node-02 with osd.10 and serial `BC7107061E7C02090817`. It holds **mon.i**; it fails over (about 10 min) while the node is out. Do this node last.

---

## ↩️ If something goes wrong
- **EPHEMERAL lands on the SuperDOM again:** the reset left the old partition. Remove the machine again; if that repeats, reset out of band (Talos ISO over IPMI virtual media → *Reset system disk*).
- **Node does not come back (volume config cannot be satisfied):** remove the new patches from the template, sync, and remove/re-add the machine again; it returns to the old layout.
- **Ceph:** while `noout` is set, a slow return costs nothing. Unset it once the node's OSDs are up.

---

## 📋 Progress

| Node | Status |
|---|---|
| sm-node-02 | Planned |
| sm-node-03 | Planned (combined with the disk swap) |
| sm-node-01 | Planned |
| Remove soft taint `homelab.bar2sek.com/small-var`, revisit monitor placement | After all three |
