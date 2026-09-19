---
title: System Architecture
tags:
  - architecture
  - macos
  - hybrid-model
  - mlx
created: 2026-08-24
---

# 🏗️ System Architecture

## The Hybrid Host + Container Model

Running local AI workflows alongside isolated development environments on Apple Silicon requires a **hybrid architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│                       macOS Host                            │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐  │
│   │  Bare-Metal LLM Engine (Zero System Bloat via `uv`)  │  │
│   │  • Apple MLX (`mlx-lm`) / Ollama                     │  │
│   │  • Qwen 2.5 Coder (14B / 32B @ 4-bit)                │  │
│   │  • Direct Metal GPU & 48GB Unified Memory Access     │  │
│   │  • Exposes OpenAI-compatible API (localhost:8080)    │  │
│   └──────────────────────────┬───────────────────────────┘  │
│                              │ API Calls (JSON / SSE)       │
│   ┌──────────────────────────┴───────────────────────────┐  │
│   │  Isolated Application & Dev Container Layer          │  │
│   │  • Apple Container (`apple/container`) or OrbStack   │  │
│   │  • DevContainers, Databases, Node/Rust Toolchains    │  │
│   │  • IDEs (VS Code / Antigravity) connect to port 8080 │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Design Principles

### 1. Metal GPU Access Boundary
* **The Reality:** Linux containers running on macOS (whether via Docker, OrbStack, or Apple Container) run inside a Linux VM managed by macOS `Virtualization.framework`.
* **The Limitation:** Linux guest VMs do **not** have direct pass-through access to Apple's Metal GPU API.
* **The Solution:** Always execute LLM inference natively on macOS using Apple's [[Local LLMs with MLX|MLX]] or Metal-accelerated backends to achieve full GPU compute speeds and zero-copy memory throughput.

### 2. Application & Dev Isolation
* Keep the host macOS clean of language runtime clutter (Node versions, Rust toolchains, Postgres/Redis daemons).
* Run all project dependencies, microservices, and databases inside [[Container Strategy|lightweight containers]] or [[Mac Cleanliness & Anti-Bloat Guide|isolated virtual environments]].

### 3. Unified OpenAI-Compatible API Layer
* The host MLX server exposes a standard endpoint: `http://localhost:8080/v1`.
* All tools (IDEs, DevContainers, web frontends, CLI agents) interface with local models using standard OpenAI client libraries or API keys (set as dummy values like `EMPTY`).

---

## Related Notes
* [[Hardware & Memory Budget]]
* [[Local LLMs with MLX]]
* [[Container Strategy]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
