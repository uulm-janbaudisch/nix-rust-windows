{
  description = "Packages and development environments for ddnnife";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fenix,
      ...
    }:
    let
      lib = nixpkgs.lib;
      systems = with lib.systems.doubles; unix ++ windows;
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        toolchain = fenix.packages.${system}.combine [
          fenix.packages.${system}.stable.defaultToolchain
          fenix.packages.${system}.targets.x86_64-pc-windows-gnu.stable.rust-std
        ];

        rust = pkgs.pkgsCross.mingwW64.makeRustPlatform {
          cargo = toolchain;
          rustc = toolchain;
        };

        crate = {
          name = "hello";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          #RUSTFLAGS = "-L native=${pkgs.pkgsCross.mingwW64.windows.mcfgthreads}/lib -C target-feature=+crt-static";
        };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        packages.default = rust.buildRustPackage crate;
      }
    );
}
