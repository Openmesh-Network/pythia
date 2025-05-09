{
  description = "Pythia frontend + indexer + database.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    indexer = {
      url = "github:Plopmenz/pythia-indexer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    frontend = {
      url = "github:Plopmenz/pythia-frontend";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    {
      nixosModules.default = (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.pythia;
        in
        {
          imports = [
            inputs.indexer.nixosModules.default
            inputs.frontend.nixosModules.default
          ];

          options = {
            services.pythia = {
              enable = lib.mkEnableOption "Enable Pythia.";
            };
          };

          config = lib.mkIf cfg.enable {
            services.pythia-indexer = {
              enable = true;
            };
            systemd.services.pythia-indexer.after = [ "postgresql.service" ];

            services.pythia-frontend = {
              enable = true;
            };
            systemd.services.pythia-frontend.after = [ "postgresql.service" ];

            services.postgresql = {
              enable = true;
              initialScript = pkgs.writeText "init-sql-script" ''
                CREATE DATABASE pythia;
                \connect pythia;

                CREATE ROLE pythiabackend WITH LOGIN PASSWORD 'pythiabackend';
                GRANT pg_write_all_data TO pythiabackend;

                CREATE ROLE pythiafrontend WITH LOGIN PASSWORD 'pythiafrontend';
                GRANT pg_read_all_data TO pythiafrontend;

                CREATE TABLE ethereum_blocks (timestamp bigint, number bigint, hash character(66), extradata text, size bigint, gasused numeric);

                CREATE TABLE ethereum_transactions (timestamp bigint, hash character(66), fromaddr character(42), toaddr character(42), value numeric, gas bigint, gasprice bigint, input text, blocknumber bigint);

                CREATE TABLE fetch_erc20_transfers (timestamp bigint, fromaddr character(42), toaddr character(42), value numeric, transactionhash character(66), logindex integer, blocknumber bigint);

                CREATE TABLE fetch_erc20_approvals (timestamp bigint, owner character(42), spender character(42), value numeric, transactionhash character(66), logindex integer, blocknumber bigint);
              '';
            };
          };
        }
      );
    };
}
