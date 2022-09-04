#!/usr/bin/env bash

_path_gen() {
    local sshyp_path="$HOME/.local/share/sshyp/"
    local sshyp_path_length="${#sshyp_path}"
    readarray -t full_paths < <(find "$HOME"/.local/share/sshyp -type f -exec ls {} \;)
    for path in "${full_paths[@]}"; do
        trimmed_path=$(echo $path | sed 's/.\{4\}$//' | cut -c"$sshyp_path_length"-)
        trimmed_path=$(echo ${trimmed_path// /\\ })
        trimmed_paths+=("$trimmed_path")
    done
} &&

# from this point, this completions script was partially generated by
# completely (https://github.com/dannyben/completely)

_sshyp_completions() {
  if [ "${#COMP_WORDS[@]}" -gt "4" ]; then
    return
  fi
  local cur=${COMP_WORDS[COMP_CWORD]}
  local compline="${COMP_WORDS[@]:1:$COMP_CWORD-1}"

  case "$compline" in
    'add password'* | 'add note'* | 'add folder'* | 'edit relocate'* | 'edit username'* | 'edit password'* | 'edit url' | 'edit note'* | 'copy username'* | 'copy password'* | 'copy note'* | 'copy url'* | 'gen update'*)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W  "$(printf "'%s' " "${trimmed_paths[@]}")" -- "$cur" )
      ;;

    'edit'*)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W "relocate username password note url" -- "$cur" )
      ;;

    'copy'*)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W "username password url note" -- "$cur" )
      ;;

    'add'*)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W "password note folder" -- "$cur" )
      ;;

    'gen'*)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W "update" -- "$cur" )
      ;;
    *)
      while read; do COMPREPLY+=( "$REPLY" ); done < <( compgen -W "help version tweak add gen edit copy shear sync $(printf "'%s' " "${trimmed_paths[@]}")" -- "$cur" )
      ;;

  esac
} &&
complete -F _sshyp_completions sshyp && _path_gen
