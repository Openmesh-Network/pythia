{
  inputs = {
    pythia.url = "github:Plopmenz/pythia";
    nixpkgs.follows = "pythia/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      pythia,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pythia;
        };
        modules = [
          (
            { pythia, ... }:
            {
              imports = [
                pythia.nixosModules.default
              ];

              boot.isContainer = true;

              services.pythia.enable = true;
              services.pythia-indexer.infuraApiKey = "<YOUR API KEY>";
              services.pythia-frontend.asiApiKey = "<YOUR API KEY>";

              system.stateVersion = "25.05";
            }
          )
        ];
      };
    };
}
