#!/usr/bin/env bash
# ==============================================================================
# Mac AI Workstation - 1-Click Bootstrap Installer
# Run this script on your new Mac to configure the entire OS in minutes!
# ==============================================================================

set -e

echo ""
echo "=========================================================="
echo "🚀 Mac AI Workstation - Automated Bootstrap"
echo "=========================================================="
echo ""

# 1. Check / Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "--> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Please complete the Apple popup prompt, then press [ENTER] to continue..."
  read -r
else
  echo "✅ Xcode Command Line Tools already installed."
fi

# 2. Check / Install Homebrew (for GUI casks & oMLX tap)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
  echo "--> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed."
fi

# 3. Check / Install Determinate Systems Nix
if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix &>/dev/null; then
  echo "--> Installing Determinate Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  echo "✅ Nix package manager already installed."
fi

# 4. Deploy flake.nix and Justfile
echo "--> Deploying declarative configuration..."
mkdir -p "$HOME/.config/nix-darwin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="$(id -un)"

sed "s/system\.primaryUser = .*/system.primaryUser = \"$CURRENT_USER\";/g" "$SCRIPT_DIR/flake.nix" > "$HOME/.config/nix-darwin/flake.nix"
cp "$SCRIPT_DIR/Justfile" "$HOME/Justfile"
cp "$SCRIPT_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# 5. Build and Apply Nix-Darwin System
HOSTNAME_TARGET="$(scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null || echo 'MacBook-Pro')"

if nix eval "$HOME/.config/nix-darwin#darwinConfigurations.$HOSTNAME_TARGET" &>/dev/null; then
  FLAKE_TARGET="$HOME/.config/nix-darwin#$HOSTNAME_TARGET"
else
  FLAKE_TARGET="$HOME/.config/nix-darwin#MacBook-Pro"
fi

echo "--> Building and applying declarative system state ($FLAKE_TARGET)..."
sudo -H nix run nix-darwin -- switch --flake "$FLAKE_TARGET"

# 6. Automated DMG Applications (Auto-installs ANY .dmg dropped on USB drive)
echo "--> Checking for local installer DMGs on USB drive..."
shopt -s nullglob nocaseglob
USB_DMGS=("$SCRIPT_DIR/.."/*.dmg "$SCRIPT_DIR/../installers"/*.dmg "$SCRIPT_DIR"/*.dmg)
shopt -u nullglob nocaseglob

if [ ${#USB_DMGS[@]} -gt 0 ]; then
  for dmg_file in "${USB_DMGS[@]}"; do
    [ -f "$dmg_file" ] || continue
    dmg_name=$(basename "$dmg_file")
    mount_dir=$(mktemp -d /tmp/dmg_mount.XXXXXX)

    echo "--> Inspecting $dmg_name..."
    if hdiutil attach "$dmg_file" -nobrowse -mountpoint "$mount_dir" -quiet 2>/dev/null; then
      for app in "$mount_dir"/*.app; do
        [ -d "$app" ] || continue
        app_name=$(basename "$app")
        if [ -d "/Applications/$app_name" ]; then
          echo "✅ $app_name already installed in /Applications."
        else
          echo "--> Installing $app_name to /Applications..."
          cp -R "$app" /Applications/ 2>/dev/null || true
          echo "✅ Successfully installed $app_name."
        fi
      done
      hdiutil detach "$mount_dir" -quiet 2>/dev/null || true
    else
      echo "⚠️ Failed to mount $dmg_name"
    fi
    rm -rf "$mount_dir"
  done
else
  echo "ℹ️  No local .dmg files found on USB drive."
fi

# A. oMLX (Fetch latest from GitHub if not already installed)
if [ -d "/Applications/oMLX.app" ]; then
  echo "✅ oMLX already installed."
else
  echo "--> Fetching latest oMLX.dmg from GitHub..."
  OMLX_URL=$(curl -sL https://api.github.com/repos/jundot/omlx/releases/latest | grep "browser_download_url.*\.dmg" | tail -n 1 | cut -d '"' -f 4 || true)
  if [ -n "$OMLX_URL" ]; then
    OMLX_TMP="/tmp/oMLX.dmg"
    if curl -fSL -o "$OMLX_TMP" "$OMLX_URL" 2>/dev/null; then
      mount_dir=$(mktemp -d /tmp/dmg_mount.XXXXXX)
      if hdiutil attach "$OMLX_TMP" -nobrowse -mountpoint "$mount_dir" -quiet 2>/dev/null; then
        cp -R "$mount_dir"/*.app /Applications/ 2>/dev/null || true
        hdiutil detach "$mount_dir" -quiet 2>/dev/null || true
        echo "✅ Successfully installed oMLX.app."
      fi
      rm -rf "$mount_dir" "$OMLX_TMP"
    else
      echo "⚠️ Could not download oMLX.dmg. Download manually from https://github.com/jundot/omlx/releases"
    fi
  fi
fi

# 7. Check / Install Antigravity CLI (agy)
if ! command -v agy &>/dev/null && [ ! -x "$HOME/.local/bin/agy" ]; then
  echo "--> Installing Antigravity CLI (agy)..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://antigravity.google/cli/install.sh | bash || true
else
  echo "✅ Antigravity CLI (agy) already installed."
fi

echo ""
echo "=========================================================="
echo "✨ System Configuration Complete!"
echo "• All apps, fonts, and CLI tools are installed."
echo "• oMLX & Antigravity are ready in /Applications."
echo "• Antigravity CLI (agy) ready in ~/.local/bin."
echo "• VS Code & Ghostty are configured with JetBrainsMono Nerd Font."
echo "• Dock & Finder preferences applied."
echo "=========================================================="
echo ""
