FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/zsh
ENV TZ=Europe/Isle_of_Man

# Timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    openssh-server \
    mosh \
    sudo \
    zsh \
    unzip \
    build-essential \
    ca-certificates \
    gnupg \
    ripgrep \
    fd-find \
    fzf \
    tmux \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN sed -i '/en_GB.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB:en
ENV LC_ALL=en_GB.UTF-8

# Neovim (latest stable - Debian's is ancient)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz \
    && tar -C /opt -xzf nvim-linux-arm64.tar.gz \
    && ln -s /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim \
    && rm nvim-linux-arm64.tar.gz

# Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create dev user
RUN useradd -m -s /bin/zsh dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/dev/.ssh \
    && chmod 700 /home/dev/.ssh \
    && chown -R dev:dev /home/dev

# SSH config
RUN mkdir -p /run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Copy config files
COPY --chown=dev:dev config/.tmux.conf /home/dev/.tmux.conf
COPY --chown=dev:dev config/starship.toml /home/dev/.config/starship.toml
COPY --chown=dev:dev config/authorized_keys /home/dev/.ssh/authorized_keys
RUN chmod 600 /home/dev/.ssh/authorized_keys

USER dev
WORKDIR /home/dev

# Zig
RUN curl -LO https://ziglang.org/download/0.13.0/zig-linux-aarch64-0.13.0.tar.xz \
    && tar -C /opt -xf zig-linux-aarch64-0.13.0.tar.xz \
    && ln -s /opt/zig-linux-aarch64-0.13.0/zig /usr/local/bin/zig \
    && rm zig-linux-aarch64-0.13.0.tar.xz

# fnm (Fast Node Manager)
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.fnm" --skip-shell
ENV PATH="/home/dev/.fnm:$PATH"
RUN /home/dev/.fnm/fnm install 22 && /home/dev/.fnm/fnm default 22

# Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/home/dev/.bun/bin:$PATH"

# pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | sh -
ENV PATH="/home/dev/.local/share/pnpm:$PATH"

# Claude Code (native binary)
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.claude/local/bin:$PATH"

# Tmux Plugin Manager
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# LazyVim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim \
    && rm -rf ~/.config/nvim/.git

# Create Code directory
RUN mkdir -p ~/Code

# Shell config
RUN echo 'eval "$(/home/dev/.fnm/fnm env --use-on-cd --shell zsh)"' >> ~/.zshrc \
    && echo 'export PATH="$HOME/.bun/bin:$HOME/.local/share/pnpm:$HOME/.claude/local/bin:$PATH"' >> ~/.zshrc \
    && echo 'eval "$(starship init zsh)"' >> ~/.zshrc \
    && echo '# Git identity from env vars' >> ~/.zshrc \
    && echo 'export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-dev}"' >> ~/.zshrc \
    && echo 'export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-dev}"' >> ~/.zshrc \
    && echo 'export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-dev@local}"' >> ~/.zshrc \
    && echo 'export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-dev@local}"' >> ~/.zshrc

USER root

EXPOSE 22
EXPOSE 60000-60010/udp

COPY --chmod=755 entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
