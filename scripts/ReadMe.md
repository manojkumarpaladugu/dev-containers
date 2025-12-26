# Dev Containers Setup

This repository contains helper scripts to open a development workspace in an editor (VS Code or Cursor) and connect to local or remote development containers and hosts.

**Prerequisites**
- **Docker**: for `local-container` and remote containers. Install Docker and follow post-install steps for your OS.
- **SSH access**: for `remote-host` and `remote-container` modes (passwordless/agent-based SSH is recommended).
- **Editor**: one of the supported editors (see configuration).

**Where to look**
- The launcher script is `scripts/launch.py`.
- Defaults are configured in `scripts/launch.json`.

**Usage**
The launcher is a Python script that provides three connection modes: `remote-host`, `remote-container`, and `local-container`.

Run the launcher with the mode as the first positional argument. Use `--dry-run` to print the computed URI and command without launching the editor, and `--verbose` for more output.

Common flags (available to all modes):
- `--editor`: Editor executable to run (default from `scripts/launch.json`).
- `--ssh-port`: SSH port (default from `scripts/launch.json`).
- `--ssh-key`: Path to the SSH private key to use for SSH connections.
- `--dry-run`: Print the commands / URI without launching.
- `--verbose`: Print extra information.

Modes and mode-specific flags:
- `remote-host`:
	- `--host`: Remote host to SSH to (default from config).
	- `--workspace`: Workspace path to open on the remote host (default from config).
- `remote-container`:
	- `--host`: Remote host to SSH to.
	- `--dev-container`: Path to the dev container configuration on the remote host.
	- `--workspace`: Remote workspace path to open.
- `local-container`:
	- `--dev-container`: Path to the local dev container configuration (will be hex-encoded into the URI).
	- `--workspace`: Local workspace path to open.

Notes about behavior:
- `remote-host` and `remote-container` test the SSH connection by running a simple `true` remote command first; ensure SSH connectivity is working.
- `local-container` checks Docker availability by running `docker info` before proceeding.
- When specifying a dev container path, the script hex-encodes the path and embeds it in the `vscode-remote` URI (this matches VS Code's `dev-container` URI format used by the script).

Examples
```bash
# Remote host (dry-run)
python scripts/launch.py remote-host --host example.com --workspace /home/dev --editor code --dry-run

# Remote container, verbose
python scripts/launch.py remote-container --host example.com --dev-container /opt/workspace/dev-containers/zephyr --workspace /home/dev --editor code --verbose

# Local container
python scripts/launch.py local-container --dev-container /opt/workspace/dev-containers/zephyr --workspace /opt/workspace --editor code
```

Configuration (`scripts/launch.json`)
The script reads `scripts/launch.json` for default values. Typical keys include:
- `SUPPORTED_EDITORS`: array of editor executable names (e.g. `["code", "cursor"]`).
- `DEFAULT_EDITOR`: default editor executable (e.g. `"code"`).
- `DEFAULT_HOST`: default SSH host to use for remote modes.
- `DEFAULT_DEV_CONTAINER`: default path to local/remote dev container config.
- `DEFAULT_WORKSPACE`: default workspace path to open in the editor.
- `DEFAULT_SSH_PORT`: default SSH port (usually `22`).
- `DEFAULT_SSH_KEY`: default SSH private key path (empty by default).

Remote helper
- Use `RemoteVSCode/prepare_remote_setup.py` to help prepare remote hosts (setup keys, git, etc.). Example:

```bash
python RemoteVSCode/prepare_remote_setup.py --git_user username --remote_user username --remote_host hostname-or-ip
```
