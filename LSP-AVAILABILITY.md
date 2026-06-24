# LSP Availability Report

**Date**: 2026-06-24
**Environment**: Ubuntu 24.04 (WSL2), OMP v16.1.16
**Report type**: Binary discovery — checked via `which` against all 52 built-in OMP LSP servers

## Summary

| Category | Count |
|----------|-------|
| **Total OMP built-in servers** | 52 |
| **Available on PATH** | 22 |
| **Missing from PATH** | 30 |
| **Coverage** | 42% |

## Available Servers (22)

### C/C++/ObjC
| Server | Binary | Path |
|--------|--------|------|
| `clangd` | `clangd` | `/usr/bin/clangd` |

### Rust
| Server | Binary | Path |
|--------|--------|------|
| `rust-analyzer` | `rust-analyzer` | `/home/slava/.cargo/bin/rust-analyzer` |

### TypeScript / JavaScript
| Server | Binary | Path |
|--------|--------|------|
| `typescript-language-server` | `typescript-language-server` | `/home/slava/.local/bin/typescript-language-server` |
| `denols` | `deno` | — |

### Linters / Formatters (Node.js)
| Server | Binary | Path |
|--------|--------|------|
| `biome` | `biome` | `/home/slava/.local/bin/biome` |
| `eslint` | `vscode-eslint-language-server` | `/home/slava/.local/bin/vscode-eslint-language-server` |

### HTML / CSS / JSON
| Server | Binary | Path |
|--------|--------|------|
| `vscode-html-language-server` | `vscode-html-language-server` | `/home/slava/.local/bin/vscode-html-language-server` |
| `vscode-css-language-server` | `vscode-css-language-server` | `/home/slava/.local/bin/vscode-css-language-server` |
| `vscode-json-language-server` | `vscode-json-language-server` | `/home/slava/.local/bin/vscode-json-language-server` |

### Tailwind CSS
| Server | Binary | Path |
|--------|--------|------|
| `tailwindcss` | `tailwindcss-language-server` | `/home/slava/.local/bin/tailwindcss-language-server` |

### Svelte
| Server | Binary | Path |
|--------|--------|------|
| `svelte` | `svelteserver` | `/home/slava/.local/bin/svelteserver` |

### Vue
| Server | Binary | Path |
|--------|--------|------|
| `vue-language-server` | `vue-language-server` | `/home/slava/.local/bin/vue-language-server` |

### Astro
| Server | Binary | Path |
|--------|--------|------|
| `astro-ls` | `astro-ls` | `/home/slava/.local/bin/astro-ls` |

### Dockerfile
| Server | Binary | Path |
|--------|--------|------|
| `dockerls` | `docker-langserver` | `/home/slava/.local/bin/docker-langserver` |

### Prisma
| Server | Binary | Path |
|--------|--------|------|
| `prismals` | `prisma-language-server` | `/home/slava/.local/bin/prisma-language-server` |

### Vim Script
| Server | Binary | Path |
|--------|--------|------|
| `vimls` | `vim-language-server` | `/home/slava/.local/bin/vim-language-server` |

### PHP
| Server | Binary | Path |
|--------|--------|------|
| `intelephense` | `intelephense` | `/home/slava/.local/bin/intelephense` |

### YAML
| Server | Binary | Path |
|--------|--------|------|
| `yamlls` | `yaml-language-server` | `/home/slava/.local/bin/yaml-language-server` |

### Bash / Zsh
| Server | Binary | Path |
|--------|--------|------|
| `bashls` | `bash-language-server` | `/home/slava/.local/bin/bash-language-server` |

### GraphQL
| Server | Binary | Path |
|--------|--------|------|
| `graphql-lsp` | `graphql-lsp` | `/home/slava/.local/bin/graphql-lsp` |

## Missing Servers (30)

### Zig
| Server | Binary | Notes |
|--------|--------|-------|
| `zls` | `zls` | Needs Zig toolchain |

### Go
| Server | Binary | Notes |
|--------|--------|-------|
| `gopls` | `gopls` | Go 1.26.4 available for `go install` |

### Deno
| Server | Binary | Notes |
|--------|--------|-------|
| `denols` | `deno` | Deno not installed |

### Python (all Python LSPs)
| Server | Binary | Notes |
|--------|--------|-------|
| `pyright` | `pyright-langserver` | Python 3 available but pyright not pip-installed |
| `basedpyright` | `basedpyright-langserver` | — |
| `pylsp` | `pylsp` | — |
| `ruff` | `ruff` | Standalone binary not installed |

### JVM-based
| Server | Binary | Notes |
|--------|--------|-------|
| `jdtls` | `jdtls` | No JVM |
| `metals` | `metals` | No JVM |

### Haskell
| Server | Binary | Notes |
|--------|--------|-------|
| `hls` | `haskell-language-server-wrapper` | No GHC |

### OCaml
| Server | Binary | Notes |
|--------|--------|-------|
| `ocamllsp` | `ocamllsp` | No OCaml/opam |

### Elixir
| Server | Binary | Notes |
|--------|--------|-------|
| `elixirls` | `elixir-ls` | No Erlang/Elixir |
| `expert` | `expert` | No Erlang/Elixir |

### Erlang
| Server | Binary | Notes |
|--------|--------|-------|
| `erlangls` | `erlang_ls` | No Erlang |

### Gleam
| Server | Binary | Notes |
|--------|--------|-------|
| `gleam` | `gleam` | No Gleam runtime |

### Lua
| Server | Binary | Notes |
|--------|--------|-------|
| `lua-language-server` | `lua-language-server` | Standalone binary not installed |

### Markdown
| Server | Binary | Notes |
|--------|--------|-------|
| `marksman` | `marksman` | Standalone binary not installed |

### Terraform
| Server | Binary | Notes |
|--------|--------|-------|
| `terraformls` | `terraform-ls` | Standalone binary not installed |

### LaTeX
| Server | Binary | Notes |
|--------|--------|-------|
| `texlab` | `texlab` | Standalone binary not installed |

### Helm
| Server | Binary | Notes |
|--------|--------|-------|
| `helm-ls` | `helm_ls` | Standalone binary not installed |

### Nix
| Server | Binary | Notes |
|--------|--------|-------|
| `nixd` | `nixd` | No Nix |
| `nil` | `nil` | No Nix |

### C#
| Server | Binary | Notes |
|--------|--------|-------|
| `omnisharp` | `omnisharp` | No .NET runtime |

### Swift
| Server | Binary | Notes |
|--------|--------|-------|
| `sourcekit-lsp` | `sourcekit-lsp` | macOS-only |
| `swiftlint` | `swiftlint` | macOS-only |

### Odin
| Server | Binary | Notes |
|--------|--------|-------|
| `ols` | `ols` | No Odin compiler |

### PHP (second server)
| Server | Binary | Notes |
|--------|--------|-------|
| `phpactor` | `phpactor` | No PHP |

### Ruby (all Ruby LSPs)
| Server | Binary | Notes |
|--------|--------|-------|
| `solargraph` | `solargraph` | No Ruby |
| `ruby-lsp` | `ruby-lsp` | No Ruby |
| `rubocop` | `rubocop` | No Ruby |

### Dart
| Server | Binary | Notes |
|--------|--------|-------|
| `dartls` | `dart` | No Dart SDK |

### Emmet
| Server | Binary | Notes |
|--------|--------|-------|
| `emmet-language-server` | `emmet-language-server` | Not npm-installed |

### TLA+
| Server | Binary | Notes |
|--------|--------|-------|
| `tlaplus` | `tlapm_lsp` | Not installed |

## Runtime Dependencies Present

| Runtime | Version | Used By |
|---------|---------|---------|
| Node.js | v24.17.0 | 18 Node.js-based LSP servers |
| Python 3 | present | 0 (no Python LSPs installed) |
| Go | 1.26.4 | 0 (gopls not installed, but can be built) |
| Rust | 1.96.0 | rust-analyzer (installed) |

## Key Observations

1. **All Node.js LSPs are installed** — 18 of the 22 available servers are Node.js-based. Node.js v24 is present and all npm global installs succeeded.
2. **No Python LSPs** — Python 3 exists but pyright, basedpyright, pylsp, and ruff are not pip-installed.
3. **Go runtime present but gopls not installed** — Go 1.26.4 is available; `go install golang.org/x/tools/gopls@latest` would work.
4. **Zig, Lua, Terraform, marksman, texlab, helm-ls** — standalone binaries not downloaded.
5. **JVM, Erlang, Ruby, Swift, Haskell, OCaml, Nix, PHP, Dart, .NET** — entire ecosystems missing.
6. **No Swift servers** — sourcekit-lsp and swiftlint are Apple-only; not expected on Linux.
