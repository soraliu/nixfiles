{ secretsUser, ... }: {
  config.programs.sops = {
    decryptFiles = [{
      from = "secrets/users/${secretsUser}/.config/github-copilot/hosts.enc.json";
      to = ".config/github-copilot/hosts.json";
    }];
  };
}
