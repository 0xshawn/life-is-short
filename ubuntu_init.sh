#!/usr/bin/env bash

set -euo pipefail

# Usage:
#   sudo ./ubuntu_init.sh
#   wget -qO- <url-to-this-script> | sudo bash

readonly MIN_UBUNTU_MAJOR=24
readonly MIN_UBUNTU_MINOR=4
readonly DOCKER_DATA_ROOT="/data/docker"
readonly OS_RELEASE_PATH="${OS_RELEASE_FILE:-/etc/os-release}"

die() {
  echo "$1" >&2
  exit 1
}

unsupported_os() {
  die "Error: This script is only supported on Ubuntu >= 24.04."
}

read_os_release_value() {
  local key="$1"
  local file="$2"
  local line
  local value

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key="*)
        value="${line#*=}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        printf '%s' "$value"
        return 0
        ;;
    esac
  done <"$file"

  return 1
}

version_at_least_minimum() {
  local version_id="$1"
  local version_major
  local version_minor

  version_major="${version_id%%.*}"
  version_minor="${version_id#*.}"
  if [ "$version_minor" = "$version_id" ]; then
    version_minor="0"
  else
    version_minor="${version_minor%%.*}"
  fi

  case "$version_major" in
    ''|*[!0-9]*) return 1 ;;
  esac
  case "$version_minor" in
    ''|*[!0-9]*) return 1 ;;
  esac

  version_major=$((10#$version_major))
  version_minor=$((10#$version_minor))

  if [ "$version_major" -gt "$MIN_UBUNTU_MAJOR" ]; then
    return 0
  fi

  if [ "$version_major" -eq "$MIN_UBUNTU_MAJOR" ] &&
    [ "$version_minor" -ge "$MIN_UBUNTU_MINOR" ]; then
    return 0
  fi

  return 1
}

require_supported_os() {
  local os_id
  local version_id

  [ -r "$OS_RELEASE_PATH" ] || unsupported_os

  os_id="$(read_os_release_value ID "$OS_RELEASE_PATH" || true)"
  version_id="$(read_os_release_value VERSION_ID "$OS_RELEASE_PATH" || true)"

  [ "$os_id" = "ubuntu" ] || unsupported_os
  version_at_least_minimum "$version_id" || unsupported_os
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    die "Please run as root"
  fi
}

install_common_tools() {
  local packages=(
    git
    vim
    curl
    wget
    htop
    atop
    iotop
    tmux
    mtr
    unzip
    zip
    zsh
    tree
    mosh
    jq
    build-essential
  )

  apt update
  apt install -y "${packages[@]}"
}

set_default_editor() {
  update-alternatives --set editor /usr/bin/vim.basic
}

configure_docker() {
  mkdir -p /etc/docker "$DOCKER_DATA_ROOT"
  cat >/etc/docker/daemon.json <<EOL
{
  "data-root": "$DOCKER_DATA_ROOT",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file":"5"
  }
}
EOL
}

install_docker() {
  wget -qO- get.docker.com | bash
  systemctl enable docker
}

configure_vim() {
  cat >/etc/vim/vimrc.local <<EOL
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab
EOL
}

configure_passwordless_sudo() {
  cat >/etc/sudoers.d/sudo <<EOL
%sudo ALL=(ALL) NOPASSWD: ALL
EOL
}

configure_journald() {
  mkdir -p /etc/systemd/journald.conf.d
  cat >/etc/systemd/journald.conf.d/00-journal-limit.conf <<EOL
[Journal]
SystemMaxUse=1G
SystemMaxFileSize=200M
MaxRetentionSec=14day
EOL
  systemctl restart systemd-journal-flush.service
  systemctl restart systemd-journald
}

configure_logrotate() {
  if [ -f /etc/logrotate.conf ]; then
    if ! grep -q "maxsize" /etc/logrotate.conf; then
      sed -i '/^# global options/a \    maxsize 1G' /etc/logrotate.conf
    fi
    sed -i 's/#compress/compress/g' /etc/logrotate.conf
  fi
}

disable_apt_daily_timers() {
  systemctl mask \
    apt-daily.service \
    apt-daily.timer \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer
}

disable_welcome_message() {
  touch ~/.hushlogin
}

main() {
  require_supported_os
  require_root

  install_common_tools
  set_default_editor
  configure_docker
  install_docker
  configure_vim
  configure_passwordless_sudo
  configure_journald
  configure_logrotate
  disable_apt_daily_timers
  disable_welcome_message
}

main "$@"
