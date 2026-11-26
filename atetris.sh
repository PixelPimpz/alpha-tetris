#!/usr/bin/env bash
## Tetris in pure BASH
#   A tetris game inspired by and a bit based on
#   Dave Eddy of ysap.sh (the CURL-able BASH 
#   scripting guide and site
#
[[ -n "$_ALPHA_ATETRIS_SH" ]] && return 0
_ALPHA_ATETRIS_SH=1

## SETUP
W=10 H=20 
CELL="  " 
RESET=$'\e[0m'
COLORS=("" $'\e[48;5;51m' $'\e[48;5;226m' $'\e[48;5;129m' $'\e[48;5;46m' $'\e[48;5;196m' $'\e[48;5;21m' $'\e[48;5;208m')
SHAPES=("" "-1,0 0,0 1,0 2,0" "0,0 1,0 0,1 1,1" "-1,0 0,0 1,0 0,1" "0,0 1,0 -1,1 0,1" "-1,0 0,0 0,1 1,1" "-1,0 0,0 1,0 1,1" "-1,0 0,0 1,0 -1,1")
BOARD=()
CURSHAPE="" PX=0 PY=0 PTYPE=1 NEXT_TYPE=$(( RANDOM % 7 + 1 ))
SCORE=0 CLEARED=0 LEVEL=1

## DEFINE BOARD
for (( i=0; i < W*H; i++ )); do
  BOARD[i]="0"
done


trap 'stty echo 2>/dev/null; printf "\e[?25h\e[0m"' EXIT INT TERM
stty -echo 2>/dev/null; printf '\e[?25l\e[2J'

## FUNCTIONS
get_color() {
  local format xrgb="${1:-FFFFFF}"
  printf -v format '\e[48;2;%d;%d;%dm' "0x${xrgb:0:2}" "0x${xrgb:3:2}" "0x${xrgb:5:2}"
  printf "%s" "$format"
}

placeable() {
  local px="${1:-0}" py="${2:-0}" shape="$3"
  local cell dx dy x y
  for cell in $shape; do
    dx="${cell%,*}" dy="${cell#*,}"
    x=$(( dx + px ))  y=$(( dy + py ))
    if (( x < 0 || x >= W || y >= H )) || (( y >= 0 && BOARD[ y * W + x ] != 0 )); then
      return 1
    fi
  done
  return 0
}

spawn() {
  PTYPE="$NEXT_TYPE"
  NEXT_TYPE=$(( RANDOM % 7 + 1 ))
  CURSHAPE="${SHAPES[$PTYPE]}"
  PX=4 PY=0
  placeable "$PX" "$PY" "$CURSHAPE" || return 1
}

rotate() {
  (( PTYPE == 2 )) && return 0
  local dir="${1:-cw}"
  local cell dx dy rot=""
  for cell in $CURSHAPE; do
    dx="${cell%,*}"; dy="${cell#*,}"
    if [[ "$dir" == "ccw" ]]; then
      rot+="${dy},$((-dx)) "
    else
      rot+="$((-dy)),${dx} "
    fi
  done
  placeable "$PX" "$PY" "$rot" && CURSHAPE="$rot"
}

lock() {
  local cell dx dy x y
  for cell in $CURSHAPE; do
    dx="${cell%,*}"; dy="${cell#*,}"
    x=$(( PX + dx )); y=$(( PY + dy ))
    (( y >= 0 )) && BOARD[y * W + x]="$PTYPE"
  done
}

rm_line() {
  local y x ry full cleared=0 pts=(0 100 300 500 800)
  for (( y = H - 1; y >= 0; y-- )); do
    full=1
    for (( x = 0; x <= W - 1; x++ )); do
      if (( BOARD[y * W + x] == 0 )); then
        full=0
        break
      fi
    done
    if (( full == 1 )); then
      (( cleared++ ))
      for (( ry = y; ry > 0; ry-- )); do
        for (( x = 0; x < W; x++ )); do
           BOARD[ry * W + x]="${BOARD[(ry - 1) * W + x]}"
        done
      done
      for (( x = 0; x < W; x++ )); do BOARD[x]=0; done
      (( y++ ))
    fi
  done
  if (( cleared > 0 )); then
    (( CLEARED += cleared ))
    LEVEL=$(( CLEARED / 10 + 1 ))
    (( SCORE += pts[cleared] * LEVEL ))
  fi
}

draw() {
  local dx dy x y c hud
  local frame cell view=("${BOARD[@]}")
  for cell in $CURSHAPE; do
    dx="${cell%,*}"; dy="${cell#*,}"
    x=$(( PX + dx )); y=$(( PY + dy ))
    (( y >= 0 && y < H )) && view[y * W + x]="$PTYPE"
  done
  frame=$'\e[H'
  frame+=" ╭────────────────────╮"$'\n'
  for (( y=0; y < H; y++ )); do
    frame+=" |"
    for (( x = 0; x < W; x++ )); do
      c="${view[y * W + x]}"
      if (( c > 0 )); then 
        frame+="${COLORS[$c]}${CELL}${RESET}"
      else 
        frame+="  "
      fi
    done
    frame+="|"
    case "$y" in 
      1) frame+="   SCORE" ;;
      2) printf -v hud "  %06d" "$SCORE"; frame+="$hud" ;;
      4) frame+="   LINES" ;;
      5) printf -v hud "  %d" "$CLEARED"; frame+="$hud" ;;
      7) frame+="   LEVEL" ;;
      8) printf -v hud "  %d" "$LEVEL"; frame+="$hud" ;;
      10) frame+="   NEXT" ;;
      12|13)
        local ny=$(( y - 12 )) nx hit
        frame+="  "
        for (( nx = -1; nx <= 2; nx++ )); do
          hit=0
          for cell in ${SHAPES[$NEXT_TYPE]}; do
            [[ "$cell" == "${nx},${ny}" ]] && { hit=1; break; }
          done
          if (( hit )); then
            frame+="${COLORS[$NEXT_TYPE]}${CELL}${RESET}"
          else
            frame+="  "
          fi
        done ;;
    esac
    frame+=$'\e[K\n'
  done
  frame+=" ╰────────────────────╯"$'\e[K\n'
  frame+="  ←/→ ↓ ↑/z  Space:Drop  q:Quit"$'\e[K'
  printf "%s" "$frame"
}

main() {
  local key rest tick
  local ticks=("" "1.20" "1.05" "0.90" "0.75" "0.62" "0.50" "0.40" "0.30" "0.22")
  spawn || return 0
  # main game loop
  while true; do
    draw
    tick="${ticks[$(( LEVEL > 9 ? 9 : LEVEL ))]}"
    if IFS= read -rsn1 -t "$tick" key; then
      if [[ "$key" == $'\x1b' ]]; then
        IFS= read -rsn2 -t 0.02 rest
        case "$rest" in
          "[A") key="UP" ;;
          "[B") key="DOWN" ;;
          "[C") key="RIGHT" ;;
          "[D") key="LEFT" ;;
          "")   key="ESC" ;;
        esac
      fi
      case "$key" in
        LEFT|a|h) 
          placeable $(( PX - 1 )) "$PY" "$CURSHAPE" && (( PX-- )) ;;
        RIGHT|d|l) 
          placeable $(( PX + 1 )) "$PY" "$CURSHAPE" && (( PX++ )) ;;
        DOWN|s|j) 
          placeable "$PX" $(( PY + 1 )) "$CURSHAPE" && (( PY++ )) ;;
        UP|w|k)
          rotate cw ;;
        z) rotate ccw ;;
        " ") 
          while placeable "$PX" $(( PY + 1 )) "$CURSHAPE"; do 
            (( PY++ )) 
          done
          lock
          rm_line
          spawn || break ;;
        q|Q|ESC) 
          break ;;
      esac
    else
      if placeable "$PX" $(( PY + 1 )) "$CURSHAPE"; then 
        (( PY++ ))
      else
        lock
        rm_line
        if ! spawn; then
          draw
          printf "printf \n  GAME OVER! Score: %d" "$SCORE"
          read -rsn1; break
        fi
      fi
    fi
  done
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
