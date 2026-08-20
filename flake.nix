{
  description = "Run Granola (the macOS/Windows-only AI notepad) as a native Linux app";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          electronArch = {
            "x86_64-linux" = "x64";
            "aarch64-linux" = "arm64";
          }.${pkgs.stdenv.hostPlatform.system};

          # The installer downloads the official prebuilt Electron for the exact
          # version the .dmg ships. That binary expects an FHS layout
          # (/lib64/ld-linux-*, system libraries), which NixOS does not have, so
          # the launcher runs it inside this bubblewrap FHS environment. On
          # non-NixOS distros this works too and keeps the library set pinned.
          fhsEnv = pkgs.buildFHSEnv {
            name = "granola-electron-env";
            runScript = pkgs.writeShellScript "granola-electron-run" ''exec "$@"'';
            targetPkgs = ps: with ps; [
              alsa-lib
              at-spi2-atk
              at-spi2-core
              atk
              cairo
              cups
              dbus
              expat
              fontconfig
              freetype
              gdk-pixbuf
              glib
              gtk3
              libdrm
              libgbm
              libglvnd
              libnotify
              libsecret
              libuuid
              libxkbcommon
              libxshmfence
              mesa
              nspr
              nss
              pango
              pciutils
              udev
              libx11
              libxcb
              libxcomposite
              libxcursor
              libxdamage
              libxext
              libxfixes
              libxi
              libxrandr
              libxrender
              libxscrnsaver
              libxtst
            ];
          };

          granola-linux = pkgs.writeShellApplication {
            name = "granola-linux";
            runtimeInputs = with pkgs; [
              _7zz          # LZFSE-capable 7-Zip for reading the .dmg
              curl
              gcc
              gnumake
              nodejs
              python3
            ];
            text = ''
              export GRANOLA_ARCH=${electronArch}
              export GRANOLA_FHS_RUN=${fhsEnv}/bin/granola-electron-env
              export CACHE_DIR="''${CACHE_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/granola-linux}"
              exec bash ${./granola-linux.sh} "$@"
            '';
          };
        in
        {
          default = granola-linux;
          inherit granola-linux fhsEnv;
        });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/granola-linux";
        };
      });
    };
}
