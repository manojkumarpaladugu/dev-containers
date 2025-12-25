
#!/bin/bash
# ============================================================
# Script: Connect to Remote Host
# Description: Opens editor connected to a remote host via SSH
# ============================================================

# Configuration
SUPPORTED_EDITORS=("code" "cursor")
EDITOR="code"
# HOST: SSH host name configured in ~/.ssh/config
HOST="Fusion"
HOST_WORK_DIR="/opt/workspace"

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

if [ -z "$HOST_WORK_DIR" ]; then
    echo "ERROR: HOST_WORK_DIR is not set."
    echo "Set HOST_WORK_DIR to the desired working directory on the remote host."
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$HOST" "echo Connection successful" >/dev/null 2>&1; then
    echo "ERROR: Could not establish SSH connection with host ($HOST)."
    exit 1
fi
echo

echo "====================================="
echo "Connecting to Remote Host via SSH..."
echo "====================================="
echo "Editor: $EDITOR"
echo "Host: $HOST"
echo "Host Work Directory: $HOST_WORK_DIR"
echo "====================================="
echo

# Launch Editor
"$EDITOR" --folder-uri "vscode-remote://ssh-remote+${HOST}${HOST_WORK_DIR}"

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to launch editor (exit code: $?)"
    exit $?
fi
