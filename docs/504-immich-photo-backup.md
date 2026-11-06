---
title: "Immich: Owned Photo Library (Second Copy Alongside Google Photos)"
date: 2026-10-20
tags:
  - homelab/apps
  - homelab/backups
  - kubernetes/immich
status: in-progress
aliases:
  - "Immich Plan"
  - "Photo Ownership Plan"
---

# 📸 Immich: Owned Photo Library

> [!NOTE]
> **Status (2026-11-05): Phase 1 complete and verified** (v3.3.5, non-root under Pod Security `restricted`; LAN and tailnet URLs, Authentik SSO, a test upload with thumbnails, smart search and face detection on CPU). **Immich has no backups until Phase 4.** Next: Phase 0 (Takeout), then Phase 2. Google Photos stays primary during a 2–3 month trial of Immich as the day-to-day app; this plan is only rewritten around Immich-as-primary if that trial passes (restore drill, background backup keeps up, sharing solved). Plan approved 2026-10-20 (decisions D1–D6 final). This replaces the earlier "decommissioned" reference doc. That decision assumed a 500 GB library and GPU-accelerated ML. The real library is ~25 GB, and the RTX 4070 on `pc-node-05` now belongs to the Bazzite VM ([[303-kubevirt-bazzite-gpu-vm|KubeVirt GPU VM]]), so this plan runs ML on CPU.

## 🎯 Goal and non-goals

**Goal:** a complete copy of the photo library that I own and control. It should not depend on any single provider or account, and it must be restorable without Google.

**Non-goals (for now):**
- Replacing Google Photos. Google stays the **primary** app for browsing, editing and sharing.
- Public sharing links or internet exposure. Immich is reachable only on the LAN and the tailnet.

### Why this is needed

Google is currently the **only** home for these photos. An account lockout, a policy flag or a billing mistake would make the library unreachable, and nothing could be appealed or restored from my side. Google also cannot be synced automatically: since the 2025 Photos Library API changes, third-party tools (rclone etc.) can only see media they uploaded themselves. Google Takeout is the only bulk export.

So ownership has to come from **the phone itself** (new photos) plus a **one-time Takeout import** (history).

---

## 🏛️ Architecture

```mermaid
graph LR
    PHONE["iPhone camera roll"] -->|"Google Photos app"| GP["Google Photos<br/>(primary, unchanged)"]
    PHONE -->|"Immich app<br/>LAN or Tailscale only"| IMM

    GP -.->|"Takeout, one-time + every 2 months"| WS["Workstation<br/>(outside the Drive-synced vault)"]
    WS -->|"immich-go"| IMM

    subgraph Cluster["Talos Kubernetes · namespace immich"]
        IMM["immich-server"] --> ML["immich-machine-learning<br/>(CPU)"]
        IMM --> PG[("Postgres + VectorChord")]
        IMM --> VK[("Valkey")]
        IMM --> LIB[("Library PVC<br/>rook-ceph-block · SSD · 3 copies")]
    end

    LIB -->|"nightly restic<br/>incremental snapshots"| NAS["Garage Synology<br/>bulk-media-mirror share"]
    LIB -->|"monthly full tar | age"| S3["S3 photos bucket<br/>Deep Archive · Object Lock"]
```

### Copies after the plan is done (3-2-1 plus Google)

| # | Copy | Media / location | Protects against |
| :--- | :--- | :--- | :--- |
| 1 | Immich library | Ceph SSD pool, 3 replicas across hosts | Disk or node failure |
| 2 | restic repository | Garage Synology (separate building zone, separate power) | Cluster loss, bad upgrade, accidental deletion (snapshots) |
| 3 | Monthly encrypted archive | S3 Deep Archive, Object Lock, `us-east-2` | House-level disaster, ransomware on the LAN |
| 4 | Google Photos | Google | Everything above, as long as the account exists |

---

## ⚖️ Decisions

All decisions confirmed 2026-10-20. The chosen option in each is marked **(chosen)**; the alternatives stay listed for context.

### D1. Library storage class  *(decided 2026-10-20)*
- **`rook-ceph-block` (SSD, size 3) (chosen).** Per the [[104-phase2-rook-ceph-storage|storage placement policy]], the HDD EC pool is for re-creatable data and must never hold the only copy. ~30 GB × 3 = ~90 GB raw, which is trivial on 16 TB.
- `rook-ceph-hdd-ec`: allowed only because Google and the backups hold other copies. That's a weaker argument for irreplaceable data, and EC is slower on small random writes (thumbnail generation).

### D2. Local backup format (Synology)  *(decided 2026-10-20)*
- **restic (chosen):** incremental, deduplicated, encrypted, with point-in-time snapshots, so a deletion in Immich doesn't spread into the backup. **Trade-off:** the restic password must live in the cluster, so the cluster *can* read this copy. That breaks the "cluster cannot decrypt" rule in the backup design (`kubernetes/infrastructure/backups/README.md`). It's accepted for the local LAN copy only.
- Nightly full `tar | age`: keeps the rule, but 35 days × 30 GB = ~1 TB, which won't fit the 600 GB share.

### D3. Offsite backup target  *(decided 2026-10-20)*
- **A new, dedicated bucket (chosen)**, e.g. `s3-aws-photos-prod-use2-001`: Deep Archive storage class, Object Lock (governance) for ~180 days to match Deep Archive's minimum billing period, and keep the last ~6 monthly archives. The uploader keeps the existing **write-only, `*.age` only** model, so the cluster can never read or delete it. Cost: ~30 GB × 6 × ~$0.001/GB-month ≈ **$0.20/month**.
- Reusing `s3-aws-backups-prod-use2-001`: its lifecycle rule (`filter {}`, expire after 35 days) would delete the archives. Fixing that would mean rewriting a rule that protects every other backup.

### D4. Remote access for the phone  *(decided 2026-10-20)*
- **LAN plus Tailscale (chosen):** the Immich app supports a local Wi-Fi URL and an external URL, and switches between them automatically. Uploads go over Wi-Fi at home, and over the tailnet when away (on demand). Nothing is exposed publicly.
- Cloudflare Tunnel: the free plan's 100 MB upload limit breaks long videos, and Cloudflare Access in front of the app needs custom-header workarounds. Not needed while Google handles sharing.

### D5. Sign-in  *(decided 2026-10-20)*
- **Authentik OIDC (chosen)**, matching the other apps, plus one local admin account kept as break-glass access (in Apple Passwords).

### D6. ML acceleration (GPU)  *(decided 2026-10-20)*

The RTX 4070 can't be used by cluster pods. It is bound to `vfio-pci` at boot and passed whole to the Bazzite VM (see [[303-kubevirt-bazzite-gpu-vm#🧠 GPU Ownership & Bazzite as a GPU Server|GPU ownership]]). The order of preference:

1. **Now: CPU.** The in-cluster `immich-machine-learning` pod runs on CPU. For ~25 GB that means a few hours for the first indexing pass, then seconds per new photo. This is always deployed, because it's the fallback.
2. **Next: Bazzite as the GPU server.** Run a CUDA build of the Immich ML container *inside* the Bazzite VM, which already has the NVIDIA driver and CUDA. Expose it to the cluster with a Kubernetes Service. Immich accepts **several ML URLs, tried in order**: list the Bazzite URL first and the in-cluster CPU service second, so ML keeps working when the VM is off or busy.
3. **Last resort: buy hardware.** Only if 1 and 2 aren't enough (e.g. LLMs that need VRAM while gaming): add a second GPU, such as an Intel Arc A310/A380 in `pc-node-04` (pc-node-05 is Mini-ITX with one slot).

**Why not hand the 4070 to the cluster?** Passthrough is all-or-nothing and chosen at boot. Switching between "VM mode" and "cluster mode" means a Talos config change and a reboot every time.

---

## 🗺️ Phases

Each phase ends with a verification step. Don't start the next phase until it passes.

### Phase 0: Prep (no cluster changes)
1. In Google Photos, check that the backup quality is **Original**, not "Storage saver". If it's "Storage saver", the phone copy is better than Google's, so the phone backup (Phase 3) matters more than Takeout.
2. Request a **Google Takeout** of Google Photos only, and schedule it to repeat every 2 months for a year.
3. Choose a download location **outside the vault** (e.g. `~/Downloads/takeout/`). 25 GB of zips inside Google Drive would sync straight back to Google.

**Verify:** Takeout archive downloaded; total size ≈ the storage shown in Google One.

### Phase 1: Deploy Immich (`kubernetes/apps/immich/immich.yaml`)

| Component | Image / storage | Notes |
| :--- | :--- | :--- |
| `immich-server` | v3.3.5, pinned by digest; `immich-library` 100 Gi on `rook-ceph-block` (D1) | Thin provisioned: the size only caps growth, and the PVC can be expanded |
| `immich-machine-learning` | Same version, CPU (D6); `immich-model-cache` 10 Gi on `rook-ceph-hdd-ec` | Limited to 4 CPUs. Models re-download, so the HDD pool is allowed |
| `immich-postgres` | Immich's VectorChord image from the release's compose file; 10 Gi on `rook-ceph-block` | Runs as UID 999 |
| `immich-valkey` | Digest from the release's compose file; `emptyDir` | Job queue only, no persistence |

Why the manifest looks the way it does:

- **`enableServiceLinks: false` everywhere.** Kubernetes would otherwise inject variables like `IMMICH_SERVER_PORT=tcp://...`, and Immich reads `IMMICH_*` as configuration.
- **`PGDATA` is a subdirectory**, because `initdb` refuses a mount root that contains `lost+found`. The image's entrypoint honours it.
- **Postgres runs as UID 999, not 1000**, the image's own user: `initdb` needs a UID that exists in `/etc/passwd`.
- **`fsGroupChangePolicy: OnRootMismatch`** stops a recursive `chown` of the whole library on every pod start.
- **The root filesystem stays writable** (still non-root). Upstream doesn't document read-only operation, and the Postgres entrypoint writes to `/etc/postgresql`.
- **Plain manifest instead of the official Helm chart**, matching the other apps here.
- **The database password is generated by `just immich-apply`**, once, and never written to disk. This replaces the `*.example.yaml` pattern. The recipe never rotates it, because Postgres keeps the password it was initialized with.

**Exposure (D4):** `immich.bar2sek.com` on ingress-nginx for the LAN, `immich.tail6e33.ts.net` through the Tailscale operator for away from home.

> [!WARNING]
> `immich.bar2sek.com` is LAN-only because it has **no public DNS record** (checked 2026-11-03: the name doesn't resolve publicly and the zone has no wildcard). Adding a public record or a tunnel hostname would expose Immich to the internet.

#### Deploy

```bash
just tf-plan unifi    # expect: 1 to add (unifi_dns_record.immich)
just tf-apply unifi
just immich-apply
just immich-status
```

**Immediately after the rollout,** open `https://immich.bar2sek.com` and create the admin account: **the first account to sign up becomes the admin.** Keep it as the break-glass login (D5), in Apple Passwords.

#### Authentik SSO (D5)

Settings live in the Authentik and Immich databases, not in git. The Authentik side was created 2026-11-05 with `ak shell` as a copy of the Grafana provider (same flows, signing key and scope mappings; client ID `immich`, no access policy binding, so any Authentik user can pass Authentik).

> [!WARNING]
> A provider created through `ak shell` gets an **empty `grant_types`** list unless you set it (Grafana's provider has them all). Login then fails in Immich with "Failed to finish oauth" and in the Authentik log with `Invalid grant_type for provider`. Immich's provider allows only `authorization_code` and `refresh_token`.

1. **Authentik → Applications → Create with provider:** OAuth2/OpenID, confidential client, an RS256 signing key, slug `immich`. Strict redirect URIs:

   ```text
   app.immich:///oauth-callback
   https://immich.bar2sek.com/auth/login
   https://immich.bar2sek.com/user-settings
   https://immich.tail6e33.ts.net/auth/login
   https://immich.tail6e33.ts.net/user-settings
   ```

   The first is required by the iOS app.
2. **Immich → Administration → Settings → Authentication → OAuth:** enable it, with issuer URL `https://auth.bar2sek.com/application/o/immich/` plus the client ID and secret from step 1. Copy the secret from Authentik → Applications → Providers → Immich → Edit. Turn auto-register **off**: Immich then only accepts Authentik users whose email matches an existing Immich account, so the admin's email must match its Authentik email.
3. Test in a private window, keeping the admin session open until it works.

**First deploy (2026-11-05):** all four rollouts passed first try, in about a minute. Startup warnings that are normal on a first boot: `FailedScheduling` (PVCs still binding), failed readiness/startup probes while Postgres initialized, and `relation "system_metadata" does not exist` (Immich checks for the table just before its migrations create it).

**DNS gotcha:** right after adding the record, `dig` answered correctly while `curl` and browsers still failed with "could not resolve host". `dig` queries the DNS server directly; everything else goes through macOS's resolver, which can keep a failed lookup cached. Flush it with the command in [[205-split-horizon-dns-ipv6-leak|docs/205]].

**Verify:**
- Web login via Authentik works on both URLs.
- Upload one test photo from the browser. The thumbnail appears and smart search finds it. The first search is slow, because the model has to download.
- `dig +short immich.bar2sek.com` on the LAN returns `ingress.home.arpa` and the VIP. `https://cloudflare-dns.com/dns-query?name=immich.bar2sek.com&type=A` (DoH, see [[205-split-horizon-dns-ipv6-leak|docs/205]]) still has no answer.
- Until Phase 4, **Immich has no backups**. That's acceptable only because Google is still primary, so don't remove anything from Google or the phone.

### Phase 2: Import history from Takeout
- Run `immich-go` from the workstation (via `nix-mac`, not a global install) against the Takeout zips. It reads Google's JSON sidecars to restore dates, GPS, albums and favorites.

**Verify:** compare Immich's asset count with Google's (roughly; Google counts some edits differently). Spot-check a few old photos for correct dates and Live Photo playback.

### Phase 3: Phone backup
- Install the Immich iOS app, sign in with OIDC, set the LAN and external URLs (D4), and turn on background backup for the camera roll. Leave the Google Photos backup on.

**Verify:** take a photo and check that it appears in both Google and Immich within a day. Do it once at home and once away.

### Phase 4: Backups
- **NAS (D2):** a CronJob runs `restic backup` of the library PVC to the `bulk-media-mirror` share (600 GB quota). Retention: 7 daily, 4 weekly, 12 monthly.
- **Postgres:** add the Immich database to the existing Tier 2 `pg_dump` jobs (S3 and NAS). Immich also writes its own daily database dumps into the library, so restic captures those too.
- **S3 (D3):** a monthly CronJob runs `tar | age -r <public key> | aws s3 cp --storage-class DEEP_ARCHIVE`. The bucket, Object Lock and lifecycle go in Terraform, owned according to the existing split: guardrails in `bootstrap/aws`, the bucket body in `infra-cloud-deployments`.
- Alert via ntfy and Grafana when any photo backup job fails or hasn't succeeded in 36 hours (NAS) or 35 days (S3).

**Verify (restore drill, required):** restore a restic snapshot to a scratch PVC and diff it against the library. Restore one S3 archive with the offline age identity on the workstation. Note that Deep Archive retrieval takes up to 12 hours.

### Phase 5: Operate
| Cadence | Task |
| :--- | :--- |
| Every 2 months | Import the scheduled Takeout with `immich-go`. It skips duplicates, and picks up anything the phone missed, such as photos shared to me in Google. |
| Monthly | Check the backup job dashboard; look at the Immich job queue for stuck jobs. |
| Per release | Read the Immich release notes **before** bumping the pinned tags; check for required database migrations. |
| Twice a year | Repeat the restore drill. |

---

## ⚠️ Gotchas

- **iOS background backup is best-effort.** iOS decides when background apps run. Opening the Immich app occasionally forces a catch-up. The bi-monthly Takeout import is the safety net.
- **Deleting in Google doesn't delete in Immich, and vice versa.** That's intentional: Immich is the archive. Clean up in both places on purpose, if at all.
- **Takeout zips must stay outside the Drive-synced vault** (see the root `AGENTS.md` §6).
- **CPU ML backfill:** the first indexing pass over ~25 GB takes a few hours. Limit ML CPU so it doesn't starve other workloads on its node.
- **Don't name a Service plain `immich`.** Even with service links off today, a Service called `immich` is what produces the classic `IMMICH_PORT=tcp://...` crash if `enableServiceLinks` is ever dropped.
- **ML versions must match everywhere.** If the Bazzite ML container (D6) is used, pin it to the same version as `immich-server` and the in-cluster ML pod, and bump all three together.
