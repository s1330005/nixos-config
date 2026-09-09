{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant.url = "github:abenz1267/elephant"; # for walker
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    awww.url = "git+https://codeberg.org/LGFae/awww";
    niri.url = "github:sodiboo/niri-flake";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
    llm-agents.url = "github:numtide/llm-agents.nix";
    flake-utils.url = "github:numtide/flake-utils";
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      niri,
      codex-cli-nix,
      claude-code-nix,
      llm-agents,
      flake-utils,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Shared modules for every machine; host-specific bits (hostname,
      # keyboard layout, hardware-configuration.nix) live under ./hosts/<name>.
      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            hostModule
            niri.nixosModules.niri
            {
              environment.systemPackages = [
                llm-agents.packages.x86_64-linux.agent-browser
              ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.sam = import ./home.nix;
              };
            }
          ];
        };
    in
    {
      # NixOS system configurations, one per machine
      nixosConfigurations = {
        laptop = mkHost ./hosts/laptop;
        desktop = mkHost ./hosts/desktop;
      };
    }

    //

      flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nodejs_latest
              playwright-driver.browsers
            ];

            buildInputs = [
              codex-cli-nix.packages.${system}.default
            ];

            shellHook = ''
              export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            '';
          };
        }
      );
}
