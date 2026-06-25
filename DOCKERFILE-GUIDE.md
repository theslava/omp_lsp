# Dockerfile Guide

This document describes the Dockerfile architecture, build patterns, and optimization strategies for the OhMyPi LSP Docker image.

## Image Structure

```
omp_agent/
├── Dockerfile              # Main image definition
├── .omp/
│   ├── mcp.json            # MCP server config (copied into image)
│   └── agents/             # Agent definitions (copied into image)
├── lsp-markers/            # Empty marker files that trigger LSP auto-discovery
└── lsp_trigger/            # (empty) — future LSP trigger scripts
```

## LSP Auto-Discovery via Root Markers

OMP auto-discovers LSP servers by checking if the **project workspace directory** contains at least one of each server's `rootMarkers` (defined in OMP's built-in `defaults.json`). The `lsp-markers/` directory contains minimal empty files — one per unique LSP server — that serve as project root indicators.

When OMP opens a workspace, it scans that directory for these marker files. If found and the corresponding server binary is on `PATH`, the server is automatically launched.

### How It Works

```
OMP scans workspace root
  → finds "Cargo.toml"
  → matches rust-analyzer's rootMarkers: ["Cargo.toml", "rust-analyzer.toml"]
  → checks PATH for "rust-analyzer" binary
  → launches rust-analyzer over stdin/stdout
```

### Marker File Inventory

The `lsp-markers/` directory contains the minimal set of empty files needed to trigger all 52 built-in LSP servers from OMP's `defaults.json`:

| Marker File | LSP Server(s) Triggered |
|---|---|
| `.git` | bashls, emmet-language-server, vimls, yamlls |
| `package.json` | typescript-language-server, vscode-html, vscode-css, vscode-json, vue-language-server |
| `pyproject.toml` | pyright, basedpyright, pylsp, ruff |
| `build.gradle` or `pom.xml` | jdtls, kotlin-lsp, metals |
| `Gemfile` | rubocop, ruby-lsp, solargraph |
| `mix.exs` | elixirls, expert |
| `default.nix` or `flake.nix` | nixd, nil |
| `Package.swift` | sourcekit-lsp, swiftlint |
| `composer.json` | intelephense, phpactor |
| `.clang-format` | clangd |
| `.luarc.json` | lua-language-server |
| `.marksman.toml` | marksman |
| `.ocamlformat` | ocamllsp |
| `.swiftlint.yaml` | swiftlint |
| `.terraform` | terraformls |
| `Cargo.toml` | rust-analyzer |
| `Chart.yaml` | helm-ls |
| `Dockerfile` | dockerls |
| `astro.config.js` | astro-ls |
| `biome.json` | biome |
| `build.zig` | zls |
| `deno.json` | denols |
| `erlang.mk` | erlangls |
| `eslint.config.js` | eslint |
| `gleam.toml` | gleam |
| `go.mod` | gopls |
| `graphql.config.js` | graphql |
| `hie.yaml` | hls |
| `latexmkrc` or `.latexmkrc` | texlab |
| `nuxt.config.js` | vue-language-server |
| `ols.json` | ols |
| `omnisharp.json` | omnisharp |
| `pubspec.yaml` | dartls |
| `ruff.toml` | ruff |
| `schema.prisma` | prismals |
| `svelte.config.js` | svelte |
| `tailwind.config.js` | tailwindcss |
| `empty.tla` | tlaplus (via `*.tla` glob pattern) |

**Total: 34 marker files → 52 unique LSP servers**

Some markers trigger multiple servers (e.g., `Gemfile` → 3 servers, `build.gradle` → 3 servers, `package.json` → 5 servers). The set is optimized via greedy set cover to minimize the number of files while covering all servers.

## Current Dockerfile

```dockerfile
FROM ubuntu:24.04

# run as root
RUN apt-get update && apt-get install -y \
    curl git ca-certificates ripgrep clangd \
    && rm -rf /var/lib/apt/lists/*

RUN sed -ie 's/ubuntu/slava/g' /etc/passwd* /etc/group*
RUN mv /home/ubuntu /home/slava

# Become slava user
USER slava:slava
ENV PATH="/home/slava/.local/bin:$PATH"

# OMP standalone binary
RUN curl -fsSL https://omp.sh/install | bash

CMD ["sleep", "infinity"]
```

## Key Design Decisions

### 1. Ubuntu 24.04 Base

- Current LTS with long support window
- Ships clangd 18, shellcheck 0.9.0, fortran-language-server
- Familiar package management (`apt`)
- Reasonable image size (~150MB base)

### 2. User `slava`

The existing image renames `ubuntu` to `slava` via `/etc/passwd` and `/etc/group` manipulation. This is preserved for compatibility with OMP's default `~/.omp` path resolution.

### 3. OMP Installation

OMP is installed via the official installer script:

```bash
curl -fsSL https://omp.sh/install | bash
```

This places the binary at `/home/slava/.local/bin/omp` (~150MB binary). The binary is self-contained and requires no additional dependencies.

### 4. Multi-Stage Builds

For LSP servers that require build toolchains (Go, Rust, Node.js, JVM, Ruby, Erlang), use multi-stage builds:

```dockerfile
# Stage 1: Build LSP servers
FROM golang:1.22-bookworm AS gopls-builder
RUN go install golang.org/x/tools/gopls@v0.18.0

FROM node:lts AS node-builder
RUN npm install -g typescript@5.5.4 typescript-language-server@4.3.3

# Stage 2: Final image
FROM ubuntu:24.04
COPY --from=gopls-builder /go/bin/gopls /usr/local/bin/gopls
COPY --from=node-builder /usr/local/bin/typescript-language-server /usr/local/bin/typescript-language-server
```

This keeps the final image lean — only the compiled binaries are copied, not the build toolchains.

### 5. Layer Optimization

- Combine `apt-get` commands to reduce layers
- Use `--no-install-recommends` to minimize installed packages
- Clean apt cache in the same layer: `&& rm -rf /var/lib/apt/lists/*`
- Use `.dockerignore` to exclude unnecessary files

## Dockerfile Rewrite Plan

The Dockerfile should be rewritten to include all 60+ built-in LSP servers from OMP's `defaults.json`. No server is excluded.

```dockerfile
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
    emmet-language-server

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
# jdtls and metals binaries would be downloaded here

# ============================================================
# Stage 6: Ruby servers
# ============================================================
FROM ruby:3.3 AS ruby-lsp
RUN gem install solargraph ruby-lsp rubocop

# ============================================================
# Stage 7: Erlang/Elixir servers
# ============================================================
FROM erlang:26 AS erlang-lsp
# elixirls, expert, erlang_ls binaries

# ============================================================
# Stage 8: Final image
# ============================================================
FROM ubuntu:24.04

LABEL org.opencontainers.image.description="OhMyPi-capable Docker image with all LSP binaries"
LABEL org.opencontainers.image.source="https://github.com/omp/omp_agent"

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates ripgrep clangd shellcheck \
    fortran-language-server \
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
COPY --from=jvm-lsp /opt /opt
COPY --from=ruby-lsp /usr/local/bin /usr/local/bin

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
```

## Image Size Estimates

| Component | Size |
|-----------|------|
| Ubuntu 24.04 base | ~77MB |
| OMP binary | ~153MB |
| clangd + system libs | ~50MB |
| Node.js LSP servers | ~80MB |
| Python LSP servers | ~40MB |
| Go LSP servers | ~30MB |
| Standalone binaries (rust-analyzer, zls, terraform-ls, etc.) | ~50MB |
| JVM servers (jdtls, metals) | ~200MB |
| Ruby gems | ~30MB |
| Erlang/Elixir servers | ~20MB |
| **Estimated total** | **~730MB** |

Using `node:lts`, `python:3.12-slim`, `golang:1.22-bookworm`, `eclipse-temurin:21-jdk`, `ruby:3.3`, `erlang:26` as builder stages adds significant temporary space but doesn't affect the final image.

## .dockerignore

```
.git
.github
*.md
!Dockerfile
!DOCKERFILE-GUIDE.md
!LSP-SERVERS.md
!AGENTS.md
node_modules
*.log
.omp/agent/sessions
.omp/agent/*.db*
.omp/logs
.lsp_trigger
```

## Build Commands

```bash
# Standard build
docker build -t omp-lsp:latest .

# Build with buildkit for better caching
DOCKER_BUILDKIT=1 docker build -t omp-lsp:latest .

# Run with workspace mount
docker run -it --rm -v $(pwd):/workspace -w /workspace omp-lsp:latest omp

# Run with specific model
docker run -it --rm -v $(pwd):/workspace -w /workspace \
    -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    omp-lsp:latest omp --model opus

# Run with MCP servers (mount config volume)
docker run -it --rm -v $(pwd):/workspace -w /workspace \
    -v $(pwd)/.omp:/home/slava/.omp \
    omp-lsp:latest omp
```

## Testing the Image

```bash
# Verify all LSP servers are on PATH
docker run --rm omp-lsp:latest bash -c '
  for bin in clangd rust-analyzer zls gopls typescript-language-server \
    denols biome eslint vscode-html-language-server vscode-css-language-server \
    vscode-json-language-server tailwindcss svelte-language-server \
    vue-language-server astro-ls bash-language-server yaml-language-server \
    dockerfile-language-server-nodejs graphql-lsp prismals vim-language-server \
    emmet-language-server pyright-langserver basedpyright pylsp ruff \
    lua-language-server terraform-ls marksman texlab helm_ls \
    solargraph ruby-lsp rubocop; do
    which $bin && echo "OK: $bin" || echo "MISSING: $bin"
  done
'

# Test OMP starts correctly
docker run --rm omp-lsp:latest omp --help

# Test LSP handshake for a specific server
docker run --rm omp-lsp:latest bash -c \
  'echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"processId\":1,\"rootUri\":\"file:///\",\"capabilities\":{}}}" | timeout 5 clangd --log=error'

# Verify all 60+ servers respond
docker run --rm omp-lsp:latest bash -c '
  count=0; missing=0
  for bin in clangd rust-analyzer zls gopls typescript-language-server \
    denols biome eslint vscode-html-language-server vscode-css-language-server \
    vscode-json-language-server tailwindcss svelte-language-server \
    vue-language-server astro-ls bash-language-server yaml-language-server \
    dockerfile-language-server-nodejs graphql-lsp prismals vim-language-server \
    emmet-language-server pyright-langserver basedpyright pylsp ruff \
    lua-language-server terraform-ls marksman texlab helm_ls \
    solargraph ruby-lsp rubocop jdtls metals hls ocamllsp elixirls expert \
    erlangls gleam solargraph ruby-lsp rubocop intelephense phpactor \
    omnisharp nixd nil ols dartls sourcekit-lsp swiftlint tlapm_lsp \
    marksman texlab helm_ls; do
    if which $bin >/dev/null 2>&1; then
      ((count++))
    else
      echo "MISSING: $bin"
      ((missing++))
    fi
  done
  echo "Found: $count / $((count + missing))"
'
```

## Optimization Tips

1. **Combine RUN layers** — fewer layers = smaller image
2. **Use `--no-install-recommends`** — avoids pulling in unnecessary packages
3. **Clean caches in same layer** — `&& rm -rf /var/lib/apt/lists/*`
4. **Use `.dockerignore`** — prevents unnecessary files from being sent to the build context
5. **Use BuildKit cache mounts** — `RUN --mount=type=cache,target=/go/pkg/mod` for Go builds
6. **Use BuildKit cache mounts** — `RUN --mount=type=cache,target=/root/.npm` for npm builds
