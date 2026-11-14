{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    cargo-watch
    cargo-edit
    restic
    hdparm
    typst
    python3
    uv
    inkscape

    (obsidian.override { electron = electron_42; }) # electron 43 renders a black window
    go
    nodejs
    deno
    github-cli
    fd
    tree
    simplex-chat-desktop
    tdf
    viu
    basalt
    # Open the zellij `ide` layout (see ide.nix)
    (writeShellScriptBin "ide" ''
      [ -n "$1" ] && cd "$1"
      exec zellij --layout ide
    '')
    inputs.codex-cli-nix.packages.${system}.default
    inputs.claude-code-nix.packages.${system}.default
  ];
}
