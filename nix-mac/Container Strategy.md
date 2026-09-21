---
title: Container Strategy
tags:
  - containers
  - orbstack
  - apple-container
  - docker
  - devcontainers
created: 2026-08-24
---

# 📦 Container Strategy (macOS Isolation)

## Overview: Ditching Docker Desktop

Docker Desktop adds significant overhead on macOS (heavy Electron UI, background telemetry, high idle memory/battery consumption). We replace it with native, lightweight alternatives.

---

## Comparison of Container Runtimes

| Feature | **Apple Container (`apple/container`)** | **OrbStack** | **Colima** | **Docker Desktop** |
| :--- | :--- | :--- | :--- | :--- |
| **Engine Core** | Native Swift (`Virtualization.framework`) | Swift / Rust native daemon | Lima (`Virtualization.framework`) | QEMU / Virtualization.framework |
| **Architecture** | 1 lightweight VM per container | Single optimized lightweight VM | Single lightweight VM | Heavy monolithic VM + GUI |
| **Idle CPU / RAM** | ~0.0% / Near zero | ~0.1% CPU / ~150MB RAM | ~0.2% CPU / ~300MB RAM | ~2-5% CPU / 1.5–3 GB RAM |
| **Docker CLI Compat** | Custom CLI (OCI compatible) | 100% Drop-in (`docker`, `compose`) | Drop-in via docker CLI | Native |
| **Dev Containers** | Manual setup / scripting | Instant 1-click in VS Code / Cursor | Supported | Supported |
| **GUI Quality** | None (pure CLI) | Ultra-fast native macOS GUI | None / Third-party | Heavy Electron |
| **License** | Open Source (Apache 2.0) | Free for personal / paid commercial | Open Source (Apache 2.0) | Paid subscription for enterprise |

---

## Recommended Approach

### Primary Recommendation: OrbStack
For most developers, **OrbStack** offers the best balance of speed, battery efficiency, and zero-friction compatibility with existing tools:
* Completely replaces Docker Desktop.
* Works seamlessly with `docker`, `docker compose`, and VS Code **Dev Containers**.
* Seamless network bridge (`host.docker.internal` lets containers reach services running on the macOS host).

### Native Pure CLI Alternative: Apple Container
If you prefer 100% official Apple open-source software:
* Repository: [github.com/apple/container](https://github.com/apple/container)
* Runs OCI containers with microsecond startup times.
* Ideal for headless scripting and isolated CI/build pipelines.

---

## Calling AI Providers from Containers

Containers reach model providers the same way the host does — straight out over HTTPS. There is no host inference server to bridge to.

* Pass credentials in explicitly; they are deliberately not baked into images:
  ```bash
  docker run --rm -e ANTHROPIC_API_KEY "$IMAGE"
  ```
* In a Dev Container, list the variable under `remoteEnv` in `devcontainer.json` so it inherits from your shell rather than being committed.

> [!CAUTION]
> Never put an API key in a `Dockerfile`, a build arg, or a committed `devcontainer.json`. Build args persist in image history, so a key added that way is exposed to anyone who pulls the image.

---

## Related Notes
* [[System Architecture]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
