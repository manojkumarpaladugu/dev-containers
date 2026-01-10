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
    config_path = Path(__file__).parent / "defaults.json"
    if not config_path.exists():
        logger.warning("Default configuration not found. Using internal defaults.")
        defaults = {
            "SUPPORTED_EDITORS": ["code", "cursor"],
            "DEFAULT_HOST": "Fusion",
            "DEFAULT_DEV_CONTAINER": "/opt/workspace/dev-containers/zephyr",
            "DEFAULT_WORKSPACE": "/opt/workspace",
            "DEFAULT_EDITOR": "code"
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

def parse_args():
    """Parse command-line arguments."""
    cfg = load_default_config()

   # Common flags
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument(
        '--workspace',
        default=cfg.get('DEFAULT_WORKSPACE'),
        help="Absolute path to workspace directory"
    )
    common_parser.add_argument(
        '--editor',
        default=cfg.get('DEFAULT_EDITOR'),
        help=f"Specify editor ({', '.join(cfg.get('SUPPORTED_EDITORS', []))})"
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

    # SSH flags
    ssh_parser = argparse.ArgumentParser(add_help=False)
    ssh_parser.add_argument(
        '--host',
        default=cfg.get('DEFAULT_HOST'),
        help="Remote hostname for SSH connections"
    )

    # Dev container flags
    dev_container_parser = argparse.ArgumentParser(add_help=False)
    dev_container_parser.add_argument(
        '--dev-container',
        default=cfg.get('DEFAULT_DEV_CONTAINER'),
        help="Absolute path to .devcontainer directory"
    )

    # Main parser inherits from common parser
    main_parser = argparse.ArgumentParser(
        description="Launch Editor Connected to Remote Host or Remote/Local Docker Container"
    )

    # Set up subparsers for different connection modes
    subparsers = main_parser.add_subparsers(dest='mode', help='Connection modes')
    remote_host_parser = subparsers.add_parser(
        'remote-host', 
        help='Connect to remote host via SSH',
        parents=[ssh_parser, common_parser]
    )

    remote_container_parser = subparsers.add_parser(
        'remote-container', 
        help='Connect to Docker container on remote host via SSH',
        parents=[ssh_parser, dev_container_parser, common_parser]
    )

    local_container_parser = subparsers.add_parser(
        'local-container', 
        help='Connect to Docker container on local host',
        parents=[dev_container_parser, common_parser]
    )

    args = main_parser.parse_args()

    if not args.mode:
        main_parser.print_help()
        input("Press ENTER key to exit...")
        sys.exit(1)

    return args

def verify_ssh_connection(host, verbose=False, dry_run=False):
    """Verify SSH connection to the remote host."""
    ssh_cmd = [
        "ssh",
        "-o", "ConnectTimeout=5",
        "-o", "BatchMode=yes",
        "-o", "ConnectionAttempts=3"
    ]
    if verbose: ssh_cmd += ["-v"]
    ssh_cmd += [host, "true"]

    run(cmd=ssh_cmd, verbose=verbose, dry_run=dry_run)

def main():
    args = parse_args()
    setup_logging(args.verbose)

    uri = ""
    if args.mode == 'remote-host':
        verify_ssh_connection(host=args.host, verbose=args.verbose, dry_run=args.dry_run)
        uri = f"vscode-remote://ssh-remote+{args.host}{args.workspace}"
    elif args.mode == 'remote-container':
        verify_ssh_connection(host=args.host, verbose=args.verbose, dry_run=args.dry_run)
        hex_path = hex_encode(args.dev_container)
        uri = f"vscode-remote://dev-container+{hex_path}@ssh-remote+{args.host}{args.workspace}"
    elif args.mode == 'local-container':
        hex_path = hex_encode(args.dev_container)
        uri = f"vscode-remote://dev-container+{hex_path}@{args.workspace}"

    logger.info("-" * 40)
    logger.info("Launching with the following parameters:")
    logger.info("-" * 40)
    logger.info("Mode          : %s", args.mode)
    if args.mode in {'remote-host', 'remote-container'}:
        logger.info("Host          : %s", args.host)
    if args.mode in {'remote-container', 'local-container'}:
        logger.info("Dev Container : %s", args.dev_container)
    logger.info("Workspace     : %s", args.workspace)
    logger.info("Editor        : %s", args.editor)
    logger.info("-" * 40)

    # Launch the editor
    launch_cmd = [args.editor, "--folder-uri", uri]
    run(cmd=launch_cmd, verbose=args.verbose, dry_run=args.dry_run)

    sys.exit(0)

if __name__ == "__main__":
    main()
