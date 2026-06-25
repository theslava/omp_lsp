# ============================================================
# Stage 1: Node.js LSP servers
# ============================================================
FROM node:lts AS node-lsp
RUN npm install -g \
    typescript@5.x \
    typescript-language-server@4.x \
    bash-language-server@3.x \
    yaml-language-server@1.x \
    vscode-langservers-extracted@5.x \
    eslint@9.x \
    @biomejs/biome@1.x \
    @tailwindcss/language-server \
    svelte@4.x \
    svelte-language-server \
    @vue/language-server \
    @astrojs/language-server \
    dockerfile-language-server-nodejs \
    graphql-language-service-cli \
    @prisma/language-server \
    vim-language-server \
    emmet-language-server \
    deno \
    intelephense

# ============================================================
# Stage 2: Python LSP servers
# ============================================================
FROM python:3.12-slim AS python-lsp
RUN pip install --no-cache-dir \
    pyright==1.1.x \
    basedpyright \
    python-lsp-server \
    ruff==0.5.x

# ============================================================
# Stage 3: Go LSP servers
# ============================================================
FROM golang:1.22-bookworm AS go-lsp
RUN go install golang.org/x/tools/gopls@latest

# ============================================================
# Stage 4: Download standalone binaries
# ============================================================
FROM ubuntu:24.04 AS downloader
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Rust analyzer
RUN curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz \
    | gzip -d - > /usr/local/bin/rust-analyzer && chmod +x /usr/local/bin/rust-analyzer

# ZLS
RUN curl -L https://github.com/zigtools/zls/releases/latest/download/zls-linux-x86_64.tar.gz \
    | tar xz -C /tmp && mv /tmp/zls /usr/local/bin/zls

# Lua language server
RUN curl -L https://github.com/LuaLS/lua-language-server/releases/download/3.x/lua-language-server-3.x-linux-x64.tar.gz \
    | tar xz -C /tmp && mv /tmp/lua-language-server /opt/lua-language-server

# Terraform LS
RUN curl -L https://github.com/hashicorp/terraform-ls/releases/download/v0.30.0/terraform-ls_0.30.0_linux_amd64.zip \
    -o /tmp/terraform-ls.zip && unzip /tmp/terraform-ls.zip -d /usr/local/bin/

# Marksman
RUN curl -L https://github.com/artempyanykh/marksman/releases/latest/download/marksman-x86_64-linux.tar.gz \
    | tar xz -C /tmp && mv /tmp/marksman /usr/local/bin/marksman

# Texlab
RUN curl -L https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz \
    | tar xz -C /tmp && mv /tmp/texlab /usr/local/bin/texlab

# Helm LS
RUN curl -L https://github.com/hypnos1/helm-ls/releases/latest/download/helm_ls_linux_x86_64.tar.gz \
    | tar xz -C /tmp && mv /tmp/helm_ls /usr/local/bin/helm_ls

# ============================================================
# Stage 5: JVM-based servers (Java, Scala)
# ============================================================
FROM eclipse-temurin:21-jdk AS jvm-lsp

# JDTLS (Java)
RUN mkdir -p /opt/jdtls/bin /opt/jdtls/plugins && \
    curl -L https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz \
    | tar xz -C /opt/jdtls && \
    chmod +x /opt/jdtls/bin/jdtls

# Metals (Scala)
RUN curl -L https://github.com/scalameta/metals/releases/latest/download/metals_3-1.3.5.zip \
    -o /tmp/metals.zip && unzip /tmp/metals.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/metals

# ============================================================
# Stage 6: Ruby servers
# ============================================================
FROM ruby:3.3 AS ruby-lsp
RUN gem install --no-document solargraph ruby-lsp rubocop

# ============================================================
# Stage 7.5: Perl LSP servers
# ============================================================
FROM node:lts AS perl-lsp
RUN npm install -g perlnavigator-server

FROM perl:5.38-slim AS perl-runtime
RUN apt-get update && apt-get install -y --no-install-recommends gcc && cpanm --quiet --no-interaction PPI Class::Inspector Devel::Symdump Sub::Util Scalar::Util List::Util File::Spec Storable File::Basename Encode Perl::Critic Perl::Tidy App::perlimports && apt-get purge -y gcc && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# ============================================================
# Stage 7: Erlang/Elixir servers
# ============================================================
FROM erlang:26 AS erlang-lsp

# Install Elixir for elixir-ls
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# elixirls
RUN curl -L https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip \
    -o /tmp/elixir-ls.zip && unzip /tmp/elixir-ls.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/elixir-ls /usr/local/bin/language-server.sh

# expert
RUN curl -L https://github.com/gleam-lang/expert/releases/latest/download/expert-x86_64-unknown-linux-gnu.zip \
    -o /tmp/expert.zip && unzip /tmp/expert.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/expert

# erlang_ls
RUN pip install --no-cache-dir erlang-ls

# ============================================================
# Final image
# ============================================================
FROM ubuntu:24.04

LABEL org.opencontainers.image.description="OhMyPi-capable Docker image with all LSP binaries"
LABEL org.opencontainers.image.source="https://github.com/omp/omp_agent"

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates ripgrep clangd shellcheck \
    fortran-language-server unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy LSP binaries from builder stages
COPY --from=node-lsp /usr/local/bin /usr/local/bin
COPY --from=python-lsp /usr/local/bin /usr/local/bin
COPY --from=go-lsp /go/bin/gopls /usr/local/bin/gopls
COPY --from=downloader /usr/local/bin/rust-analyzer /usr/local/bin/rust-analyzer
COPY --from=downloader /usr/local/bin/zls /usr/local/bin/zls
COPY --from=downloader /usr/local/bin/terraform-ls /usr/local/bin/terraform-ls
COPY --from=downloader /usr/local/bin/marksman /usr/local/bin/marksman
COPY --from=downloader /usr/local/bin/texlab /usr/local/bin/texlab
COPY --from=downloader /usr/local/bin/helm_ls /usr/local/bin/helm_ls
COPY --from=downloader /opt/lua-language-server /opt/lua-language-server
COPY --from=jvm-lsp /opt/jdtls /opt/jdtls
COPY --from=jvm-lsp /usr/local/bin/metals /usr/local/bin/metals
COPY --from=ruby-lsp /usr/local/bin /usr/local/bin
COPY --from=erlang-lsp /usr/local/bin /usr/local/bin
COPY --from=perl-lsp /usr/local/bin/perlnavigator /usr/local/bin/perlnavigator
COPY --from=perl-runtime /usr/local/bin/perl /usr/local/bin/perl
COPY --from=perl-runtime /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=perl-runtime /etc/perl /etc/perl

# Create non-root user
RUN sed -ie 's/ubuntu/slava/g' /etc/passwd* /etc/group* \
    && mv /home/ubuntu /home/slava

# Set up OMP
USER slava:slava
ENV PATH="/home/slava/.local/bin:$PATH"
RUN curl -fsSL https://omp.sh/install | bash

# Copy MCP config
COPY --chown=slava:slava .omp/mcp.json /home/slava/.omp/mcp.json

# Copy agent definitions
RUN mkdir -p /home/slava/.omp/agent/agents
COPY --chown=slava:slava .omp/agents/ /home/slava/.omp/agent/agents/

WORKDIR /workspace
VOLUME ["/workspace"]

CMD ["omp"]
