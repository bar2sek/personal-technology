{ pkgs, config, ... }: {
  home.stateVersion = "26.11"; # Set once at adoption; never bump casually

  # ----------------------------------------------------------------------
  # 1. User-Scope Packages
  # ----------------------------------------------------------------------
  # Tools with dedicated `programs.<name>` blocks below (git, gh, fzf, eza,
  # bat, zoxide, direnv) are installed automatically by their module.
  home.packages = [
    # Core CLI & Python Tooling
    pkgs.uv
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.htop
    pkgs.tree
    pkgs.nixfmt

    # Zsh Theme (autosuggestions & syntax-highlighting are pulled in by programs.zsh)
    pkgs.zsh-powerlevel10k

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

    # Terminal AI Agents & Cloud Identity Federation
    pkgs.claude-code
    pkgs.granted
  ];

  # ----------------------------------------------------------------------
  # 2. Session Environment & Out-of-Store Links
  # ----------------------------------------------------------------------
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.omlx/bin"
  ];

  home.sessionVariables = {
    TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
  };

  # Declarative symlink to the Tailscale CLI bundled inside the Homebrew cask app
  home.file.".local/bin/tailscale".source =
    config.lib.file.mkOutOfStoreSymlink "/Applications/Tailscale.app/Contents/MacOS/Tailscale";

  # Home-directory command runner: `~/Justfile` is owned by home-manager so it never drifts
  home.file."Justfile".source = ./Justfile;

  # Powerlevel10k layout. `p10k configure` cannot write this read-only link:
  # run it, then copy its output over templates/p10k.zsh and `just switch`.
  home.file.".p10k.zsh".source = ./p10k.zsh;

  # ----------------------------------------------------------------------
  # 3. Git, GitHub CLI & SSH Configuration
  # ----------------------------------------------------------------------
  # Writes ~/.config/git/config, which both Apple's /usr/bin/git and the Nix git read.
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ryan Bartusek";
      user.email = "bar2sek@users.noreply.github.com"; # GitHub noreply; never a personal address
      credential.helper = "osxkeychain";
      # Drop origin/* refs for branches deleted on GitHub (e.g. after a PR merges),
      # so a merged branch shows "upstream gone" instead of looking pushable.
      fetch.prune = true;
    };
  };

  # Writes ~/.config/gh/config.yml while leaving ~/.config/gh/hosts.yml (auth state) untouched.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };

  # Writes ~/.ssh/config while leaving ~/.ssh/id_ed25519* and known_hosts untouched.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # OrbStack Linux VM SSH integration (must appear at top of ~/.ssh/config before Host blocks)
    includes = [
      "~/.orbstack/ssh/config"
    ];
    settings."*" = {
      IdentityFile = "~/.ssh/id_ed25519";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
    };
  };

  # ----------------------------------------------------------------------
  # 4. Modern CLI & Shell Integrations (Zsh, fzf, eza, bat, zoxide, direnv)
  # ----------------------------------------------------------------------
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Enables Ctrl+R history search and Ctrl+T file picker
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = false; # Custom aliases defined in programs.zsh.shellAliases below
    icons = "auto";
    git = true;
  };

  programs.bat = {
    enable = true;
  };

  # Smarter cd (`z <dir>`); home-manager adds the init line to ~/.zshrc
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Per-project environment loader (.envrc); Determinate Nix manages the Nix daemon
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = false;
  };

  # Zsh: home-manager writes ~/.zshenv, ~/.zprofile and ~/.zshrc.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Login shells only (runs before ~/.zshrc)
    profileExtra = ''
      # OrbStack: docker/orb CLIs and shell integration
      source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initContent = ''
      # Load uncommitted local secrets (API keys, private tokens). Never in Nix.
      [[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

      if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      export PATH="$HOME/.local/bin:$HOME/.omlx/bin:$PATH"

      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';

    # Shell Aliases (Modern, Colorized with Nerd Font Icons)
    shellAliases = {
      # Kubernetes & Homelab Shortcuts
      k = "kubectl";
      kc = "kubectl";
      k9 = "k9s";
      talos = "talosctl";
      tf = "terraform";
      # Terraform can't read `aws login` sessions, so it uses the
      # [profile terraform] in ~/.aws/config, whose credential_process
      # fetches fresh credentials on every run. Scoped to terraform only:
      # a global AWS_PROFILE would point `aws login` at that profile and fail.
      terraform = "AWS_PROFILE=\${AWS_PROFILE:-terraform} terraform";
      ts = "tailscale";

      # AWS & Cloud Development Kit (CDK) Shortcuts
      assume = "source assume";
      cdks = "cdk synth";
      cdkd = "cdk diff";
      cdkl = "cdk list";
      cdkw = "cdk watch";

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
  };

  # ----------------------------------------------------------------------
  # 5. Ghostty Terminal Configuration
  # ----------------------------------------------------------------------
  # The cask installs the app; home-manager owns ~/.config/ghostty/config.
  programs.ghostty = {
    enable = true;
    package = null; # Installed by the Homebrew cask, not Nix
    settings = {
      # Font & Typography
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;
      font-feature = [ "calt" "liga" ]; # Written as one `font-feature =` line each

      # Theme & Appearance (Ghostty 1.3 theme names are case-sensitive)
      theme = "TokyoNight";
      background-opacity = 0.95;
      background-blur-radius = 20;
      macos-titlebar-style = "tabs";

      # Performance & Cursor
      cursor-style = "block";
      cursor-style-blink = false;
      macos-option-as-alt = true;
    };
  };

  # ----------------------------------------------------------------------
  # 6. VS Code & Multi-Model Agent Configuration
  # ----------------------------------------------------------------------
  # The cask installs the app; home-manager owns settings.json and the
  # extensions dir (read-only). UI setting changes and in-app extension installs
  # will not stick: change them here. Extensions come from the marketplace
  # mirror (nix-vscode-extensions); `just update` moves them to newer versions.
  programs.vscode = {
    enable = true;
    package = null;               # Installed by the Homebrew cask, not Nix
    mutableExtensionsDir = false; # Only the extensions listed below exist

    profiles.default = {
      enableExtensionUpdateCheck = false; # Extension updates come from `just update`

      extensions = with pkgs.vscode-marketplace-release; [
        # AI assistants
        google.google-antigravity
        anthropic.claude-code
        rooveterinaryinc.roo-cline

        # Theme & icons
        enkia.tokyo-night
        pkief.material-icon-theme

        # Infrastructure & cloud
        jnoortheen.nix-ide
        hashicorp.terraform
        ms-azuretools.vscode-docker
        ms-azuretools.vscode-containers # Required by vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        redhat.vscode-yaml

        # Languages & formatting
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        golang.go
        ms-python.python
        ms-python.vscode-pylance     # Required by ms-python.python
        ms-python.debugpy            # Required by ms-python.python
        ms-python.vscode-python-envs # Required by ms-python.python
      ];

      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', Menlo, Monaco, 'Courier New', monospace";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "editor.lineNumbers" = "on";
        "editor.minimap.enabled" = true;
        "editor.formatOnSave" = true;
        "[nix]" = {
          "editor.formatOnSave" = false;
        };
        "workbench.colorTheme" = "Tokyo Night";
        "workbench.iconTheme" = "material-icon-theme";
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "default"; # VS Code updates itself (the cask is auto_updates, so brew skips it)
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autorefresh" = true;
        "git.autoRepositoryDetection" = true;
        "git.repositoryScanMaxDepth" = 1;
        "scm.alwaysShowRepositories" = true;
        "scm.repositories.visible" = 10;
        "scm.repositories.selectionMode" = "multiple";
        "roo-cline.autoImportSettingsPath" = "~/.config/roo-code/settings.json";
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/.direnv/**" = true;
          "**/.trash/**" = true;
          "**/.obsidian/cache/**" = true;
        };
      };
    };
  };

  # Roo Code multi-model profiles: Grok (xAI), local MLX (Qwen 2.5 Coder 32B on
  # port 8080), AWS Bedrock. Claude runs through the Claude Code extension instead.
  # No API keys here: anything in Nix is readable by every user via /nix/store.
  home.file.".config/roo-code/settings.json".text = ''
    {
      "providerProfiles": {
        "currentApiConfigName": "Grok (xAI)",
        "apiConfigs": {
          "Grok (xAI)": {
            "id": "grok-xai",
            "apiProvider": "xai",
            "apiKey": "",
            "apiModelId": "grok-2"
          },
          "Local MLX (Qwen 2.5 Coder 32B)": {
            "id": "local-mlx-qwen-32b",
            "apiProvider": "openai",
            "openAiBaseUrl": "http://localhost:8080/v1",
            "openAiApiKey": "local",
            "openAiModelId": "mlx-community/Qwen2.5-Coder-32B-Instruct-4bit",
            "openAiCustomModelInfo": {
              "contextWindow": 32768,
              "maxTokens": 8192,
              "supportsImages": false,
              "supportsPromptCache": false
            }
          },
          "AWS Bedrock": {
            "id": "bedrock-hosted-llm",
            "apiProvider": "bedrock",
            "apiModelId": "anthropic.claude-3-5-sonnet-20241022-v2:0",
            "awsRegion": "us-east-2"
          }
        }
      },
      "globalSettings": {}
    }
  '';

  # Roo Code custom modes: a pure Chat mode with zero tools, for local LLMs.
  # Read-only: edit modes here, not in Roo's UI.
  home.file."Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/custom_modes.yaml".text = ''
    customModes:
      - slug: "chat"
        name: "💬 Chat / Pair Programmer"
        roleDefinition: "You are an expert pair programmer and software architect. Answer questions, provide clear explanations, and write clean, idiomatic code without executing tools."
        groups: []
        customInstructions: "Answer all questions directly in clear markdown with code blocks. Do not attempt to invoke tools or execute terminal commands."
  '';
}
