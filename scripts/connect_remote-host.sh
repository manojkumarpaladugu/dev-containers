#!/bin/bash
# ============================================================
# Script: Connect to Remote Host
# Description: Opens editor connected to a remote host via SSH
# ============================================================

# Configuration
SUPPORTED_EDITORS=("code" "cursor")
EDITOR="code"
REMOTE_HOST="Fusion"
REMOTE_HOST_WORKSPACE="/opt/workspace"

# Validate configuration
if [ -z "${EDITOR}" ]; then
    echo "ERROR: EDITOR is not set."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi
if [[ ! " ${SUPPORTED_EDITORS[*]} " =~ " ${EDITOR} " ]]; then
    echo "ERROR: EDITOR (${EDITOR}) is not supported."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi
if ! command -v "${EDITOR}" >/dev/null 2>&1; then
    echo "ERROR: Editor (${EDITOR}) not found."
    echo "Set EDITOR to one of the supported editors: ${SUPPORTED_EDITORS[*]}"
    exit 1
fi

if [ -z "${REMOTE_HOST}" ]; then
    echo "ERROR: REMOTE_HOST is not set."
    echo "Set REMOTE_HOST to the SSH host name configured in ~/.ssh/config."
    exit 1
fi

if [ -z "${REMOTE_HOST_WORKSPACE}" ]; then
    echo "ERROR: REMOTE_HOST_WORKSPACE is not set."
    echo "Set REMOTE_HOST_WORKSPACE to the desired working directory on the remote host."
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_HOST}" "echo Connection successful" >/dev/null 2>&1; then
    echo "ERROR: Could not establish SSH connection with host (${REMOTE_HOST})."
    exit 1
fi
echo

echo "====================================="
echo "Connecting to Remote Host via SSH..."
echo "====================================="
echo "Editor: ${EDITOR}"
echo "Host: ${REMOTE_HOST}"
echo "Host Workspace: ${REMOTE_HOST_WORKSPACE}"
echo "====================================="
echo

# Launch Editor
REMOTE_HOST_URI="vscode-remote://ssh-remote+${REMOTE_HOST}${REMOTE_HOST_WORKSPACE}"
${EDITOR} --folder-uri ${REMOTE_HOST_URI}

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to launch editor (exit code: $?)"
    exit $?
fi
