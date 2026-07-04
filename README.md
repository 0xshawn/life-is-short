# ops

Ubuntu server initialization script for Ubuntu 24.04 and newer.

## Remote execution

Run the initializer directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/0xshawn/ops/main/ubuntu_init.sh | bash
```

The script uses sudo for system changes and exits on non-Ubuntu systems or Ubuntu versions older than 24.04.

## Selective modules

With no arguments the script runs every module. Pass module names to run only
those (they always execute in their canonical order):

```bash
./ubuntu_init.sh disable_welcome_message
curl -fsSL https://raw.githubusercontent.com/0xshawn/ops/main/ubuntu_init.sh | bash -s -- disable_welcome_message
```

List the available modules with `./ubuntu_init.sh --list` (or `--help`).

## Modules

| Module | Description |
| --- | --- |
| `install_common_tools` | Install common CLI tools (git, vim, curl, wget, htop, tmux, jq, build-essential, …) |
| `set_default_editor` | Set Vim as the system default editor |
| `configure_docker` | Write `/etc/docker/daemon.json` (data root `/data/docker`, JSON log limits) |
| `install_docker` | Install Docker if missing, then enable and restart the service |
| `configure_vim` | Write `/etc/vim/vimrc.local` with 4-space indentation defaults |
| `configure_passwordless_sudo` | Grant the `sudo` group passwordless sudo |
| `configure_journald` | Cap journald disk usage and retention, then restart it |
| `configure_logrotate` | Enable compression and a max log size in logrotate |
| `disable_apt_daily_timers` | Mask the `apt-daily` and `apt-daily-upgrade` services and timers |
| `disable_welcome_message` | Create `~/.hushlogin` to silence the login banner |
