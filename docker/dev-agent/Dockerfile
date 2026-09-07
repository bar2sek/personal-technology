FROM ubuntu:24.04

LABEL maintainer="bar2sek"
LABEL description="Remote Antigravity Agent & Dev Container Environment for Kubernetes"

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/zsh

# Install core development tools & utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    htop \
    jq \
    libssl-dev \
    locales \
    neovim \
    openssh-server \
    pkg-config \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    rsync \
    sudo \
    tmux \
    tree \
    unzip \
    vim \
    wget \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Generate locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Configure OpenSSH Server
RUN mkdir -p /var/run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install Go (v1.22)
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL "https://go.dev/dl/go1.22.6.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin

# Install Node.js (v20 LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm yarn

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl & talosctl
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    curl -fsSL -o /usr/local/bin/talosctl "https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-${ARCH}" && \
    chmod +x /usr/local/bin/talosctl

# Install Oh-My-Zsh for root
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set working directory
WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
