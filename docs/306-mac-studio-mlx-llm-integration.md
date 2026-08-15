# Mac Studio Integration: Native MLX Local LLM Inference & Hybrid K8s Integration

This guide details the optimal architecture to integrate an **Apple Silicon Mac Studio** into our homelab ecosystem, leveraging its Unified Memory architecture for bare-metal **MLX / Ollama** AI LLM inference while connecting seamlessly to our **Talos Linux Kubernetes cluster**.

---

## 📐 Recommended Architecture: Native macOS + K8s ExternalName Integration

Running Talos Linux natively on Apple Silicon bare-metal is **not recommended** because it wipes macOS, breaking Apple Silicon Metal GPU hardware acceleration, MLX framework optimization, and Remote Mac Desktop access.

Instead, we keep **macOS running natively on the Mac Studio** and expose its MLX / Ollama local AI inference API directly into our Talos Kubernetes cluster as a hybrid external compute node!

```
 +-----------------------------------------------------------------------------------+
 |                             Apple Silicon Mac Studio                              |
 |  - macOS Native Workstation & Mac Remote Desktop (Screen Sharing / RustDesk)     |
 |  - MLX / Ollama AI Inference Engine (Metal GPU + Unified Memory Architecture)    |
 |  - Exposes OpenAI-compatible API on LAN / Tailscale (Port 11434 / 8080)           |
 +-----------------------------------------------------------------------------------+
                                          |
                     Hybrid Network Access | (VLAN 10 / Tailscale Mesh)
                                          v
 +-----------------------------------------------------------------------------------+
 |                             Talos Kubernetes Cluster                              |
 |                                                                                   |
 |  +-----------------------------------------------------------------------------+  |
 |  |  K8s Service: `ollama-mac-studio` (type: ExternalName -> 10.10.10.x)          |  |
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

## ⚡ Dual-AI Acceleration: Mac Studio (MLX) vs NVIDIA RTX 4070 (CUDA)

Our homelab features **two powerful AI hardware engines**. By partitioning workloads based on hardware strengths, we maximize throughput:

```
                  +-------------------------------------------------------------+
                  |               Dual-AI Hardware Allocation                   |
                  +-------------------------------------------------------------+
                                 /                               \
                                v                                 v
   +---------------------------------------+   +---------------------------------------+
   |        Apple Silicon Mac Studio       |   |       NVIDIA RTX 4070 (12GB VRAM)     |
   |      (Unified Memory Architecture)    |   |     (CUDA Cores + Tensor Cores)       |
   +---------------------------------------+   +---------------------------------------+
   | - Large 70B LLMs (Llama 3.3, DeepSeek)|   | - Fast 8B/14B LLMs (<10ms Latency)   |
   | - Long Context Windows (128k Tokens)  |   | - Immich CUDA Facial Recognition      |
   | - Apple MLX Framework Optimization    |   | - Stable Diffusion / ComfyUI Images   |
   | - Code Generation & Deep Reasoning    |   | - Sunshine/Moonlight 4K Gaming Video  |
   +---------------------------------------+   +---------------------------------------+
```

### AI Workload Allocation Table:

| AI Task / Service | Target Hardware | Engine | Why? |
| :--- | :--- | :--- | :--- |
| **Large Text LLMs (70B / DeepSeek-R1)** | **Mac Studio** | Native MLX / Ollama | Unified Memory (64GB+) holds 70B parameter models that exceed 12GB VRAM. |
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
            # Primary Backend: Mac Studio (Large 70B & DeepSeek Models)
            - name: OLLAMA_BASE_URL
              value: "http://mac-studio-ollama.ai-system.svc.cluster.local:11434"
            # Secondary Backend: RTX 4070 (Fast 8B Models & CUDA Image Gen)
            - name: OPENAI_API_BASE_URLS
              value: "http://mac-studio-ollama.ai-system:11434;http://rtx4070-cuda.ai-system:8000"
```

## 💡 Key Benefits of this Architecture

1. **Maximum MLX / Local LLM Performance**: Native macOS allows **MLX** (`mlx-lm`) and **Ollama** to utilize 100% of Apple Silicon Unified Memory bandwidth (up to 800 GB/s on M-Max/Ultra chips) to run 70B parameter models (Llama 3 70B, DeepSeek-R1, Qwen 2.5) at blistering speeds.
2. **Mac Remote Desktop Access**: Full native macOS GUI remote desktop access via Screen Sharing, VNC, RustDesk, or Moonlight.
3. **Zero Cluster Compute Overhead**: Cluster workload pods offload heavy AI tensor processing to the Mac Studio while K8s manages web UIs, auth, storage, and networking.
4. **Dedicated Omni Appliance Preserved**: The cheap Dell OptiPlex remains the dedicated 24/7 Sidero Omni PXE boot appliance without risking Mac Studio uptime.

---

## 🛠 Step-by-Step Setup Guide

### 1. Configure Native Ollama / MLX Server on Mac Studio (macOS)

Install and run Ollama as a launch daemon listening on all network interfaces (`0.0.0.0`):

```bash
# Set Ollama to listen on all interfaces
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
launchctl setenv OLLAMA_ORIGINS "*"

# Pull high-performance local models
ollama run deepseek-r1:14b
ollama run llama3.3:70b
```

---

### 2. Kubernetes ExternalName Service Manifest (`mac-studio-service.yaml`)

Deploy this manifest to expose the Mac Studio's LLM engine to all K8s namespaces:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mac-studio-ollama
  namespace: ai-system
spec:
  type: ExternalName
  externalName: mac-studio.mgmt.homelab.local # Or Mac Studio static IP 10.10.10.50
  ports:
    - name: http
      port: 11434
      targetPort: 11434
```

---

### 3. Open WebUI Deployment Manifest (`open-webui.yaml`)

Expose **Open WebUI** on `ai.bar2sek.com` via Cloudflare Tunnel and Authentik SSO, backed by the Mac Studio:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: open-webui
  namespace: ai-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: open-webui
  template:
    metadata:
      labels:
        app: open-webui
    spec:
      containers:
        - name: open-webui
          image: ghcr.io/open-webui/open-webui:main
          env:
            - name: OLLAMA_BASE_URL
              value: "http://mac-studio-ollama.ai-system.svc.cluster.local:11434"
          ports:
            - containerPort: 8080
```

---

## ⚖️ Option B: OrbStack / Linux VM Worker Node (Alternative)

If you strictly want the Mac Studio to contribute worker pod CPU/RAM to the K8s cluster:
- Install **OrbStack** or **UTM** on macOS.
- Launch a Talos / Linux VM inside OrbStack.
- Join the VM to the Talos cluster as a worker node.
- *Note*: This introduces virtualization overhead for Linux pods and restricts direct Apple Metal GPU access. Option A (Native macOS + K8s ExternalName) remains the recommended best practice.
