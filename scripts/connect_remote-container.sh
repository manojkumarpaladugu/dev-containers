#!/bin/bash
# ==================================================================================
# Script: Connect to Remote Docker Container
# Description: Opens editor connected to a Docker container on a remote host via SSH
# ==================================================================================

# Configuration
SUPPORTED_EDITORS=("code" "cursor")
EDITOR="code"
REMOTE_HOST="Fusion"
REMOTE_DEV_CONTAINER="/opt/workspace/dev-containers/zephyr"
REMOTE_CONTAINER_WORKSPACE="/opt/workspace"

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

if [ -z "${REMOTE_DEV_CONTAINER}" ]; then
    echo "ERROR: REMOTE_DEV_CONTAINER is not set."
    echo "Set REMOTE_DEV_CONTAINER to the dev container directory on the remote host."
    exit 1
fi

if [ -z "${REMOTE_CONTAINER_WORKSPACE}" ]; then
    echo "ERROR: REMOTE_CONTAINER_WORKSPACE is not set."
    echo "Set REMOTE_CONTAINER_WORKSPACE to the desired working directory on the remote container."
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_HOST}" "echo Connection successful" >/dev/null 2>&1; then
    echo "ERROR: Could not establish SSH connection with host (${REMOTE_HOST})."
    exit 1
fi
echo

# Generate hex-encoded URI from dev container path
echo "Generating dev container URI..."
URI=$(ssh "${REMOTE_HOST}" "echo -n ${REMOTE_DEV_CONTAINER} | od -An -t x1 | tr -d ' \n'")
if [ -z "$URI" ]; then
    echo "ERROR: Failed to generate container URI"
    echo "Please check that the remote host has 'od' and 'tr' commands available."
    exit 1
fi
echo

echo "================================================="
echo "Connecting to Remote Docker Container via SSH..."
echo "================================================="
echo "Editor: ${EDITOR}"
echo "Host: ${REMOTE_HOST}"
echo "Dev Container: ${REMOTE_DEV_CONTAINER}"
echo "Container Workspace: ${REMOTE_CONTAINER_WORKSPACE}"
echo "================================================="
echo

# Launch Editor
REMOTE_DEV_CONTAINER_URI="vscode-remote://dev-container+${URI}@ssh-remote+${REMOTE_HOST}${REMOTE_CONTAINER_WORKSPACE}"
${EDITOR} --folder-uri ${REMOTE_DEV_CONTAINER_URI}

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to launch editor (exit code: $?)"
    exit $?
fi
