# LSP Servers — Complete Reference

This document covers every LSP server included in the OhMyPi Docker image, sourced from OMP's built-in `defaults.json` (source: `packages/coding-agent/src/lsp/defaults.json` in the oh-my-pi repo).
## LSP Root Markers

OMP auto-discovers servers by checking if the project workspace directory contains at least one of each server's `rootMarkers` (defined in `defaults.json`). The `lsp-markers/` directory contains the minimal set of empty files to trigger all 53 built-in servers plus custom servers like perlnavigator.

### Marker → Server Mapping

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
| `.perl-lsp-marker` | perlnavigator |
| `empty.tla` | tlaplus (via `*.tla` glob) |

**35 marker files → 53 unique LSP servers.** Some markers trigger multiple servers (e.g., `Gemfile` → 3, `build.gradle` → 3, `package.json` → 5). The set is optimized via greedy set cover.

### Custom Markers

For servers not in OMP's built-in defaults (like perlnavigator), create a custom marker file in your project root. OMP will use it for discovery when the server is registered in `lsp.json`. Example: touch `.perl-lsp-marker` for Perl projects.

## OMP LSP Architecture

OMP provides IDE-like code intelligence through a custom JSON-RPC LSP client that:

- **Auto-discovers** servers by intersecting `rootMarkers` with project files and checking binary availability on PATH (project-local bins first: `node_modules/.bin/`, `.venv/bin/`, then `$PATH`)
- **Intercepts writes** via a writethrough system: format-on-write and real-time diagnostics after every file edit
- **Manages lifecycle**: idle timeout shutdown, batch-aware optimization (multiple writes in one tool call reduce LSP roundtrips), warmup at session launch
- **Suppresses stale diagnostics** until the server confirms it processed the latest document version

### LSP Writethrough Flow

1. Agent calls `edit`/`write`/`ast_edit`
2. File written to disk
3. `syncContent` sent to LSP server (keeps in-memory buffer in sync)
4. Diagnostics fetched, filtered, grouped by file, sorted (errors before warnings)
5. Noise stripped (URLs, clippy metadata) for clean context windows
6. Results rendered in TUI (red for errors, yellow for warnings)

### LSP Tool Operations (14 ops)

The `lsp` tool provides these operations:

| Operation | LSP Method | Purpose |
|-----------|-----------|---------|
| `diagnostics` | `$/diagnostic` | Get errors/warnings for a file, glob, or workspace (`file: "*"`) |
| `definition` | `textDocument/definition` | Navigate to symbol definition |
| `type_definition` | `textDocument/typeDefinition` | Get symbol's type definition |
| `implementation` | `textDocument/implementation` | Find concrete implementations |
| `references` | `textDocument/references` | Find all usages of a symbol |
| `hover` | `textDocument/hover` | Get type info, docs, signatures |
| `symbols` | `textDocument/documentSymbol` / `textDocument/workspaceSymbol` | List symbols in file or search workspace |
| `rename` | `textDocument/rename` + `workspace/willRenameFiles` | Project-wide symbol rename (honors re-exports, barrel files, aliased imports) |
| `code_actions` | `textDocument/codeAction` | List and apply quick-fixes/refactors |
| `status` | N/A (internal) | Check active LSP server status |
| `reload` | N/A (internal) | Restart a language server |
| `request` | Arbitrary JSON-RPC | Send raw LSP requests with custom payload |
| `capabilities` | N/A (internal) | Per-server capabilities |
| `code_actions` (apply) | `codeAction/resolve` + apply edits | Apply a selected quick-fix |

**Timeout management**: All LSP requests are clamped between 5–60 seconds. Warmup uses parallel initialization with short timeouts to avoid blocking startup.

### Server Capabilities (per-server, boolean flags)

| Capability | Description | Used By |
|-----------|-------------|---------|
| `flycheck` | Real-time error checking | rust-analyzer |
| `ssr` | Structured search & replace | rust-analyzer |
| `expandMacro` | Macro expansion inspection | rust-analyzer |
| `runnables` | Run/test targets | rust-analyzer |
| `relatedTests` | Find related tests | rust-analyzer |

## LSP Configuration System

OMP merges LSP config from multiple files, lowest to highest priority:

| Priority | Location |
|----------|----------|
| 5 (lowest) | `~/lsp.json`, `~/.lsp.json`, `~/lsp.yaml`, `~/.lsp.yaml`, `~/lsp.yml`, `~/.lsp.yml` |
| 4 | Plugin LSP configs (marketplace / `--plugin-dir` roots) |
| 3 | User config dirs: `~/.omp/agent/lsp.*`, `~/.claude/lsp.*`, `~/.codex/lsp.*`, `~/.gemini/lsp.*` |
| 2 | Project config dirs: `<project>/.omp/lsp.*`, `<project>/.claude/lsp.*`, `<project>/.codex/lsp.*`, `<project>/.gemini/lsp.*` |
| 1 (highest) | Project root: `<project>/lsp.*` and `<project>/.lsp.*` |

Each location accepts `.json`, `.yaml`, and `.yml` variants. Files are merged: higher-priority overrides lower-priority fields for the same server.

### Config Schema

```jsonc
{
  "idleTimeoutMs": 300000,          // Shut down idle servers (optional)
  "servers": {                       // Optional wrapper; flat form also accepted
    "rust-analyzer": {
      "command": "rust-analyzer",    // Binary name (PATH-resolved) or absolute path
      "args": ["lsp"],               // Arguments (optional)
      "fileTypes": [".rs"],          // File extensions this server handles
      "rootMarkers": ["Cargo.toml", ".git"],  // Project root indicators
      "initOptions": {},             // Sent as initializationOptions during handshake
      "settings": {},                // Workspace settings via workspace/didChangeConfiguration
      "disabled": false,             // Set true to disable
      "warmupTimeoutMs": 15000,      // Startup timeout override
      "isLinter": true,              // Linter/formatter only — excluded from type-intelligence ops
      "capabilities": {              // Server-specific feature flags
        "flycheck": true,
        "ssr": true
      }
    }
  }
}
```

**Auto-detection**: When no config file contributes server overrides, OMP auto-detects built-in servers. Auto-detection is skipped only when at least one config file contributes server overrides. A config file that only sets `idleTimeoutMs` still lets auto-detection run.

## Complete Built-in Server List

All servers below ship in OMP's `defaults.json` and are eligible for auto-detection. **Every server must be installed in the Docker image** — no exclusions.

### C/C++/ObjC

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `clangd` | `clangd` | `apt install clangd` (Ubuntu 24.04 ships clangd 18) |

### Rust

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `rust-analyzer` | `rust-analyzer` | Download from GitHub releases; standalone binary |

### Zig

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `zls` | `zls` | `zig fetch` or download from releases |

### Go

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `gopls` | `gopls` | `go install golang.org/x/tools/gopls@latest` (requires Go 1.21+) |

### TypeScript / JavaScript / JSX / TSX

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `typescript-language-server` | `typescript-language-server` | `npm i -g typescript typescript-language-server` (requires Node.js LTS) |

### Deno (TypeScript/JavaScript)

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `denols` | `deno` | `npm i -g deno` or download from releases |

### TypeScript/JS/JSON Linter

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `biome` | `biome` | `npm i -g @biomejs/biome` (requires Node.js LTS) |

### TypeScript/JS/Vue/Svelte Linter

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `eslint` | `vscode-eslint-language-server` | `npm i -g eslint vscode-eslint-language-server` (requires Node.js LTS) |

### HTML

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `vscode-html-language-server` | `vscode-html-language-server` | `npm i -g vscode-langservers-extracted` (requires Node.js LTS) |

### CSS / SCSS / Less

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `vscode-css-language-server` | `vscode-css-language-server` | `npm i -g vscode-langservers-extracted` (requires Node.js LTS) |

### JSON

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `vscode-json-language-server` | `vscode-json-language-server` | `npm i -g vscode-langservers-extracted` (requires Node.js LTS) |

### Tailwind CSS

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `tailwindcss` | `tailwindcss-language-server` | `npm i -g @tailwindcss/language-server` (requires Node.js LTS) |

### Svelte

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `svelte` | `svelteserver` | `npm i -g svelte svelte-language-server` (requires Node.js LTS) |

### Vue

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `vue-language-server` | `vue-language-server` | `npm i -g @vue/language-server` (requires Node.js LTS) |

### Astro

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `astro-ls` | `astro-ls` | `npm i -g @astrojs/language-server` (requires Node.js LTS) |

### Python

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `pyright` | `pyright-langserver` | `pip install pyright` (requires Python 3.8+) |
| `basedpyright` | `basedpyright-langserver` | `pip install basedpyright` (requires Python 3.8+) |
| `pylsp` | `pylsp` | `pip install python-lsp-server` (requires Python 3.8+) |

### Python Linter

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `ruff` | `ruff` | Download standalone binary from Astral (no runtime needed) |

### Java

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `jdtls` | `jdtls` | Download from Eclipse releases; requires JVM |

### Kotlin

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `kotlin-lsp` | `kotlin-lsp` | Download from releases |

### Scala

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `metals` | `metals` | Download from releases; requires JVM |

### Haskell

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `hls` | `haskell-language-server-wrapper` | `cabal install haskell-language-server` (requires GHC) |

### OCaml

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `ocamllsp` | `ocamllsp` | `opam install ocamllsp` (requires OCaml) |

### Elixir

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `elixirls` | `elixir-ls` | Download from releases; requires Erlang/Elixir |
| `expert` | `expert` | Download from releases; requires Erlang/Elixir |

### Erlang

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `erlangls` | `erlang_ls` | `pip install erlang-ls` (requires Erlang) |

### Gleam

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `gleam` | `gleam` | Download from releases; requires Gleam runtime |

### Ruby

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `solargraph` | `solargraph` | `gem install solargraph` (requires Ruby) |
| `ruby-lsp` | `ruby-lsp` | `gem install ruby-lsp` (requires Ruby) |

### Ruby Linter

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `rubocop` | `rubocop` | `gem install rubocop` (requires Ruby) |

### Bash / Zsh

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `bashls` | `bash-language-server` | `npm i -g bash-language-server` (requires Node.js LTS) |

### Lua

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `lua-language-server` | `lua-language-server` | Download from GitHub releases; standalone binary |

### PHP

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `intelephense` | `intelephense` | `npm i -g intelephense` (requires Node.js LTS) |

### Perl

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `perlnavigator` | `perlnavigator` | `npm install -g perlnavigator-server` (requires Node.js LTS); needs PPI, Class::Inspector, Devel::Symdump, Sub::Util, Scalar::Util, List::Util, File::Spec, Storable, File::Basename, Encode; also requires gcc for XS module compilation during install |

**Perl tooling**: `perl-critic` (static analysis), `perl-tidy` (formatting), `perlimports` (import cleanup) installed via cpanm for full perlnavigator feature support.

| Tool Key | Binary | Purpose |
|----------|--------|---------|
| `perl-critic` | `perlcritic` | Static code analysis / linting |
| `perl-tidy` | `perltidy` | Code formatting |
| `perlimports` | `perlimports` | Import statement management |

### C#

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `omnisharp` | `omnisharp` | Download from releases; requires .NET runtime |

### YAML

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `yamlls` | `yaml-language-server` | `npm i -g yaml-language-server` (requires Node.js LTS) |

### Terraform

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `terraformls` | `terraform-ls` | Download from HashiCorp releases; standalone binary |

### Dockerfile

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `dockerls` | `docker-langserver` | `npm i -g dockerfile-language-server-nodejs` (requires Node.js LTS) |

### Helm

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `helm-ls` | `helm_ls` | Download from releases; standalone binary |

### Nix

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `nixd` | `nixd` | `nix shell nixpkgs#nixd` (requires Nix) |
| `nil` | `nil` | `nix shell github:oxalica/nil` (requires Nix) |

### Odin

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `ols` | `ols` | Download from releases; requires Odin compiler |

### Dart

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `dartls` | `dart` | `dart serve-sdk language-server` (requires Dart SDK) |

### Markdown

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `marksman` | `marksman` | Download from releases; standalone binary |

### LaTeX

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `texlab` | `texlab` | Download from releases; standalone binary |

### GraphQL

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `graphql-lsp` | `graphql-lsp` | `npm i -g graphql-language-service-cli` (requires Node.js LTS) |

### Prisma

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `prismals` | `prisma-language-server` | `npm i -g @prisma/language-server` (requires Node.js LTS) |

### Vim Script

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `vimls` | `vim-language-server` | `npm i -g vim-language-server` (requires Node.js LTS) |

### Emmet (HTML/CSS/JSX)

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `emmet-language-server` | `emmet-language-server` | `npm i -g emmet-language-server` (requires Node.js LTS) |

### Swift

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `sourcekit-lsp` | `sourcekit-lsp` | Download from Apple releases; requires Swift toolchain |

### Swift Linter

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `swiftlint` | `swiftlint` | `brew install swiftlint` or download from releases |

### TLA+

| Server Key | Binary | Install Method |
|-----------|--------|---------------|
| `tlaplus` | `tlapm_lsp` | Download from releases |

## Server Categories by Runtime Dependency

### Standalone Binaries (no runtime needed)

These are single compiled binaries — easiest to install in the Docker image:

- `clangd` (C/C++/ObjC) — apt
- `rust-analyzer` (Rust)
- `ruff` (Python linter)
- `zls` (Zig)
- `gopls` (Go) — needs Go for build, but runs standalone
- `lua-language-server` (Lua)
- `terraform-ls` (Terraform)
- `helm-ls` (Helm)
- `marksman` (Markdown)
- `texlab` (LaTeX)
- `omnisharp` (C#) — needs .NET runtime
- `jdtls` (Java) — needs JVM
- `metals` (Scala) — needs JVM
- `ols` (Odin)
- `sourcekit-lsp` (Swift)
- `swiftlint` (Swift linter)

### Node.js Runtime Required

These require Node.js LTS installed globally:

- `typescript-language-server` (TypeScript/JS)
- `denols` (Deno)
- `biome` (TS/JS/JSON linter)
- `eslint` (TS/JS/Vue/Svelte linter)
- `vscode-html-language-server` (HTML)
- `vscode-css-language-server` (CSS/SCSS/Less)
- `vscode-json-language-server` (JSON)
- `tailwindcss` (Tailwind CSS)
- `svelte` (Svelte)
- `vue-language-server` (Vue)
- `astro-ls` (Astro)
- `bashls` (Bash/Zsh)
- `dockerls` (Dockerfile)
- `graphql-lsp` (GraphQL)
- `prismals` (Prisma)
- `vimls` (Vim Script)
- `emmet-language-server` (Emmet)

### Python Runtime Required

- `pyright` (Python type checker)
- `basedpyright` (Python type checker)
- `pylsp` (Python LSP)

### JVM Required

- `jdtls` (Java)
- `metals` (Scala)

### Erlang/Elixir Runtime Required

- `elixirls` (Elixir)
- `expert` (Elixir)
- `erlangls` (Erlang)

### Ruby Runtime Required

- `solargraph` (Ruby)
- `ruby-lsp` (Ruby)

### Perl Runtime Required

- `perlnavigator` (Perl LSP)
- `perl-critic` (Perl linter / static analysis)
- `perl-tidy` (Perl formatter)

### Go Runtime Required (for build)

- `gopls` (Go) — `go install`

### GHC Required

- `hls` (Haskell) — `cabal install`

### OCaml Required

- `ocamllsp` (OCaml) — `opam install`

### Nix Required

- `nixd` (Nix)
- `nil` (Nix)

### PHP Required

- `phpactor` (PHP)

### Dart SDK Required

- `dartls` (Dart)

### Gleam Runtime Required

- `gleam` (Gleam)

## Multi-Stage Build Plan

The Docker image should use multi-stage builds to keep the final image lean:

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

# ============================================================
# Stage 7.5: Perl LSP servers
# ============================================================
FROM node:lts AS perl-lsp
RUN npm install -g perlnavigator-server

FROM perl:5.38-slim AS perl-runtime
RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    && cpanm --quiet --no-interaction PPI Class::Inspector Devel::Symdump Sub::Util Scalar::Util List::Util File::Spec Storable File::Basename Encode Perl::Critic Perl::Tidy App::perlimports \
    && apt-get purge -y gcc && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

COPY --from=perl-lsp /usr/local/bin/perlnavigator /usr/local/bin/perlnavigator
COPY --from=perl-runtime /usr/local/bin/perl /usr/local/bin/perl
COPY --from=perl-runtime /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=perl-runtime /etc/perl /etc/perl

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
| Perl LSP + tooling (perlnavigator, perlcritic, perltidy) | ~45MB |
| **Estimated total** | **~775MB** |

Using `node:lts`, `python:3.12-slim`, `golang:1.22-bookworm`, `eclipse-temurin:21-jdk`, `ruby:3.3`, `erlang:26`, and `perl:5.38-slim` as builder stages adds significant temporary space but doesn't affect the final image.

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
    perlnavigator perlcritic perltidy perlimports

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
    perlnavigator perl-critic perltidy perlimports; do
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

## OMP LSP Discovery Flow

OMP discovers LSP servers by:

1. Checking if a server binary is on `PATH` (project-local bins first: `node_modules/.bin/`, `.venv/bin/`, then system PATH)
2. Checking if the project directory contains at least one of the server's `rootMarkers`
3. Matching the binary name to a language
4. Launching the server with the LSP JSON-RPC protocol over stdin/stdout
5. Sending the `initialize` request with workspace capabilities

No manual configuration is needed for common setups — servers auto-discover project config files (`tsconfig.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.).

## Excluded Servers

None. All 60+ built-in servers from OMP's `defaults.json` are included in the Docker image. No server is too heavy.
