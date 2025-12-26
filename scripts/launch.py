import argparse
import json
import logging
import os
from pathlib import Path
import subprocess
import sys

# Initialize logger
logger = logging.getLogger("launcher")

def setup_logging(verbose=False):
    """Configures the logging format and level."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="[%(levelname)s] %(message)s",
    )

def load_default_config():
    """Loads default configuration from file."""
    config_path = Path(__file__).parent / "default.json"
    if not config_path.exists():
        logger.warning("Default configuration not found. Using internal defaults.")
        defaults = {
            "SUPPORTED_EDITORS": ["code", "cursor"],
            "DEFAULT_EDITOR": "code",
            "DEFAULT_HOST": "Fusion",
            "DEFAULT_DEV_CONTAINER": "/opt/workspace/dev-containers/zephyr",
            "DEFAULT_WORKSPACE": "/opt/workspace",
            "DEFAULT_SSH_PORT": 22,
            "DEFAULT_SSH_KEY": ""
        }
        return defaults
    try:
        with open(config_path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        logger.error("Failed to parse default.json.")
        return {}

def hex_encode(path):
    """Hex-encodes the path as required for vscode-remote URIs."""
    return path.encode().hex()

def run(cmd, verbose=False, dry_run=False):
    """Run system command."""
    cmd_str = ' '.join(cmd)
    if dry_run:
        logger.info("[Dry-Run] Would execute: %s", cmd_str)
        return None
    logger.debug("Executing command: %s", cmd_str)
    try:
        return subprocess.run(cmd,
                              text=True,
                              check=True, 
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              timeout=10)
    except subprocess.TimeoutExpired as e:
        logger.error(f"{e}")
        input("Press ENTER key to exit...")
        sys.exit(1)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"Command failed: {cmd_str}")
        logger.error(f"{e}")
        input("Press ENTER key to exit...")
        sys.exit(1)

def setup_arg_parser():
    """Sets up the argument parser with subcommands and shared arguments."""
    cfg = load_default_config()

   # Create a parent parser for shared/global arguments
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument(
        '--editor',
        default=cfg.get('DEFAULT_EDITOR'),
        help=f"Specify editor ({', '.join(cfg.get('SUPPORTED_EDITORS', []))})"
    )
    common_parser.add_argument(
        '--ssh-port',
        type=int,
        default=cfg.get('DEFAULT_SSH_PORT'),
        help="SSH port number"
    )
    common_parser.add_argument(
        '--ssh-key',
        default=cfg.get('DEFAULT_SSH_KEY'),
        help="Path to the SSH private key"
    )
    common_parser.add_argument(
        '--dry-run',
        action='store_true',
        help="Print the commands without executing"
    )
    common_parser.add_argument(
        '--verbose',
        action='store_true',
        help="Enable verbose output"
    )

    # Main parser inherits from common parser
    main_parser = argparse.ArgumentParser(
        description="Launch Editor Connected to Remote Host or Remote/Local Docker Container",
        parents=[common_parser]
    )

    default_host = cfg.get('DEFAULT_HOST')
    default_dev_container = cfg.get('DEFAULT_DEV_CONTAINER')
    default_workspace = cfg.get('DEFAULT_WORKSPACE')

    # Set up subparsers for different connection modes
    subparsers = main_parser.add_subparsers(dest='mode', help='Connection modes')
    remote_host_parser = subparsers.add_parser(
        'remote-host', 
        help='Connect to remote host via SSH',
        parents=[common_parser]
    )
    remote_host_parser.add_argument(
        '--host',
        default=default_host,
        help="Remote host for SSH connections"
    )
    remote_host_parser.add_argument(
        '--workspace',
        default=default_workspace,
        help="Workspace path to open in the editor"
    )

    remote_container_parser = subparsers.add_parser(
        'remote-container', 
        help='Connect to Docker container on remote host',
        parents=[common_parser]
    )
    remote_container_parser.add_argument(
        '--host',
        default=default_host,
        help="Remote host for SSH connections"
    )
    remote_container_parser.add_argument(
        '--dev-container',
        default=default_dev_container,
        help="Path to the development container configuration"
    )
    remote_container_parser.add_argument(
        '--workspace',
        default=default_workspace,
        help="Workspace path to open in the editor"
    )

    local_container_parser = subparsers.add_parser(
        'local-container', 
        help='Connect to Docker container on local host',
        parents=[common_parser]
    )
    local_container_parser.add_argument(
        '--dev-container',
        default=default_dev_container,
        help="Path to the development container configuration"
    )
    local_container_parser.add_argument(
        '--workspace',
        default=default_workspace,
        help="Workspace path to open in the editor"
    )

    return main_parser

def main():
    parser = setup_arg_parser()
    args = parser.parse_args()

    setup_logging(args.verbose)

    if not args.mode:
        logger.error("No valid mode selected.")
        parser.print_help()
        input("Press ENTER key to exit...")
        sys.exit(1)

    # Build SSH command base
    ssh_cmd = [
        "ssh",
        "-o", "ConnectTimeout=5",
        "-o", "BatchMode=yes",
        "-o", "ConnectionAttempts=3"
    ]
    if args.verbose: ssh_cmd += ["-v"]
    if args.ssh_key: ssh_cmd += ["-i", args.ssh_key]
    if args.ssh_port: ssh_cmd += ["-p", str(args.ssh_port)]

    uri = ""
    if args.mode == 'remote-host':
        run(cmd=ssh_cmd + [args.host, "true"], verbose=args.verbose, dry_run=args.dry_run)
        uri = f"vscode-remote://ssh-remote+{args.host}{args.workspace}"
    elif args.mode == 'remote-container':
        run(cmd=ssh_cmd + [args.host, "true"], verbose=args.verbose, dry_run=args.dry_run)
        hex_path = hex_encode(args.dev_container)
        uri = f"vscode-remote://dev-container+{hex_path}@ssh-remote+{args.host}{args.workspace}"
    elif args.mode == 'local-container':
        run(cmd=["docker", "info"], verbose=args.verbose, dry_run=args.dry_run)
        hex_path = hex_encode(args.dev_container)
        uri = f"vscode-remote://dev-container+{hex_path}@{args.workspace}"

    logger.info("-" * 40)
    logger.info("Launching with the following parameters:")
    logger.info("-" * 40)
    logger.info("Mode:          %s", args.mode)
    logger.info("Editor:        %s", args.editor)
    logger.info("Host:          %s", getattr(args, 'host', 'localhost'))
    logger.info("Dev Container: %s", getattr(args, 'dev_container', 'N/A'))
    logger.info("Workspace:     %s", args.workspace)
    logger.info("-" * 40)

    # Launch the editor
    launch_cmd = [args.editor, "--folder-uri", uri]
    run(cmd=launch_cmd, verbose=args.verbose, dry_run=args.dry_run)

    sys.exit(0)

if __name__ == "__main__":
    main()
