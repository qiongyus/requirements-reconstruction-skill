#!/usr/bin/env bash
# 证据源清点：对一个仓库根目录，报告需求重建所需各类行为证据的存在情况与陷阱。
#
# 用法: bash inventory_behavior_evidence.sh <repo-root>
#
# 设计要点：重点是告出「哪些证据源不存在」——据此判断哪些结论根本没有依据可给，
# 以及检测会让证据说谎的陷阱（浅克隆、squash 导入、生成代码、vendor）。

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "无法进入目录: $ROOT" >&2; exit 1; }

PRUNE_NAMES='node_modules target .git vendor dist build .venv __pycache__ .next .tox venv'
PRUNE=""
for n in $PRUNE_NAMES; do PRUNE="$PRUNE -name $n -o"; done
PRUNE="${PRUNE% -o}"

SECT_HIT=0

section() { SECT_HIT=0; printf '\n\033[1m%s\033[0m\n' "$1"; }

hit() { # hit <label> <maxdepth> <find-expr...>
  local label="$1"; shift
  local depth="$1"; shift
  local out
  out=$(find . -maxdepth "$depth" \( $PRUNE \) -prune -o \( "$@" \) -print 2>/dev/null \
        | head -8 | sed 's|^\./||' | paste -sd' ' -)
  if [ -n "$out" ]; then
    printf '  \033[32m✓\033[0m %-16s %s\n' "$label" "$out"
    SECT_HIT=1
  fi
}

# fallback <label> <msg>：仅当本节一无所获时才报缺失
fallback() {
  [ "$SECT_HIT" = 0 ] && printf '  \033[31m✗\033[0m %-16s %s\n' "$1" "$2"
  return 0
}

echo "════════════════════════════════════════════════════════════"
echo " 证据源清点: $(pwd)"
echo "════════════════════════════════════════════════════════════"

section "[1] 分层测试 —— 有意锁定行为的最强证据"
hit "测试目录"     3 -name tests -type d -o -name test -type d -o -name spec -type d
hit "集成/e2e"    3 -name 'e2e*' -type d -o -name 'integration*' -type d
hit "BDD"         4 -name '*.feature'
hit "golden/快照"  4 -name testdata -type d -o -name golden -type d -o -name __snapshots__ -type d -o -name '*.snap' -o -name 'fixtures' -type d
fallback "测试" "无 —— 行为断言只能从代码反推，confidence 上限 medium；重写无红灯保护"

section "[2] 可执行示例"
hit "examples"    2 -name examples -type d -o -name example -type d -o -name demos -type d -o -name cookbook -type d
fallback "示例" "无"

section "[3] API 契约/schema"
hit "openapi"     4 -iname 'openapi*.y*ml' -o -iname 'swagger*' -o -name '*.proto' -o -name '*.thrift' -o -name '*.graphql' -o -name '*.avsc' -o -iname '*jsonschema*'
fallback "API 契约" "无 —— 接口面从路由/导出符号反推"

section "[4] CLI 面"
hit "argparse 类"  4 -name 'cli*.rs' -o -name 'cli*.go' -o -name 'cli*.py' -o -name 'args*.py' -o -name 'flags*.go' -o -name 'cmd' -type d
hit "man/补全"     3 -name man -type d -o -name completions -type d -o -name '*.1'
fallback "CLI 面" "未自动识别 —— 用 --help 递归展开人工清点"

section "[5] 用户文档 —— 宣称行为的来源"
hit "README"      1 -iname 'readme*'
hit "docs"        2 -name docs -type d -o -name doc -type d -o -name book -type d -o -name website -type d
fallback "文档" "无 —— doc 源缺失：无宣称行为可对照，发现 #1/#2 不可用"

section "[6] 变更记录"
hit "CHANGELOG"   2 -iname 'changelog*' -o -iname 'CHANGES*' -o -iname 'NEWS*' -o -name 'releases' -type d
fallback "变更记录" "无 —— 行为变更史不可考"

section "[7] 兼容/一致性套件"
hit "conformance" 3 -name 'conformance*' -type d -o -name 'compat*' -type d -o -iname '*test*vector*' -o -name 'spec' -type d
fallback "兼容套件" "无"

section "[8] 依赖证据（仓库外）"
hit "issue 模板"   4 -path '*ISSUE_TEMPLATE*'
printf '  \033[33m⚠ 提示\033[0m           parity-incidental-relied 的依赖证据（下游 issue、生态用法）不在仓库内，需上网取证\n'

section "[9] 证据谱系预判 —— 本 skill 的档位由目的驱动，不由规模驱动"
SRC=$(find . \( $PRUNE \) -prune -o -type f \( \
  -name '*.go' -o -name '*.rs' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
  -o -name '*.py' -o -name '*.java' -o -name '*.kt' -o -name '*.rb' -o -name '*.php' \
  -o -name '*.cpp' -o -name '*.cc' -o -name '*.c' -o -name '*.h' -o -name '*.hpp' \
  -o -name '*.cs' -o -name '*.swift' -o -name '*.scala' -o -name '*.vue' -o -name '*.svelte' \
  \) -print 2>/dev/null | wc -l | tr -d ' ')
TESTS=$(find . \( $PRUNE \) -prune -o -type f \( -name '*_test.*' -o -name 'test_*' -o -name '*.test.*' -o -name '*.spec.*' -o -path '*/tests/*' -o -path '*/test/*' \) -print 2>/dev/null | wc -l | tr -d ' ')
printf '  源文件数（已排除 vendor/生成目录）: %s\n' "$SRC"
printf '  测试文件数: %s\n' "$TESTS"

if [ "$TESTS" -eq 0 ]; then PROFILE="doc-only/贫证据型：confidence 预期以 low 与缺口为主"
elif [ $((TESTS * 5)) -ge "$SRC" ]; then PROFILE="测试充分型：confidence 预期以 high 为主"
else PROFILE="混合型：逐行为面判断"
fi
printf '  \033[1m证据谱系预判: %s\033[0m\n' "$PROFILE"

section "[10] 陷阱检测 —— 会让证据说谎的东西"

if [ -d .git ]; then
  COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  if [ -f .git/shallow ]; then
    CUT=$(git log --reverse --format=%ad --date=short 2>/dev/null | head -1)
    printf '  \033[33m⚠ 浅克隆\033[0m         历史截断于 %s（共 %s commit）\n' "$CUT" "$COMMITS"
    printf '                     → git 类结论必须标注此截断日期\n'
    printf '                     → 可用 git fetch --deepen=500 增量加深\n'
  elif [ "$COMMITS" -le 2 ]; then
    printf '  \033[33m⚠ 无有效历史\033[0m     仅 %s 个 commit（squash 导入或镜像快照）\n' "$COMMITS"
    printf '                     → 热点与共变分析不可用，声明该证据源缺失\n'
  else
    FIRST=$(git log --reverse --format=%ad --date=short 2>/dev/null | head -1)
    AUTHORS=$(git shortlog -sn HEAD 2>/dev/null | wc -l | tr -d ' ')
    printf '  \033[32m✓ git 历史完整\033[0m   %s commit, %s 贡献者, 起于 %s\n' "$COMMITS" "$AUTHORS" "$FIRST"
  fi
else
  printf '  \033[31m✗ 无 git\033[0m          热点与共变分析不可用\n'
fi

GEN=$(find . \( $PRUNE \) -prune -o -type f \( -name '*.pb.go' -o -name '*_generated.go' \
      -o -name '*.qtpl.go' -o -name '*_pb2.py' -o -name '*.generated.*' -o -name '*.g.dart' \
      -o -name '*_gen.go' \) -print 2>/dev/null | wc -l | tr -d ' ')
[ "$GEN" -gt 0 ] && printf '  \033[33m⚠ 生成代码\033[0m       %s 个文件 → 分析时排除，但记录生成链\n' "$GEN"

if [ -n "$(find . \( $PRUNE \) -prune -o \( -name testdata -type d -o -name golden -type d -o -name __snapshots__ -type d -o -name '*.snap' -o -name 'fixtures' -type d \) -print -quit 2>/dev/null)" ]; then
  printf '  \033[33m⚠ golden/快照存在\033[0m → 直译前必须过 parity 分类（发现 #4）\n'
fi

echo
echo "────────────────────────────────────────────────────────────"
echo " 下一步：把标 ✗ 的证据源写进候选块的缺口声明；"
echo " ⚠ 陷阱在相关断言处逐条标注。"
echo "────────────────────────────────────────────────────────────"
