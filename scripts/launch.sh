#!/bin/bash
# ==================================================================================
# Script: Launch Editor Connected to Remote Host or Local/Remote Docker Container
# Description: Opens editor connected to a local container, remote container via
#              SSH, or remote host via SSH
# Usage: ./launch.sh <mode> [options]
# ==================================================================================

set -euo pipefail

# Load configuration file if it exists
CONFIG_FILE="$(dirname "$0")/launch.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Mode-specific configuration (set via arguments)
EDITOR=""
HOST=""
DEV_CONTAINER=""
WORKSPACE=""
SSH_PORT=""
SSH_KEY=""
DRY_RUN=false
VERBOSE=false

# Function to display usage
usage() {
    echo "Usage: $0 <mode> [options]"
    echo "Modes:"
    echo "  local-container    Connect to a local Docker container"
    echo "  remote-container   Connect to a Docker container on a remote host via SSH"
    echo "  remote-host        Connect to a remote host via SSH"
    echo ""
    echo "Options:"
    echo "  -e, --editor EDITOR                    Specify editor (${SUPPORTED_EDITORS[*]})"
    echo "  --host HOST                            SSH host name"
    echo "  --dev-container PATH                   Path to dev container"
    echo "  --workspace PATH                       Workspace path"
    echo "  --ssh-port PORT                        SSH port (default: ${DEFAULT_SSH_PORT})"
    echo "  --ssh-key KEY                          SSH private key path"
    echo "  --dry-run                              Show what would be done without launching"
    echo "  --verbose                              Enable verbose output"
    echo "  --version                              Show version information"
    echo "  -h, --help                             Show this help message"
}

# Parse arguments
MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        local-container|remote-container|remote-host)
            MODE="$1"
            shift
            ;;
        -e|--editor)
            EDITOR="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --dev-container)
            DEV_CONTAINER="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --ssh-port)
            SSH_PORT="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_KEY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --version)
            echo "launch.sh version 1.0"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "ERROR: Mode not specified."
    usage
    exit 1
fi

# Set defaults for unset variables
EDITOR="${EDITOR:-$DEFAULT_EDITOR}"
HOST="${HOST:-$DEFAULT_HOST}"
DEV_CONTAINER="${DEV_CONTAINER:-$DEFAULT_DEV_CONTAINER}"
WORKSPACE="${WORKSPACE:-$DEFAULT_WORKSPACE}"
SSH_PORT="${SSH_PORT:-$DEFAULT_SSH_PORT}"
SSH_KEY="${SSH_KEY:-$DEFAULT_SSH_KEY}"

# Build SSH options
build_ssh_opts() {
    SSH_OPTS="-o ConnectTimeout=5 -o BatchMode=yes"
    if [ -n "$SSH_KEY" ]; then
        SSH_OPTS="$SSH_OPTS -i $SSH_KEY"
    fi
    if [ "$SSH_PORT" != "22" ]; then
        SSH_OPTS="$SSH_OPTS -p $SSH_PORT"
    fi
}

build_ssh_opts

# Validate common configuration
if [ -z "${EDITOR}" ]; then
    echo "ERROR: --editor is required."
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

# Function to log verbose messages
log() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to test SSH connection
test_ssh() {
    log "Testing SSH connection..."
    if ! ssh $SSH_OPTS "${HOST}" "echo Connection successful" >/dev/null 2>&1; then
        echo "ERROR: Could not establish SSH connection with host (${HOST})."
        exit 1
    fi
    log "SSH connection successful."
}

# Function to launch editor
launch_editor() {
    local uri=$1
    if [ "$DRY_RUN" = true ]; then
        echo "Dry run: Would launch \"${EDITOR} --folder-uri ${uri}\""
        exit 0
    fi
    ${EDITOR} --folder-uri ${uri}
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Failed to launch editor (exit code: $?)"
        exit $?
    fi
}

# Function for remote-host mode
connect-remote-host() {
    # Validate remote host configuration
    if [ -z "${HOST}" ]; then
        echo "ERROR: --host is required for remote-host mode."
        exit 1
    fi
    if [ -z "${WORKSPACE}" ]; then
        echo "ERROR: --workspace is required for remote-host mode."
        exit 1
    fi

    test_ssh

    echo "====================================="
    echo "Connecting to Remote Host via SSH..."
    echo "====================================="
    echo "Editor    : ${EDITOR}"
    echo "Host      : ${HOST}"
    echo "Workspace : ${WORKSPACE}"
    echo "SSH Port  : ${SSH_PORT}"
    if [ -n "$SSH_KEY" ]; then
        echo "SSH Key   : ${SSH_KEY}"
    fi
    echo "====================================="
    echo

    # Launch Editor
    REMOTE_HOST_URI="vscode-remote://ssh-remote+${HOST}${WORKSPACE}"
    launch_editor "$REMOTE_HOST_URI"
}

# Function to generate dev container URI
generate_dev_container_uri() {
    local path=$1
    local is_remote=$2
    local host=$3
    log "Generating dev container URI..."
    if [ "$is_remote" = true ]; then
        DEV_CONTAINER_URI=$(ssh $SSH_OPTS "${host}" "echo -n ${path} | od -An -t x1 | tr -d ' \n'")
    else
        DEV_CONTAINER_URI=$(echo -n "${path}" | od -An -t x1 | tr -d ' \n')
    fi
    if [ -z "$DEV_CONTAINER_URI" ]; then
        if [ "$is_remote" = true ]; then
            echo "ERROR: Failed to generate container URI"
            echo "Please check that the remote host has 'od' and 'tr' commands available."
        else
            echo "ERROR: Failed to generate container URI"
            echo "Please check that 'od' and 'tr' commands are available."
        fi
        exit 1
    fi
    log "Dev container URI: $DEV_CONTAINER_URI"
}

# Function for local-container mode
connect-local-container() {
    # Validate local container configuration
    if [ -z "${DEV_CONTAINER}" ]; then
        echo "ERROR: --dev-container is required for local-container mode."
        exit 1
    fi
    if [ -z "${WORKSPACE}" ]; then
        echo "ERROR: --workspace is required for local-container mode."
        exit 1
    fi

    # Check if dev container path exists
    if [ ! -d "${DEV_CONTAINER}" ]; then
        echo "ERROR: Dev container directory does not exist: ${DEV_CONTAINER}"
        exit 1
    fi

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "ERROR: Docker is not running or not accessible."
        exit 1
    fi

    generate_dev_container_uri "$DEV_CONTAINER" false ""

    echo "========================================"
    echo "Connecting to Local Docker Container..."
    echo "========================================"
    echo "Editor        : ${EDITOR}"
    echo "Dev Container : ${DEV_CONTAINER}"
    echo "Workspace     : ${WORKSPACE}"
    echo "========================================"
    echo

    # Launch Editor
    LOCAL_DEV_CONTAINER_URI="vscode-remote://dev-container+${DEV_CONTAINER_URI}@${WORKSPACE}"
    launch_editor "$LOCAL_DEV_CONTAINER_URI"
}

# Function for remote-container mode
connect-remote-container() {
    # Validate remote container configuration
    if [ -z "${HOST}" ]; then
        echo "ERROR: --host is required for remote-container mode."
        exit 1
    fi
    if [ -z "${DEV_CONTAINER}" ]; then
        echo "ERROR: --dev-container is required for remote-container mode."
        exit 1
    fi
    if [ -z "${WORKSPACE}" ]; then
        echo "ERROR: --workspace is required for remote-container mode."
        exit 1
    fi

    test_ssh

    generate_dev_container_uri "$DEV_CONTAINER" true "$HOST"

    echo "================================================="
    echo "Connecting to Remote Docker Container via SSH..."
    echo "================================================="
    echo "Editor        : ${EDITOR}"
    echo "Host          : ${HOST}"
    echo "Dev Container : ${DEV_CONTAINER}"
    echo "Workspace     : ${WORKSPACE}"
    echo "SSH Port      : ${SSH_PORT}"
    if [ -n "$SSH_KEY" ]; then
        echo "SSH Key       : ${SSH_KEY}"
    fi
    echo "================================================="
    echo

    # Launch Editor
    REMOTE_DEV_CONTAINER_URI="vscode-remote://dev-container+${DEV_CONTAINER_URI}@ssh-remote+${HOST}${WORKSPACE}"
    launch_editor "$REMOTE_DEV_CONTAINER_URI"
}

case $MODE in
   remote-host)
        connect-remote-host
        ;;

    local-container)
        connect-local-container
        ;;

    remote-container)
        connect-remote-container
        ;;
    *)
        echo "ERROR: Invalid mode: $MODE"
        usage
        exit 1
        ;;
esac
