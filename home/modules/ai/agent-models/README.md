# omp/pi 模型目录统一管理

omp(`~/.omp/agent/models.yml`)与 pi(`~/.pi/agent/models.json` + `~/.pi/agent/auth.json`)的「支持的模型」目录,以本模块声明的数据为**单一事实来源**:`just switch-home` 时自动 merge 进各工具的全局 config,本机独有条目永久保留。

- 解决的问题:双栈手工维护漂移(pi 侧曾多出 `zaiToolStream`、`supportsToolSearch` 等 compat 字段)、换机器不同步、apiKey 散落明文文件。
- 声明的数据不进明文 git:模型目录与密钥都走 sops 加密(见下表)。

## 组成

| 文件 | 作用 |
| --- | --- |
| `default.nix`(本目录) | 合并模块本体,ide 系 profile 经 `home/profiles/ide.nix` 挂载 |
| `secrets/.config/ai/agent-models-catalog.enc.json` | 模型目录母本 sops 密文:{provider: {baseUrl, api, compat, models:[…]}}(含 provider 私密字段) |
| `secrets/.config/ai/agent-models-keys.enc.json` | 密钥表 sops 密文:`{provider: apiKey}` |

ide/ide-cn/ide-mirror/ide-mobile、`darwinConfigurations.soraliu*` 与 `switch-nixos ide` 均自动获得;clawbot / vpn-server / drive-server / eject 不导入该模块,且模块内还有 `secretsUser == "soraliu"` 守卫,clawbot 环境整体 no-op(将来给 clawbot 部署需另建专属 catalog/keys,不共用)。

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
- 不触碰运行时状态/缓存:pi `settings.json`、omp `config.yml`、pi `models-store.json`。

## 日常维护

```sh
# 1. 编辑模型目录(provider/model/compat/baseUrl 等)
sops secrets/.config/ai/agent-models-catalog.enc.json
# 或编辑密钥表(新增/更换 provider apiKey)
sops secrets/.config/ai/agent-models-keys.enc.json

# 2. 应用(ide 系;本机独有条目不受影响)
just switch-home ide
```

效果速查:

| 想要的效果 | 做什么 |
| --- | --- |
| 新增/修改某 model(含 compat 字段) | 改 catalog → switch;同 id 即覆盖,改即生效 |
| 新增 provider | catalog 加条目 + keys 加密钥(pi 走 auth.json;omp 侧的 apiKey 靠 keymap 注入,漏配则该 provider 在 omp 无密钥) |
| 换新机器 | 正常 `just switch-home ide`,目标文件缺失自动全量生成 |
| 从声明里删除某 model | 改 catalog → switch 后**本机残留仍在**,需手工清 |

## 已知边界

- omp 18.10.4 暂不识别 pi 侧新 compat 键,故 omp 侧按 deny-list(`default.nix` 的 `_ompdeny`)剥离后写入;omp 升级跟进 pi-mono schema 后把列表清空即可恢复全量传播(下 switch 会自动把这些键补回 omp 的 models.yml)。
- sops 构建期解密产物存在于 `/nix/store`(仓库既有约定,单用户机器可接受)——若未来某个工具 schema 收紧导致启动报错,删该工具对应 merge 段改人工迁移。

验证记录见 PR #57:merge 断言、omp/pi 端到端、连续 switch 字节级幂等均实测通过。
