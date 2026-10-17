# AI Agent 规则与指南

## vLLM 配置

### 快速参考

如果你需要了解 WSL Ubuntu 环境下 vLLM 的配置规范、排障方法和最佳实践，请查看：

**📖 [WSL Ubuntu vLLM 配置指南](./docs/agents/wsl-ubuntu-vllm.md)**

## `secretsUser` 与 `homeUser` 规则速览

### `secretsUser`

- **用途**：决定 `mkHomeExtraSpecialArgs` 注入的 `userProfile`，用于区分不同用户的身份信息，并选择对应的 `sops` 密钥管理路径。
- **默认值**：`"soraliu"`。
- **可用值**：当前只显式定义了 `soraliu` 和 `clawbot` 两个用户档案。
- **回退规则**：如果传入的 `secretsUser` 不存在，就回退到 `userProfiles.soraliu`。
- **影响范围**：只影响 `gitName`、`gitEmail` 这类用户身份信息，以及依赖这些信息的模块。

### `homeUser`

- **用途**：决定 Home Manager / NixOS / nix-darwin 最终生成的实际登录用户。
- **默认值**：`"soraliu"`。
- **影响范围**：
  - `home-manager.users.${homeUser}`
  - `home.username`
  - `home.homeDirectory`
  - NixOS 下的 `users.users.${homeUser}`
  - Darwin 下的 `users.users.${homeUser}.home`
  - `system.primaryUser`
  - `nix.settings.trusted-users`
- **常见组合**：
  - `homeUser = "soraliu"`：默认个人环境。
  - `homeUser = "clawbot"`：`clawbot` 独立环境，通常会同时配合 `secretUser = "clawbot"`。
  - `homeUser = "root"`：用于部分服务型配置，例如 `wsl-infer`、`vpn-server`。

### 快速判断规则

- **身份信息** 看 `secretUser`。
- **实际系统登录用户** 看 `homeUser`。
- **两者可以独立设置**，但在 `clawbot` 这类独立环境中，通常需要同时切换。

### `secretsUser` / `homeUser` 的明确区分

- **`secretsUser`**：这是代码里实际传递给模块的变量名，用来拼接 `secrets/users/${secretsUser}/...` 这类 `sops` 解密路径，同时也用于选择对应的用户身份档案。
- **`homeUser`**：这是系统层面的实际登录用户，用来决定 `home-manager.users.*`、`users.users.*`、`system.primaryUser` 等最终落点。
- **关系总结**：
  - `secretsUser` 解决的是“用哪套身份或密钥配置”。
  - `homeUser` 解决的是“最终归属到哪个系统用户”。
  - 两者可以相同，也可以不同，但不能混为一谈。

## 敏感信息（禁止入库）

- **内网 IP / 主机地址**：任何 `README.md`、注释、commit message、文档中一律不得出现内网 IP（如 `192.168.x.x`、`10.x.x.x`）或其他内网拓扑信息（主机名、SSH 别名、端口布局）。本仓库公开在 GitHub，内网拓扑属于敏感信息。
- 描述目标机器时用「clawbot 的 Linux 桌面盒」「vpn-relayer 所在 VPS」这类**角色指称**；需要具体地址时指向本地私有记录（`~/.ssh/config`、运维记录），不在仓库里写明。
- sops 密文（`secrets/`）与 age 公钥本身不受此限制（设计如此入库），但**密文描述、路径注释也不得夹带内网 IP**。
