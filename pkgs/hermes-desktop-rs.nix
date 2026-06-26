# Hermes Desktop RS — statically linked Rust GUI client for Hermes Agent
{ pkgs }:

let
  # Use the musl target for static linking
  rustStatic = pkgs.rust-bin.stable.latest.default.override {
    targets = [ "x86_64-unknown-linux-musl" ];
  };

  # Native build inputs needed for compilation
  nativeBuildInputs = with pkgs; [
    rustStatic
    pkg-config
  ];

  # Build inputs — for static linking we need static versions of these
  buildInputs = with pkgs; [
    wayland
    libxkbcommon
    libGL
    libEGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    fontconfig
    freetype
  ];

in pkgs.rustPlatform.buildRustPackage rec {
  pname = "hermes-desktop-rs";
  version = "0.1.0";

  src = /data/hermes-desktop-rs;

  cargoLock.lockFile = /data/hermes-desktop-rs/Cargo.lock;

  nativeBuildInputs = nativeBuildInputs;
  buildInputs = buildInputs;

  # Build statically with musl
  CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
  CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";

  # Ensure we link against static libraries where possible
  RUSTFLAGS = "-C target-feature=+crt-static";

  # Skip tests during build (they may need a display)
  doCheck = false;

  meta = with pkgs.lib; {
    description = "GUI client for Hermes Agent";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
