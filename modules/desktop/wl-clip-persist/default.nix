{ ... }:

{
  # wl-clip-persist - Keep clipboard contents alive after apps exit
  # Prevents clipboard from being cleared when the owning application closes

  home-manager.sharedModules = [
    (_: {
      services.wl-clip-persist = {
        enable = true;
        clipboardType = "both";
      };
    })
  ];
}
