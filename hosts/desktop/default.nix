{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  services.xserver.xkb = {
    layout = "jp";
    variant = "";
  };

  console.keyMap = "jp106";

  # Wireshark: installs the package and sets up the `wireshark` group with
  # dumpcap capabilities for non-root capture. Add sam to that group.
  programs.wireshark.enable = true;
  users.users.sam.extraGroups = [ "wireshark" ];

  # Desktop-only apps
  environment.systemPackages = with pkgs; [
    tor-browser
    theharvester

    # Browser
    brave

    # Recon / OSINT
    subfinder
    maltego
    trufflehog
    nuclei
    katana
    httpx

    # Scanning
    rustscan
    nmap

    # Web / proxies
    caido-desktop
    sqlmap
    ffuf

    # Exploitation / C2
    metasploit
    exploitdb # provides searchsploit
    social-engineer-toolkit
    netexec
    responder
    ligolo-ng
    bettercap

    # Password / wireless
    hashcat
    thc-hydra
    aircrack-ng

    # AD / post-exploitation
    bloodhound-ce
    certipy
    linux-exploit-suggester

    # Networking
    netcat-openbsd

    # Reversing / forensics
    ghidra
    autopsy
    volatility3
    cyberchef
  ];
}
