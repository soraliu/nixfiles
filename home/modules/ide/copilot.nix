{ ... }: {
  config.programs.sops = {
    decryptFiles = [{
      from = "secrets/.config/github-copilot/hosts.enc.json";
      to = ".config/github-copilot/hosts.json";
    }];
  };
}
