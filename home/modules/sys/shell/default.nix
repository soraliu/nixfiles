{ pkgs, lib, config, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = !pkgs.stdenv.isDarwin;
    shellOptions = if pkgs.stdenv.isDarwin then [
      "histappend"
      "extglob"
    ] else [
      "histappend"
      "extglob"
      "globstar"
      "checkjobs"
    ];
  };

  programs.bash.initExtra = ''
    if [ -z "''${HOME_PROFILE_DIRECTORY:-}" ] && [ -r "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    fi
  '';

  home.sessionPath = [
    "${config.home.homeDirectory}/.volta/bin"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
    "${config.home.homeDirectory}/.local/bin"
    "$GOPATH/bin"
    "${config.home.profileDirectory}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/.mint/bin"
  ];

  home.packages = with pkgs; [
    comma # run software without installing it (need nix-index), Github: https://github.com/nix-community/comma
  ];
}
