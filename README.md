# MCP Quick Install Repository

Author: [Kayvan Sylvan](https://git.standard.re/kayvan)

This repo provides **very fast, copy/paste setup** for recommended (opinionated) Model Context Protocol (MCP) servers for use with **Claude Code**. It currently includes a unified launcher script that can start multiple servers (GitHub, Ref Tools, Brave Search, and Sequential Thinking) with automatic installation.

---

## 🚀 Super Quick Start

**Install all MCP servers with one command:**

```bash
chmod +x ./mcp.sh && ./mcp.sh install
```

### Prerequisites

- [Claude CLI](https://docs.anthropic.com/claude-cli) installed
- Node.js/npm for JavaScript servers
- Docker for containerized servers
- Required API keys set as environment variables (see Setup section)

### Install Options

```bash
# Install all servers
./mcp.sh install

# Install specific servers
./mcp.sh install brave github

# Preview what will be installed
./mcp.sh install --dry-run

# Force reinstall
./mcp.sh install --force

# With API key for Brave Search
BRAVE_API_KEY=your_key ./mcp.sh install brave
```

The `install` command is idempotent - run it multiple times safely. It will skip already installed servers unless you use `--force`.

---

## Contents

- `mcp.sh` – multiplexer script: `./mcp.sh github` (Docker) or `./mcp.sh ref` (npx)
- `env-example.sh` – example environment variable file to copy and customize
- `env.sh` – your local (ignored) secrets file (create this yourself)

---

## 1. Prerequisites

- macOS with Docker installed & running (for the GitHub server)
- Node.js + npx available (for the Ref Tools server)
- A GitHub (or GHES) Personal Access Token (PAT) for the GitHub server
- Claude Code extension / client that supports MCP (Anthropic's official Claude extension in VS Code / Cursor / compatible clients)

---

## 2. Setup (30 seconds)

From the top level of this repository:

```bash
cp env-example.sh env.sh
```

Edit env.sh and set:

- export GITHUB_PERSONAL_ACCESS_TOKEN={{your Personal Access Token}}
- export GITHUB_HOST={{Your GitHub base URL}}
- export REF_API_KEY={{Your Ref API}}
- export BRAVE_API_KEY={{Your Brave Search API key}}

Recommended minimal PAT scopes (adjust to your needs):

- For public repos only: `public_repo`
- For private repo access: `repo`
- If you need org membership context: `read:org`

Keep the token as restrictive as possible.

`env.sh` is in `.gitignore` so it won't be committed.

---

## 3. Quick Run (manual sanity check)

Run `mcp.sh` without any arguments to see the list of MCP servers:

```bash
./mcp.sh
Usage: ./mcp.sh {github|ref|sequentialthinking}
```

GitHub MCP server:

```bash
./mcp.sh github
```

Ref Tools MCP server:

```bash
./mcp.sh ref
```

What happens for `github`:

1. Loads `env.sh` if present
2. Runs Docker image: `ghcr.io/github/github-mcp-server`
3. Passes through `GITHUB_PERSONAL_ACCESS_TOKEN` and `GITHUB_HOST`

What happens for `ref`:

1. Executes `npx ref-tools-mcp@latest`

If it starts cleanly and speaks MCP over stdin/stdout, you're good.

---

## 4. Claude Code Integration

### Quick Install All Servers

The easiest way to register all servers at once:

```bash
./mcp.sh install
```

### Individual Server Setup

#### GitHub Server

Provides access to GitHub repositories, issues, and pull requests.

**Quick install:**

```bash
./mcp.sh install github
```

**Manual install:**

```bash
claude mcp add --scope user github "${PWD}/mcp.sh" github
```

**Requirements:** `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable

#### Ref Tools Server

Provides reference and documentation tools.

**Quick install:**

```bash
./mcp.sh install ref
```

**Manual install:**

```bash
claude mcp add --scope user ref "${PWD}/mcp.sh" ref
```

#### Brave Search Server

Adds web search capabilities via Brave Search API.

**Quick install:**

```bash
./mcp.sh install brave
```

**Manual install:**

```bash
claude mcp add --scope user brave "${PWD}/mcp.sh" brave
```

**Requirements:**

- `BRAVE_API_KEY` environment variable
- Get your API key from [Brave Search API](https://brave.com/search/api/)

#### Sequential Thinking Server

Provides structured thinking and reasoning capabilities.

**Quick install:**

```bash
./mcp.sh install sequentialthinking
```

**Manual install:**

```bash
claude mcp add --scope user sequentialthinking "${PWD}/mcp.sh" sequentialthinking
```

Notes:

- The CLI writes/updates your MCP config automatically; restart / reload the Claude extension if it doesn't auto-detect.
- Use absolute paths; some clients spawn processes from different working directories.

Verification:

```bash
claude mcp list
```

You should see entries named `github` and/or `ref`. Then in the editor, ask Claude to list a repository file (GitHub) or use a ref-tools command to confirm connectivity.

---

## 5. Updating / Pinning Versions

The script currently pulls the latest container tag by default. To pin a version, edit `GITHUB_DOCKER_IMAGE` at the top of `mcp.sh`, e.g.:

```bash
GITHUB_DOCKER_IMAGE="ghcr.io/github/github-mcp-server:v1.2.3"
```

Then restart the server (no need to re-run the add command).

---

## 6. Security Tips

- Rotate your PAT regularly.
- Use separate tokens for automation vs. personal use.
- Never commit `env.sh`.
- If using a self-hosted GitHub Enterprise Server, ensure `GITHUB_HOST` matches the base URL (including protocol).

---

## 7. Extending with More MCP Servers

Add a new branch to the `case` in `mcp.sh`:

```bash
 myserver)
  exec docker run --rm -i -e SOME_ENV my/registry-image:tag
  ;;
```

Or for a local binary:

```bash
 my_local_mcp_name)
  exec /path/to/local-binary [args ...]
  ;;
```

Register it:

```bash
claude mcp add myserver "${PWD}/mcp.sh" my_local_mcp_name
```

If you need new env vars, document them in `env-example.sh` (the script already sources `env.sh`).

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Docker image not found | Check network / image name or pin a tag |
| Auth failures | Confirm PAT scopes & value loaded (echo `$GITHUB_PERSONAL_ACCESS_TOKEN` length) |
| Claude not showing server | Verify absolute path & executable bit; restart client |

Quick debug:

```bash
set -x
./mcp.sh github 2>&1 | tee debug.log
```

## 9. Support

Feel free to email me (Kayvan Sylvan) at <kayvan@meanwhile.bm> or create an Issue in this repo.
