{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        gradle = pkgs.gradle_7.override {
          java = pkgs.jdk11;
        };
        androidsdk = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "30.0.2" ];
          platformVersions = [ "30" ];
          includeNDK = true;
          ndkVersion = "22.1.7171670";
          cmakeVersions = [ "3.22.1" ];
        };
      in
      rec {
        default = pkgs.stdenv.mkDerivation (finalAttrs: {
          name = "winlator";
          src = ./app;
          nativeBuildInputs = [ gradle ];
          ANDROID_SDK_ROOT = "${androidsdk.androidsdk}/libexec/android-sdk";
          gradleFlags = builtins.concatStringsSep " " [
            "--stacktrace"
            "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidsdk.androidsdk}/libexec/android-sdk/build-tools/${(builtins.elemAt androidsdk.build-tools 0).version}/aapt2"
          ];
          preBuild = ''
            export ANDROID_SDK_HOME="$(mktemp -d)"
          '';
          mitmCache = gradle.fetchDeps {
            pkg = default;
            data = ./deps.json;
          };
        });

        updateDeps = pkgs.writeShellApplication {
          name = "update-deps.sh";
          text = ''
            exec ${default.mitmCache.updateScript}
          '';
        };
      };
  };
}
