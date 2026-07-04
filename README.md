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
