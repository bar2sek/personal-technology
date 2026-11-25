---
title: Dual-Tier AI Workflow
date: 2026-09-20
tags:
  - workflow
  - architecture
  - ai/cloud
  - antigravity
status: evergreen
aliases: []
---

# ⚡ The Unified Agentic Developer Workflow

Routing work across **frontier cloud providers** inside a single unified canvas (**VS Code** with the Antigravity and Claude Code extensions, plus optional VS Code native BYOK) balances speed, cost, and depth of reasoning. The tiers below are ordered by how often you should reach for them, not by capability — escalate only when the cheaper tier stalls.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           HYBRID AGENTIC ARCHITECTURE                            │
├──────────────────────────────────────────────────────────────────────────────────┤
│                       WORKSPACE CANVAS: VISUAL STUDIO CODE                       │
├────────────────────────────┬──────────────────────────┬──────────────────────────┤
│ PRIMARY: Native AGY Agent  │ EXTENSION: Claude Code   │ VS CODE BYOK             │
├────────────────────────────┼──────────────────────────┼──────────────────────────┤
│ • Gemini (Cloud)           │ • Claude Sonnet / Opus   │ • Copilot Free commits   │
│ • Multi-file Planning      │ • Claude.ai Subscription │ • Azure AI Foundry       │
│ • Terminal Sandbox Tools   │ • Zero per-token API fees│ • AWS Bedrock            │
│ • Autonomous Subagents     │ • Deep code refactoring  │ • Local MLX (Qwen 27B)   │
│ • Visual diff overlays     │ • Graphical chat & diffs │   (on-demand :8080)      │
└────────────────────────────┴──────────────────────────┴──────────────────────────┘
```

---

## Tier 1: Primary Orchestrator (Native Antigravity Agent)
* **Goal:** High-level planning, complex multi-repo orchestration, and autonomous execution.
* **Platform:** Antigravity extension agent panel in VS Code.
* **Model:** Gemini (Cloud).
* **Capabilities:**
  1. Inspecting file structures, reading docs, and drafting implementation plans.
  2. Executing terminal commands (`talosctl`, `kubectl`, `nix`).
  3. Spawning subagents for concurrent tasks.
  4. Visual diff overlays and inline diagnostic auto-fixes.

---

## Tier 2: Subscription Frontier Reasoning (Claude Code Extension & Desktop)
* **Goal:** Top-tier reasoning, deep codebase comprehension, and multi-agent / heavy refactoring work.
* **Platform:** Official Claude Code extension in the VS Code sidebar (`anthropic.claude-code`) and Claude Desktop app.
* **Authentication:** **Claude.ai paid subscription** (Pro/Team/Enterprise).
* **Cost Advantage:** Billed under your existing monthly Claude subscription — **zero per-token Anthropic API charges**.
* **Capabilities:** Full workspace indexing, interactive chat, inline diff application, and git status awareness.

---

## Tier 3: On-Demand Cloud APIs (Azure AI Foundry & AWS Bedrock via VS Code BYOK)
* **Goal:** Enterprise cloud API testing, provisioned models, and alternative provider evaluation without extra extensions.
* **Platform:** VS Code built-in **Chat: Manage Language Models** (BYOK) alongside Copilot Free for Git commit messages and optional Tab completions.
* **Providers:** **Azure AI Foundry** (endpoint + key or Entra ID) and **AWS Bedrock** (IAM credentials or AWS profile).

---

## Tier 4: Local Playground & Offline Coder (Apple MLX via VS Code BYOK)
* **Goal:** Zero-cost experimentation, offline coding, and playing with open-weights without cloud quotas.
* **Provider:** Apple MLX running on Apple Silicon Metal GPU via `uvx` (`http://localhost:8080/v1`), connected via VS Code BYOK.
* **Model:** `mlx-community/Qwen3.8-27B-4bit` (~18–19 GB footprint active).
* **Lifecycle:** On-demand via `just serve-qwen-27b` — memory is freed immediately upon exiting.
* **Guide:** see [[Local LLMs with MLX]] for server commands and hardware sizing.

---

## Summary Comparison of Antigravity Flavors

| Antigravity Flavor | Has In-Editor Code Canvas? | Multi-Model Extension Support? | Primary Focus |
| :--- | :--- | :--- | :--- |
| **Antigravity extension in VS Code** | Yes (VS Code) | Yes (VS Code Extensions) | **Daily Driver: coding & agent IDE** |
| **Antigravity Desktop 2.0**| No (Companion app) | No | High-level agent mission control & cron dashboard |
| **Antigravity CLI (`agy`)** | Terminal CLI | CLI Tools / MCP | Scriptable terminal pair programming |

---

## Related Notes
* [[System Architecture]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
