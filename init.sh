#!/usr/bin/env bash
[[ -n "$_ALPHA_ALPHA_TETRIS_SH" ]] && return 0
_ALPHA_ALPHA_TETRIS_SH=1

ATETRIS_D="$( cd "${BASH_SOURCE[0]%/*}" && pwd)"
alpha_tetris_draw() {
  center "${ACCENTC}$(get_icon "plug")  ${TEXTC}Alpha tetris active!${RESET}"
}

is_bin() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

init() {
  local bin chk data_d
  local -A ctx=()
  for bin in "tmux" "tput" "bash"; do 
    if is_bin "$bin"; then 
      chk="OK"
    else
      chk="FAIL"
    fi
    ctx["$bin"]="$chk"
  done
  data_d="$(get_opt "alpha-tetris" "data_d" "${XDG_DATA_HOME:-$HOME/.local/share}/alpha-tmux" )"
  data_d="${data_d/#\~/$HOME}"
  ctx["scores"]="$data_d/scores.yaml"
  if mkdir -p "$data_d" && touch "${ctx[scores]}"; then
    ctx["env"]="OK"
  else
    ctx["env"]="FAIL"
  fi
  ctx["bin_path"]="$ATETRIS_D/atetris.sh"
  if [[ -x "${ctx[bin_path]}" ]]; then 
    ctx["bin"]="OK"
  else
    ctx["bin"]="FAIL"
  fi
  start ctx
}

start() {
  local -n _ctx="$1"
  local key
  for key in "${!_ctx[@]}"; do
    if [[ "${_ctx[$key]}" == "FAIL" ]]; then
      pu_toast -t "aTetris" -d 2.0 "Preflight failed: $key"
      return 1
    fi
  done
  popped "" "aTetris" "d" 36 26 env ATETRIS_SCORES="${_ctx[scores]}" "${_ctx[bin_path]}"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && init "$@"
