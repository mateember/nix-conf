{
  description = "My NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    vscode-server,
    winapps,
    ...
  }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    lib-unstable = nixpkgs-unstable.lib;

    pkgs-unstable = import nixpkgs-unstable {
      config.allowUnfree = true;
      localSystem = {inherit system;};
    };
  in {
    nixosConfigurations = {
      matevono = lib-unstable.nixosSystem {
        inherit system;
        modules = [
          ./hosts/matevono
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "nixbk";
              users.mate = import ./hosts/matevono/home.nix;
              extraSpecialArgs = {
                inherit pkgs-unstable;
              };
            };
          }
        ];

        specialArgs = {
          inherit pkgs-unstable winapps;
        };
      };

      homelab = lib.nixosSystem {
        inherit system;
        modules = [
          vscode-server.nixosModules.default
          ./hosts/homelab
        ];

        specialArgs = {
          inherit pkgs-unstable;
        };
      };
    };
  };
}
