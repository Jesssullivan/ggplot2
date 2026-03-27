{
  description = "ggplot2 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rWithPackages = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            # Imports (from DESCRIPTION)
            cli
            gtable
            isoband
            lifecycle
            rlang
            S7
            scales
            vctrs
            withr

            # Dev tooling
            devtools
            roxygen2
            testthat
            usethis

            # Test Suggests (critical subset)
            vdiffr
            svglite
            ragg
            dplyr
            tibble
            knitr
            xml2
            hexbin
            Hmisc
            MASS
            mgcv
            multcomp
            munsell
            nlme
            quantreg
            RColorBrewer
            rpart
            sf
            mapproj
            maps
            broom
            hms
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rWithPackages
            pkgs.pandoc
          ];
          shellHook = ''
            echo "ggplot2 dev shell ready — R $(R --version | head -1 | grep -oP '\\d+\\.\\d+\\.\\d+')"
          '';
        };
      }
    );
}
