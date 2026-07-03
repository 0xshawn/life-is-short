#!/bin/bash

set -e

# Must run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# 2. Must be Ubuntu
if ! grep -qi "ubuntu" /etc/os-release; then
  echo "Error: This script is only supported on Ubuntu >= 24.04."
  exit 1
fi

# Set vim as default editor
update-alternatives --set editor /usr/bin/vim.basic

# Install common tools
apt update && \
apt install -y git vim curl htop atop iotop tmux mtr \
    unzip zip zsh tree mosh \
    jq build-essential

# vim
cat >/etc/vim/vimrc.local <<EOL
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab
EOL

# sudo without password
cat >/etc/sudoers.d/sudo <<EOL
%sudo ALL=(ALL) NOPASSWD: ALL
EOL

# log rotate
mkdir -p /etc/systemd/journald.conf.d
cat >/etc/systemd/journald.conf.d/00-journal-limit.conf <<EOL
[Journal]
SystemMaxUse=1G
SystemMaxFileSize=200M
MaxRetentionSec=14day
EOL
systemctl restart systemd-journal-flush.service
systemctl restart systemd-journald
# Change global logrotate config for non-systemd log
if [ -f /etc/logrotate.conf ]; then
    if ! grep -q "maxsize" /etc/logrotate.conf; then
        sed -i '/^# global options/a \    maxsize 1G' /etc/logrotate.conf
    fi
    sed -i 's/#compress/compress/g' /etc/logrotate.conf
fi

# Disable apt daily timer
systemctl mask \
    apt-daily.service \
    apt-daily.timer \
    apt-daily-upgrade.service \
    apt-daily-upgrade.timer

# Disable welcome message
touch ~/.hushlogin
