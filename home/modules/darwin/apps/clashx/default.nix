{ pkgs, ... }: with pkgs; {
  config = {
    programs = {
      sops = {
        decryptFiles = [{
          from = "secrets/.config/clash/config-whitelist.enc.yaml";
          to = ".config/clash.meta/config.yaml";
        }];
      };
    };
  };
}
