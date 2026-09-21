---
title: "System Architecture"
date: 2026-09-20
tags:
  - architecture
  - macos
  - ai/cloud
status: evergreen
aliases: []
---

# 🏗️ System Architecture

## The Thin-Client + Container Model

The workstation is a **thin client for inference and a heavy host for builds**. Reasoning happens over the network; unified memory is spent on containers and compilers:

```
┌─────────────────────────────────────────────────────────────┐
│                       macOS Host                            │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  Editors & Agents (thin clients, no model weights)   │  │
│   │  • VS Code + Continue.dev                            │  │
│   │  • Antigravity IDE + Roo Code switcher               │  │
│   │  • Claude Code (terminal-native agent)               │  │
│   └──────────────────────────┬───────────────────────────┘  │
│                              │ HTTPS (provider APIs)        │
│   ┌──────────────────────────┴───────────────────────────┐  │
│   │  Isolated Application & Dev Container Layer          │  │
│   │  • Apple Container (`apple/container`) or OrbStack   │  │
│   │  • DevContainers, Databases, Node/Rust Toolchains    │  │
│   │  • Free to use the full unified memory envelope      │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
        Anthropic · Google · xAI  (see [[Cloud AI Providers & Models]])
```

---

## Key Design Principles

### 1. Metal GPU Access Boundary
* **The Reality:** Linux containers running on macOS (whether via Docker, OrbStack, or Apple Container) run inside a Linux VM managed by macOS `Virtualization.framework`.
* **The Limitation:** Linux guest VMs do **not** have direct pass-through access to Apple's Metal GPU API.
* **The Consequence:** Any GPU-bound workload on this machine must run natively on macOS, never inside a container. In practice this constraint is now mostly moot for AI work — inference runs on [[Cloud AI Providers & Models|cloud providers]], and the cluster RTX 4070 covers workloads that genuinely need a local GPU.

### 2. Application & Dev Isolation
* Keep the host macOS clean of language runtime clutter (Node versions, Rust toolchains, Postgres/Redis daemons).
* Run all project dependencies, microservices, and databases inside [[Container Strategy|lightweight containers]] or [[Mac Cleanliness & Anti-Bloat Guide|isolated virtual environments]].

### 3. Provider API Layer
* Every tool talks to a hosted provider over HTTPS — there is no local endpoint to start, supervise, or contend for a port.
* Credentials come from the shell environment or the editor keychain, never from tracked config. See [[Cloud AI Providers & Models]] for the routing table and credential hygiene.
* **Gotcha:** because inference is now off-box, connectivity is a hard dependency. There is no offline fallback; plan accordingly for flights and outages.

---

## Related Notes
* [[Hardware & Memory Budget]]
* [[Cloud AI Providers & Models]]
* [[Container Strategy]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
