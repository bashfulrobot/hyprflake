{ config, lib, pkgs, ... }:

{
  # Essential fonts for desktop environment
  # Includes basic system fonts, emoji, and common programming fonts

  fonts.packages = with pkgs; [
    # Basic system fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf

    # Programming fonts
    fira-code
    fira-code-symbols
    jetbrains-mono

    # Additional useful fonts
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
