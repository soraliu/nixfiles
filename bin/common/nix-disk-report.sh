#!/usr/bin/env bash
# nix-disk-report.sh — 生成 /nix/store 占用与 lazy-trees 等关键指标基线报告
#
# 用法:
#   bin/common/nix-disk-report.sh [--phase phaseN]
#   → 默认打印到 stdout (markdown)
#   → 若设置 --phase phaseN, 会同时写入 docs/reports/nix-disk-<phaseN>.md
#
# 设计要点:
#   - 跨平台 (Darwin BSD du vs GNU du)
#   - 只读, 不改变任何状态
#   - 关键 lazy-trees 信号: flake_src_copy_mb (通过 --store /tmp 隔离测 eval 增量)
#   - sops_decrypt_closure_mb: 验证 pkgs/sops/decrypt 的 src filter 改写收益

set -u

PHASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
uname_s="$(uname)"

# 跨平台 du 人类可读
du_hs() {
  du -sh "$1" 2>/dev/null | awk '{print $1}'
}

# 跨平台 du 字节
du_b() {
  if [[ "$uname_s" == "Darwin" ]]; then
    # BSD du -s 默认 512-byte blocks, -k 是 KiB
    local kb
    kb="$(du -sk "$1" 2>/dev/null | awk '{print $1}')"
    [[ -n "$kb" ]] && echo $((kb * 1024)) || echo 0
  else
    du -sb "$1" 2>/dev/null | awk '{print $1}'
  fi
}

# 跨平台 df /nix 可用空间 (人类可读, 如 "1.3T" / "120G")
disk_free="$(df -h /nix 2>/dev/null | awk 'NR==2 {print $4}')"
disk_free="${disk_free:-n/a}"

# /nix/store 大小
store_bytes="$(du_b /nix/store)"
store_hs="$(du_hs /nix/store)"
store_entries="$(ls /nix/store 2>/dev/null | wc -l | tr -d ' ')"

# nix 版本 + lazy-trees 状态
nix_version="$(nix --version 2>/dev/null | head -1 || echo '<missing>')"
is_determinate="no"
if echo "$nix_version" | grep -qi determinate; then is_determinate="yes"; fi

lazy_trees="unknown"
if command -v nix >/dev/null 2>&1; then
  if nix show-config 2>/dev/null | grep -q '^lazy-trees'; then
    lazy_trees="$(nix show-config 2>/dev/null | awk '/^lazy-trees/ {print $3}')"
  else
    lazy_trees="not-supported"
  fi
fi

# generations
darwin_gens=0
if [[ -d /nix/var/nix/profiles ]]; then
  darwin_gens="$(ls /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l | tr -d ' ')"
fi
hm_gens=0
if [[ -d "$HOME/.local/state/nix/profiles" ]]; then
  hm_gens="$(ls "$HOME/.local/state/nix/profiles"/profile-*-link 2>/dev/null | wc -l | tr -d ' ')"
fi
gcroots=0
if [[ -d /nix/var/nix/gcroots/auto ]]; then
  gcroots="$(ls /nix/var/nix/gcroots/auto 2>/dev/null | wc -l | tr -d ' ')"
fi

# flake_src_copy_mb: 用隔离 store 跑 nix flake metadata / eval, 测源树复制增量
# 这是 lazy-trees 生效与否的铁证:
#   - 无 lazy-trees: 整个 flake 根目录会被完整 copy → 约等于仓库源树总大小
#   - 有 lazy-trees (Determinate 3.5+): 仅按需 copy → 通常几 MB
flake_src_copy_mb="skipped"
if command -v nix >/dev/null 2>&1; then
  tmp_store="$(mktemp -d -t nix-disk-report-XXXXXX)"
  trap 'rm -rf "$tmp_store"' EXIT
  sys="$(nix eval --impure --raw --expr 'builtins.currentSystem' 2>/dev/null || echo "")"
  if [[ -n "$sys" ]]; then
    (
      cd "$repo_root"
      # nix flake show 会把 flake 源树 copy 到 store (lazy-trees 对照点)
      # 加 --extra-experimental-features 以防上游 Nix 默认未启
      nix \
        --extra-experimental-features 'nix-command flakes' \
        --store "$tmp_store" \
        flake show --no-write-lock-file 2>/dev/null >/dev/null || true
    )
  fi
  if [[ -d "$tmp_store/nix/store" ]]; then
    tmp_bytes="$(du_b "$tmp_store/nix/store")"
    flake_src_copy_mb="$(awk "BEGIN{printf \"%.1f\", $tmp_bytes/1048576}")"
  fi
fi

# sops_decrypt_closure_mb: 实例化 sops/decrypt (只 eval 不 build), 测 src closure 大小
sops_decrypt_closure_mb="n/a"
# 通过 nix-instantiate 评估 src 路径, 再量 size. 这里 best-effort,
# 失败不影响其它指标
if command -v nix-instantiate >/dev/null 2>&1; then
  sops_src_size="$(
    nix eval --impure --raw --expr "
      let
        pkgs = import <nixpkgs> {};
        src = (import $repo_root/pkgs/sops/decrypt.nix) { inherit pkgs; files = []; };
      in toString src.src
    " 2>/dev/null || echo ""
  )"
  if [[ -n "$sops_src_size" && -e "$sops_src_size" ]]; then
    _b="$(du_b "$sops_src_size")"
    sops_decrypt_closure_mb="$(awk "BEGIN{printf \"%.2f\", $_b/1048576}")"
  fi
fi

# 最大 5 个 store path
largest5="$(du -sh /nix/store/* 2>/dev/null | sort -hr | head -5 | sed 's/^/  - /')"

# 组装 markdown
gen_md() {
  cat <<EOF
# Nix 磁盘占用报告

- **时间**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **主机**: $(hostname)
- **OS**: ${uname_s} $(uname -r)
- **Phase**: ${PHASE:-<unspecified>}

## 核心指标

| 指标 | 值 |
|---|---|
| /nix/store 大小 | ${store_hs} (${store_bytes} bytes) |
| /nix/store 条目数 | ${store_entries} |
| /nix 可用空间 | ${disk_free} |
| Nix 版本 | \`${nix_version}\` |
| 是否 Determinate | ${is_determinate} |
| lazy-trees 配置 | ${lazy_trees} |
| Darwin system generations | ${darwin_gens} |
| HM profile generations | ${hm_gens} |
| GC roots (auto) | ${gcroots} |
| **flake_src_copy_mb** (lazy-trees 铁证) | ${flake_src_copy_mb} MB |
| **sops_decrypt_closure_mb** (src filter 铁证) | ${sops_decrypt_closure_mb} MB |

## 最大 5 个 store 路径

${largest5:-  <n/a>}

## 说明

- \`flake_src_copy_mb\`: 在隔离 store 中跑一次 \`nix eval\`, 记录 store 增量. 开启 lazy-trees 后应 ↓ ≥ 10×.
- \`sops_decrypt_closure_mb\`: 评估 \`pkgs/sops/decrypt.nix\` 的 \`src\` 路径大小. 改用 \`builtins.path\` + filter 后应只含 \`secrets/\`, ↓ ≥ 20×.
EOF
}

out="$(gen_md)"
echo "$out"

# 若指定 --phase, 同时写到 docs/reports/
if [[ -n "$PHASE" ]]; then
  target_dir="$repo_root/docs/reports"
  mkdir -p "$target_dir"
  target_file="$target_dir/nix-disk-${PHASE}.md"
  echo "$out" > "$target_file"
  echo "" >&2
  echo "Report written to: $target_file" >&2
fi
