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

Routing work across **frontier cloud providers** inside a single unified canvas (**Antigravity IDE**) balances speed, cost, and depth of reasoning. The tiers below are ordered by how often you should reach for them, not by capability — escalate only when the cheaper tier stalls.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      HYBRID AGENTIC ARCHITECTURE                       │
├────────────────────────────────────────────────────────────────────────┤
│                   WORKSPACE CANVAS: ANTIGRAVITY IDE                    │
├────────────────────────────┬────────────────────────────┬──────────────┤
│ PRIMARY: Native AGY Agent  │ EXTENSION: Claude Code     │ ROO CODE     │
├────────────────────────────┼────────────────────────────┼──────────────┤
│ • Gemini Flash/Pro (Cloud) │ • Claude 3.7 / Sonnet      │ • Grok (xAI) │
│ • Native Tab Autocomplete  │ • Claude.ai Subscription   │ • Local MLX  │
│ • Multi-file Planning      │ • Zero per-token API fees  │   (Qwen 32B) │
│ • Terminal Sandbox Tools   │ • Deep code refactoring    │ • AWS Bedrock│
│ • Autonomous Subagents     │ • Graphical chat & diffs   │   (Hosted)   │
└────────────────────────────┴────────────────────────────┴──────────────┘
```

---

## Tier 1: Primary Orchestrator (Native Antigravity Agent)
* **Goal:** High-level planning, complex multi-repo orchestration, and autonomous execution.
* **Platform:** Antigravity IDE native agent panel.
* **Model:** Gemini 3.8 Flash / Gemini Pro + Native Antigravity Tab (speculative decoding).
* **Capabilities:**
  1. Inspecting file structures, reading docs, and drafting implementation plans.
  2. Executing terminal commands (`talosctl`, `kubectl`, `nix`).
  3. Spawning subagents for concurrent tasks.
  4. Visual diff overlays and inline diagnostic auto-fixes.
  5. Built-in low-latency ghost-text tab autocomplete.

---

## Tier 2: Subscription Frontier Reasoning (Claude Code Extension)
* **Goal:** Top-tier reasoning, deep codebase comprehension, and multi-turn pair programming.
* **Platform:** Official Claude Code extension in Antigravity IDE sidebar (`anthropic.claude-code`).
* **Authentication:** **Claude.ai paid subscription** (Pro/Team/Enterprise).
* **Cost Advantage:** Billed under your existing monthly Claude subscription — **zero per-token Anthropic API charges**.
* **Capabilities:** Full workspace indexing, interactive chat, inline diff application, and git status awareness.

---

## Tier 3: Real-Time & High-Velocity Coding (xAI Grok via Roo Code)
* **Goal:** Fast, state-of-the-art coding and real-time knowledge queries without burning primary quotas.
* **Provider:** xAI API (`grok-2` / `grok-code`).
* **Environment:** Configured in Roo Code provider profiles.

---

## Tier 4: Local Playground & Offline Coder (Apple MLX via Roo Code)
* **Goal:** Zero-cost experimentation, offline coding, and playing with open-weights without cloud quotas.
* **Provider:** Apple MLX running on Apple Silicon Metal GPU via `uvx` (`http://localhost:8080/v1`).
* **Model:** `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit` (~22 GB footprint active).
* **Lifecycle:** On-demand via `just serve-qwen-32b` — memory is freed immediately upon exiting.
* **Guide:** see [[Local LLMs with MLX]] for server commands and hardware sizing.

---

## Tier 5: Enterprise Cloud Inference (AWS Bedrock via Roo Code)
* **Goal:** Enterprise security boundary, provisioned models, and private cloud quota.
* **Provider:** AWS Bedrock (IAM credentials or AWS profile from `~/.aws/credentials`).
* **Model:** Private hosted LLM ARN or provisioned foundation model in `us-east-1`.
* **Environment:** Configured in Roo Code provider profiles.

---

## Summary Comparison of Antigravity Flavors

| Antigravity Flavor | Has In-Editor Code Canvas? | Multi-Model Extension Support? | Primary Focus |
| :--- | :--- | :--- | :--- |
| **Antigravity IDE** | Yes (VS Code base) | Yes (VS Code Extensions) | **Daily Driver: All-in-one coding & agent IDE** |
| **Antigravity Desktop 2.0**| No (Companion app) | No | High-level agent mission control & cron dashboard |
| **Antigravity CLI (`agy`)** | Terminal CLI | CLI Tools / MCP | Scriptable terminal pair programming |

---

## Related Notes
* [[System Architecture]]
* [[Cloud AI Providers & Models]]
* [[Nix-Darwin Guide]]
