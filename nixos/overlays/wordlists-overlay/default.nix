_self: super: {
  wordlists = super.stdenv.mkDerivation {
    pname = "wordlists";
    version = "1.0";

    # Fetch the repository using fetchgit with Git LFS support.
    src = super.fetchgit {
      url = "https://github.com/Red-Flake/wordlists.git";
      rev = "2121735d44999f84a488291b412a6528e08cc9d6"; # e.g. commit hash or branch name
      sha256 = "sha256-L9XPRTEPMtAr58wvfFuXiokUmHv0ILyVGZYvV4a7i7I=";
      fetchLFS = true;
    };

    phases = [
      "unpackPhase"
      "installPhase"
    ];

    installPhase = ''
      mkdir -p $out/share/wordlists
      cp -r * $out/share/wordlists
    '';
  };
}
