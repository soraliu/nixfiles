{ config, lib, pi, pkgs, secretsUser, system, ... }:
let
  providerJson = builtins.toJSON {
    "1xtoken" = {
      baseUrl = "https://1xtoken.cc/v1";
      api = "openai-completions";
      models = [{
        id = "glm-5.2";
        name = "GLM-5.2";
      }];
    };
  };
in
{
  config.home.packages = [
    pi.packages.${system}.coding-agent
  ];

  config.programs.sops.decryptFiles = [{
    from = "secrets/users/${secretsUser}/.config/pi/auth.enc.json";
    to = ".pi/agent/auth.json";
  }];

  config.home.activation.configurePi = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -eu
    pi_dir="${config.home.homeDirectory}/.pi/agent"
    models="$pi_dir/models.json"
    settings="$pi_dir/settings.json"
    mkdir -p "$pi_dir"

    provider_json='${providerJson}'
    if [ -f "$models" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq --argjson provider "$provider_json" \
        '.providers = ((.providers // {}) + $provider)' "$models" > "$tmp"
      chmod 600 "$tmp"
      mv "$tmp" "$models"
    else
      printf '%s\n' "{\"providers\":$provider_json}" > "$models"
      chmod 600 "$models"
    fi

    if [ -f "$settings" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq \
        --arg provider "1xtoken" \
        --arg model "glm-5.2" \
        '.defaultProvider = $provider | .defaultModel = $model' "$settings" > "$tmp"
      chmod 600 "$tmp"
      mv "$tmp" "$settings"
    else
      printf '%s\n' '{"defaultProvider":"1xtoken","defaultModel":"glm-5.2"}' > "$settings"
      chmod 600 "$settings"
    fi
  '';
}
