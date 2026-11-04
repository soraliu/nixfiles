# omp/pi 模型目录统一管理

omp(`~/.omp/agent/models.yml`)与 pi(`~/.pi/agent/models.json` + `~/.pi/agent/auth.json`)的「支持的模型」目录,以本模块声明的数据为**单一事实来源**:`just switch-home` 时自动 merge 进各工具的全局 config,本机独有条目永久保留。

- 解决的问题:双栈手工维护漂移(pi 侧曾多出 `zaiToolStream`、`supportsToolSearch` 等 compat 字段)、换机器不同步、apiKey 散落明文文件。
- 声明的数据不进明文 git:模型目录与密钥都走 sops 加密(见下表)。

## 组成

| 文件 | 作用 |
| --- | --- |
| `default.nix`(本目录) | 合并模块本体,ide 系 profile 经 `home/profiles/ide.nix`、clawbot 经 `home/profiles/clawbot.nix` 挂载 |
| `secrets/.config/ai/agent-models-catalog.enc.json` | 模型目录母本 sops 密文:{provider: {baseUrl, api, compat, models:[…]}}(含 provider 私密字段) |
| `secrets/.config/ai/agent-models-keys.enc.json` | 密钥表 sops 密文:`{provider: apiKey}` |
| `secrets/.config/ai/omp-config.enc.json` | omp 模块合并到 `config.yml`；`modelRoles.vision` 指定读图模型 |
| `secrets/.config/ai/pi-config.enc.json` | pi 模块合并到 `settings.json`；声明 `defaultProvider/defaultModel`，其他本机设置保留 |

ide/ide-cn/ide-mirror/ide-mobile、`darwinConfigurations.soraliu*` 与 `switch-nixos ide` 均自动获得;clawbot(Linux 桌面盒 / darwin)也导入并共享同一套 catalog/keys(密文位于用户共享的 `secrets/.config/ai/`,无 per-user 分家);vpn-server / drive-server / eject 不导入该模块,不受影响。将来需要分家时再挪 `secrets/users/<user>/` 另建密文并按 `secretsUser` 分流。

## 工作原理

### 1. 构建期:解密

`pkgs/sops/decrypt.nix` 一次调用解密两个文件进 store(复用仓库既有约定,age 私钥在 `/tmp/.age/keys.txt`,`just pre-init-age` 自愈):

```nix
_dec = pkgs.callPackage ../../../../pkgs/sops/decrypt.nix {
  files = [
    { from = "secrets/.config/ai/agent-models-keys.enc.json";    to = "keys.json"; }
    { from = "secrets/.config/ai/agent-models-catalog.enc.json"; to = "catalog.json"; }
  ];
}
# activation 脚本内: _keys=$_dec/keys.json, _catalog=$_dec/catalog.json
```

### 2. 运行期(activation):三段 merge

`home.activation.mergeAgentModels = lib.hm.dag.entryAfter ["writeBoundary"]`,对三个目标文件逐个处理,全部走 `*.tmp` + `mv` 原子替换,`umask 077` 使落地即 600:

| 目标 | 管线 |
| --- | --- |
| `~/.pi/agent/models.json` | jq:catalog 按 `_mergefilter` 合并(纯目录文件) |
| `~/.pi/agent/auth.json` | jq:`. * ($keymap[0] \| map_values({type:"api_key", key:.}))`,只新增/更新被声明 provider 的条目 |
| `~/.omp/agent/models.yml` | yq(YAML→JSON) → jq(merge + 注入 `provider.apiKey` + 剥离 `_ompdeny` 中 omp 未识别的 compat 键) → yq(-o=yaml -P),首次 switch 重排排版,之后字节级幂等 |

### 3. 合并语义(model 级)

`_mergefilter` 的行为:

- **provider 集合**:live 里的 provider 全保留;被 catalog 声明的同名 provider 做深合并(catalog 胜);catalog 独有的 provider 追加。
- **provider 对象字段**(baseUrl/api/compat 等):jq `*` 深合并,nix 定义覆盖(改即生效);compat 等嵌套对象递归合并,标量/数组 catalog 侧胜。
- **models**:live + catalog 的 models 拼接后按 `id` reduce 建表,同 id **nix 定义覆盖**;输出保持首次出现顺序(live 在前,catalog 新增追加)。
- **本机独有条目**(手工新增的 provider/model,如 pi 的 `zai-coding-cn` auth 登录条目)永不删除。
- **从 nix 删除一个 model/provider 不清理本机残留**——声明式只做增量收敛,删除需手工同步清 target 文件。
- **omp 侧 compat 键剥离**:catalog 是 pi 超集,但 omp 18.10.4 未识别的键(`zaiToolStream`、`supportsToolSearch` 等)写回 models.yml 前按 `_ompdeny` deny-list 剥离,避免每次启动刷 "Unknown compat key" 警告;pi 侧全量保留不受影响。

### 4. 降级路径

目标文件缺失(新机器)→ 以 `{}` 起步全量生成;存在但损坏(jq/yq 解析失败)→ `agent-models: WARN` 后保持原文件不动,不阻断整个 switch。所有临时文件在失败分支即时清理。

> 实现坑位备忘:omp 段 jq 程序嵌在 shell 双引号串中,程序里的 jq 变量必须写成 `\$p`/`\$keymap`;否则被 shell 当 shell 变量展开,而 home-manager activation 以 `set -u` 运行,直接 `unbound variable` 崩掉(已实测踩过)。

### 5. 时序假设

- 只处理默认 agent 目录(`~/.omp/agent`、`~/.pi/agent`);`--profile`/环境变量改写 agentDir 的场景不覆盖。
- 与运行中的 pi/omp 不加锁:进程持有启动时快照,merge 结果下次启动生效。
- 本模块不触碰 pi `settings.json`、`models-store.json` 或 omp `config.yml`。模型角色由各工具模块另行合并：omp 使用 `omp-config.enc.json`，pi 使用 `pi-config.enc.json`；均保留未声明的本机设置。

## 日常维护

```sh
# 1. 编辑模型目录(provider/model/compat/baseUrl 等)
sops secrets/.config/ai/agent-models-catalog.enc.json
# 或编辑密钥表(新增/更换 provider apiKey)
sops secrets/.config/ai/agent-models-keys.enc.json

# 2. 应用(ide 系与 clawbot;本机独有条目不受影响)
just switch-home ide
```

效果速查:

| 想要的效果 | 做什么 |
| --- | --- |
| 新增/修改某 model(含 compat 字段) | 改 catalog → switch;同 id 即覆盖,改即生效 |
| 新增 provider | catalog 加条目 + keys 加密钥(pi 走 auth.json;omp 侧的 apiKey 靠 keymap 注入,漏配则该 provider 在 omp 无密钥) |
| 换新机器 | 正常 `just switch-home ide` / `just switch-home clawbot`,目标文件缺失自动全量生成 |
| 从声明里删除某 model | 改 catalog → switch 后**本机残留仍在**,需手工清 |

### DeepSeek V4.1 Flash 协议

`1xtoken/deepseek-v4.1-flash-1017` 使用 `api: openai-completions`。模型级 `api` 会覆盖 provider 默认值；误设为 `openai-responses` 会向 `/responses` 发送 `input` 而非 `messages`，本次实测返回 HTTP 400 `messages cannot be empty`。

- 推理档位保留 `low/high/max`；`maxTokensField: max_tokens`，不发送 `tool_choice`。
- 历史 assistant 回传原始 `reasoning_content`，包括工具调用轮；设置 `requiresReasoningContentForAllAssistantTurns: true`、`requiresReasoningContentForToolCalls: true` 和 `allowsSyntheticReasoningContentForToolCalls: false`，不能用合成占位推理替代。
- 保留图片输入与 `stripImageInput: false`，不改变现有上下文窗口。

依据 omp [18.10.4 模型配置](https://github.com/can1357/oh-my-pi/blob/v18.10.4/docs/models.md)、[DeepSeek provider 规则](https://github.com/can1357/oh-my-pi/blob/v18.10.4/packages/catalog/src/compat/rules/providers/deepseek.kdl)与[模型规则](https://github.com/can1357/oh-my-pi/blob/v18.10.4/packages/catalog/src/compat/rules/classes/deepseek.kdl)。官方规则不是 1xtoken 的可用性保证：修改后需重新启动 omp，实测文本回复与工具调用往返。

2026-11-04 验证：执行 `./.nix-switch` 成功；新进程 `low/max` 文本回复及 `high` 读取临时文件后的工具结果续答均通过。omp 的 `read image.png?q=...` 与 pi 默认模型的图片附件均正确识别测试图片文字；长上下文未实测。

### vision 模型与 pi 默认模型

- omp 的 `modelRoles.vision` 指向 `1xtoken/deepseek-v4.1-flash-1017`，仅控制图片分析，不改变其他模型角色；不要与用于图片生成的 `image` 角色混淆。
- pi 1.1.0 没有独立 vision 槽位，图片由当前模型处理。按用户确认，`pi-config.enc.json` 将 `defaultProvider` 设为 `1xtoken`、`defaultModel` 设为 `deepseek-v4.1-flash-1017`，因此新会话的文字和图片任务都默认使用该模型。
- 修改对应密文后执行 `./.nix-switch`。pi 已有会话会恢复自身模型选择；新建会话使用新默认，也可通过 `/model` 手动切换。`--profile` 或自定义 agent 目录不在本模块的管理范围内。

## 已知边界

- omp 18.10.4 暂不识别 pi 侧新 compat 键,故 omp 侧按 deny-list(`default.nix` 的 `_ompdeny`)剥离后写入;omp 升级跟进 pi-mono schema 后把列表清空即可恢复全量传播(下 switch 会自动把这些键补回 omp 的 models.yml)。
- sops 构建期解密产物存在于 `/nix/store`(仓库既有约定,单用户机器可接受)——若未来某个工具 schema 收紧导致启动报错,删该工具对应 merge 段改人工迁移。

验证记录见 PR #57:merge 断言、omp/pi 端到端、连续 switch 字节级幂等均实测通过。
