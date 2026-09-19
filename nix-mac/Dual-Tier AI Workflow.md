---
title: Dual-Tier AI Workflow
tags:
  - workflow
  - architecture
  - local-llm
  - antigravity
  - qwen
created: 2026-08-24
---

# ⚡ The Unified Agentic Developer Workflow

Combining **local M5 Pro hardware** with **frontier cloud models** inside a single unified canvas (**Antigravity IDE**) yields the optimal balance of speed, zero token exhaustion, and deep reasoning:

```
┌─────────────────────────────────────────────────────────────┐
│                 UNIFIED AGENTIC ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│               WORKSPACE CANVAS: ANTIGRAVITY IDE             │
├──────────────────────────────┬──────────────────────────────┤
│ PRIMARY: Native AGY Agent    │ BACKUP: Roo Code Switcher    │
├──────────────────────────────┼──────────────────────────────┤
│ • Gemini Flash / Pro (Cloud) │ • Local Qwen 32B (:8080 MLX) │
│ • Multi-file Planning & Docs │ • Claude Sonnet 4.6 / Opus 5 │
│ • Subagent Orchestration     │ • $0 Scoped Edits & Scripts  │
│ • Terminal Sandbox Tools     │ • Rate-Limit Relief Valve    │
│ • Runs until Quota Pause     │ • 100% In-IDE Seamless Flow  │
└──────────────────────────────┴──────────────────────────────┘
```

---

## Tier 1: Primary Orchestrator (Native Antigravity Agent)
* **Goal:** High-level planning, complex multi-repo orchestration, and autonomous execution.
* **Platform:** Antigravity IDE native agent panel.
* **Model:** Gemini 3.8 Flash (Medium) / Gemini Pro.
* **Capabilities:**
  1. Inspecting file structures, reading docs, and drafting implementation plans.
  2. Executing terminal commands (`talosctl`, `kubectl`, `nix`).
  3. Spawning subagents for concurrent tasks.
  4. Visual diff overlays and inline diagnostic auto-fixes.

---

## Tier 2: Zero-Dollar Local Inference (Qwen 2.5 Coder 32B on MLX)
* **Goal:** High-performance, zero-cost coding without touching cloud quotas.
* **Engine:** Dedicated `oMLX` server on `http://localhost:8080/v1`.
* **Hardware Sizing:** High-quant (6-bit/8-bit) Qwen 32B utilizing Apple Silicon Unified Memory (~25–34GB).
* **Environment:** Roo Code extension inside Antigravity IDE.
* **Use Cases:** Scoped single-file refactors, unit tests, shell script generation, and offline work.

---

## Tier 3: Strategic Frontier Backup (Claude Sonnet 4.6 & Opus 5)
* **Goal:** Seamless continuity when Antigravity quota pauses, or for tough architectural tie-breakers and maximum-reasoning deep audits.
* **Provider:** Anthropic API (Pay-As-You-Go with hard spending limit) or OpenRouter.
* **Environment:** Toggle dropdown in Roo Code inside Antigravity IDE (`Claude Sonnet 4.6` for fast, cost-efficient edits; `Claude Opus 5` for heavy frontier reasoning).
* **Cost Advantage:** Because it acts purely as a backup, monthly costs stay low with prompt caching enabled.

---

## Summary Comparison of Antigravity Flavors

| Antigravity Flavor | Has In-Editor Code Canvas? | Multi-Model Extension Support? | Can Host Local MLX via Roo Code? | Primary Focus |
| :--- | :--- | :--- | :--- | :--- |
| **Antigravity IDE** | Yes (VS Code base) | Yes (VS Code Extensions) | Yes (via Roo Code sidebar) | **Daily Driver: All-in-one coding & agent IDE** |
| **Antigravity Desktop 2.0**| No (Companion app) | No | No | High-level agent mission control & cron dashboard |
| **Antigravity CLI (`agy`)** | Terminal CLI | CLI Tools / MCP | CLI integrations | Scriptable terminal pair programming |

---

## Related Notes
* [[System Architecture]]
* [[Local LLMs with MLX]]
* [[Nix-Darwin Guide]]
