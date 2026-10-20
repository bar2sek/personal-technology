{
  description = "Mac AI Workstation - M5 Pro 48GB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # User-scope config (dotfiles and user packages in ~). Runs as a nix-darwin
    # module, so one `just switch` applies system and user state together.
    # See "Home Manager Guide.md".
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # The whole VS Code marketplace as Nix packages, rebuilt daily (nix-community).
    # Lets home-manager own every VS Code extension; `just update` refreshes them.
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-vscode-extensions }:
  let
    mkDarwinSystem = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./darwin.nix
        home-manager.darwinModules.home-manager
      ];
    };
  in
  {
    darwinConfigurations = {
      "MacBook-Pro" = mkDarwinSystem;
      "default" = mkDarwinSystem;
    };
  };
}
