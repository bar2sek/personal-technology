# Mac mini (M4 Pro 48GB) Integration: Native MLX Local LLM Inference & 10GbE Cluster Mesh

This guide details the architecture to integrate an **Apple Mac mini (M4 Pro, 48GB Unified Memory, 10GbE Networking)** into our homelab ecosystem, leveraging its 273 GB/s memory bandwidth for bare-metal **MLX / Ollama** AI LLM inference while connecting directly to our **Talos Linux Kubernetes cluster** over dedicated 10GbE.

---

## 📐 Recommended Architecture: Native macOS + 10GbE K8s ExternalName Integration

Running Talos Linux natively on Apple Silicon bare-metal is **not recommended** because it wipes macOS, breaking Apple Metal GPU acceleration, MLX framework optimization, and Remote Mac Desktop access.

Instead, we keep **macOS running natively on the M4 Pro Mac mini** and expose its MLX / Ollama local AI inference API directly into our Talos Kubernetes cluster as a hybrid external compute node over **10GbE SFP+ / 10GBASE-T**!

```
 +-----------------------------------------------------------------------------------+
 |                   Apple Mac mini (M4 Pro / 48GB Unified RAM / 10GbE)              |
 |  - macOS Native Workstation & Mac Remote Desktop (Screen Sharing / RustDesk)     |
 |  - MLX / Ollama AI Inference Engine (Metal GPU + 273 GB/s Unified Memory)        |
 |  - Direct 10GbE Uplink to UniFi USW-Aggregation Switch (Sub-Millisecond Latency) |
 |  - Exposes OpenAI-compatible API on LAN / Tailscale (Port 11434 / 8080)           |
 +-----------------------------------------------------------------------------------+
                                          |
                     10GbE Switch Backbone | (VLAN 10/20 / Tailscale Mesh)
                                          v
 +-----------------------------------------------------------------------------------+
 |                             Talos Kubernetes Cluster                              |
 |                                                                                   |
 |  +-----------------------------------------------------------------------------+  |
 |  |  K8s Service: `mac-mini-ollama` (type: ExternalName -> 10.10.10.50)           |  |
 |  +-----------------------------------------------------------------------------+  |
 |        /                                  |                                  \    |
 |       v                                   v                                   v   |
 | +---------------+                 +---------------+                 +-----------+ |
 | |  Open WebUI   |                 | Home Assistant|                 |  Immich   | |
 | |(ai.bar2sek.com)                 | (Voice AI LLM)|                 | (OCR / AI)| |
 | +---------------+                 +---------------+                 +-----------+ |
 +-----------------------------------------------------------------------------------+
```

---

## ⚡ Dual-AI Acceleration: Mac mini M4 Pro (MLX) vs NVIDIA RTX 4070 (CUDA)

Our homelab features **two powerful AI hardware engines**. By partitioning workloads based on hardware strengths, we maximize throughput:

```
                  +-------------------------------------------------------------+
                  |               Dual-AI Hardware Allocation                   |
                  +-------------------------------------------------------------+
                                 /                               \
                                v                                 v
   +---------------------------------------+   +---------------------------------------+
   |        Mac mini (M4 Pro / 48GB)       |   |       NVIDIA RTX 4070 (12GB VRAM)     |
   |      (273 GB/s Unified Memory)        |   |     (CUDA Cores + Tensor Cores)       |
   +---------------------------------------+   +---------------------------------------+
   | - 32B/70B LLMs (DeepSeek-R1, Llama 3) |   | - Fast 8B/14B LLMs (<10ms Latency)   |
   | - Long Context Windows (128k Tokens)  |   | - Immich CUDA Facial Recognition      |
   | - Apple MLX Framework 4-bit / 8-bit   |   | - Stable Diffusion / ComfyUI Images   |
   | - Code Generation & Deep Reasoning    |   | - Sunshine/Moonlight 4K Gaming Video  |
   | - 10GbE High-Speed Cluster Interlink  |   | - NVENC Hardware Video Encoder        |
   +---------------------------------------+   +---------------------------------------+
```

### AI Workload Allocation Table:

| AI Task / Service | Target Hardware | Engine | Why? |
| :--- | :--- | :--- | :--- |
| **Large Text LLMs (DeepSeek-R1 32B/70B, Llama 3.3)** | **Mac mini M4 Pro** | Native MLX / Ollama | 48GB Unified Memory holds 32B/70B parameter models that exceed 12GB VRAM. |
| **Fast Chat & Smart Home Voice** | **RTX 4070** | CUDA / vLLM | 504 GB/s GDDR6X VRAM delivers 100+ tokens/sec for 8B models. |
| **Immich Facial Recognition & Search** | **RTX 4070** | CUDA / ONNX | Immich CUDA acceleration processes thousands of photos in seconds. |
| **Image Generation (Stable Diffusion XL)**| **RTX 4070** | PyTorch TensorRT | NVIDIA CUDA TensorRT generates 1024x1024 images in <2 seconds. |
| **4K 120Hz Moonlight Streaming** | **RTX 4070** | NVENC Hardware Encoder| Dedicated 8th Gen NVENC encoder handles 4K video encoding at 0.5ms. |

---

## 🛠 Dual-AI Provider Configuration in Open WebUI

Open WebUI supports querying both AI engines simultaneously from a single unified chat interface:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: open-webui
  namespace: ai-system
spec:
  template:
    spec:
      containers:
        - name: open-webui
          image: ghcr.io/open-webui/open-webui:main
          env:
            # Primary Backend: Mac mini M4 Pro (32B & 70B DeepSeek / Llama Models via 10GbE)
            - name: OLLAMA_BASE_URL
              value: "http://mac-mini-ollama.ai-system.svc.cluster.local:11434"
            # Secondary Backend: RTX 4070 (Fast 8B Models & CUDA Image Gen)
            - name: OPENAI_API_BASE_URLS
              value: "http://mac-mini-ollama.ai-system:11434;http://rtx4070-cuda.ai-system:8000"
```

---

## 💡 Key Benefits of this Architecture

1. **Maximum MLX / Local LLM Performance**: Native macOS allows **MLX** (`mlx-lm`) and **Ollama** to utilize 100% of M4 Pro's 273 GB/s memory bandwidth to run 32B and 70B parameter models (DeepSeek-R1, Llama 3.3 70B, Qwen 2.5 32B) at blistering speeds.
2. **10GbE High-Speed Network Pipe**: With native 10GbE on the Mac mini connected to the UniFi switch fabric, Kubernetes pods experience near-zero latency (<0.5ms) and massive throughput when querying AI models.
3. **Mac Remote Desktop Access**: Full native macOS GUI remote desktop access via Screen Sharing, VNC, RustDesk, or Moonlight.
4. **Dedicated Omni Appliance Preserved**: The cheap Dell OptiPlex remains the dedicated 24/7 Sidero Omni PXE boot appliance without risking Mac mini uptime.

---

## 🛠 Step-by-Step Setup Guide

### 1. Configure Native Ollama / MLX Server on Mac mini (macOS)

Install and run Ollama as a launch daemon listening on all network interfaces (`0.0.0.0`):

```bash
# Set Ollama to listen on all interfaces
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
launchctl setenv OLLAMA_ORIGINS "*"

# Pull high-performance local models
ollama run deepseek-r1:32b
ollama run llama3.3:70b-instruct-q4_K_M
```

---

### 2. Kubernetes ExternalName Service Manifest (`mac-mini-service.yaml`)

Deploy this manifest to expose the Mac mini's LLM engine to all K8s namespaces:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mac-mini-ollama
  namespace: ai-system
spec:
  type: ExternalName
  externalName: 10.10.10.50 # Mac mini 10GbE static IP on VLAN 10
  ports:
    - name: http
      port: 11434
      targetPort: 11434
```
