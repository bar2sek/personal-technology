---
title: Mac AI Workstation Index
tags:
  - macos
  - ai
  - mlx
  - containers
  - obsidian
created: 2026-08-24
---

# 🖥️ Mac AI Workstation (M5 Pro 48GB)

Welcome to the **Mac AI Workstation** notes vault. This workspace documents the architecture, setup, configuration, and maintenance routines for running local coding LLMs (Qwen 2.5 Coder) alongside a clean, containerized development environment.

---

## 🗺️ Map of Content (MOC)

### ⭐ Pre-Flight & Unboxing (Start Here!)
* [[Pre-Flight Preparation & Unboxing Master Plan]] — The 15-minute 1-click bootstrap pipeline and pre-flight checklist.

### 1. Architecture & Hardware
* [[System Architecture]] — The hybrid bare-metal LLM + containerized applications paradigm.
* [[Dual-Tier AI Workflow]] — Pairing local Qwen (micro/tab completions) with Antigravity (macro/agentic planning).
* [[Hardware & Memory Budget]] — Unified memory allocation (48GB), model quantization, and headroom math.
* [[Hardware Protection & Keyboard Care]] — Step-by-step Barekey decal application & screen buffer setup.

### 2. LLM Serving & MLX
* [[Local LLMs with MLX]] — Running Qwen 2.5 Coder (14B/32B) via Apple's MLX and `uv` with zero global system bloat.
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
