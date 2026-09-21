---
title: "Mac AI Workstation Index"
date: 2026-09-20
tags:
  - macos
  - ai/cloud
  - containers
  - obsidian
status: evergreen
aliases: []
---

# 🖥️ Mac AI Workstation (M5 Pro 48GB)

Welcome to the **Mac AI Workstation** notes vault. This workspace documents the architecture, setup, configuration, and maintenance routines for a cloud-first AI development environment — frontier models over provider APIs, with the machine's unified memory reserved for containers, compilers, and Nix builds.

---

## 🗺️ Map of Content (MOC)

### ⭐ Pre-Flight & Unboxing (Start Here!)
* [[Pre-Flight Preparation & Unboxing Master Plan]] — The 15-minute 1-click bootstrap pipeline and pre-flight checklist.

### 1. Architecture & Hardware
* [[System Architecture]] — The containerized applications paradigm and Metal GPU access boundary.
* [[Dual-Tier AI Workflow]] — Routing work between fast and deep cloud model tiers.
* [[Hardware & Memory Budget]] — Unified memory allocation (48GB) and headroom math.
* [[Hardware Protection & Keyboard Care]] — Step-by-step Barekey decal application & screen buffer setup.

### 2. Cloud AI & Model Routing
* [[Cloud AI Providers & Models]] — Model tiering, provider routing per tool, and credential hygiene.
* [[IDE Configuration Guide]] — Step-by-step config for VS Code + Continue.dev and Antigravity.

### 3. Containerization & Isolation
* [[Container Strategy]] — Apple Container (`apple/container`) vs. OrbStack vs. Docker Desktop.

### 4. System Hygiene & Operations
* [[Declarative macOS Setup]] — Extending "System as Code" across dotfiles, settings, runtimes, and runners.
* [[Nix-Darwin Guide]] — The single-file (`flake.nix`) agent-driven declarative OS setup.
* [[Cloud Storage & Google Drive Guide]] — Disabling iCloud syncing & configuring Google Drive for Desktop.
* [[Mac Cleanliness & Anti-Bloat Guide]] — Best practices for keeping macOS pristine (uv, Brewfile, ephemeral environments).
* [[Setup Checklist]] — Step-by-step unboxing and setup checklist for the new Mac.

---

> [!TIP]
> All notes are formatted with Obsidian-compatible Markdown, tags, and callouts for seamless graph visualization and search.
