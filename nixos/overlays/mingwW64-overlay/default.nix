final: prev: {
  pkgsCross = prev.pkgsCross // {
    mingwW64 = prev.pkgsCross.mingwW64 // {
      windows = prev.pkgsCross.mingwW64.windows // {
        mcfgthreads = prev.pkgsCross.mingwW64.windows.mcfgthreads.overrideAttrs (_old: {
          dontDisableStatic = true;
        });
      };
      buildPackages = prev.pkgsCross.mingwW64.buildPackages // {
        gcc = prev.pkgsCross.mingwW64.buildPackages.gcc.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ prev.pkgs.makeWrapper ];
          postFixup = (old.postFixup or "") + ''
            wrapProgram $out/bin/x86_64-w64-mingw32-gcc --add-flags "-L${final.pkgsCross.mingwW64.windows.mcfgthreads}/lib"
            wrapProgram $out/bin/x86_64-w64-mingw32-g++ --add-flags "-L${final.pkgsCross.mingwW64.windows.mcfgthreads}/lib"
          '';
        });
      };
    };
  };
}
