{
  inputs = {
    voxtype.url = "github:peteonrails/voxtype";
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/v1.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher/8ff394e3ddfcb2fd755ed2e7b4c6f01f3e26e596";
      flake = false;
    };
  };
}
