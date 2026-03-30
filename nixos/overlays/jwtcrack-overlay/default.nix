# jwtcrack-overlay.nix
# https://github.com/Sjord/jwtcrack
_: prev:

let
  inherit (prev) lib;
in
{
  jwtcrack = prev.stdenv.mkDerivation rec {
    pname = "jwtcrack";
    version = "unstable-2023-01-10";

    src = prev.fetchFromGitHub {
      owner = "Sjord";
      repo = "jwtcrack";
      rev = "e9b170f7e0d48079790bbd10341437307f9a52cc";
      sha256 = "sha256-5i70bRn2nAxx+LOa8+inUMv6Af/OJMYu3lJkZDeVxHM=";
    };

    buildInputs = [
      (prev.python3.withPackages (ps: with ps; [
        pyjwt
        tqdm
      ]))
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp crackjwt.py $out/bin/crackjwt
      cp jwt2john.py $out/bin/jwt2john
      chmod +x $out/bin/crackjwt
      chmod +x $out/bin/jwt2john
    '';

    meta = with lib; {
      description = "Crack the shared secret of HS256, HS384, and HS512 signed JWT tokens";
      homepage = "https://github.com/Sjord/jwtcrack";
      license = licenses.agpl3Only;
      maintainers = [ ];
      platforms = platforms.linux;
    };
  };
}
