{ lib, stdenv, fetchFromGitHub, makeWrapper, nodejs, electron, bower, gnumake, nodePackages }:

stdenv.mkDerivation rec {
  pname = "glowing-bear-electron";
  version = "0.9.0"; # Update with the correct version

  src = fetchFromGitHub {
    owner = "glowing-bear";
    repo = "glowing-bear";
    rev = "master"; # Replace with specific tag/commit if needed
    sha256 = "sha256-4HgmUgV/orL8vr5lNwZiijypHpr8rBiULCglgNV2R88="; # Replace with actual hash after first build attempt
  };

  nativeBuildInputs = [ makeWrapper nodejs nodePackages.bower gnumake ];

  buildPhase = ''
    # Install dependencies
    export HOME=$TMPDIR
    npm install
    bower install --allow-root

    # Build the electron app
    npm run build-electron-linux
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/applications

    # Copy the built electron app
    cp -r Glowing-Bear-linux-* $out/share/glowing-bear

    # Create wrapper script
    makeWrapper ${electron}/bin/electron $out/bin/glowing-bear \
      --add-flags "$out/share/glowing-bear"

    # Create desktop entry
    cat > $out/share/applications/glowing-bear.desktop << EOF
    [Desktop Entry]
    Name=Glowing Bear
    Comment=A web frontend for WeeChat IRC client
    Exec=$out/bin/glowing-bear
    Icon=$out/share/glowing-bear/resources/app/assets/img/favicon.png
    Type=Application
    Categories=Network;Chat;
    EOF
  '';

  meta = with lib; {
    description = "A web frontend for the WeeChat IRC client";
    homepage = "https://github.com/glowing-bear/glowing-bear";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ "kusuriya" ];
  };
}
