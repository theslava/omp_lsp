.PHONY: help build run test clean rebuild verify docker-verify

# Default target
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build the Docker image (omp-lsp:latest)
	docker build -t omp-lsp:latest .

rebuild: ## Force rebuild without cache
	docker build --no-cache -t omp-lsp:latest .

run: ## Run container interactively with workspace mount
	docker run -it --rm -v $(PWD):/workspace -w /workspace omp-lsp:latest omp

run-shell: ## Run container with shell for debugging
	docker run -it --rm -v $(PWD):/workspace -w /workspace omp-lsp:latest bash

run-mcp: ## Run with MCP config mounted from project
	docker run -it --rm -v $(PWD):/workspace -w /workspace \
		-v $(PWD)/.omp:/home/slava/.omp \
		omp-lsp:latest omp

test: run verify ## Full test: build + verify all LSP servers

verify: ## Verify all LSP servers are on PATH
	docker run --rm omp-lsp:latest bash -c '
	count=0; missing=0;
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
	  if which $$bin >/dev/null 2$$&1; then
	    ((count++));
	  else
	    echo "MISSING: $$bin"; ((missing++));
	  fi;
	done;
	echo "Found: $$count / $$(($$count + $$missing))"
	'

docker-verify: ## Test LSP handshake for clangd (quick smoke test)
	docker run --rm omp-lsp:latest bash -c \
	  'echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"processId\":1,\"rootUri\":\"file:///\",\"capabilities\":{}}}" | timeout 5 clangd --log=error'

clean: ## Remove the Docker image
	docker rmi omp-lsp:latest 2>/dev/null || true
