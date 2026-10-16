{
  description = "RagFit | Monitor — Layer 5 Unified Observability Surface & OCI Container";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
            }
          )
        );
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          monitorAssets = pkgs.runCommand "ragfit-monitor-assets" { } ''
            mkdir -p $out/etc/grafana/provisioning \
                     $out/usr/share/grafana/conf \
                     $out/usr/share/grafana/public/img/ragfit \
                     $out/licenses
            cp ${./ragfit/deploy/grafana.ini} $out/etc/grafana/grafana.ini
            cp -r ${./conf}/* $out/usr/share/grafana/conf/
            cp -r ${./conf/provisioning}/* $out/etc/grafana/provisioning/
            cp -r ${./public/img/ragfit}/* $out/usr/share/grafana/public/img/ragfit/
            cp ${./LICENSE} ${./LICENSING.md} ${./NOTICE.md} ${./MODIFICATIONS.md} ${./TRADEMARKS.md} $out/licenses/
          '';

          container = pkgs.dockerTools.buildLayeredImage {
            name = "ghcr.io/erynoagroup/ragfit-monitor";
            tag = "latest";
            contents = [
              pkgs.grafana
              pkgs.cacert
              pkgs.tzdata
              monitorAssets
            ];
            config = {
              User = "472:472";
              WorkingDir = "/usr/share/grafana";
              Entrypoint = [ "${pkgs.grafana}/bin/grafana" "server" ];
              Cmd = [
                "--homepath=/usr/share/grafana"
                "--config=/etc/grafana/grafana.ini"
              ];
              ExposedPorts = {
                "3000/tcp" = { };
              };
              Env = [
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "TZDIR=${pkgs.tzdata}/share/zoneinfo"
                "GF_PATHS_CONFIG=/etc/grafana/grafana.ini"
                "GF_PATHS_PROVISIONING=/etc/grafana/provisioning"
                "GF_PATHS_HOME=/usr/share/grafana"
              ];
              Labels = {
                "org.opencontainers.image.title" = "ragfit-monitor";
                "org.opencontainers.image.description" = "RagFit | Monitor Unified Observability Surface (Layer 5)";
                "org.opencontainers.image.source" = "https://github.com/ErynoaGroup/ragfit-monitor";
                "org.opencontainers.image.licenses" = "AGPL-3.0-only";
              };
            };
          };
        in
        {
          inherit container;
          image = container;
          default = monitorAssets;
        }
      );

      devShells = forAllSystems (
        pkgs: {
          default = pkgs.mkShell {
            name = "ragfit-monitor-dev";
            packages = with pkgs; [
              go
              nodejs_22
              yarn
              just
              jq
              git
              (python3.withPackages (ps: [ ps.pyyaml ]))
            ];
            shellHook = ''
              echo "RagFit | Monitor devShell · just --list"
            '';
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
