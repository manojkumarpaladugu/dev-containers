
#!/bin/bash
# ==================================================================================
# Script: Connect to Remote Docker Container
# Description: Opens editor connected to a Docker container on a remote host via SSH
# ==================================================================================

# Configuration
SUPPORTED_EDITORS=("code" "cursor")
EDITOR="code"
# HOST: SSH host name configured in ~/.ssh/config
HOST="Fusion"
DEV_CONTAINER_DIR="/opt/workspace/vscode-devcontainer/Zephyr"
CONTAINER_WORK_DIR="/opt/workspace"

# Validate configuration
if [ -z "$EDITOR" ]; then
    echo "ERROR: EDITOR is not set."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi
if [[ ! " ${SUPPORTED_EDITORS[*]} " =~ " $EDITOR " ]]; then
    echo "ERROR: EDITOR ($EDITOR) is not supported."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi
if ! command -v "$EDITOR" >/dev/null 2>&1; then
    echo "ERROR: Editor ($EDITOR) not found."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi

if [ -z "$HOST" ]; then
    echo "ERROR: HOST is not set."
    echo "Set HOST to the SSH host name configured in ~/.ssh/config."
    exit 1
fi

if [ -z "$DEV_CONTAINER_DIR" ]; then
    echo "ERROR: DEV_CONTAINER_DIR is not set."
    echo "Set DEV_CONTAINER_DIR to the dev container directory on the remote host."
    exit 1
fi

if [ -z "$CONTAINER_WORK_DIR" ]; then
    echo "ERROR: CONTAINER_WORK_DIR is not set."
    echo "Set CONTAINER_WORK_DIR to the desired working directory on the remote container."
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$HOST" "echo Connection successful" >/dev/null 2>&1; then
    echo "ERROR: Could not establish SSH connection with host ($HOST)."
    exit 1
fi
echo

# Generate hex-encoded URI from container name
echo "Generating docker container URI..."
URI=$(ssh "$HOST" "echo -n $DEV_CONTAINER_DIR | od -An -t x1 | tr -d ' \n'")
if [ -z "$URI" ]; then
    echo "ERROR: Failed to generate container URI"
    echo "Please check that the remote host has 'od' and 'tr' commands available."
    exit 1
fi
echo

echo "================================================="
echo "Connecting to Remote Docker Container via SSH..."
echo "================================================="
echo "Editor: $EDITOR"
echo "Host: $HOST"
echo "Dev Container Directory: $DEV_CONTAINER_DIR"
echo "Container Work Directory: $CONTAINER_WORK_DIR"
echo "================================================="
echo

# Launch Editor
"$EDITOR" --folder-uri "vscode-remote://dev-container+${URI}@ssh-remote+${HOST}${CONTAINER_WORK_DIR}"

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to launch editor (exit code: $?)"
    exit $?
fi
