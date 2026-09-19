---
title: Cloud Storage & Google Drive Guide
tags:
  - icloud
  - google-drive
  - cloud-storage
  - macos
  - obsidian
created: 2026-08-24
---

# ☁️ Disabling iCloud & Using Google Drive Exclusively

You do **not** need to use Apple iCloud on macOS. You can completely disable iCloud sync and use **Google Drive for Desktop** as your primary cloud storage and file system sync engine.

---

## 🎯 The "Best of Both Worlds" Setup

You can keep all the beloved Apple ecosystem features (iMessage, FaceTime, Keychain, Find My, Handoff) while **strictly disabling iCloud file sync** so that **Google Drive** handles 100% of your documents, project files, and cloud storage.

```
┌─────────────────────────────────────────────────────────────┐
│              MODULAR ICLOUD TOGGLE MATRIX                   │
├──────────────────────────────┬──────────────────────────────┤
│   ✅ KEEP ENABLED (Apple)    │    🚫 DISABLE (Use Google)   │
├──────────────────────────────┼──────────────────────────────┤
│ • iMessage & FaceTime        │ • iCloud Drive               │
│ • iCloud Keychain & Passkeys │ • Desktop & Documents Sync   │
│ • Find My Mac                │ • iCloud Photos (optional)   │
│ • AirDrop & Universal Copy   │ • iCloud Backups of code     │
│ • Apple Notes / Reminders    │                              │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 🛑 Step 1: Disabling Only File Syncing in macOS

1. Open **System Settings** $\rightarrow$ Click your **Apple Account Name** at the top.
2. Click **iCloud**:
   * Click **iCloud Drive** $\rightarrow$ Toggle **"Sync this Mac"** to **OFF**.
   * Turn **Desktop & Documents Folders** $\rightarrow$ **OFF** *(This ensures macOS never uploads your code repositories or local files to Apple servers).*
3. **Leave everything else turned ON:**
   * **Messages in iCloud:** ON (keeps iMessage in sync with your iPhone).
   * **Passwords & Keychain:** ON (syncs Safari & app passwords/passkeys).
   * **Find My:** ON (laptop tracking and activation lock).
   * **Notes / Reminders / Calendar:** ON (if you use them on iOS).

> [!TIP]
> **Enforced Declaratively in `flake.nix`:**
> Our `flake.nix` includes `NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;` and `finder.FXICloudDriveDesktop = false;` to guarantee all applications and Finder default to local storage rather than iCloud!

---

## 📂 Step 2: Install Google Drive for Desktop via `nix-darwin`

Google Drive for Desktop is declared in your `templates/flake.nix` under `homebrew.casks`:

```nix
homebrew.casks = [
  "google-drive"
  "obsidian"
  "orbstack"
  "visual-studio-code"
  "ghostty"
  "appcleaner"
];
```

Or install manually via terminal:
```bash
brew install --cask google-drive
```

---

## ⚙️ Step 3: Google Drive Configuration & Modes

Launch **Google Drive.app** from `/Applications` and open **Google Drive Preferences**:

```
┌─────────────────────────────────────────────────────────────┐
│                   GOOGLE DRIVE SYNC MODES                   │
├──────────────────────────────┬──────────────────────────────┤
│    1. STREAM FILES (Default) │      2. MIRROR FILES         │
├──────────────────────────────┼──────────────────────────────┤
│ • Files live in the cloud    │ • All files stored locally   │
│ • Downloaded on-demand       │ • Available 100% offline     │
│ • Saves SSD storage space    │ • Uses local Mac SSD space   │
│ • Lives in Finder sidebar    │ • Lives in designated folder │
└──────────────────────────────┴──────────────────────────────┘
```

### Recommendation for Developers:
* Use **Stream files** as your global default to keep your Mac internal SSD clean and fast.
* For critical coding assets or your **Obsidian Vault**, right-click the folder in Finder $\rightarrow$ select **"Available offline"** so files are always instantly accessible without network latency.

---

## 📝 Best Practices: Running Obsidian on Google Drive

If you want your **Obsidian Vault** synced across machines using Google Drive:

1. **Location:** Place your Obsidian vault inside your Google Drive directory:
   `~/Google Drive/My Drive/Obsidian Vault/`
2. **Offline Pinning (Crucial):**
   * Right-click your `Obsidian Vault` folder in Finder.
   * Select **Google Drive $\rightarrow$ Available offline**.
   * *Why:* This ensures markdown notes are permanently stored on your SSD, preventing Obsidian from hanging while waiting for a remote file to download.
3. **Git Integration (Optional Alternative):**
   * If you prefer developer-style version control instead of cloud syncing, you can keep your Obsidian vault in a private GitHub repository using the `obsidian-git` community plugin.

---

## Related Notes
* [[Mac Cleanliness & Anti-Bloat Guide]]
* [[Setup Checklist]]
* [[Nix-Darwin Guide]]
* [[Index]]
