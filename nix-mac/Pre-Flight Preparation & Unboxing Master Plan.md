---
title: Pre-Flight Preparation & Unboxing Master Plan
tags:
  - preflight
  - unboxing
  - master-plan
  - checklist
  - automation
  - macos
created: 2026-08-30
---

# 🚀 Pre-Flight Preparation & Unboxing Master Plan

This master plan ensures **zero fiddling** when your new M5 Pro MacBook Pro arrives. Everything has been pre-configured and automated into a single 1-click bootstrap pipeline.

---

## 📦 1. Pre-Flight Checklist (What to Have Ready TODAY)

Before the delivery truck arrives, ensure you have:

### A. Physical Protection Kit Ready
- [ ] **Barekey Key Decals** & fine-point curved tweezers (see [[Hardware Protection & Keyboard Care]])
- [ ] **70% Isopropyl Alcohol** & lint-free microfiber wipes
- [ ] **UPPERCASE GhostBlanket** buffer cloth
- [ ] Blue painter’s tape (for dust lifting)

### B. Account & Setup Prerequisites
- [ ] **iPhone / 2FA Device nearby** for Apple ID & Google authentication
- [ ] **Google Drive Credentials** ready (for your main cloud files & Obsidian vault)
- [ ] **This `Mac AI Workstation` Folder Accessible:** 
  * Keep this folder synced on Google Drive, or push it to a private GitHub repository so you can download it on your new Mac in 5 seconds.

---

## ⏱️ 2. The 15-Minute "Zero-Fiddle" Unboxing Flowchart

```
┌─────────────────────────────────────────────────────────────┐
│ 1. UNBOX & APPLY PHYSICAL PROTECTION (10 mins)              │
│    • Clean keys with 70% IPA & dust tape                    │
│    • Apply Barekey decals with curved tweezers              │
│                              │                              │
│ 2. MACOS OUT-OF-BOX SETUP ASSISTANT (2 mins)                │
│    • Enable FileVault disk encryption                       │
│    • Sign in to Apple ID for iMessage/Keychain              │
│    • ⚠️ UNCHECK "Store files in iCloud Drive" checkbox      │
│                              │                              │
│ 3. RUN 1-CLICK BOOTSTRAP SCRIPT (3 mins)                    │
│    • Open Terminal & run: `bash templates/bootstrap.sh`     │
│    • Nix-Darwin installs all tools, apps, fonts & configs   │
│                              │                              │
│ 4. INSTALL oMLX & LAUNCH QWEN (2 mins)                      │
│    • Download `oMLX.dmg` & drag to Applications             │
│    • Run: `just serve-omlx-32b`                             │
│                              │                              │
│ 5. START CODING IN ZED & ANTIGRAVITY 🎉                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ 3. What the 1-Click Bootstrap Script Does for You

Located in `templates/bootstrap.sh`, this script executes the entire workstation setup sequentially:

1. **Xcode Command Line Tools:** Installs `clang`, `git`, `make` without the 30GB Xcode bloat.
2. **Homebrew:** Installs Homebrew and sets up shell paths.
3. **Determinate Nix:** Installs the modern, reliable Nix package manager daemon.
4. **Nix-Darwin System Build:**
   * Installs **Brave Browser, Microsoft Edge, Google Drive, Microsoft OneNote, Keymapp, Obsidian, AppCleaner, Visual Studio Code, Ghostty, OrbStack, and oMLX**.
   * Installs **JetBrainsMono Nerd Font** system-wide.
   * **Auto-writes `~/.config/ghostty/config`** with matching fonts, ligatures, and Tokyo Night theme.
   * **Organizes the Dock in your custom 3-section order**:
     * 🌐 **Left (Browsers):** Safari $\rightarrow$ Microsoft Edge $\rightarrow$ Brave Browser
     * 💬 **Middle (Apple Core & OneNote):** Messages $\rightarrow$ Mail $\rightarrow$ Maps $\rightarrow$ Photos $\rightarrow$ FaceTime $\rightarrow$ Calendar $\rightarrow$ Contacts $\rightarrow$ Reminders $\rightarrow$ Notes $\rightarrow$ Microsoft OneNote
     * 💻 **Right (Developer & AI):** Gemini $\rightarrow$ Antigravity $\rightarrow$ Ghostty $\rightarrow$ Visual Studio Code $\rightarrow$ Obsidian $\rightarrow$ OrbStack
   * Enforces local file saving defaults (disables iCloud file routing).
   * Automatically purges GarageBand, iMovie, and sound libraries to reclaim **~5–8 GB**.

---

## 🏃 4. The 3 Terminal Commands on Your New Mac

When you open your new Mac, all you need to do is open the default Terminal and run:

```bash
# 1. Download / clone your workstation setup folder
cd ~/Downloads
# (Or open your synced Google Drive folder)

# 2. Run the 1-click bootstrap installer
bash "Mac AI Workstation/templates/bootstrap.sh"

# 3. Launch your local 32B Qwen MLX server
just serve-omlx-32b
```

---

## 🎯 5. Post-Setup Verification (Day 1)

After running the bootstrap script:
- [ ] Open **Visual Studio Code** $\rightarrow$ Verify Continue.dev extension, theme, and keybindings.
- [ ] Open **Ghostty** $\rightarrow$ Verify crisp JetBrains Mono Nerd Font typography.
- [ ] Open **OrbStack** $\rightarrow$ Test container engine with `docker run --rm hello-world`.
- [ ] Open **Google Drive** $\rightarrow$ Set Obsidian Vault folder to **"Available offline"**.
- [ ] Open **Antigravity** $\rightarrow$ Test high-level agentic pairing on your projects.

---

## Related Notes
* [[Setup Checklist]]
* [[Hardware Protection & Keyboard Care]]
* [[Nix-Darwin Guide]]
* [[IDE Configuration Guide]]
* [[Local LLMs with MLX]]
* [[Cloud Storage & Google Drive Guide]]
