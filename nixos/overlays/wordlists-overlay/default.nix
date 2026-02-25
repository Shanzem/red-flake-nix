_self: super: {
  wordlists = super.stdenv.mkDerivation {
    pname = "wordlists";
    version = "1.0";

    # Fetch the repository using fetchgit with Git LFS support.
    src = super.fetchgit {
      url = "https://github.com/Red-Flake/wordlists.git";
      rev = "e27f00a20c20c31ca0360f67bd4ac10bd93b1432"; # e.g. commit hash or branch name
      sha256 = "sha256-ANg2ARepMWUIKNIuN7LSl+7rCTGIbmAVbRuyqK0jkbs=";
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
