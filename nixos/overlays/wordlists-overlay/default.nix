_self: super: {
  wordlists = super.stdenv.mkDerivation {
    pname = "wordlists";
    version = "1.0";

    # Fetch the repository using fetchgit with Git LFS support.
    src = super.fetchgit {
      url = "https://github.com/Red-Flake/wordlists.git";
      rev = "7fac1a1a6af2e41ba9a2264b89a521587416f19f"; # e.g. commit hash or branch name
      sha256 = "sha256-YfEcKVByIPIagMhPZ6iDbx+o9EAUE8N7hW5QlM/y1hM=";
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
