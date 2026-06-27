# ============================================================
# Stage 1: Node.js LSP servers
# ============================================================
FROM node:lts AS node-lsp
RUN npm install -g \
    typescript@5.8.3 \
    typescript-language-server@4.4.1 \
    bash-language-server@3.3.1 \
    yaml-language-server@1.23.0 \
    vscode-langservers-extracted@4.10.0 \
    eslint@9.39.4 \
    @biomejs/biome@1.9.4 \
    @tailwindcss/language-server@0.14.29 \
    svelte@4.2.19 \
    svelte-language-server@0.18.3 \
    @vue/language-server@3.3.5 \
    @astrojs/language-server@2.16.10 \
    dockerfile-language-server-nodejs@0.15.0 \
    graphql-language-service-cli@3.5.0 \
    @prisma/language-server@31.11.0 \
    vim-language-server@2.3.1 \
    emmet-language-server@0.1.3 \
    deno@2.9.0 \
    intelephense@1.9.4

# ============================================================
# Stage 2: Python LSP servers
# ============================================================
FROM python:3.12-slim AS python-lsp
RUN pip install --no-cache-dir \
    pyright==1.1.411 \
    basedpyright \
    python-lsp-server \
    ruff

# ============================================================
# Stage 3: Go LSP servers
# ============================================================
FROM golang:1.22-bookworm AS go-lsp
RUN go install golang.org/x/tools/gopls@latest

# ============================================================
# Stage 4: Standalone binary downloads (rust, zls, lua, terraform, marksman, texlab, helm)
# ============================================================
FROM ubuntu:24.04 AS downloader
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Rust analyzer
RUN curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz \
    | gzip -d - > /usr/local/bin/rust-analyzer && chmod +x /usr/local/bin/rust-analyzer

# ZLS (.tar.xz format, not .tar.gz)
RUN curl -L https://github.com/zigtools/zls/releases/latest/download/zls-x86_64-linux.tar.xz \
    | tar xJ -C /tmp && mv /tmp/zls /usr/local/bin/zls

# Lua language server (exact version in URL, no wildcard)
RUN curl -L https://github.com/LuaLS/lua-language-server/releases/download/3.18.2/lua-language-server-3.18.2-linux-x64.tar.gz \
    | tar xz -C /tmp && mv /tmp/lua-language-server /opt/lua-language-server

# Terraform LS (v0.30.0 last release with Linux assets; v0.38+ has none)
RUN curl -L https://github.com/hashicorp/terraform-ls/releases/download/v0.30.0/terraform-ls_0.30.0_linux_amd64.zip \
    -o /tmp/terraform-ls.zip && unzip /tmp/terraform-ls.zip -d /usr/local/bin/

# Marksman (filename is marksman-linux-x64, not marksman-x86_64-linux)
RUN curl -L https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64 \
    -o /usr/local/bin/marksman && chmod +x /usr/local/bin/marksman

# Texlab
RUN curl -L https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz \
    | tar xz -C /tmp && mv /tmp/texlab /usr/local/bin/texlab

# Helm LS (hypnos1/helm-ls repo deleted; use mrjosh/helm-ls fork)
RUN curl -L https://github.com/mrjosh/helm-ls/releases/latest/download/helm_ls_linux_x86_64.tar.gz \
    | tar xz -C /tmp && mv /tmp/helm_ls /usr/local/bin/helm_ls

# Nixd
RUN curl -L https://github.com/nix-community/nixd/releases/latest/download/nixd-x86_64-linux-deb12.tar.xz \
    | tar xJ -C /tmp && mv /tmp/nixd /usr/local/bin/nixd && chmod +x /usr/local/bin/nixd

# Nil (nil-editor, the Nix language server)
RUN curl -L https://github.com/oxalica/nil/releases/latest/download/nil-x86_64-unknown-linux-gnu.tar.gz \
    | tar xz -C /tmp && mv /tmp/nil /usr/local/bin/nil && chmod +x /usr/local/bin/nil

# ============================================================
# Stage 5: Kotlin Language Server
# ============================================================
FROM ubuntu:24.04 AS kotlin-lsp
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/kotlin-lsp && \
    curl -L https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip \
        -o /tmp/kotlin-lsp.zip && unzip /tmp/kotlin-lsp.zip -d /opt/kotlin-lsp && \
    ln -sf /opt/kotlin-lsp/server/bin/kotlin-language-server /usr/local/bin/kotlin-ls

# ============================================================
# Stage 6: Haskell Language Server
# ============================================================
FROM ubuntu:24.04 AS hls
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/hls-bin && \
    curl -L https://github.com/haskell/haskell-language-server/releases/latest/download/haskell-language-server-2.14.0.0-x86_64-linux-deb12.tar.xz \
        | tar xJ -C /opt/hls-bin --strip-components=1 && \
    cp /opt/hls-bin/bin/haskell-language-server-wrapper /usr/local/bin/hls && \
    chmod +x /usr/local/bin/hls && \
    cp -r /opt/hls-bin/lib /usr/local/lib/hls-lib

# ============================================================
# Stage 7: OCaml LSP — source tarball (compiled binary inside)
# ============================================================
FROM ubuntu:24.04 AS ocamllsp
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates bzip2 \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /tmp/ocaml-lsp-src && \
    curl -L https://github.com/ocaml/ocaml-lsp/releases/latest/download/lsp-1.27.0.tbz \
        -o /tmp/lsp.tbz && tar xjf /tmp/lsp.tbz -C /tmp/ocaml-lsp-src && \
    find /tmp/ocaml-lsp-src -name 'lsp' -type f | head -1 | while read bin; do \
        echo "Found lsp binary at $bin"; cp "$bin" /usr/local/bin/ocamllsp; \
    done || { \
        find /tmp/ocaml-lsp-src -name 'ocamllsp' -o -name '*.exe' 2>/dev/null | head -1 | while read bin; do \
            cp "$bin" /usr/local/bin/ocamllsp; chmod +x /usr/local/bin/ocamllsp; \
        done || true; \
    }

# ============================================================
# Stage 8: OmniSharp Roslyn (.NET C#/VB/F# language server)
# ============================================================
FROM ubuntu:24.04 AS omnisharp
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/omnisharp && \
    curl -L https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-linux-x64.tar.gz \
        -o /tmp/omnisharp.tar.gz && tar xzf /tmp/omnisharp.tar.gz -C /opt/omnisharp && \
    for d in /opt/omnisharp/*/; do [ -d "$d" ] && mv "$d"* /opt/omnisharp/ && rmdir "$d"; break; done && \
    chmod +x /opt/omnisharp/omnisharp && \
    ln -sf /opt/omnisharp/omnisharp /usr/local/bin/omnisharp

# ============================================================
# Stage 9: JVM-based servers (Java, Scala) — Metals via Maven/coursier
# ============================================================
FROM eclipse-temurin:21-jdk AS jvm-lsp

# JDTLS (Java) — download from official Eclipse release endpoint
RUN mkdir -p /opt/jdtls/bin /opt/jdtls/plugins && \
    curl -L "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz" \
        -o /tmp/jdtls.tar.gz || true && \
    if [ ! -s /tmp/jdtls.tar.gz ]; then \
        curl -L "https://download.eclipse.org/jdtls/release/latest/jdt-language-server-latest.tar.gz" \
            -o /tmp/jdtls.tar.gz; \
    fi && \
    tar xzf /tmp/jdtls.tar.gz -C /opt/jdtls && \
    chmod +x /opt/jdtls/bin/jdtls

# Metals (Scala) — no GitHub assets available; use coursier to install
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates \
    && rm -rf /var/lib/apt/lists/* && \
    wget -qO /usr/local/bin/coursier https://github.com/coursier/launchers/raw/master/coursier && \
    chmod +x /usr/local/bin/coursier && \
    /usr/local/bin/coursier bootstrap org.scalameta:metals_3.4.2_2.13:1.6.7 -o /usr/local/bin/metals -f 2>/dev/null || { \
        mkdir -p /opt/metals && \
        curl -L "https://repo1.maven.org/maven2/org/scalameta/metals_3.4.2_2.13/1.6.7/metals_3.4.2_2.13-1.6.7.jar" \
            -o /opt/metals/metals.jar && \
        printf '#!/bin/bash\nexec java -jar /opt/metals/metals.jar "$@"\n' > /usr/local/bin/metals && \
        chmod +x /usr/local/bin/metals; \
    }

# ============================================================
# Stage 10: Ruby servers
# ============================================================
FROM ruby:3.3 AS ruby-lsp
RUN gem install --no-document solargraph ruby-lsp rubocop

# ============================================================
# Stage 11: Perl LSP servers
# ============================================================
FROM node:lts AS perl-lsp
RUN npm install -g perlnavigator-server

FROM perl:5.38-slim AS perl-runtime
RUN apt-get update && apt-get install -y --no-install-recommends gcc && cpanm --quiet --no-interaction PPI Class::Inspector Devel::Symdump Sub::Util Scalar::Util List::Util File::Spec Storable File::Basename Encode Perl::Critic Perl::Tidy App::perlimports && apt-get purge -y gcc && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# ============================================================
# Stage 12: Erlang/Elixir servers
# ============================================================
FROM elixir:1.17-slim AS erlang-lsp

RUN curl -L https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls-v0.31.1.zip \
    -o /tmp/elixir-ls.zip && unzip -q /tmp/elixir-ls.zip -d /opt/elixir-ls && \
    cat > /usr/local/bin/elixir_ls << 'WRAPPER'
#!/bin/sh
export ELS_INSTALL_PREFIX=/opt/elixir-ls
exec "$ELS_INSTALL_PREFIX/language_server.sh" "$@"
WRAPPER
    chmod +x /usr/local/bin/elixir_ls && rm -f /tmp/elixir-ls.zip

# expert — removed (gleam-lang/expert repo is gone, 404)
# erlang_ls — removed (not available on PyPI, project discontinued)

# ============================================================
# Final image
# ============================================================
FROM ubuntu:24.04

LABEL org.opencontainers.image.description="OhMyPi-capable Docker image with all LSP binaries"
LABEL org.opencontainers.image.source="https://github.com/omp/omp_agent"

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates ripgrep clangd shellcheck \
    fortran-language-server unzip xz-utils wget bzip2 \
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
COPY --from=downloader /usr/local/bin/nixd /usr/local/bin/nixd
COPY --from=downloader /usr/local/bin/nil /usr/local/bin/nil
COPY --from=downloader /opt/lua-language-server /opt/lua-language-server
COPY --from=kotlin-lsp /usr/local/bin/kotlin-ls /usr/local/bin/kotlin-ls
COPY --from=hls /usr/local/bin/hls /usr/local/bin/hls
COPY --from=ocamllsp /usr/local/bin/ocamllsp /usr/local/bin/ocamllsp || true
COPY --from=omnisharp /usr/local/bin/omnisharp /usr/local/bin/omnisharp || true
COPY --from=jvm-lsp /opt/jdtls /opt/jdtls/
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
