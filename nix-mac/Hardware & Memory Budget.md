---
title: "Hardware & Memory Budget"
date: 2026-09-20
tags:
  - hardware
  - memory
  - m5-pro
status: evergreen
aliases: []
---

# 🧠 Hardware & Memory Budget

## Target Specifications
* **Machine:** MacBook Pro
* **Processor:** Apple M5 Pro
* **Unified Memory:** 48 GB
* **Storage:** Fast internal NVMe

---

## Where the 48 GB Goes

The **48 GB Unified Memory Architecture (UMA)** shares one pool between CPU, GPU, and OS. With inference moved to cloud providers, that pool now serves development workloads exclusively:

| Consumer | Typical | Peak | Notes |
| :--- | :--- | :--- | :--- |
| **macOS + system daemons** | ~6.0 GB | ~8.0 GB | Baseline; grows with login items |
| **Editor (VS Code / Antigravity)** | ~2.5 GB | ~5.0 GB | Per window; language servers dominate |
| **Browser** | ~3.0 GB | ~8.0 GB | Scales with tab count |
| **OrbStack VM + containers** | ~4.0 GB | ~16.0 GB | Databases and Dev Containers |
| **Nix builds / compilers** | ~2.0 GB | ~12.0 GB | Parallel `nix build` and Rust/Go links are the real spikes |
| **Headroom** | — | **~10 GB** | Absorbs peaks without swapping |

The important property is that **nothing holds a permanent reservation**. Memory is claimed and released as work happens, so a heavy `nix build` and a full container stack can coexist as long as they peak at different moments.

---

## Why This Replaced the Old Model-Sizing Budget

This note used to be a quantization table. A 32B model at 6-bit consumed ~25 GB of weights plus ~3.5 GB of KV cache — a **standing** reservation held for as long as the server ran, leaving roughly 13 GB for everything else. At 8-bit it left about 5 GB, which is below what a container stack plus a compiler needs.

That is the trade the cloud-first migration bought back: a fixed ~31 GB commitment became zero, and the machine stopped being memory-bound during normal development.

> [!TIP] Diagnosing memory pressure
> Watch the **Memory Pressure** graph in Activity Monitor, not the "Memory Used" figure — macOS deliberately uses free RAM for file cache, so high usage is normal and not itself a problem. Yellow or red pressure, or a rising swap figure, is the real signal. `vm_stat 5` shows compressor and pageout activity live.

> [!NOTE] Storage
> Fast NVMe still matters, but for build caches, container layers, and Nix store operations rather than model-weight loading. Decommissioning local inference reclaimed ~59 GB of SSD; see [[Cloud AI Providers & Models]] for the cleanup command if a stale weight cache remains.

---

## Related Notes
* [[System Architecture]]
* [[Cloud AI Providers & Models]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
