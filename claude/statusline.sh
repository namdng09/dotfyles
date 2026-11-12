#!/usr/bin/env bash
# Status line Claude Code:
#   ◆ Opus 5.5  📁 toast-sigma  ⎇ main*  ████████░░░░░░░░░░░░ 41.3% · used 82.6k · left 117.4k / 200k  $0.42
# Phải chạy nhanh: Claude Code huỷ lần chạy cũ khi có cập nhật mới, script chậm thì status line trống.
input=$(cat)

# Đọc mọi trường bằng 1 lần jq (mỗi lần gọi jq tốn vài chục ms)
IFS=$'\t' read -r model model_id cwd size used transcript cost < <(
  echo "$input" | jq -r '[
    (.model.display_name // "?"),
    (.model.id // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.context_window_size // ""),
    (.context_window.current_usage
      | if . == null then "" else
          ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
        end),
    (.transcript_path // ""),
    (.cost.total_cost_usd // "")
  ] | map(tostring | if . == "" then "-" else . end) | @tsv')
for v in model_id cwd size used transcript cost; do [ "${!v}" = "-" ] && printf -v "$v" ''; done

# ---- Context ----
if [ -z "$size" ]; then
  case "$model_id" in *"[1m]"*) size=1000000 ;; *) size=200000 ;; esac
fi
if [ -z "$used" ] && [ -f "$transcript" ]; then
  used=$(tail -n 200 "$transcript" | jq -s -r '
    [ .[] | select(.message.usage != null and (.isSidechain // false) == false) | .message.usage ]
    | last
    | if . == null then 0 else
        ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
      end' 2>/dev/null)
fi
used=${used:-0}
[ "$used" -gt "$size" ] && used=$size
left=$(( size - used ))

fmt() { # 117400 -> 117.4k, 200000 -> 200k
  if   [ "$1" -ge 1000000 ]; then printf '%d.%dM' $(( $1 / 1000000 )) $(( $1 % 1000000 / 100000 ))
  elif [ "$1" -ge 1000 ];    then printf '%d.%dk' $(( $1 / 1000 )) $(( $1 % 1000 / 100 ))
  else printf '%d' "$1"; fi | sed 's/\.0\([kM]\)$/\1/'
}
pct10=$(( used * 1000 / size ))                     # phần nghìn → in 1 số lẻ
pct_txt="$(( pct10 / 10 )).$(( pct10 % 10 ))%"

# ---- Màu thanh: chuyển liên tục theo đúng % (xanh → vàng → đỏ), không chia mức ----
# 0% (80,200,120) → 50% (235,200,70) → 100% (240,80,80)
if [ "$pct10" -le 500 ]; then
  t=$pct10;           r=$(( 80 + (235-80)*t/500 ));   g=200;                         b=$(( 120 + (70-120)*t/500 ))
else
  t=$(( pct10-500 )); r=$(( 235 + (240-235)*t/500 )); g=$(( 200 + (80-200)*t/500 )); b=$(( 70 + (80-70)*t/500 ))
fi
FG=$'\033[38;2;'"$r;$g;$b"'m'
EMPTY_RGB="60;60;70"
EFG=$'\033[38;2;'"$EMPTY_RGB"'m'
EBG=$'\033[48;2;'"$EMPTY_RGB"'m'
R=$'\033[0m'; DIM=$'\033[2m'; B=$'\033[1m'
C_MODEL=$'\033[38;2;180;140;255m'
C_DIR=$'\033[38;2;100;170;255m'
C_GIT=$'\033[38;2;130;210;140m'
C_COST=$'\033[38;2;240;200;110m'

# ---- Thanh 20 ô, chính xác 1/8 ô ----
# Ô dở: ký tự khối trái màu thanh trên nền màu ô trống → liền mạch, không có vạch lạ.
W=20
parts=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
eighths=$(( used * W * 8 / size ))
full=$(( eighths / 8 )); rem=$(( eighths % 8 ))
bar="$FG"
for ((i = 0; i < full; i++)); do bar+="█"; done
empty=$(( W - full ))
if [ "$rem" -gt 0 ]; then bar+="${EBG}${parts[$rem]}${R}"; empty=$(( empty - 1 )); fi
bar+="$EFG"
for ((i = 0; i < empty; i++)); do bar+="█"; done
bar+="$R"

# ---- Git: nhánh đọc thẳng .git/HEAD (nhanh); "*" (có thay đổi) chạy nền, nhớ 30 giây ----
# (git status trên /mnt/d của WSL mất ~2 giây → không được chạy trực tiếp)
git_part=""
d=$cwd
while [ -n "$d" ] && [ "$d" != "/" ] && [ ! -e "$d/.git" ]; do d=${d%/*}; done
if [ -n "$d" ] && [ -e "$d/.git" ]; then
  gitdir="$d/.git"
  [ -f "$gitdir" ] && gitdir=$(sed -n 's/^gitdir: //p' "$gitdir")
  head=$(<"$gitdir/HEAD") 2>/dev/null
  case "$head" in
    "ref: refs/heads/"*) branch=${head#ref: refs/heads/} ;;
    *) branch=${head:0:7} ;;
  esac
  cache="${TMPDIR:-/tmp}/claude-statusline-$(printf '%s' "$d" | md5sum | cut -c1-12)"
  now=$(date +%s)
  mtime=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
  if [ $(( now - mtime )) -gt 30 ]; then
    touch "$cache"
    ( s=$(git -C "$d" status --porcelain --untracked-files=no 2>/dev/null | head -n1)
      if [ -n "$s" ]; then echo "*" > "$cache"; else : > "$cache"; fi ) >/dev/null 2>&1 &
    disown 2>/dev/null
  fi
  dirty=$(<"$cache") 2>/dev/null
  git_part="  ${C_GIT}⎇ ${branch}${dirty}${R}"
fi

cost_part=""
[ -n "$cost" ] && cost_part="  ${C_COST}$(printf '$%.2f' "$cost")${R}"
warn=""
[ "$pct10" -ge 900 ] && warn="  ${FG}${B}⚠ almost full${R}"

printf '%s' \
  "${C_MODEL}${B}◆ ${model}${R}" \
  "  ${C_DIR}📁 ${cwd##*/}${R}" \
  "${git_part}" \
  "  ${bar}" \
  " ${FG}${B}${pct_txt}${R}" \
  " ${DIM}·${R} used ${FG}$(fmt "$used")${R}" \
  " ${DIM}·${R} left ${B}$(fmt "$left")${R}${DIM} / $(fmt "$size")${R}" \
  "${warn}${cost_part}"
