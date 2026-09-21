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
┌─────────────────────────────────────────────────────────────┐
│                 CLOUD-FIRST AGENTIC ARCHITECTURE            │
├─────────────────────────────────────────────────────────────┤
│               WORKSPACE CANVAS: ANTIGRAVITY IDE             │
├──────────────────────────────┬──────────────────────────────┤
│ PRIMARY: Native AGY Agent    │ EXTENSION: Roo Code Switcher │
├──────────────────────────────┼──────────────────────────────┤
│ • Gemini Flash / Pro (Cloud) │ • Claude Sonnet 5 / Opus 5   │
│ • Multi-file Planning & Docs │ • xAI Grok (API)             │
│ • Subagent Orchestration     │ • Deep Audits & Alternative  │
│ • Terminal Sandbox Tools     │ • Rate-Limit Relief Valve    │
│ • Built-in Cloud Intelligence│ • 100% In-IDE Seamless Flow  │
└──────────────────────────────┴──────────────────────────────┘
```

---

## Tier 1: Primary Orchestrator (Native Antigravity Agent)
* **Goal:** High-level planning, complex multi-repo orchestration, and autonomous execution.
* **Platform:** Antigravity IDE native agent panel.
* **Model:** Gemini 3.8 Flash / Gemini Pro.
* **Capabilities:**
  1. Inspecting file structures, reading docs, and drafting implementation plans.
  2. Executing terminal commands (`talosctl`, `kubectl`, `nix`).
  3. Spawning subagents for concurrent tasks.
  4. Visual diff overlays and inline diagnostic auto-fixes.

---

## Tier 2: Frontier Multi-Model Engine (Claude Sonnet 5 & Opus 5 via Roo Code)
* **Goal:** Alternative reasoning perspective, deep architectural tie-breakers, and maximum-reasoning audits.
* **Provider:** Anthropic API (Pay-As-You-Go with spending limits).
* **Environment:** Toggle dropdown in Roo Code inside Antigravity IDE — `claude-sonnet-5` for fast, cost-efficient edits; `claude-opus-5` for heavy reasoning.
* **Model reference:** see [[Cloud AI Providers & Models]] for the full tiering table and exact model ID strings.

---

## Tier 3: Real-Time & High-Velocity Coding (xAI Grok via Roo Code)
* **Goal:** Fast, state-of-the-art coding and real-time knowledge queries without burning primary quotas.
* **Provider:** xAI API (`grok-2` / `grok-code`).
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
