function __promptline_git_branch_status_sha {
  [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]] || return 1

  local added_ws=0

  local ws=""
  local out=""

  local branch
  local branch_symbol=" "
  if branch=$( { git symbolic-ref --quiet HEAD || git rev-parse --short HEAD; } 2>/dev/null ); then
    branch=${branch##*/}
    out="$ws${branch_symbol}${branch:-unknown}"
    ws=" "
    [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#branch_symbol} - 1 ))
  fi

  local added_symbol="●"
  local unmerged_symbol=" "
  local modified_symbol=" "
  local clean_symbol=" "
  local has_untracked_files_symbol=""

  local ahead_symbol=""
  local behind_symbol=""

  local unmerged_count=0 modified_count=0 has_untracked_files=0 added_count=0 is_clean=""

  set -- $(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
  local behind_count=$1
  local ahead_count=$2

  # Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R), changed (T), Unmerged (U), Unknown (X), Broken (B)
  while read line; do
    case "$line" in
      M*) modified_count=$(( $modified_count + 1 )) ;;
      U*) unmerged_count=$(( $unmerged_count + 1 )) ;;
    esac
  done < <(git diff --name-status)

  while read line; do
    case "$line" in
      *) added_count=$(( $added_count + 1 )) ;;
    esac
  done < <(git diff --name-status --cached)

  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    has_untracked_files=1
  fi

  if [ $(( unmerged_count + modified_count + has_untracked_files + added_count )) -eq 0 ]; then
    is_clean=1
  fi

  #local ws=""
  [[ $ahead_count -gt 0 ]]         && { out="$out$ws$ahead_symbol$ahead_count"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#ahead_symbol} - 1 )); }
  [[ $behind_count -gt 0 ]]        && { out="$out$ws$behind_symbol$behind_count"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#behind_symbol} - 1 )); }
  [[ $modified_count -gt 0 ]]      && { out="$out$ws$modified_symbol$modified_count"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#modified_symbol} - 1 )); }
  [[ $unmerged_count -gt 0 ]]      && { out="$out$ws$unmerged_symbol$unmerged_count"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#unmerged_symbol} - 1 )); }
  [[ $added_count -gt 0 ]]         && { out="$out$ws$added_symbol$added_count"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#added_symbol} - 1 )); }
  [[ $has_untracked_files -gt 0 ]] && { out="$out$ws$has_untracked_files_symbol"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#has_untracked_files_symbol} - 1 )); }
  [[ $is_clean -gt 0 ]]            && { out="$out$ws$clean_symbol"; ws=" "; [ "$KONSOLE" -eq "1" ] && (( added_ws += ${#clean_symbol} - 1 )); }

  sha=$(git rev-parse --short HEAD 2>/dev/null)
  [[ -n "$sha" ]] && { [[ $is_clean -gt 0 ]] && out="$out$sha" || out="$out$ws$sha"; }

  while [[ $added_ws -gt 0 ]]; do
      out="$out "
      (( added_ws-- ))
  done

  printf "%s" "$out"
}
