{ lib, ... }:

let
  handle = desktop: types: lib.genAttrs types (_: desktop);

  browserTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];

  imageTypes = map (t: "image/${t}") [
    "png"
    "jpeg"
    "jpg"
    "gif"
    "bmp"
    "tiff"
    "webp"
  ];

  textTypes =
    map (t: "text/${t}") [
      "plain"
      "x-python"
      "x-csrc"
      "x-chdr"
      "x-c++src"
      "x-java"
      "x-rust"
      "x-shellscript"
      "x-script.python"
      "javascript"
      "typescript"
      "x-lua"
      "x-makefile"
      "markdown"
      "x-markdown"
      "css"
      "xml"
      "yaml"
      "x-yaml"
      "x-toml"
    ]
    ++ map (t: "application/${t}") [
      "json"
      "x-yaml"
      "xml"
      "javascript"
      "x-sh"
      "x-shellscript"
      "toml"
    ];
in
{
  xdg.mime.enable = true;
  xdg.mime.defaultApplications = {
    "application/pdf" = "org.gnome.Papers.desktop";
  }
  // handle "firefox.desktop" browserTypes
  // handle "org.gnome.Loupe.desktop" imageTypes
  // handle "Helix.desktop" textTypes;
}
