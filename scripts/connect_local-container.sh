#!/bin/bash
# ==================================================================================
# Script: Connect to Remote Docker Container
# Description: Opens editor connected to a Docker container on a remote host via SSH
# ==================================================================================

# Configuration
SUPPORTED_EDITORS=("code" "cursor")
EDITOR="code"
DEV_CONTAINER="/opt/workspace/dev-containers/zephyr"
CONTAINER_WORKSPACE="/opt/workspace"

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

if [ -z "${DEV_CONTAINER}" ]; then
    echo "ERROR: DEV_CONTAINER is not set."
    echo "Set DEV_CONTAINER to the dev container directory on the remote host."
    exit 1
fi

if [ -z "${CONTAINER_WORKSPACE}" ]; then
    echo "ERROR: CONTAINER_WORKSPACE is not set."
    echo "Set CONTAINER_WORKSPACE to the desired working directory on the remote container."
    exit 1
fi

# Generate hex-encoded URI from dev container path
echo "Generating dev container URI..."
# Use printf (more portable than echo -n) and proper command substitution.
DEV_CONTAINER_URI=$(echo -n "${DEV_CONTAINER}" | od -An -t x1 | tr -d ' \n')
if [ -z "$DEV_CONTAINER_URI" ]; then
    echo "ERROR: Failed to generate container URI"
    echo "Please check that the remote host has 'od' and 'tr' commands available."
    exit 1
fi
echo

echo "========================================"
echo "Connecting to Local Docker Container..."
echo "========================================"
echo "Editor: ${EDITOR}"
echo "Dev Container: ${DEV_CONTAINER}"
echo "Container Workspace: ${CONTAINER_WORKSPACE}"
echo "========================================"
echo

# Launch Editor
URI="vscode-remote://dev-container+${DEV_CONTAINER_URI}@${CONTAINER_WORKSPACE}"
${EDITOR} --folder-uri ${URI}

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to launch editor (exit code: $?)"
    exit $?
fi
