#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

#Helpers
echoerr() { printf "%s\n" "$*" >&2; }
info() { echoerr "[INFO] $*"; }
warning() { echoerr "[WARNING] $*"; }
error() { echoerr "[ERROR] $*"; }
fatal() {
  echoerr "[FATAL] $*"
  exit 1
}

make_su() {
  if [ "$USER" != "root" ]; then
    echo "You need root priviliges to continue"
    sudo -s
  fi
}

confirm() {
  local _prompt _default _response

  if [ "$1" ]; then _prompt="$1"; else _prompt="Are you sure"; fi
  _prompt="$_prompt [y/n] ?"

  while true; do
    read -r -p "$_prompt " _response
    case "$_response" in
    [Yy][Ee][Ss] | [Yy]) # Yes or Y (case-insensitive).
      return 0
      ;;
    [Nn][Oo] | [Nn]) # No or N.
      return 1
      ;;
    *) # Anything else (including a blank) is invalid.
      ;;
    esac
  done
}

cleanup() {
  # Remove temporary files
  # Restart services
  info "... cleaned up"
}

# GLOBAL VARS
PATH_TO_GLOBAL_EXTENSIONS="/usr/share/gnome-shell/extensions"
PATH_TO_LOCAL_EXTENSIONS="$HOME/.local/share/gnome-shell/extensions"

# Import
restart_shell() {
  [[ $(pgrep gnome-shell) ]] || return
  echo "Restarting GNOME Shell..."
  dbus-send --session --type=method_call \
    --dest=org.gnome.Shell /org/gnome/Shell \
    org.gnome.Shell.Eval string:"global.reexec_self();"
}

# Export
function get_enabled_extensions() {
  gsettings get org.gnome.shell enabled-extensions | sed -e 's|^@as ||g' | tr -d "[",",","]","\'" | tr ' ' '\n'
}

function get_installed_extensions() {
  global_installed_extensions=($(find $PATH_TO_GLOBAL_EXTENSIONS -maxdepth 1 -type d -name "*@*" -exec /usr/bin/basename {} \;))
  local_installed_extensions=($(find $PATH_TO_LOCAL_EXTENSIONS -maxdepth 1 -type d -name "*@*" -exec /usr/bin/basename {} \;))

  combined=("${local_installed_extensions[@]}" "${global_installed_extensions[@]}")
  printf '%s\n' "${combined[@]}" | sort -u
}

function check_extension_is_enabled() {
  extension_to_check=$1
  enabled_extensions=($(get_enabled_extensions))

  for enabled_extension in "${enabled_extensions[@]}"; do
    if [ "$enabled_extension" = "$extension_to_check" ]; then
      echo true
      return
    fi
  done
  echo false
}

function print_installed_extensions() {
  installed_extensions=($(get_installed_extensions))
  info "${#installed_extensions[@]}"
  for installed_extension in "${installed_extensions[@]}"; do
    [ "$(check_extension_is_enabled "$installed_extension")" = true ] &&
      status="enabled" || status="disabled"
    printf "%-65s - %-10s \n" "$installed_extension" "$status"
  done
}

function verify_enabled_extensions_consistency() {
  local installed_extensions=($(get_installed_extensions))
  local enabled_extensions=($(get_enabled_extensions))
  local not_installed_enabled_extensions;
  for enabled_extension in "${enabled_extensions[@]}"; do
    if ! [[ " ${installed_extensions[@]} " =~ " ${enabled_extension} " ]]; then
      confirm "Enabled extension ${enabled_extension} is not installed do you want to remove from enabled extensions?"
    fi
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap cleanup EXIT
  # Script goes here
  info "starting script ..."

  verify_enabled_extensions_consistency
  info "TEST"
fi
