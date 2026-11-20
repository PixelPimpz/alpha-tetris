#!/usr/bin/env bash
[[ -n "$_ALPHA_ATETRIS_SH" ]] && return 0
_ALPHA_ATETRIS_SH=1

## SETUP
W=10 H=20 CELL="  " RESET=$'\e[0m'
COLORS=("" $'\e[48;5;51m' $'\e[48;5;226m' $'\e[48;5;129m' $'\e[48;5;46m' $'\e[48;5;196m' $'\e[48;5;21m' $'\e[48;5;208m')
SHAPES=("" "-1,0 0,0 1,0 2,0" "0,0 1,0 0,1 1,1" "-1,0 0,0 1,0 0,1" "0,0 1,0 -1,1 0,1" "-1,0 0,0 0,1 1,1" "-1,0 0,0 1,0 1,1" "-1,0 0,0 1,0 -1,1")
BOARD=()
for (( i=0; i < W*H; i++ )); do
  BOARD[i]="0"
done
CURSHAPE="" PX=0 PY=0 PTYPE=1 NEXT_TYPE=$(( RANDOM % 7 + 1 ))
SCORE=0 LINES=0 LEVEL=1

trap 'stty echo 2>/dev/null; printf "\e[?25h\e[0m"' EXIT INT TERM
stty -echo 2>/dev/null; printf '\e[?25l\e[2J'

## FUNCTIONS
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

  :
}

lock() {
  :
}

rm_line() {
  :
}

draw() {
  :
}

main() {
  :
}
