# Dev Containers Setup

This repository contains scripts to easily connect to local and remote development containers using VS Code or Cursor.

## Prepare Host Machine

### Setup Docker Engine

1. [Install Docker Engine](https://docs.docker.com/engine/install/)
2. [Linux Post-install](https://docs.docker.com/engine/install/linux-postinstall/)
3. [Install Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Generate SSH key and add it to the GitHub account

1. [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
2. [Add to GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
3. [Test connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)

## Usage

Use the `scripts/launch.sh` script to connect to different environments.

### Modes

- `local-container`: Connect to a local Docker container
- `remote-container`: Connect to a Docker container on a remote host via SSH
- `remote-host`: Connect to a remote host via SSH

### Examples

```bash
# Local container
./scripts/launch.sh local-container --editor code --dev-container /path/to/.devcontainer --workspace /workspace

# Remote container
./scripts/launch.sh remote-container --editor code --host example.com --dev-container /remote/path/.devcontainer --workspace /workspace

# Remote host
./scripts/launch.sh remote-host --editor code --host example.com --workspace /workspace
```

### Configuration

Create `scripts/launch.conf` to set default values:

```bash
DEFAULT_EDITOR="code"
DEFAULT_SSH_PORT=22
DEFAULT_SSH_KEY=""
```

### Remote Setup

Use the `RemoteVSCode/prepare_remote_setup.py` script to set up passwordless SSH and git access on remote hosts.

```bash
python RemoteVSCode/prepare_remote_setup.py --git_user username --remote_user username --remote_host hostname-or-ip
```
