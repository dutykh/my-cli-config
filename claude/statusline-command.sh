#!/usr/bin/env bash
# ~/.claude/statusline-command.sh — high-tech Claude Code status line
#
#  line 1  identity   : model · effort · window │ path │ git branch + status (+worktree) │ PR │ toolchain │ repo
#  line 2  telemetry  : context gauge │ prompt cache │ cost · wall time · lines │ 5h / 7d / spend rate limits
#  line 3  system     : load · mem · cpu (· battery) ┃ user@host · claude version · flags ┃ session ┃ clock
#
#  Config   : ~/.claude/statusline.conf   (bash syntax; every knob in the "defaults" block)
#  Preview  : bash ~/.claude/statusline-command.sh --demo [nerd|emoji|unicode] [COLUMNS]
#  Icons    : auto → Nerd Font glyphs when a Nerd Font is installed, otherwise emoji
#  Colours  : Okabe–Ito colour-blind-safe palette; truecolor with 256-colour fallback
#  Layout   : responsive — reads $COLUMNS (set by Claude Code) and drops segments on narrow terminals
#  Budget   : one jq call, cached git status, /proc reads → typically 30–50 ms

shopt -s nullglob

# ───────────────────────────── defaults ─────────────────────────────
ICONS=auto          # auto | nerd | emoji | unicode
THEME=auto          # auto | light | dark   (auto reads ~/.claude/settings.json)
LINES=3             # 1 | 2 | 3
RESPONSIVE=1        # shrink / drop segments when $COLUMNS is narrow
SHOW_GIT=1  SHOW_PR=1  SHOW_ENV=1  SHOW_REPO=1  SHOW_CACHE=1  SHOW_RATE=1
SHOW_SYSTEM=1  SHOW_HOST=1  SHOW_SESSION=1  SHOW_CLOCK=1
GAUGE_W=10          # width of the context gauge
RATE_W=5            # width of the rate-limit gauges
GIT_TIMEOUT=0.6     # seconds before giving up on git status
GIT_CACHE=4         # seconds to reuse the previous git status (keeps 1 s refreshes cheap)
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-statusline-${UID:-$(id -u)}"
CONF="${CLAUDE_STATUSLINE_CONF:-$HOME/.claude/statusline.conf}"
[[ -r "$CONF" ]] && . "$CONF"
mkdir -p "$STATE_DIR" 2>/dev/null

# ───────────────────────────── input ────────────────────────────────
demo_json() {
cat <<'JSON'
{"session_id":"demo","session_name":"Claude status line","model":{"id":"claude-fable-5-1","display_name":"Fable 5.1"},
 "workspace":{"current_dir":"/home/dds/workspace/CVDutykh","project_dir":"/home/dds/workspace/CVDutykh",
 "repo":{"host":"github.com","owner":"dutykh","name":"CVDutykh"}},
 "version":"2.1.278","effort":{"level":"xhigh"},"thinking":{"enabled":true},"fast_mode":false,
 "pr":{"number":42,"url":"https://github.com/dutykh/CVDutykh/pull/42","review_state":"approved"},
 "cost":{"total_cost_usd":2.7534,"total_duration_ms":246994,"total_api_duration_ms":345207,"total_lines_added":86,"total_lines_removed":1},
 "context_window":{"context_window_size":1000000,"used_percentage":10,
   "current_usage":{"input_tokens":32,"output_tokens":2,"cache_creation_input_tokens":1481,"cache_read_input_tokens":101675}},
 "prompt_cache":{"warm":true,"ttl":"1h","expires_at":EXP,"hit_ratio":0.89},
 "rate_limits":{"five_hour":{"used_percentage":1,"resets_at":R5},"seven_day":{"used_percentage":15,"resets_at":R7}}}
JSON
}
if [[ "${1:-}" == "--demo" ]]; then
  [[ -n "${2:-}" ]] && ICONS=$2
  [[ -n "${3:-}" ]] && COLUMNS=$3
  printf -v _now '%(%s)T' -1
  input=$(demo_json | sed "s/EXP/$((_now+3500))/; s/R5/$((_now+14000))/; s/R7/$((_now+190000))/")
else
  input=$(cat)
fi

# One jq pass → newline-separated fields → array  (null/absent → "")
mapfile -t F < <(printf '%s' "$input" | jq -r '
  def s: if . == null then "" else tostring end;
  [ .model.display_name, .model.id, .session_id,
    (.workspace.current_dir // .cwd), .workspace.project_dir,
    .workspace.repo.host, .workspace.repo.owner, .workspace.repo.name,
    (.workspace.git_worktree // .worktree.name),
    .version, .session_name, .effort.level, .thinking.enabled, .fast_mode,
    .output_style.name, .vim.mode, .agent.name,
    .cost.total_cost_usd, .cost.total_duration_ms, .cost.total_api_duration_ms,
    .cost.total_lines_added, .cost.total_lines_removed,
    .context_window.context_window_size, .context_window.used_percentage,
    ((.context_window.current_usage // {}) | ((.input_tokens//0)+(.cache_creation_input_tokens//0)+(.cache_read_input_tokens//0))),
    .exceeds_200k_tokens,
    .prompt_cache.warm, .prompt_cache.ttl, .prompt_cache.expires_at, .prompt_cache.hit_ratio,
    .rate_limits.five_hour.used_percentage, .rate_limits.five_hour.resets_at,
    .rate_limits.seven_day.used_percentage, .rate_limits.seven_day.resets_at,
    .rate_limits.spend_limit.used_percentage,
    .pr.number, .pr.url, .pr.review_state, .pr.kind
  ] | map(s) | .[]' 2>/dev/null)

model=${F[0]:-Claude}  model_id=${F[1]}  sid=${F[2]:-nosession}
cwd=${F[3]:-$PWD}      proj=${F[4]}
repo_host=${F[5]}  repo_owner=${F[6]}  repo_name=${F[7]}  worktree=${F[8]}
version=${F[9]}  session=${F[10]}  effort=${F[11]}  thinking=${F[12]}  fast=${F[13]}
ostyle=${F[14]}  vim=${F[15]}  agent=${F[16]}
cost=${F[17]:-0}  dur_ms=${F[18]:-0}  api_ms=${F[19]:-0}  ladd=${F[20]:-0}  ldel=${F[21]:-0}
ctx_size=${F[22]:-0}  ctx_pct=${F[23]}  ctx_used=${F[24]:-0}  over200k=${F[25]}
c_warm=${F[26]}  c_ttl=${F[27]}  c_exp=${F[28]}  c_hit=${F[29]}
r5=${F[30]}  r5_at=${F[31]}  r7=${F[32]}  r7_at=${F[33]}  rspend=${F[34]}
pr_num=${F[35]}  pr_url=${F[36]}  pr_state=${F[37]}  pr_kind=${F[38]}

printf -v NOW '%(%s)T' -1
printf -v CLOCK '%(%H:%M:%S)T' -1
W=${COLUMNS:-200}

# responsive tiers (only when the user has not turned it off)
if (( RESPONSIVE )); then
  if   (( W < 80  )); then LINES=$(( LINES < 2 ? LINES : 2 )); SHOW_REPO=0 SHOW_ENV=0 SHOW_PR=0 SHOW_CACHE=0 SHOW_RATE=0; GAUGE_W=5
  elif (( W < 110 )); then SHOW_REPO=0 SHOW_CACHE=0 SHOW_HOST=0; GAUGE_W=6 RATE_W=3
  elif (( W < 150 )); then SHOW_REPO=0; GAUGE_W=8 RATE_W=4
  fi
fi

# ───────────────────────────── theme ────────────────────────────────
claude_theme() {   # first "theme" value found in Claude's config files (settings.json wins)
  local f v
  for f in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" "$HOME/.claude/settings.json" "$HOME/.claude.json"; do
    [[ -r $f ]] || continue
    v=$(grep -oE '"theme"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null | head -n1 | sed -E 's/.*"([^"]*)"$/\1/')
    [[ -n $v ]] && { printf '%s' "$v"; return; }
  done
}
if [[ $THEME == auto ]]; then
  ct=$(claude_theme)
  case $ct in
    light*) THEME=light ;;
    dark*)  THEME=dark ;;
    *)      # no Claude theme → terminal hint: COLORFGBG="fg;bg" with a light background code
            case ${COLORFGBG:-} in *";15"|*";7") THEME=light ;; *) THEME=dark ;; esac ;;
  esac
fi
TC=0; [[ "${COLORTERM:-}" =~ (truecolor|24bit) || "${TERM_PROGRAM:-}" == zed || -n "${WARP_IS_LOCAL_SHELL_SESSION:-}" ]] && TC=1

# Okabe–Ito palette (colour-blind safe) + neutrals.  name → "r;g;b" / xterm-256 index
#   structure (blue gradient): navy → blue → azure → sky → ice, steel for secondary pills
#   semantics (Okabe–Ito):      sky = fine, orange = watch, verm = critical, green/verm = lines added/removed
declare -A RGB=( [navy]="20;60;122" [blue]="0;114;178" [azure]="46;139;192" [sky]="86;180;233" [ice]="191;227;247"
                 [steel]="74;111;165" [deep]="16;33;58" [deep2]="30;53;86" [frost]="141;180;220"
                 [green]="0;158;115" [orange]="230;159;0" [verm]="213;94;0" [yellow]="240;228;66" [amber]="163;95;0" [brick]="176;70;0"
                 [ink]="24;28;36" [paper]="240;243;247" [mist]="216;222;233" [gray]="100;118;150" [white]="255;255;255" )
declare -A IDX=( [navy]=24 [blue]=25 [azure]=32 [sky]=74 [ice]=153 [steel]=67 [deep]=234 [deep2]=236 [frost]=110
                 [green]=36 [orange]=214 [verm]=166 [yellow]=221 [amber]=130 [brick]=130
                 [ink]=233 [paper]=255 [mist]=253 [gray]=60 [white]=15 )
declare -A FG BG
for k in "${!RGB[@]}"; do
  if ((TC)); then printf -v "FG[$k]" '\e[38;2;%sm' "${RGB[$k]}"; printf -v "BG[$k]" '\e[48;2;%sm' "${RGB[$k]}"
  else            printf -v "FG[$k]" '\e[38;5;%sm' "${IDX[$k]}"; printf -v "BG[$k]" '\e[48;5;%sm' "${IDX[$k]}"; fi
done
R=$'\e[0m'  BOLD=$'\e[1m'  DIM=$'\e[2m'
# HUD strip: deep navy with ice text on both themes; muted text steel-blue (light) / frost (dark)
if [[ $THEME == light ]]; then HUD_BG=${BG[deep]}  HUD_FG=${FG[ice]} MUTED=${FG[gray]}  TXT=${FG[navy]}
else                           HUD_BG=${BG[deep2]} HUD_FG=${FG[ice]} MUTED=${FG[frost]} TXT=${FG[ice]}; fi
link() { printf '\e]8;;%s\a%s\e]8;;\a' "$1" "$2"; }   # OSC 8 hyperlink
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }   # GNU / BSD
if command -v timeout >/dev/null; then TMO=(timeout -k 0.1 "$GIT_TIMEOUT")
elif command -v gtimeout >/dev/null; then TMO=(gtimeout -k 0.1 "$GIT_TIMEOUT"); else TMO=(); fi

# ───────────────────────────── icons ────────────────────────────────
if [[ $ICONS == auto ]]; then
  ICONS=emoji
  det="$STATE_DIR/nerd-detect"
  if [[ -f $det ]] && (( NOW - $(mtime "$det") < 3600 )); then
    read -r n < "$det"
  else
    n=0
    grep -qi 'nerd' "$HOME/.config/zed/settings.json" 2>/dev/null && n=1
    (( n == 0 )) && command -v fc-list >/dev/null && fc-list 2>/dev/null | grep -qi 'nerd' && n=1
    (( n == 0 )) && ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi 'nerd' && n=1
    (( n == 0 )) && find "$HOME/.local/share/fonts" "$HOME/.fonts" /usr/local/share/fonts /usr/share/fonts -maxdepth 3 -iname '*nerd*' -print -quit 2>/dev/null | grep -q . && n=1
    printf '%s\n' "$n" > "$det"
  fi
  (( n == 1 )) && ICONS=nerd
fi
declare -A I
case $ICONS in
  nerd)
    I=( [model]=$'' [dir]=$'' [git]=$'' [wt]=$'' [pr]=$'' [py]=$'' [node]=$''
        [typst]=$'' [rust]=$'' [julia]=$'' [tex]=$'' [github]=$'' [gitlab]=$''
        [repo]=$'' [ctx]=$'' [cache]=$'' [cost]=$'' [clock]=$'' [rate]=$''
        [sys]=$'' [think]=$'' [fast]=$'' [vim]=$'' [agent]=$'' [session]=$''
        [hour]=$'' [bat]=$'' [warn]=$'' )
    SEP_L=$'' SEP_M=$'' SEP_R=$'' G_ON='━' G_OFF='╌' ;;
  emoji)
    I=( [model]='🤖' [dir]='📂' [git]='🌿' [wt]='🌳' [pr]='🔀' [py]='🐍' [node]='⬢' [typst]='📝' [rust]='🦀' [julia]='jl'
        [tex]='📄' [github]='🐙' [gitlab]='🦊' [repo]='🔗' [ctx]='🧠' [cache]='⚡' [cost]='💰' [clock]='⏱' [rate]='📊'
        [sys]='🖥' [think]='💭' [fast]='🚀' [vim]='vim' [agent]='🕵' [session]='🏷' [hour]='⏳' [bat]='🔋' [warn]='⚠' )
    SEP_L='▐' SEP_M='▐' SEP_R='▌' G_ON='▰' G_OFF='▱' ;;
  *)
    I=( [model]='◈' [dir]='▤' [git]='⎇' [wt]='⌂' [pr]='⇄' [py]='py' [node]='⬢' [typst]='typ' [rust]='rs' [julia]='jl'
        [tex]='tex' [github]='◉' [gitlab]='◉' [repo]='◉' [ctx]='◐' [cache]='⚡' [cost]='$' [clock]='⏱' [rate]='≋'
        [sys]='⚙' [think]='✧' [fast]='⇶' [vim]='vim' [agent]='☍' [session]='⌗' [hour]='⧗' [bat]='▮' [warn]='⚠' )
    SEP_L='▐' SEP_M='▐' SEP_R='▌' G_ON='▰' G_OFF='▱' ;;
esac

# ───────────────────────────── helpers ──────────────────────────────
fmt_tok() { local t=${1%.*}; if (( t >= 1000000 )); then local d=$(( (t%1000000)/100000 )); (( d )) && printf '%d.%dM' $((t/1000000)) $d || printf '%dM' $((t/1000000));
            elif (( t >= 1000 )); then printf '%dk' $((t/1000)); else printf '%d' "$t"; fi; }
fmt_dur() { local s=$(( ${1%.*} / 1000 ));
            if (( s >= 3600 )); then printf '%dh%02dm' $((s/3600)) $((s%3600/60));
            elif (( s >= 60 )); then printf '%dm%02ds' $((s/60)) $((s%60)); else printf '%ds' "$s"; fi; }
fmt_left() { local s=$1; (( s <= 0 )) && { printf 'now'; return; }
            if (( s >= 86400 )); then printf '%dd%dh' $((s/86400)) $((s%86400/3600));
            elif (( s >= 3600 )); then printf '%dh%02dm' $((s/3600)) $((s%3600/60)); else printf '%dm' $((s/60)); fi; }
pct_col() { local p=${1%.*}; if (( p >= 85 )); then echo verm; elif (( p >= 60 )); then echo orange; else echo sky; fi; }
val_col() { local c; c=$(pct_col "$1")   # same thresholds, darkened for plain text on a light terminal
            if [[ $THEME == light ]]; then case $c in sky) c=blue;; orange) c=amber;; verm) c=brick;; esac; fi; echo "$c"; }
gauge()   { local p=${1%.*} w=$2 f i s=''; f=$(( (p*w + 50) / 100 )); (( f > w )) && f=$w; (( f < 0 )) && f=0
            for ((i=0;i<f;i++)); do s+=$G_ON; done; for ((i=f;i<w;i++)); do s+=$G_OFF; done; printf '%s' "$s"; }
short_path() { local p=$1; [[ $p == "$HOME"* ]] && p="~${p#"$HOME"}"
            local IFS=/; read -ra a <<< "$p"; local n=${#a[@]}
            if (( n <= 3 || W >= 150 )); then printf '%s' "$p"; else printf '%s/…/%s/%s' "${a[0]:-}" "${a[n-2]}" "${a[n-1]}"; fi; }

# powerline-style pills for line 1
L1='' prev=''
seg() { # seg <bg> <fg> <text>
  local b=$1 f=$2 t=$3
  if [[ -z $prev ]]; then L1+="${FG[$b]}${SEP_L}"; else L1+="${BG[$b]}${FG[$prev]}${SEP_M}"; fi
  L1+="${BG[$b]}${FG[$f]} ${t} "; prev=$b
}
seg_end() { [[ -n $prev ]] && L1+="${R}${FG[$prev]}${SEP_R}${R}"; }

# ═════════════════════════════ LINE 1 ═══════════════════════════════
rb="${BG[navy]}${FG[white]}"
m="${I[model]} ${BOLD}${model}${R}${rb}"
[[ -n $effort ]]     && m+=" ${DIM}${effort}${R}${rb}"
(( ctx_size > 0 ))   && m+=" ${DIM}$(fmt_tok "$ctx_size")${R}${rb}"
[[ $fast == true ]]  && m+=" ${I[fast]}"
seg navy white "$m"

seg blue white "${I[dir]} $(short_path "$cwd")"

# git (cached per session for GIT_CACHE seconds)
if (( SHOW_GIT )) && [[ -d $cwd ]]; then
  gc="$STATE_DIR/git-${sid}"; gs=''; ts=0; gcwd=''
  [[ -s $gc ]] && { read -r ts gcwd; } < "$gc"
  if [[ $gcwd == "$cwd" ]] && (( NOW - ts < GIT_CACHE )); then
    gs=$(tail -n +2 "$gc")
  else
    gs=$("${TMO[@]}" git --no-optional-locks -C "$cwd" status --porcelain=v2 --branch --show-stash 2>/dev/null)
    printf '%s %s\n%s\n' "$NOW" "$cwd" "$gs" > "$gc"
  fi
  if [[ -n $gs ]]; then
    branch='' oid='' ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicts=0 stash=0
    while IFS= read -r line; do
      case $line in
        '# branch.head '*)  branch=${line#'# branch.head '} ;;
        '# branch.oid '*)   oid=${line#'# branch.oid '}; oid=${oid:0:7} ;;
        '# branch.ab '*)    set -- ${line#'# branch.ab '}; ahead=${1#+}; behind=${2#-} ;;
        '# stash '*)        stash=${line#'# stash '} ;;
        '1 '*|'2 '*)        xy=${line:2:2}; [[ ${xy:0:1} != . ]] && ((staged++)); [[ ${xy:1:1} != . ]] && ((modified++)) ;;
        'u '*)              ((conflicts++)) ;;
        '? '*)              ((untracked++)) ;;
      esac
    done <<< "$gs"
    [[ $branch == '(detached)' || -z $branch ]] && branch="➦ ${oid}"
    gcol=sky; (( staged + modified + untracked > 0 )) && gcol=orange; (( conflicts > 0 )) && gcol=verm
    gfg=ink; [[ $gcol == verm ]] && gfg=white
    g="${I[git]} ${BOLD}${branch}${R}${BG[$gcol]}${FG[$gfg]}"
    [[ -n $worktree ]]  && g+=" ${I[wt]} ${worktree}"
    (( staged    > 0 )) && g+=" ●${staged}"
    (( modified  > 0 )) && g+=" ✚${modified}"
    (( untracked > 0 )) && g+=" …${untracked}"
    (( conflicts > 0 )) && g+=" ✖${conflicts}"
    (( ahead     > 0 )) && g+=" ⇡${ahead}"
    (( behind    > 0 )) && g+=" ⇣${behind}"
    (( stash     > 0 )) && g+=" ⚑${stash}"
    seg "$gcol" "$gfg" "$g"
  fi
fi

# open pull / merge request (clickable where the terminal supports OSC 8)
if (( SHOW_PR )) && [[ -n $pr_num ]]; then
  case $pr_state in approved) pc=sky pf=ink ps='✓';; changes_requested) pc=verm pf=white ps='✗';; draft) pc=steel pf=white ps='◌';; *) pc=orange pf=ink ps='◔';; esac
  lbl="#${pr_num}"; [[ $pr_kind == mr ]] && lbl="!${pr_num}"
  [[ -n $pr_url ]] && lbl=$(link "$pr_url" "$lbl")
  seg "$pc" "$pf" "${I[pr]} ${lbl} ${ps}${pr_state:+ ${DIM}${pr_state//_/ }${R}${BG[$pc]}${FG[$pf]}}"
fi

# toolchain / environment
if (( SHOW_ENV )); then
  e=''; pb="${BG[azure]}${FG[white]}"
  if [[ -n ${VIRTUAL_ENV:-} ]]; then
    vname=${VIRTUAL_ENV##*/}; pf="$STATE_DIR/py-${vname}"
    if [[ -s $pf ]]; then read -r pyv < "$pf"; else pyv=$("$VIRTUAL_ENV/bin/python" --version 2>&1 | awk '{print $2}'); printf '%s\n' "$pyv" > "$pf"; fi
    e+="${I[py]} ${vname}${pyv:+ ${DIM}${pyv}${R}${pb}}"
  elif [[ -n ${CONDA_DEFAULT_ENV:-} ]]; then e+="${I[py]} ${CONDA_DEFAULT_ENV}"; fi
  if [[ -d $cwd ]] && cd "$cwd" 2>/dev/null; then
    t=(*.typ); (( ${#t[@]} )) && e+="${e:+ }${I[typst]} typst"
    [[ -f Cargo.toml ]]   && e+="${e:+ }${I[rust]} rust"
    [[ -f Project.toml ]] && e+="${e:+ }${I[julia]} julia"
    t=(*.tex); (( ${#t[@]} )) && e+="${e:+ }${I[tex]} tex"
    if [[ -f package.json ]]; then
      nf="$STATE_DIR/node-version"
      if [[ -s $nf ]] && (( NOW - $(mtime "$nf") < 86400 )); then read -r nv < "$nf"; else nv=$(node --version 2>/dev/null); printf '%s\n' "$nv" > "$nf"; fi
      e+="${e:+ }${I[node]} ${nv#v}"
    fi
  fi
  [[ -n $e ]] && seg azure white "$e"
fi

# remote repository
if (( SHOW_REPO )) && [[ -n $repo_name ]]; then
  ri=${I[repo]}; [[ $repo_host == github* ]] && ri=${I[github]}; [[ $repo_host == gitlab* ]] && ri=${I[gitlab]}
  seg steel white "${ri} ${repo_owner}/${repo_name}"
fi
seg_end

# ═════════════════════════════ LINE 2 ═══════════════════════════════
L2=''; hb="${HUD_BG}${HUD_FG}"
hud() { L2+="${hb}$1"; }
div="${HUD_BG}${FG[steel]} │ "

# context gauge (input-only formula, same as Claude's used_percentage)
p=${ctx_pct%.*}; p=${p:-0}; (( ctx_size > 0 && ${ctx_used%.*} > 0 )) && p=$(( ${ctx_used%.*} * 100 / ctx_size ))
c=$(pct_col "$p")
if (( ctx_size > 0 )); then
  hud " ${I[ctx]} ctx ${FG[$c]}$(gauge "$p" "$GAUGE_W") ${BOLD}${p}%${R}${hb} ${DIM}$(fmt_tok "$ctx_used")/$(fmt_tok "$ctx_size")${R}"
else
  hud " ${I[ctx]} ctx ${DIM}—${R}"
fi
[[ $over200k == true ]] && hud "${FG[verm]} ${I[warn]}>200k"

# prompt cache
if (( SHOW_CACHE )) && [[ -n $c_warm ]]; then
  if [[ $c_warm == true ]]; then ci="${FG[sky]}● warm"; else ci="${FG[orange]}○ cold"; fi
  hit=''; [[ -n $c_hit ]] && printf -v hit '%d%%' "$(awk "BEGIN{printf \"%d\", $c_hit*100}")"
  left=''; [[ -n $c_exp && $c_warm == true ]] && left=" ${I[hour]}$(fmt_left $(( ${c_exp%.*} - NOW )))"
  hud "${div}${HUD_FG}${I[cache]} cache ${ci}${HUD_FG}${hit:+ ${hit}}${DIM}${left}${c_ttl:+ ttl ${c_ttl}}${R}"
fi

# cost · wall time · lines
printf -v costf '%.2f' "$cost"
hud "${div}${HUD_FG}${I[cost]} ${FG[white]}${BOLD}\$${costf}${R}${hb} ${I[clock]} $(fmt_dur "$dur_ms") ${FG[green]}+${ladd}${FG[verm]} −${ldel}${R}"

# rate limits (windows vanish from the JSON once they reset — each is optional)
if (( SHOW_RATE )) && [[ -n $r5 || -n $r7 || -n $rspend ]]; then
  s=''
  if [[ -n $r5 ]]; then c=$(pct_col "$r5"); printf -v t '%(%H:%M)T' "${r5_at%.*}"
     s+="5h ${FG[$c]}$(gauge "$r5" "$RATE_W") ${r5%.*}%${HUD_FG} ${DIM}↻${t}${R}${hb}"; fi
  if [[ -n $r7 ]]; then c=$(pct_col "$r7"); printf -v t '%(%a %H:%M)T' "${r7_at%.*}"
     s+="${s:+  }7d ${FG[$c]}$(gauge "$r7" "$RATE_W") ${r7%.*}%${HUD_FG} ${DIM}↻${t}${R}${hb}"; fi
  if [[ -n $rspend ]]; then c=$(pct_col "$rspend"); s+="${s:+  }\$ ${FG[$c]}${rspend%.*}%${R}${hb}"; fi
  hud "${div}${HUD_FG}${I[rate]} ${s}"
fi
L2+="${HUD_BG} ${R}"

# ═════════════════════════════ LINE 3 ═══════════════════════════════
L3=''
dot="${MUTED} · "
bar="${MUTED}  ┃  "
if (( SHOW_SYSTEM )); then
  if [[ -r /proc/loadavg ]]; then                                   # Linux
    read -r l1 _ < /proc/loadavg
    ncpu=$(grep -c ^processor /proc/cpuinfo 2>/dev/null); ncpu=${ncpu:-1}
    mt=0 ma=0; while read -r k v _; do case $k in MemTotal:) mt=$v;; MemAvailable:) ma=$v;; esac; done < /proc/meminfo
    mp=0; (( mt > 0 )) && mp=$(( (mt - ma) * 100 / mt ))
    # cpu % = busy share of /proc/stat since the previous refresh of this session
    read -r _ u n s idle io irq sirq st _ < /proc/stat
    tot=$(( u+n+s+idle+io+irq+sirq+st )); idl=$(( idle+io )); cpu='—' cpv=0
    cf="$STATE_DIR/cpu-${sid}"
    if [[ -s $cf ]]; then read -r pt pi < "$cf"; dt=$(( tot - pt )); (( dt > 0 )) && { cpv=$(( (dt - (idl - pi)) * 100 / dt )); cpu="${cpv}%"; }; fi
    printf '%s %s\n' "$tot" "$idl" > "$cf"
  else                                                              # macOS / BSD: load only
    l1=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}'); l1=${l1:-0}
    ncpu=$(sysctl -n hw.ncpu 2>/dev/null); ncpu=${ncpu:-1}; mp='' cpu='' cpv=0
  fi
  lp=$(awk "BEGIN{printf \"%d\", $l1*100/$ncpu}")
  L3+="${MUTED}${I[sys]} load ${FG[$(val_col "$lp")]}${l1}${MUTED}/${ncpu}"
  [[ -n $mp ]]  && L3+="${dot}mem ${FG[$(val_col "$mp")]}${mp}%"
  [[ -n $cpu ]] && L3+="${dot}cpu ${FG[$(val_col "$cpv")]}${cpu}"
  L3+="${R}"
  for b in /sys/class/power_supply/BAT*/capacity; do read -r cap < "$b"; bc=$(val_col 0); (( cap < 50 )) && bc=$(val_col 70); (( cap < 20 )) && bc=$(val_col 90)
      L3+="${dot}${I[bat]} ${FG[$bc]}${cap}%${R}"; break; done
fi
if (( SHOW_HOST )); then
  L3+="${L3:+$bar}${MUTED}${USER:-$(id -un)}@${HOSTNAME:-$(hostname -s)}${version:+${dot}claude ${version}}"
  [[ $thinking == true ]] && L3+="${dot}${I[think]} thinking"
  [[ $fast == true ]]     && L3+="${dot}${FG[$(val_col 70)]}${I[fast]} fast${MUTED}"
  [[ -n $ostyle && $ostyle != default ]] && L3+="${dot}style ${ostyle}"
  [[ -n $vim ]]   && L3+="${dot}${I[vim]} ${TXT}${vim}${MUTED}"
  [[ -n $agent ]] && L3+="${dot}${I[agent]} ${agent}"
  L3+="${R}"
fi
(( SHOW_SESSION )) && [[ -n $session ]] && L3+="${L3:+$bar}${MUTED}${I[session]} ${TXT}${session}${R}"
(( SHOW_CLOCK )) && L3+="${L3:+$bar}${MUTED}${CLOCK}${R}"

# ───────────────────────────── output ───────────────────────────────
case $LINES in
  1) printf '%s\n' "$L1" ;;
  2) printf '%s\n%s\n' "$L1" "$L2" ;;
  *) printf '%s\n%s\n%s\n' "$L1" "$L2" "$L3" ;;
esac
