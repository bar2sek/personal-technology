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

The **48 GB Unified Memory Architecture (UMA)** shares one pool between CPU, GPU, and OS. Memory is divided between standard development workloads and optional, on-demand local inference:

| Consumer | Baseline Dev | With Local MLX Active | Notes |
| :--- | :--- | :--- | :--- |
| **macOS + system daemons** | ~6.0 GB | ~6.0 GB | Baseline; grows with login items |
| **VS Code (+ Antigravity / Claude Code extensions)** | ~2.5 GB | ~2.5 GB | Per window; language servers & agent canvas |
| **Browser** | ~3.0 GB | ~3.0 GB | Scales with tab count |
| **Local MLX (Qwen 3.8 27B 4-bit)** | — | **~18–19 GB** | On-demand weights (~16.1 GB) + KV cache (~2–3 GB) |
| **OrbStack VM + containers** | ~4.0 GB | ~4.0 GB (up to ~8 GB) | Databases and Dev Containers |
| **Nix builds / compilers** | ~2.0 GB | ~2.0 GB (up to ~6 GB) | Parallel `nix build` and compilation spikes |
| **Available Headroom** | **~30 GB** | **~11–13 GB** | Absorbs peaks without swapping |

The key architectural invariant is that **local inference holds NO permanent reservation**. It runs ephemerally via `just serve-qwen-27b`. When closed, all ~18–19 GB is immediately released back to macOS, leaving 30+ GB free for heavy container stacks and parallel compilation.

---

## On-Demand Sizing: Qwen 3.8 27B (4-bit)

* **Why 4-bit instead of 8-bit?**
  * At 8-bit, weights consume ~30 GB, squeezing headroom down for everything else.
  * At 4-bit, weights consume ~16.1 GB (`14.97 GiB`), leaving a comfortable **~29–30 GB buffer** for simultaneous IDE, browser, and container operation.

> [!TIP] Diagnosing memory pressure
> Watch the **Memory Pressure** graph in Activity Monitor, not the "Memory Used" figure — macOS deliberately uses free RAM for file cache, so high usage is normal and not itself a problem. Yellow or red pressure, or a rising swap figure, is the real signal. `vm_stat 5` shows compressor and pageout activity live.

> [!NOTE] Storage
> Qwen 3.8 27B (4-bit) weights occupy ~16.1 GB (`14.97 GiB`) in `~/.cache/huggingface/hub/`. To reclaim this space when not experimenting locally, simply remove the cache directory (see [[Local LLMs with MLX]]).

---

## Related Notes
* [[Workstation Display & Monitor Mounting Guide]]
* [[System Architecture]]
* [[Local LLMs with MLX]]
* [[Dual-Tier AI Workflow]]
* [[Cloud AI Providers & Models]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
