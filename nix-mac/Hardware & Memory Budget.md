---
title: Hardware & Memory Budget
tags:
  - hardware
  - memory
  - m5-pro
  - qwen
created: 2026-08-24
---

# 🧠 Hardware & Memory Budget

## Target Specifications
* **Machine:** MacBook Pro
* **Processor:** Apple M5 Pro
* **Unified Memory:** 48 GB
* **Storage Consideration:** Fast internal NVMe (essential for rapid model weight loading)

---

## Model Sizing & RAM Allocation

The **48GB Unified Memory Architecture (UMA)** allows dynamic sharing between the CPU, GPU, and OS. Below is the realistic memory allocation breakdown:

| Workload Scenario | Qwen Model & Quantization | Model Weight RAM | Context Buffer (32k) | OS & Base Apps | Free / Container RAM |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Max RAM Utilization (8-bit)** | **Qwen 2.5 Coder 32B (8-bit)** | ~33.5 GB | ~3.8 GB | ~6.0 GB | **~4.7 GB** |
| **High Precision Sweet Spot (6-bit)** | **Qwen 2.5 Coder 32B (6-bit)** | ~25.0 GB | ~3.5 GB | ~6.0 GB | **~13.5 GB** |
| **Standard Baseline (4-bit)** | **Qwen 2.5 Coder 32B (4-bit)** | ~18.5 GB | ~3.5 GB | ~6.0 GB | **~20.0 GB** |

---

## Key Takeaways for 48GB Configuration

> [!TIP]
> **High-Quantization on Apple Silicon (6-bit vs 8-bit):**
> * **8-bit (`mlx-community/Qwen2.5-Coder-32B-Instruct-8bit`):** Maximizes hardware investment, preserving full 16-bit weight fidelity with zero degradation. Consumes ~37GB total under full 32k context, leaving ~5GB for OS and Antigravity IDE.
> * **6-bit (`mlx-community/Qwen2.5-Coder-32B-Instruct-6bit`):** Captures >99.7% of full precision while leaving a generous ~13.5GB buffer for OrbStack containers, Antigravity IDE, and browser tabs.
> * Small tab-completion models (1.5B/14B) are completely decommissioned to dedicate 100% of GPU compute and unified memory to high-reasoning agent models.

---

## Related Notes
* [[System Architecture]]
* [[Local LLMs with MLX]]
