{
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      completions = {
        case_sensitive = false;
        algorithm = "fuzzy";
      };
    };
    shellAliases = {
      vi = "hx";
      vim = "hx";
      nano = "hx";
    };
  };

  programs.carapace.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user.name = "sam";
      user.email = "sam@example.com";
    };
  };
}
