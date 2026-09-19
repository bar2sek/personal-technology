{
  description = "Mac AI Workstation - M5 Pro 48GB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, config, ... }: {
      # Allow unfree packages (e.g., claude-code)
      nixpkgs.config.allowUnfree = true;

      # ----------------------------------------------------------------------
      # 1. System Packages (Managed via Nix)
      # ----------------------------------------------------------------------
      environment.systemPackages = [
        pkgs.git
        pkgs.uv
        pkgs.ripgrep
        pkgs.fd
        pkgs.jq
        pkgs.just
        pkgs.htop
        pkgs.tree
        pkgs.eza
        pkgs.bat
        pkgs.zoxide
        pkgs.fzf
        pkgs.zsh-powerlevel10k
        pkgs.zsh-autosuggestions
        pkgs.zsh-syntax-highlighting

        # Cloud & Kubernetes Homelab Tooling
        pkgs.kubectl
        pkgs.talosctl
        pkgs.kubernetes-helm
        pkgs.k9s
        pkgs.ansible
        pkgs.sops
        pkgs.age
        pkgs.cilium-cli
        pkgs.stern
        pkgs.yamllint
        pkgs.tflint

        # Cloud Storage & Sync Tooling
        pkgs.rclone

        # Terminal AI Agents & Assistants
        pkgs.claude-code
      ];

      # Shell Aliases (Modern, Colorized with Nerd Font Icons)
      environment.shellAliases = {
        # Kubernetes & Homelab Shortcuts
        k = "kubectl";
        kc = "kubectl";
        k9 = "k9s";
        talos = "talosctl";
        tf = "terraform";
        ts = "tailscale";

        # Modern Eza Listing (Colors + File Icons + Git status)
        ls = "eza --icons --group-directories-first";
        ll = "eza -lah --icons --group-directories-first --git";
        la = "eza -a --icons --group-directories-first";
        l = "eza -lh --icons --group-directories-first";
        tree = "eza --tree --icons";

        # Modern Bat Syntax-Highlighted File Viewing
        cat = "bat --paging=never --style=plain";
        preview = "bat --style=numbers,changes,header";

        # Navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "~" = "cd ~";
        md = "mkdir -p";
        c = "clear";

        # Git Essentials
        g = "git";
        gs = "git status -sb";
        ga = "git add";
        gaa = "git add -A";
        gc = "git commit -m";
        gca = "git commit -am";
        gp = "git push";
        gpl = "git pull --rebase";
        gco = "git checkout";
        gb = "git branch";
        gd = "git diff";
        gl = "git log --oneline --graph --decorate -n 20";

        # System & Network
        reload = "exec zsh";
        flushdns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
        myip = "curl -s https://ipinfo.io/ip";
        localip = "ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1";
        agy-awake = "caffeinate -s";
      };

      # Zsh Shell with Powerlevel10k, Auto-suggestions, Zoxide & FZF
      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        promptInit = ''
          # Load uncommitted local secrets (API keys, private tokens)
          [[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

          if [ -x "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
          fi
          export PATH="$HOME/.local/bin:$PATH"
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
          eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
        '';
      };

      # ----------------------------------------------------------------------
      # 2. Homebrew Integration (Declarative Casks & Apps)
      # ----------------------------------------------------------------------
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "zap"; # Automatically deletes unlisted apps/casks
          upgrade = true;
        };

        taps = [
          "hashicorp/tap"
        ];

        # CLI Developer & Cloud Tools (Python managed purely via uv)
        brews = [
          "awscli"                   # AWS CLI
          "azure-cli"                 # Microsoft Azure CLI (az)
          "hashicorp/tap/terraform"   # HashiCorp Terraform CLI
          "node"                      # Node.js runtime & npm
        ];

        # GUI Applications
        casks = [
          # Browsers
          "brave-browser"
          "microsoft-edge"

          # Productivity, Notes & Keyboards
          "google-drive"
          "microsoft-onenote"
          "keymapp"
          "navigator"
          "obsidian"
          "appcleaner"

          # Developer, AI & Remote Access
          "antigravity-ide"
          "antigravity"
          "ghostty"
          "orbstack"
          "google-gemini"
          "tailscale-app"
          "moonlight"
        ];

        # Mac App Store Applications (Optional, requires numeric App ID)
        masApps = {
          # "Keynote" = 409183694;
        };
      };

      # ----------------------------------------------------------------------
      # 3. macOS System Defaults & UI Preferences
      # ----------------------------------------------------------------------
      system.defaults = {
        # Dock settings matching your exact preferences from screenshot
        dock = {
          # Size & Magnification (20% larger default size + max magnification on hover)
          tilesize = 44;
          magnification = true;
          largesize = 128;

          # Position & Animations
          orientation = "bottom";
          mineffect = "genie";
          minimize-to-application = true;
          autohide = true;
          launchanim = true;
          show-process-indicators = true;
          show-recents = true;

          # Ordered Dock Layout: Browsers (Left) -> Apple Core & OneNote (Middle) -> Developer (Right)
          persistent-apps = [
            # 1. Browsers (Farthest Left, immediately right of Finder)
            "/System/Cryptexes/App/System/Applications/Safari.app"
            "/Applications/Microsoft Edge.app"
            "/Applications/Brave Browser.app"

            # 2. Apple Core Productivity & OneNote (Middle)
            "/System/Applications/Messages.app"
            "/System/Applications/Mail.app"
            "/System/Applications/Maps.app"
            "/System/Applications/Photos.app"
            "/System/Applications/FaceTime.app"
            "/System/Applications/Calendar.app"
            "/System/Applications/Contacts.app"
            "/System/Applications/Reminders.app"
            "/System/Applications/Notes.app"
            "/Applications/Microsoft OneNote.app"

            # 3. Developer & AI Workstation Tools (Farthest Right)
            "/Applications/Gemini.app"
            "/Applications/Antigravity.app"
            "/Applications/Antigravity IDE.app"
            "/Applications/Ghostty.app"
            "/Applications/Obsidian.app"
            "/Applications/OrbStack.app"
          ];
        };

        # Finder settings & Developer ergonomics
        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXPreferredViewStyle = "Nlsv"; # List view
          _FXShowPosixPathInTitle = true;
          ShowPathbar = true;            # Breadcrumb path bar at bottom
          ShowStatusBar = true;          # Status bar with item count & free SSD space
          FXDefaultSearchScope = "SCcf"; # Search current folder by default (not entire Mac)
          FXEnableExtensionChangeWarning = false; # Disable extension change popup
        };

        # Trackpad settings
        trackpad = {
          Clicking = false;         # Disable tap to click (requires deliberate press)
          FirstClickThreshold = 2;  # Firm click pressure (0 = Light, 1 = Medium, 2 = Firm)
          SecondClickThreshold = 2; # Firm Force Click threshold
        };

        # Screenshot settings (Clean Documentation)
        screencapture = {
          location = "~/Pictures/Screenshots";
          type = "png";
          disable-shadow = true; # No massive drop shadows around window screenshots
          show-thumbnail = true; # Show floating preview thumbnail in bottom-right corner
        };

        # Control Center & Menu Bar
        controlcenter = {
          BatteryShowPercentage = true; # Always show battery percentage
        };

        # Global macOS preferences (Developer Typing Ergonomics)
        NSGlobalDomain = {
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
          "com.apple.swipescrolldirection" = true; # Natural scrolling
          AppleInterfaceStyle = "Dark";            # System-wide Dark Mode
          AppleInterfaceStyleSwitchesAutomatically = false; # Keep permanently Dark
          ApplePressAndHoldEnabled = false;        # Enable key repeating for vim/coding
          NSDocumentSaveNewDocumentsToCloud = false; # Save to local disk by default, NEVER iCloud

          # Disable smart typography (prevents terminal command corruption)
          NSAutomaticQuoteSubstitutionEnabled = false; # No curved "smart" quotes
          NSAutomaticDashSubstitutionEnabled = false;  # No em-dash conversion (keeps --flags intact)
          NSAutomaticCapitalizationEnabled = false;     # No auto-capitalization
          NSAutomaticSpellingCorrectionEnabled = false; # No auto-correct interference
        };

        # Custom system & browser preferences (Telemetry & Search Engines)
        CustomUserPreferences = {
          "NSGlobalDomain" = {
            AppleActionOnDoubleClick = "Maximize"; # Window title bar double-click: Zoom/Maximize
          };
          "com.apple.finder" = {
            FXICloudDriveDesktop = false;   # Never sync Desktop to iCloud
            FXICloudDriveDocuments = false; # Never sync Documents to iCloud
          };
          # Network & USB Hygiene (Avoid .DS_Store clutter)
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          # Desktop & Stage Manager (from screenshot)
          "com.apple.WindowManager" = {
            EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop: Only in Stage Manager (disables clearing windows)
            HideDesktop = true;                      # Show items on Desktop: OFF
            StageManagerHideWidgets = true;          # Show items in Stage Manager: OFF
            GloballyEnabled = false;                 # Stage Manager: OFF
            AppWindowGroupingBehavior = 1;           # Show windows from an app: All at Once
          };

          # Brave Browser (Zero Telemetry + Google Default Search)
          "com.brave.Browser" = {
            BraveRewardsP3AEnabled = false;          # Disable P3A product analytics
            BraveStatsPing = false;                  # Disable stats ping
            MetricsReportingEnabled = false;         # Disable metrics reporting
            DefaultSearchProviderEnabled = true;
            DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
            DefaultSearchProviderName = "Google";
          };

          # Microsoft Edge (Zero Telemetry + Google Default Search)
          "com.microsoft.Edge" = {
            MetricsReportingEnabled = false;         # Disable diagnostic telemetry
            SendSiteInfoToImproveServices = false;   # Disable site reporting
            PersonalizationReportingEnabled = false; # Disable personalized tracking
            DiagnosticData = 0;                      # Turn off optional diagnostics
            DefaultSearchProviderEnabled = true;
            DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
            DefaultSearchProviderName = "Google";
          };

          # System Crash & Ad Tracking Suppression
          "com.apple.CrashReporter" = {
            DialogType = "none";
          };
          "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
          };
        };
      };

      # ----------------------------------------------------------------------
      # 4. Networking & Firewall
      # ----------------------------------------------------------------------
      networking.applicationFirewall = {
        enable = true;
        allowSigned = true;
        enableStealthMode = true;
      };

      # ----------------------------------------------------------------------
      # 5. Keyboard Remapping
      # ----------------------------------------------------------------------
      system.keyboard.enableKeyMapping = false;
      system.keyboard.remapCapsLockToEscape = false;

      # ----------------------------------------------------------------------
      # 6. Declarative Fonts (Nerd Fonts for VS Code & Ghostty)
      # ----------------------------------------------------------------------
      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      # ----------------------------------------------------------------------
      # 7. Core Nix & User Settings
      # ----------------------------------------------------------------------
      system.primaryUser = "ryan.bartusek";
      nix.enable = false; # Disable nix-darwin management of Nix to allow Determinate Nix daemon
      system.stateVersion = 5;
      nixpkgs.hostPlatform = "aarch64-darwin";

      # ----------------------------------------------------------------------
      # 8. Automated App Configs & System Fluff Purge
      # ----------------------------------------------------------------------
      system.activationScripts.postActivation.text = ''
        PRIMARY_USER="${config.system.primaryUser}"
        USER_HOME="/Users/$PRIMARY_USER"

        echo "--> Purging removable Apple bloatware & heavy audio libraries..."
        rm -rf /Applications/GarageBand.app 2>/dev/null || true
        rm -rf /Applications/iMovie.app 2>/dev/null || true
        rm -rf "/Library/Application Support/GarageBand" 2>/dev/null || true
        rm -rf "/Library/Application Support/Logic" 2>/dev/null || true
        rm -rf "/Library/Audio/Apple Loops" 2>/dev/null || true

        echo "--> Purging diagnostic logs, crash reports, and local APFS snapshots..."
        rm -rf "$USER_HOME/Library/Logs/DiagnosticReports"/* 2>/dev/null || true
        tmutil thinlocalsnapshots / 9999999999 4 2>/dev/null || true

        # Ensure Screenshots folder exists
        mkdir -p "$USER_HOME/Pictures/Screenshots"
        chown -R "$PRIMARY_USER" "$USER_HOME/Pictures/Screenshots" 2>/dev/null || true

        # Reset any hardware modifier key remappings (ensures Caps Lock behaves normally)
        hidutil property --set '{"UserKeyMapping":[]}' > /dev/null 2>&1 || true

        # Declarative per-device modifier swap for ZSA Voyager (VendorID 12951, ProductID 6519)
        # Swaps Control and Command ONLY for the Voyager; built-in MacBook keyboard remains untouched.
        echo "--> Applying ZSA Voyager modifier key mapping (Ctrl <-> Cmd)..."
        sudo -u "$PRIMARY_USER" defaults -currentHost write -g "com.apple.keyboard.modifiermapping.12951-6519-0" -array \
          '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771299</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771296</integer></dict>' \
          '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771296</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771299</integer></dict>' \
          '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771303</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771300</integer></dict>' \
          '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771300</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771303</integer></dict>'

        # Ensure ~/.local/bin exists and symlink Tailscale CLI from Tailscale.app
        mkdir -p "$USER_HOME/.local/bin"
        if [ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
          ln -sf "/Applications/Tailscale.app/Contents/MacOS/Tailscale" "$USER_HOME/.local/bin/tailscale"
          chown -h "$PRIMARY_USER" "$USER_HOME/.local/bin/tailscale" 2>/dev/null || true
        fi

        # Symlink oMLX CLI from oMLX.app and register login item
        if [ -f "/Applications/oMLX.app/Contents/MacOS/omlx-cli" ]; then
          ln -sf "/Applications/oMLX.app/Contents/MacOS/omlx-cli" "$USER_HOME/.local/bin/omlx"
          chown -h "$PRIMARY_USER" "$USER_HOME/.local/bin/omlx" 2>/dev/null || true
          sudo -u "$PRIMARY_USER" osascript -e 'tell application "System Events" to if not (exists login item "oMLX") then make login item at end with properties {path:"/Applications/oMLX.app", hidden:true, name:"oMLX"}' 2>/dev/null || true
        fi

        echo "--> Deploying declarative Antigravity IDE & Local AI configuration..."
        mkdir -p "$USER_HOME/.continue"
        cat << 'EOF' > "$USER_HOME/.continue/config.json"
{
  "models": [
    {
      "title": "Local Qwen 32B (oMLX)",
      "provider": "openai",
      "model": "mlx-community--Qwen2.5-Coder-32B-Instruct-8bit",
      "apiBase": "http://localhost:8080/v1"
    }
  ],
  "allowAnonymousTelemetry": false
}
EOF
        chown -R "$PRIMARY_USER" "$USER_HOME/.continue"

        # Declarative Roo Code multi-model profiles (Claude Sonnet 4.6 + Local Qwen 32B + Claude Opus 5)
        mkdir -p "$USER_HOME/.config/roo-code"
        cat << 'EOF' > "$USER_HOME/.config/roo-code/settings.json"
{
  "providerProfiles": {
    "currentApiConfigName": "Claude Sonnet 4.6",
    "apiConfigs": {
      "Claude Sonnet 4.6": {
        "id": "claude-sonnet-4-6",
        "apiProvider": "anthropic",
        "apiKey": "",
        "apiModelId": "claude-sonnet-4-6"
      },
      "Local Qwen 2.5 Coder 32B": {
        "id": "local-qwen-32b",
        "apiProvider": "openai",
        "openAiBaseUrl": "http://localhost:8080/v1",
        "openAiApiKey": "local",
        "openAiModelId": "mlx-community--Qwen2.5-Coder-32B-Instruct-6bit"
      },
      "Claude Opus 5": {
        "id": "claude-opus-5",
        "apiProvider": "anthropic",
        "apiKey": "",
        "apiModelId": "claude-opus-5"
      }
    }
  },
  "globalSettings": {}
}
EOF
        chown -R "$PRIMARY_USER" "$USER_HOME/.config/roo-code"

        # Apply settings to both Antigravity IDE and Code OSS
        for settings_dir in \
          "$USER_HOME/Library/Application Support/Antigravity/User" \
          "$USER_HOME/Library/Application Support/Antigravity IDE/User" \
          "$USER_HOME/Library/Application Support/Code/User"; do
          mkdir -p "$settings_dir"
          cat << 'EOF' > "$settings_dir/settings.json"
{
  "editor.fontFamily": "'JetBrainsMono Nerd Font', Menlo, Monaco, 'Courier New', monospace",
  "editor.fontSize": 14,
  "editor.fontLigatures": true,
  "editor.lineNumbers": "on",
  "editor.minimap.enabled": true,
  "editor.formatOnSave": true,
  "workbench.colorTheme": "Tokyo Night",
  "workbench.iconTheme": "material-icon-theme",
  "telemetry.telemetryLevel": "off",
  "update.mode": "default",
  "git.enableSmartCommit": false,
  "git.confirmSync": false,
  "git.autorefresh": true,
  "git.repositoryScanMaxDepth": 2,
  "roo-cline.autoImportSettingsPath": "~/Library/Application Support/Antigravity IDE/User/globalStorage/rooveterinaryinc.roo-cline/settings/roo-settings.json",
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/.direnv/**": true,
    "**/.trash/**": true,
    "**/.obsidian/cache/**": true
  }
}
EOF
          chown -R "$PRIMARY_USER" "$settings_dir"
        done

        echo "--> Installing declarative Antigravity IDE & editor extensions..."
        for ide_bin in \
          "/opt/homebrew/bin/antigravity-ide" \
          "/opt/homebrew/bin/agy-ide" \
          "/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide" \
          "/opt/homebrew/bin/code"; do
          if [ -x "$ide_bin" ]; then
            for ext in \
              "RooVeterinaryInc.roo-cline" \
              "enkia.tokyo-night" \
              "PKief.material-icon-theme" \
              "jnoortheen.nix-ide" \
              "hashicorp.terraform" \
              "amazonwebservices.aws-toolkit-vscode" \
              "ms-vscode.azure-account" \
              "ms-azuretools.vscode-azureresourcegroups" \
              "ms-azuretools.vscode-docker" \
              "ms-kubernetes-tools.vscode-kubernetes-tools"; do
              sudo -H -u "$PRIMARY_USER" env HOME="$USER_HOME" "$ide_bin" --install-extension "$ext" --force 2>/dev/null || true
            done
          fi
        done

        echo "--> Deploying declarative Ghostty configuration..."
        mkdir -p "$USER_HOME/.config/ghostty"
        cat << 'EOF' > "$USER_HOME/.config/ghostty/config"
# Font & Typography
font-family = "JetBrainsMono Nerd Font"
font-size = 14
font-feature = ["calt", "liga"]

# Theme & Appearance
theme = "tokyonight"
background-opacity = 0.95
background-blur-radius = 20
macos-titlebar-style = "tabs"

# Performance & Cursor
cursor-style = "block"
cursor-style-blink = false
macos-option-as-alt = true
EOF
        chown -R "$PRIMARY_USER" "$USER_HOME/.config/ghostty"

        # Ensure ~/.p10k.zsh is owned by the user
        [ ! -f "$USER_HOME/.p10k.zsh" ] || chown "$PRIMARY_USER" "$USER_HOME/.p10k.zsh"

        # Declarative Network Printer: Brother DCP-7065DN via Homelab CUPS Bridge
        echo "--> Configuring declarative network printer (Brother DCP-7065DN)..."
        lpadmin -p "Brother_DCP_7065DN" \
          -D "Brother DCP-7065DN" \
          -L "Homelab Rack" \
          -E \
          -v "ipp://printing.bar2sek.com:631/printers/Brother_DCP-7065DN" \
          -m everywhere 2>/dev/null || true
        lpoptions -d "Brother_DCP_7065DN" 2>/dev/null || true

        # Refresh macOS Dock and live Dark Mode appearance immediately
        sudo -u "$PRIMARY_USER" osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true
        killall Dock 2>/dev/null || true
      '';
    };
  in
  {
    darwinConfigurations = {
      "MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
      "default" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
  };
}
