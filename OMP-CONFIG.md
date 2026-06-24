# OMP Configuration Reference

This document covers OhMyPi configuration relevant to the LSP Docker image.

## OMP Binary

- **Version**: v16.1.16
- **Path**: `/home/slava/.local/bin/omp`
- **Size**: ~153MB (standalone Go binary)
- **Dependencies**: None — fully self-contained

## Agent Definitions

OMP ships with 8 bundled agent types. They are defined as YAML frontmatter + Markdown files:

```
~/.omp/agent/agents/
├── designer.md      # UI/UX specialist
├── explore.md       # Read-only codebase scout
├── librarian.md     # External library/API researcher
├── oracle.md        # Senior engineer consultant
├── plan.md          # Software architect for planning
├── quick_task.md    # Low-reasoning mechanical updates
├── reviewer.md      # Code review specialist
└── task.md          # General-purpose worker agent
```

### Agent Format

Each agent file uses YAML frontmatter followed by Markdown instructions:

```yaml
---
name: explore
description: Fast read-only codebase scout returning compressed context for handoff
tools: 
  - read
  - search
  - find
  - web_search
  - yield
model: 
  - pi/smol
thinkingLevel: medium
output: 
  properties: 
    summary:
      metadata:
        description: Brief summary of findings and conclusions
      type: string
    files:
      metadata:
        description: Files examined with relevant code references
      elements:
        properties:
          path:
            metadata:
              description: Project-relative path
            type: string
---
```

### Agent Model Roles

| Role | Model | Thinking Level | Purpose |
|------|-------|---------------|---------|
| `default` | `llama-swap/qwen3.6-35b-a3b` | `off` | General tasks |
| `slow` | `llama-swap/qwen3.6-35b-a3b` | `high` | Deep analysis, debugging |
| `plan` | `llama-swap/qwen3.6-35b-a3b` | `high` | Architectural planning |
| `smol` | `pi/smol` | `medium` | Quick lookups (explore, librarian) |
| `task` | `pi/task` | — | General worker |
| `designer` | `pi/designer` | — | UI/UX work |

## MCP Configuration

MCP (Model Context Protocol) servers extend OMP with external tools:

```json
{
  "$schema": "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json",
  "mcpServers": {
    "ddg-search": {
      "command": "uv",
      "args": ["duckduckgo-mcp-server"],
      "env": {
        "DDG_REGION": "us-en"
      }
    },
    "codegraphcontext": {
      "transport": "http",
      "url": "http://codegraphcontext-mcp:8045/mcp",
      "headers": {
        "Authorization": "Bearer your-secret-here"
      }
    }
  }
}
```

### MCP in Docker

For the Docker image, MCP servers need:

1. **Runtime available** — e.g., `uv` for Python MCP servers
2. **Network access** — HTTP transport MCP servers need reachable URLs
3. **Environment variables** — API keys, regions, etc.

## LSP Settings

OMP's LSP integration is controlled by these config settings:

```yaml
[files]
  lsp.enabled = true          # Enable LSP tools
  lsp.lazy = true             # Lazy-start language servers
  lsp.formatOnWrite = false   # Format on file save
  lsp.diagnosticsOnWrite = true  # Diagnostics on save
  lsp.diagnosticsOnEdit = false    # Real-time diagnostics
  lsp.diagnosticsDeduplicate = true
```

### LSP Discovery

OMP discovers LSP servers by:

1. Checking if a server binary exists on `PATH`
2. Matching the binary name to a supported language
3. Launching the server with the LSP JSON-RPC protocol
4. Sending the `initialize` request with workspace capabilities

No manual configuration is needed — OMP auto-discovers servers on PATH.

### Supported LSP Methods

OMP supports all standard LSP methods:

| Method | Tool | Purpose |
|--------|------|---------|
| `textDocument/hover` | `lsp` | Type info, docs |
| `textDocument/definition` | `lsp` | Go to definition |
| `textDocument/typeDefinition` | `lsp` | Type definition |
| `textDocument/implementation` | `lsp` | Implementations |
| `textDocument/references` | `lsp` | All references |
| `textDocument/rename` | `lsp` | Rename symbol |
| `textDocument/codeAction` | `lsp` | Quick fixes, refactors |
| `textDocument/formatting` | `lsp` | Format document |
| `textDocument/diagnostics` | `lsp` | Get diagnostics |

## Configuration Files

OMP reads configuration from multiple sources:

| File | Purpose |
|------|---------|
| `~/.omp/agent/config.yml` | Core OMP settings |
| `~/.omp/agent/models.yml` | Model provider configuration |
| `~/.omp/mcp.json` | MCP server configuration |
| `~/.omp/agent/agents/*.md` | Agent definitions |
| `~/.omp/agent/sessions/` | Session history |

### config.yml

```yaml
shell: /bin/bash
symbolPreset: unicode
theme:
  dark: titanium
  light: light
setupVersion: 1
modelRoles:
  default: llama-swap/qwen3.6-35b-a3b:off
  slow: llama-swap/qwen3.6-35b-a3b:high
  plan: llama-swap/qwen3.6-35b-a3b:high
```

### models.yml

```yaml
providers:
  llama-swap:
    baseUrl: http://host.docker.internal:8080/v1
    apiKey: "none"
    api: openai-completions
    compat:
      supportsDeveloperRole: false
      supportsReasoningEffort: false
      thinkingFormat: qwen-chat-template
    models:
      - id: qwen3.6-35b-a3b
        name: qwen3.6-35b-a3b
        contextWindow: 262144
        maxTokens: 32768
        reasoning: true
```

## Environment Variables

### Core Providers

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Anthropic Claude models |
| `OPENAI_API_KEY` | OpenAI GPT models |
| `GEMINI_API_KEY` | Google Gemini models |
| `COPILOT_GITHUB_TOKEN` | GitHub Copilot |

### Search & Tools

| Variable | Purpose |
|----------|---------|
| `EXA_API_KEY` | Exa web search |
| `BRAVE_API_KEY` | Brave web search |
| `PERPLEXITY_API_KEY` | Perplexity web search |
| `TAVILY_API_KEY` | Tavily web search |

### Configuration

| Variable | Purpose |
|----------|---------|
| `OMP_PROFILE` | Named profile for isolated state |
| `PI_CODING_AGENT_DIR` | Session storage directory |
| `PI_PACKAGE_DIR` | Override package directory |
| `PI_SMOL_MODEL` | Override smol/fast model |
| `PI_SLOW_MODEL` | Override slow/reasoning model |
| `PI_PLAN_MODEL` | Override planning model |
| `PI_NO_PTY` | Disable PTY-based bash |

## OMP Commands

| Command | Purpose |
|---------|---------|
| `omp [messages]` | Interactive mode |
| `omp -p "prompt"` | Non-interactive (process and exit) |
| `omp --continue` | Continue previous session |
| `omp --model opus "prompt"` | Use specific model |
| `omp --no-lsp` | Disable LSP tools |
| `omp --no-tools` | Disable all tools |
| `omp agents unpack` | Export bundled agents |
| `omp agents unpack --project` | Export to `.omp/agents/` |
| `omp config list` | List all settings |
| `omp models` | List available models |
| `omp update` | Check for updates |
| `omp setup` | Run onboarding setup |
| `omp setup python` | Install Python dependencies |

## Agent Spawn Hierarchy

```
Main Agent
├── task (*)         # General worker — can spawn anything
│   ├── explore      # Read-only scout
│   ├── librarian    # Library research
│   └── task         # Nested delegation
├── plan             # Architectural planning
│   └── explore      # Read-only scout
├── oracle (explore) # Senior engineer — can spawn explore
├── reviewer (explore) # Code reviewer — can spawn explore
├── designer         # UI/UX specialist
└── quick_task       # Low-reasoning mechanical tasks
```

## Session Storage

Sessions are stored in `~/.omp/agent/sessions/`:

```
~/.omp/agent/sessions/
├── -code-omp_agent/     # Session for this project
│   ├── 2026-06-24T01-45-28-990Z_*.jsonl  # Session transcript
│   └── *.log            # Bash logs
├── --code--/            # Root-level code sessions
├── -code-/              # General code sessions
├── --code-shi/          # Shi project sessions
└── --code-paseo/        # Paseo project sessions
```

## Skills

OMP supports skills — reusable prompts and workflows:

- `skills.enabled = true` — Enable skill discovery
- `skills.ignoredSkills = []` — Skills to skip (glob patterns)
- `skills.includeSkills = []` — Only include these skills (glob patterns)
- `skills.customDirectories = []` — Additional skill directories

Skills are discovered from:
- `~/.omp/skills/` — User skills
- `./.omp/skills/` — Project skills
- Bundled skills (git, docker, etc.)

## Rules

OMP supports rules — constraints that apply to agent behavior:

- Rules are discovered from `~/.omp/rules/` and `./.omp/rules/`
- Each rule is a Markdown file with YAML frontmatter
- Rules can define constraints, guidelines, and prohibited actions
