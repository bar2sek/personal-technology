---
title: Nix-Darwin Guide
tags:
  - nix
  - nix-darwin
  - declarative
  - automation
  - macos
created: 2026-08-24
---

# ❄️ The Agent-First `nix-darwin` Workflow

## The Big Idea
`nix-darwin` replaces disparate dotfiles, shell scripts, and manual Homebrew management with **a single source of truth** (`flake.nix`) that configures your entire Mac from the kernel parameters down to your GUI applications.

---

## 🤖 Why Nix + AI Agents is a Match Made in Heaven

Nix has historically had a reputation for having a steep learning curve because of its functional syntax and massive option tree. However, **AI coding agents excel at Nix**:

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. You express intent in plain English:                          │
│    "Add Ghostty and OrbStack, hide the dock, and map             │
│     CapsLock to Escape."                                         │
│                              │                                   │
│ 2. AI Agent edits `~/.config/nix-darwin/flake.nix`               │
│                              │                                   │
│ 3. Run: `sudo darwin-rebuild switch --flake ~/.config/nix-darwin`│
│                              │                                   │
│ 4. Entire Mac state updates atomically                           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 How Much Daily Interaction Will You Have?

| Scenario | What You Do | What Nix Does |
| :--- | :--- | :--- |
| **Daily Coding & LLMs** | **Zero interaction.** You just use your terminal, MLX, IDE, and `uv`. | Runs silently in the background. |
| **Installing a New App** | Ask your AI agent to add it to `flake.nix`. | Pulls binary or triggers Homebrew cask automatically. |
| **Changing macOS Setting** | Ask your AI agent to update `system.defaults`. | Re-links macOS plist files and restarts Dock/Finder. |
| **Getting a New Mac** | Clone your repo and run one command. | 100% of your machine is reconstructed identically. |

---

## 📄 Complete Example: `flake.nix` for M5 Pro

Here is what a complete, all-in-one `flake.nix` looks like:

```nix
{
  description = "M5 Pro Mac AI Workstation Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # 1. Nix CLI Packages
      environment.systemPackages = [
        pkgs.git
        pkgs.uv
        pkgs.ripgrep
        pkgs.fd
        pkgs.jq
        pkgs.just
        pkgs.htop
      ];

      # 2. Homebrew Management (Managed Declaratively via Nix!)
      homebrew = {
        enable = true;
        onActivation.cleanup = "zap"; # Automatically deletes unlisted apps!
        casks = [
          "obsidian"
          "orbstack"
          "appcleaner"
          "cursor"
          "ghostty"
        ];
        masApps = {
          "Keynote" = 409183694;
        };
      };

      # 3. macOS System Preferences as Code
      system.defaults = {
        dock = {
          autohide = true;
          autohide-delay = 0.0;
          autohide-time-modifier = 0.15;
          show-recents = false;
          tilesize = 48;
        };
        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXPreferredViewStyle = "Nlsv"; # List view
        };
        trackpad = {
          Clicking = true; # Tap to click
        };
        NSGlobalDomain = {
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
          "com.apple.swipescrolldirection" = true; # Natural scrolling
        };
      };

      # 4. Keyboard Remapping (e.g. Caps Lock -> Escape)
      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToEscape = true;

      # 5. Nix & System User Configuration
      system.primaryUser = "yourusername"; # Replace with your macOS username (e.g. $(id -un))
      nix.enable = false;                  # Disable nix-darwin daemon management when using Determinate Nix
      system.stateVersion = 5;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
```

---

## 🛠️ Step-by-Step Installation on a New Mac

### 1. Install Nix via Determinate Systems (Official Recommended Installer)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Initialize `nix-darwin`
```bash
mkdir -p ~/.config/nix-darwin
cd ~/.config/nix-darwin
nix flake init -t nix-darwin
```

### 3. Apply Configuration
```bash
sudo nix run nix-darwin -- switch --flake ~/.config/nix-darwin
```

---

## 🧹 Maintenance & Housekeeping
Because Nix keeps old generations for instant rollback capability, run this once a month to reclaim disk space:

```bash
# Delete older generations and clean the Nix store
nix-collect-garbage -d
```

---

## Related Notes
* [[Declarative macOS Setup]]
* [[Mac Cleanliness & Anti-Bloat Guide]]
* [[Setup Checklist]]
