{ pkgs, config, inputs, ... }: {
  # Allow unfree packages (e.g., claude-code, VS Code marketplace extensions)
  nixpkgs.config.allowUnfree = true;
  # Adds pkgs.vscode-marketplace* (all marketplace extensions) to pkgs
  nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

  # ----------------------------------------------------------------------
  # 1. Machine-Level System Packages
  # ----------------------------------------------------------------------
  # Only foundational tools needed at the machine/root level live here.
  # Developer CLIs, homelab tools, and shell utilities live in home.nix.
  environment.systemPackages = [
    pkgs.git
    pkgs.just
  ];

  # Terraform provider binaries are shared across every root and repo from one
  # cache outside the Google Drive–synced vault. Per-root .terraform data dirs
  # are moved out of the vault by each repo's Justfile (TF_DATA_DIR).
  environment.variables.TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";

  # Zsh: the system layer only hooks Nix into /etc/zshenv (PATH, fpath for
  # system completions). Prompt, plugins, aliases and compinit live in
  # home.nix so nothing loads twice.
  programs.zsh = {
    enable = true;
    enableCompletion = false; # home-manager runs compinit once, in ~/.zshrc
    promptInit = "";          # No system prompt; Powerlevel10k is set per user
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
      "aws-cdk"                  # AWS Cloud Development Kit CLI (cdk)
      "azure-cli"                # Microsoft Azure CLI (az)
      "hashicorp/tap/terraform"  # HashiCorp Terraform CLI
      "node"                     # Node.js runtime & npm
      "typescript"               # TypeScript compiler & CLI (tsc)
    ];

    # GUI Applications
    casks = [
      # Browsers
      "brave-browser"
      "google-chrome"
      "microsoft-edge"

      # Productivity, Notes & Keyboards
      "google-drive"
      "microsoft-onenote"
      "microsoft-teams"
      "keymapp"
      "navigator"
      "obsidian"
      "appcleaner"

      # Media & Entertainment
      "spotify"

      # 3D Printing & Digital Fabrication
      "bambu-studio"

      # Developer, AI & Remote Access
      "antigravity"
      "claude"
      "ghostty"
      "orbstack"
      "tailscale-app"
      "moonlight"
      "tigervnc" # KubeVirt VM consoles (virtctl vnc); macOS Screen Sharing rejects passwordless VNC
      "visual-studio-code"
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
      # Size & Magnification (compact 36px icon size + max magnification on hover)
      tilesize = 36;
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
        "/Applications/Google Chrome.app"
        "/Applications/Microsoft Edge.app"
        "/Applications/Brave Browser.app"

        # 2. Apple Core Productivity, Google Photos, OneNote & Music (Middle)
        "/System/Applications/Messages.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Maps.app"
        "/Users/${config.system.primaryUser}/Applications/Chrome Apps.localized/Google Photos.app"
        "/System/Applications/FaceTime.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Contacts.app"
        "/System/Applications/Reminders.app"
        "/System/Applications/Notes.app"
        "/Applications/Microsoft OneNote.app"
        "/Applications/Spotify.app"

        # 3. 3D Fabrication, AI & Developer Tools (Farthest Right)
        "/Applications/BambuStudio.app"
        "/Applications/Claude.app"
        "/Applications/Antigravity.app"
        "/Applications/Visual Studio Code.app"
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
  # 8. Machine-Level Hardware & Daemon Activation
  # ----------------------------------------------------------------------
  # Heavy disk housekeeping (GarageBand/iMovie purge, APFS snapshot thinning)
  # lives in `just debloat` / `just prune-all` so everyday `just switch` runs stay fast.
  # User-scope files and CLI symlinks (Tailscale, Justfile, dotfiles) live in home.nix.
  system.activationScripts.postActivation.text = ''
    PRIMARY_USER="${config.system.primaryUser}"
    USER_HOME="/Users/$PRIMARY_USER"

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

    # Declarative Network Printer: Brother DCP-7065DN via Homelab CUPS Bridge
    echo "--> Configuring declarative network printer (Brother DCP-7065DN)..."
    lpadmin -p "Brother_DCP_7065DN" \
      -D "Brother DCP-7065DN" \
      -L "Homelab Rack" \
      -E \
      -v "ipp://printing.bar2sek.com:631/printers/Brother_DCP-7065DN" \
      -m everywhere 2>/dev/null || true
    lpoptions -d "Brother_DCP_7065DN" 2>/dev/null || true

    # Refresh live Dark Mode appearance immediately (nix-darwin's built-in
    # userDefaults activation already restarts Dock; avoid a second killall Dock
    # after brew bundle which can race with Mission Control and lock a 56px strut).
    sudo -u "$PRIMARY_USER" osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true
  '';

  # ----------------------------------------------------------------------
  # 9. Home Manager Wiring (User Scope -> home.nix)
  # ----------------------------------------------------------------------
  users.users.${config.system.primaryUser}.home = "/Users/${config.system.primaryUser}";

  home-manager = {
    useGlobalPkgs = true;   # Same nixpkgs (and allowUnfree + overlays) as the system
    useUserPackages = true; # User packages land in /etc/profiles/per-user/<user>
    # An unmanaged file in the way is renamed to *.hm-backup instead of failing the switch.
    backupFileExtension = "hm-backup";

    users.${config.system.primaryUser} = import ./home.nix;
  };
}
