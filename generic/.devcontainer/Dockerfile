FROM ubuntu:24.04

# Build time arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG TEMP_DIR="/tmp"
ARG GID=1000
ARG UID=1000
ARG IMAGE_USER="dev"
ARG USER_INSTALL_DIR="/opt"
ARG TIMEZONE="Asia/Kolkata"
ARG ZEPHYR_SDK_VERSION="0.17.0"
ARG WORKSPACE_DIR="/opt/workspace"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Switch to temporary directory
WORKDIR ${TEMP_DIR}

# Update system
RUN apt-get update     && \
    apt-get upgrade -y

# Delete default username (ubuntu) with UID 1000 and create new user
RUN apt-get install -y sudo                                                            && \
    userdel -r ubuntu                                                                  && \
    # Create new user with UID and GID that matches to the real host (1000:1000)
    # This avoids permission issues when mounting the workspaces directory
    groupadd -g ${GID} ${IMAGE_USER}                                                   && \
    useradd -m -u ${UID} -g ${GID} -d "/home/${IMAGE_USER}" -s /bin/bash ${IMAGE_USER} && \
    echo "${IMAGE_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set timezone
RUN if [ -n "${TIMEZONE}" ]; then                                 \
        apt-get install -y tzdata                              && \
        ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
        echo ${TIMEZONE} > /etc/timezone;                         \
        dpkg-reconfigure -f noninteractive tzdata;                \
    fi
ENV TZ=${TIMEZONE}

# Setup python
RUN apt-get install -y \
    python3            \
    python3-venv       \
    python3-pip
ARG VENV_DIR="${USER_INSTALL_DIR}/.venv"
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    python -m venv ${VENV_DIR}
ENV PATH="${VENV_DIR}/bin:$PATH"

# Install packages through apt
RUN apt-get install -y \
    vim                \
    git                \
    zip                \
    unzip

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

# Install packages through pip
RUN pip install \
    cmake       \
    pre-commit

# Set the default user and working directory
USER ${IMAGE_USER}
WORKDIR ${WORKSPACE_DIR}

# 'bash' will drop you into a shell prompt, ready for development.
CMD ["bash"]
