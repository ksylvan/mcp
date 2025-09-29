# MCP Quick Install Repository

Author: [Kayvan Sylvan](https://git.standard.re/kayvan)

This repo provides **very fast, copy/paste setup** for recommended (opinionated) Model Context Protocol (MCP) servers for use with **Claude Code**. It currently includes a unified launcher script that can start multiple servers (Asana, Chrome DevTools, GitHub, Ref Tools, Brave Search, Slack, and Sequential Thinking) with automatic installation.

---

## 🚀 Super Quick Start

**Install all MCP servers with one command:**

```bash
git clone https://git.standard.re/kayvan/mcp
cd mcp
./mcp.sh install
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
./mcp.sh install brave github_public

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

---~

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

- export GITHUB_ENTERPRISE_ACCESS_TOKEN={{your Personal Access Token}}
- export GITHUB_ENTERPRISE_HOST={{Your GitHub base URL}}
- export REF_API_KEY={{Your Ref API}}
- export BRAVE_API_KEY={{Your Brave Search API key}}
- export SLACK_MCP_XOXP_TOKEN={{Your Slack User OAuth Token}}

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
Usage: ./mcp.sh {asana|chrome_devtools|github_enterprise|github_public|ref|slack|sequentialthinking}
```

GitHub Enterprise MCP server:

```bash
./mcp.sh github_enterprise
```

GitHub Public MCP server:

```bash
./mcp.sh github_public
```

Ref Tools MCP server:

```bash
./mcp.sh ref
```

What happens for `github_enterprise`:

1. Loads `env.sh` if present
2. Runs Docker image: `ghcr.io/github/github-mcp-server`
3. Passes through `GITHUB_ENTERPRISE_ACCESS_TOKEN` and `GITHUB_ENTERPRISE_HOST`

What happens for `github_public`:

1. Loads `env.sh` if present
2. Runs Docker image: `ghcr.io/github/github-mcp-server`
3. Passes through `GITHUB_PUBLIC_ACCESS_TOKEN` (connects to GitHub.com)

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

#### GitHub Enterprise Server

Provides access to GitHub Enterprise repositories, issues, and pull requests.

**Quick install:**

```bash
./mcp.sh install github_enterprise
```

**Manual install:**

```bash
claude mcp add --scope user github_enterprise "${PWD}/mcp.sh" github_enterprise
```

**Requirements:**

- `GITHUB_ENTERPRISE_ACCESS_TOKEN` environment variable
- `GITHUB_ENTERPRISE_HOST` environment variable (your GitHub Enterprise base URL)

#### GitHub Public Server

Provides access to GitHub.com repositories, issues, and pull requests.

**Quick install:**

```bash
./mcp.sh install github_public
```

**Manual install:**

```bash
claude mcp add --scope user github_public "${PWD}/mcp.sh" github_public
```

**Requirements:**

- `GITHUB_PUBLIC_ACCESS_TOKEN` environment variable

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

#### Chrome DevTools Server

Enables AI coding assistants to debug web pages directly in Chrome, providing real-time verification of code changes, network diagnostics, and performance auditing.

**Quick install:**

```bash
./mcp.sh install chrome_devtools
```

**Manual install:**

```bash
claude mcp add --scope user chrome_devtools "${PWD}/mcp.sh" chrome_devtools
```

**Requirements:**

- Google Chrome browser installed
- No additional environment variables required

**Features:**

- Real-time debugging of web pages
- Performance monitoring and tracing
- Network error diagnosis
- Console error detection
- Automated performance audits
- Live styling and layout debugging
- User behavior simulation

**Example Usage:**

Ask Claude: "Please check the LCP (Largest Contentful Paint) of web.dev" and it will use Chrome DevTools to analyze the page performance.

#### Asana Server

Provides access to Asana workspaces, projects, and tasks for project management integration.

**Quick install:**

```bash
./mcp.sh install asana
```

**Manual install:**

```bash
claude mcp add --scope user asana "${PWD}/mcp.sh" asana
```

**Requirements:**

- OAuth authentication (handled automatically on first use)
- Access to Asana workspace

**Features:**

- List workspaces and projects
- Search and manage tasks
- Create and update projects
- Track task progress and assignments

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

#### Slack Server

Provides access to Slack channels, direct messages, and workspace data for team collaboration integration.

Source: [korotovsky/slack-mcp-server](https://github.com/korotovsky/slack-mcp-server)

**Quick install:**

```bash
./mcp.sh install slack
```

**Manual install:**

```bash
claude mcp add --scope user slack "${PWD}/mcp.sh" slack
```

**Requirements:**

- `SLACK_MCP_XOXP_TOKEN` environment variable (User OAuth Token)

**Token Setup:**

To get your SLACK_MCP_XOXP_TOKEN:

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app
2. Under "OAuth & Permissions", add these scopes:
   - `channels:history` - View messages in public channels
   - `channels:read` - View basic information about public channels
   - `groups:history` - View messages in private channels
   - `groups:read` - View basic information about private channels
   - `im:history` - View messages in direct messages
   - `im:read` - View basic information about direct messages
   - `im:write` - Start direct messages
   - `mpim:history` - View messages in group direct messages
   - `mpim:read` - View basic information about group direct messages
   - `mpim:write` - Start group direct messages
   - `users:read` - View people in a workspace
   - `chat:write` - Send messages on a user's behalf
   - `search:read` - Search workspace content
3. Install the app to your workspace
4. Copy the "User OAuth Token" (starts with `xoxp-`)

**Features:**

- Access channel messages and history
- Send messages on behalf of the user
- Search workspace content
- Manage direct messages and group messages
- View workspace users and channel information

Notes:

- The CLI writes/updates your MCP config automatically; restart / reload the Claude extension if it doesn't auto-detect.
- Use absolute paths; some clients spawn processes from different working directories.

Verification:

```bash
claude mcp list
```

You should see entries named `asana`, `chrome_devtools`, `github_enterprise`, `github_public`, `ref`, `slack`, etc. Then in the editor, ask Claude to list a repository file (GitHub), search Asana tasks, check Slack messages, debug a web page (Chrome DevTools), or use a ref-tools command to confirm connectivity.

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
- If using a self-hosted GitHub Enterprise Server, ensure `GITHUB_ENTERPRISE_HOST` matches the base URL (including protocol).

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
| Auth failures | Confirm PAT scopes & value loaded (echo `$GITHUB_ENTERPRISE_ACCESS_TOKEN` length) |
| Claude not showing server | Verify absolute path & executable bit; restart client |

Quick debug:

```bash
set -x
./mcp.sh github 2>&1 | tee debug.log
```

## 9. Support

Feel free to email me (Kayvan Sylvan) at <kayvan@meanwhile.bm> or create an Issue in this repo.
