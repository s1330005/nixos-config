{
  networking = {
    networkmanager.enable = true;

    wg-quick.interfaces.wg0 = {
      address = [ "10.2.0.2/32" ];
      privateKeyFile = "/etc/wireguard/proton-privatekey";
      dns = [ "10.2.0.1" ];
      peers = [
        {
          publicKey = "7FslkahrdLwGbv4QSX5Cft5CtQLmBUlpWC382SSF7Hw=";
          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
          endpoint = "103.125.235.19:51820";
        }
      ];
    };

    firewall = {
      checkReversePath = false; # for VPN
      # Dev servers (Vite, Astro, misc)
      allowedTCPPorts = [
        5173
        4321
        3000
      ];
    };
  };
}
