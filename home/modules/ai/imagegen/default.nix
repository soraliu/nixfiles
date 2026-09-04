{ ... }: {
  config.programs.sops.decryptFiles = [{
    from = "secrets/.config/ai/imagegen.auth.enc.json";
    to = ".config/ai/imagegen.auth.json";
  }];
}
