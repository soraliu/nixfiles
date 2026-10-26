{ pkgs, lib, ... }:

# omp/pi 双栈共享的「支持的模型」单一事实来源:
#   sops 加密的 catalog(模型目录母本, 含 provider 私密字段) + 密钥表 → 构建期解密, switch 时 merge 进各工具全局 config。
# 合并语义(用户拍板 model 级):
#   - 同名 provider: 对象字段(baseUrl/api/compat 等)nix 优先; models 按 id 合并,
#     同 id 以 nix 定义覆盖(改即生效), 本机独有 model 永久保留;
#   - 本机独有 provider(如 pi 的 zai-coding-cn auth 条目)永不删除;
#   - 从 nix 删除一个 model 不会清理本机残留(声明式只做增量收敛)。
# 不触碰: pi settings.json / omp config.yml(运行时状态)、pi models-store.json(运行时缓存)。
# 密文(secrets/.config/ai/)按用户共享, 所有导入本模块的 profile(ide 系与 clawbot)同享同一套
# providers/apiKey; 需要分家时再挪 secrets/users/<user>/ 另建密文并按 secretsUser 分流。
{
  home.activation.mergeAgentModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    umask 077
    _jq="${pkgs.jq}/bin/jq"
    _yq="${pkgs.yq-go}/bin/yq"

    # 构建期已解密(均 sops 加密入 secrets/): 密钥表 {provider: apiKey} + catalog 模型目录母本
    _dec="${pkgs.callPackage ../../../../pkgs/sops/decrypt.nix {
      inherit pkgs;
      files = [
        { from = "secrets/.config/ai/agent-models-keys.enc.json"; to = "keys.json"; }
        { from = "secrets/.config/ai/agent-models-catalog.enc.json"; to = "catalog.json"; }
      ];
    }}"
    _keys="$_dec/keys.json"
    _catalog="$_dec/catalog.json"

    # provider/models 的 model 级合并 filter(已实测: 幂等 + 本机独有条目保留)
    _mergefilter='
def mergeprov($live; $nx):
  (($live // {}) * ($nx // {}))
  | .models =
      ((($live.models // []) + ($nx.models // [])) as $all
      | reduce $all[] as $m ({}; .[$m.id] = $m)
      | [.[]]
      );
.providers =
  ((.providers // {}) as $live
  | ($cat[0].providers // {}) as $c
  | (($live | with_entries(.key as $k | if ($c | has($k)) then .value = mergeprov(.value; $c[$k]) else . end)) + ($c | with_entries(.key as $k | select(($live | has($k)) | not))))
  )'

    # ---------- pi: ~/.pi/agent/models.json (纯目录, 无密钥) ----------
    _t="$HOME/.pi/agent/models.json"
    mkdir -p "$HOME/.pi/agent"
    [ -f "$_t" ] || printf '{}\n' > "$_t"
    if "$_jq" --slurpfile cat "$_catalog" "$_mergefilter" "$_t" > "$_t.nix-merge.tmp"; then
      mv "$_t.nix-merge.tmp" "$_t"
    else
      rm -f "$_t.nix-merge.tmp"
      echo "agent-models: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi

    # ---------- pi: ~/.pi/agent/auth.json ----------
    # 只新增/更新声明 provider 的 api_key 条目; zai-coding-cn 等本机登录条目不动
    _t="$HOME/.pi/agent/auth.json"
    [ -f "$_t" ] || printf '{}\n' > "$_t"
    if "$_jq" --slurpfile keymap "$_keys" \
        '. * ($keymap[0] | map_values({type: "api_key", key: .}))' \
        "$_t" > "$_t.nix-merge.tmp"; then
      mv "$_t.nix-merge.tmp" "$_t"
    else
      rm -f "$_t.nix-merge.tmp"
      echo "agent-models: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi

    # ---------- omp: ~/.omp/agent/models.yml (apiKey 内嵌 provider 上) ----------
    # YAML → JSON → 合并+注入密钥 → 剥离 omp 未识别的 compat 键 → YAML;
    # 首次 switch 会重排手写排版, 之后幂等。
    # 注意: jq 程序在 shell 双引号串里, 其中的 jq 变量($p/$keymap/$k/$deny)必须写成
    # \$p/\$keymap/\$k/\$deny, 否则会被 shell 当 shell 变量展开, 在 activation 的 set -u 下直接崩掉。
    # catalog 是 pi 超集(带 zaiToolStream 等 pi 新 compat 键), 但 omp 18.10.4 不认识这些键,
    # 每次启动都会刷一串 "Unknown compat key" 警告; 因此只在 omp 侧按 deny-list 把这些键
    # 从写入的 models.yml 里剥离(pi 侧不受影响, 全量保留)。omp 升级识别后再把列表清空即可。
    _ompdeny='["zaiToolStream","supportsOpenAIGrammarTools","supportsAdditionalTools","supportsToolSearch","supportsExplicitPromptCacheMode"]'
    _t="$HOME/.omp/agent/models.yml"
    mkdir -p "$HOME/.omp/agent"
    [ -f "$_t" ] || printf '{}\n' > "$_t"
    if "$_yq" -o=json -I=0 '.' "$_t" > "$_t.nix-merge.tmp" && \
       "$_jq" --slurpfile cat "$_catalog" --slurpfile keymap "$_keys" --argjson deny "$_ompdeny" \
         "$_mergefilter
          | .providers |= with_entries(.key as \$p | if (\$keymap[0][\$p] != null) then .value.apiKey = \$keymap[0][\$p] else . end)
          | .providers |= map_values(.models |= map(.compat |= (if . == null then . else with_entries(select(.key as \$k | (\$deny | index(\$k)) == null)) end)))" \
         "$_t.nix-merge.tmp" > "$_t.nix-merge2.tmp" && \
       "$_yq" -o=yaml -P '.' "$_t.nix-merge2.tmp" > "$_t.nix-yml.tmp"; then
      mv "$_t.nix-yml.tmp" "$_t"
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp"
    else
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp" "$_t.nix-yml.tmp"
      echo "agent-models: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi
  '';
}
