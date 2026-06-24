# AGENTS.md — OhMyPi LSP Docker Image

AI coding agents working in this project should follow these guidelines when building and maintaining the OhMyPi-capable Docker image with all LSP binaries available by default.

## Project Goal

Build a Docker image that spins up an OhMyPi (OMP) capable instance with all common LSP (Language Server Protocol) binaries available by default. The image is a self-contained development environment where OMP agents can perform code intelligence (LSP diagnostics, hover, go-to-definition, references, rename, code actions, formatting) across multiple languages out of the box.

## Current State

- **Dockerfile**: Minimal — Ubuntu 24.04 base, installs `curl git ca-certificates ripgrep clangd`, renames user to `slava`, installs OMP binary via `curl -fsSL https://omp.sh/install | bash`
- **LSP binaries present**: Only `clangd` (C/C++)
- **Missing toolchains**: No Python, Node.js, Go, Rust, Ruby, Lua, Java, PHP, or any language runtime that LSP servers depend on
- **MCP config**: Configured with `duckduckgo-mcp-server` (uses `uv`)
- **OMP version**: v16.1.16 (standalone Go binary)
- **Bundled agents**: 8 types — `designer`, `explore`, `librarian`, `oracle`, `plan`, `quick_task`, `reviewer`, `task`

## Build / Run Commands

```bash
# Build the Docker image
docker build -t omp-lsp .

# Run the container
docker run -it --rm -v $(pwd):/workspace -w /workspace omp-lsp omp

# Run in background with a long-lived shell
docker run -it --rm -v $(pwd):/workspace -w /workspace omp-lsp sleep infinity

# Execute a single OMP command
docker run -it --rm -v $(pwd):/workspace -w /workspace omp-lsp omp -p "List all files"
```

## Architecture

```
omp_agent/
├── Dockerfile              # Base image definition
├── AGENTS.md               # This file — agent guidelines
├── LSP-SERVERS.md          # LSP server selection guide and marker mapping
├── DOCKERFILE-GUIDE.md     # Dockerfile architecture and build patterns
├── OMP-CONFIG.md           # OMP configuration reference
├── .omp/
│   ├── mcp.json            # MCP server configuration
│   ├── agents/             # Bundled agent definitions (copied from OMP)
│   └── lsp-markers/        # (legacy) — reference markers
└── lsp_trigger/            # (empty) — placeholder for LSP trigger scripts
```

### LSP Root Markers

OMP auto-discovers LSP servers by checking if the **project workspace directory** contains at least one of each server's `rootMarkers` (defined in `defaults.json`). The `lsp-markers/` directory in the project root contains minimal empty files to trigger all 52 built-in servers.

When OMP opens a workspace, it scans that directory for marker files. If found and the server binary is on `PATH`, the server is automatically launched.

See **[LSP-SERVERS.md](LSP-SERVERS.md)** for the complete marker-to-server mapping.

## OMP Configuration

OMP is configured with these key settings relevant to LSP:

| Setting | Default | Description |
|---------|---------|-------------|
| `lsp.enabled` | `true` | Enable LSP tools |
| `lsp.lazy` | `true` | Lazy-start language servers |
| `lsp.formatOnWrite` | `false` | Format on file save |
| `lsp.diagnosticsOnWrite` | `true` | Diagnostics on save |
| `lsp.diagnosticsOnEdit` | `false` | Real-time diagnostics |
| `lsp.diagnosticsDeduplicate` | `true` | Deduplicate diagnostic messages |

## OMP LSP Integration

OMP provides 14 LSP operations: `diagnostics`, `definition`, `type_definition`, `implementation`, `references`, `hover`, `symbols`, `rename`, `code_actions`, `status`, `reload`, `request`, `capabilities`, and apply. The `lsp` tool integrates with every file write via a writethrough system that formats code and collects diagnostics automatically.

OMP auto-discovers LSP servers by checking if the binary is on PATH (project-local bins first, then `$PATH`) and if the project contains the server's `rootMarkers`. No manual configuration is needed for common setups.

See **[LSP-SERVERS.md](LSP-SERVERS.md)** for the complete inventory of all 60+ built-in LSP servers, their runtime dependencies, install methods, and the full LSP configuration schema.

## Critical Rules

1. **Include all 60+ built-in LSP servers** — no server is too heavy. Every server in OMP's `defaults.json` must be available in the Docker image.
2. **Use multi-stage builds** — build LSP servers in builder stages (Node.js, Python, Go, JVM, Ruby, Erlang), copy only the binaries to the final image to minimize size.
3. **Pin versions** — pin all LSP server versions for reproducibility. Use specific npm versions, pip versions, or git tags.
4. **Test LSP discovery** — verify each LSP server is on PATH and responds to the LSP initialize handshake.
5. **OMP must be on PATH** — the OMP binary must be in `/home/slava/.local/bin` and that directory must be in `PATH`.
6. **Non-root user** — always run as the `slava` user, never root.
7. **No interactive prompts** — all installations must be non-interactive (`-y`, `--yes`, `--no-cache-dir`, etc.).

## Documentation Structure

- **[AGENTS.md](AGENTS.md)** — This file. Agent guidelines for this project.
- **[LSP-SERVERS.md](LSP-SERVERS.md)** — Complete LSP server inventory (52 servers), root marker mapping, runtime dependencies, install methods, LSP operations reference, and configuration schema.
- **[DOCKERFILE-GUIDE.md](DOCKERFILE-GUIDE.md)** — Dockerfile structure, multi-stage build patterns, LSP marker system, and optimization tips.

## Relevant Docs

| File | What it covers |
|------|---------------|
| [LSP-SERVERS.md](LSP-SERVERS.md) | Full 60+ server inventory, runtime dependencies, LSP operations, config schema |
| [DOCKERFILE-GUIDE.md](DOCKERFILE-GUIDE.md) | Dockerfile architecture, multi-stage builds, image optimization |
| [OMP-CONFIG.md](OMP-CONFIG.md) | OMP configuration reference, LSP settings, agent definitions |
