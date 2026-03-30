# eyewitness-overlay.nix
_: prev:
let
  xorgserverPkg = prev.xorgserver or prev.xorg.xorgserver;
  xvfbPkg = prev.xvfb or xorgserverPkg;
  xvfbRunPkg = prev."xvfb-run" or (prev.xorg."xvfb-run" or xorgserverPkg);
in
{
  python3Packages = prev.python3Packages.override {
    overrides = _pself: pprev: {
      pyvirtualdisplay = pprev.pyvirtualdisplay.overrideAttrs (_old: {
        postPatch = ''
          substituteInPlace pyvirtualdisplay/xvfb.py \
            --replace '"Xvfb"' '"${xvfbPkg}/bin/Xvfb"'
          substituteInPlace pyvirtualdisplay/abstractdisplay.py \
            --replace "'Xvfb'" "'${xvfbPkg}/bin/Xvfb'"
        '';
      });
    };
  };

  eyewitness = prev.eyewitness.overrideAttrs (old: {
    dependencies = old.dependencies or [ ] ++ [ xvfbPkg ];

    postPatch = ''
      substituteInPlace Python/modules/selenium_module.py \
        --replace "from selenium.webdriver.common.desired_capabilities import DesiredCapabilities" "" \
        --replace "capabilities = DesiredCapabilities.FIREFOX.copy()" "" \
        --replace "capabilities.update({'acceptInsecureCerts': True})" "" \
        --replace "driver = webdriver.Firefox(profile, capabilities=capabilities, options=options, service_log_path=cli_parsed.selenium_log_path)" "driver = webdriver.Firefox(options=options)"
    '';

    fixupPhase = ''
      runHook preFixup

      makeWrapper "${prev.python3Packages.python.interpreter}" "$out/bin/eyewitness" \
        --set PYTHONPATH "$PYTHONPATH" \
        --add-flags "$out/share/eyewitness/Python/EyeWitness.py" \
        --prefix PATH : "${prev.lib.makeBinPath [ xvfbPkg prev.geckodriver prev.firefox-bin xvfbRunPkg ]}"

      runHook postFixup
    '';
  });

}
