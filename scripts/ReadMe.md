# Remote Editor Launcher

A Python utility to streamline launching editor (VS Code or Cursor) into remote environments, including SSH hosts and Docker dev containers (both local and remote). It automates the URI encoding required for vscode-remote protocols and verifies connections before attempting to open the editor.


## Features

- **Three Connection Modes**:

  - `remote-host`: Direct SSH connection to a remote host.

  - `remote-container`: Connect to a Docker container running on a remote SSH host.

  - `local-container`: Connect to a Docker container on your local machine.

- **Flexible Configuration**: Supports configurations through mix of command line options and `defaults.json` file.

- **Multi-Editor Support**: Works with VS Code and Cursor.


## Requirements

- Python 3.6+

- VS Code or Cursor (with Remote Development extension pack).

- SSH Client (for `remote-host` and `remote-container`).

- Docker (for `local-container`).


## Installation

Save the script (e.g., launcher.py) to your local machine.

(Optional) Create a `default.json` in the same directory to customize your default paths and hosts.

```json
{
    "SUPPORTED_EDITORS": ["code", "cursor"],
    "DEFAULT_HOST": "my-dev-host",
    "DEFAULT_DEV_CONTAINER": "/path/to/devcontainer",
    "DEFAULT_WORKSPACE": "/path/to/workspace",
    "DEFAULT_EDITOR": "code",
}
```


## Usage

### Global Options

These flags can be applied to any mode:

- `--workspace`: Specify the directory path to open within the target environment.

- `--editor`: Choose between `code` or `cursor`.

  Note: Windows users may need to suffix with .cmd (`code.cmd` and `cursor.cmd`)

- `--dry-run`: Display the commands/URIs without launching the editor.

- `--verbose`: Show detailed logs and SSH debug output.

The script uses subparsers for each mode. You can view help for any mode using the --help flag.

### 1. Remote Host (SSH)

Connect directly to a workspace on a remote host.

```bash
python launcher.py remote-host --host my-dev-host --workspace /path/to/workspace --editor code --verbose
```


### 2. Remote Container (SSH)

Connect to a dev container on a remote host.

```bash
python launcher.py remote-container --host my-dev-host --dev-container /path/to/devcontainer --workspace /path/to/workspace --editor code --verbose
```


### 3. Local Container

Connect to a dev container on local host.

```bash
python launcher.py local-container --dev-container /path/to/devcontainer --workspace /path/to/workspace --editor code --verbose
```


## Troubleshooting
- **Editor not found**: If editor can't be found, use full path of the editor.

- **SSH Failures**: Ensure the remote host is added in SSH config file.

- **Docker Failures**: For `local-container` mode, ensure the Docker daemon is running.

- **URI Issues**: The script hex-encodes the dev-container path as required by the `vscode-remote://` protocol. If the editor opens but cannot find the container, verify the absolute path to your `.devcontainer` directory.
