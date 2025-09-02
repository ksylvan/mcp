#!/bin/bash

# MCP Server Manager - Install and run MCP servers for Claude Code

GITHUB_DOCKER_IMAGE="ghcr.io/github/github-mcp-server"
SEQUENTIAL_THINKING_DOCKER_IMAGE="mcp/sequentialthinking"

ENV_FILE="./env.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"

cd "$SCRIPT_DIR" || exit 1

# shellcheck source=/dev/null
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server definitions using functions for compatibility
get_server_name() {
    case "$1" in
        brave) echo "Brave Search" ;;
        github_enterprise) echo "GitHub Enterprise" ;;
        github_public) echo "GitHub Public" ;;
        ref) echo "Ref Tools" ;;
        sequentialthinking) echo "Sequential Thinking" ;;
        *) echo "" ;;
    esac
}

get_server_command() {
    case "$1" in
        brave|github_enterprise|github_public|ref|sequentialthinking) echo "$1" ;;
        *) echo "" ;;
    esac
}

get_server_env_vars() {
    case "$1" in
        brave) echo "BRAVE_API_KEY" ;;
        github) echo "GITHUB_ENTERPRISE_ACCESS_TOKEN" ;;
        github_public) echo "GITHUB_PUBLIC_ACCESS_TOKEN" ;;
        ref) echo "" ;;
        sequentialthinking) echo "" ;;
        *) echo "" ;;
    esac
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    install [servers...]  Install MCP servers to Claude Code
    list                  List installed MCP servers
    help                  Show this help message
    <server-name>         Run a specific MCP server

Servers:
    brave                 Brave Search MCP server
    github_enterprise     GitHub Enterprise MCP server
    github_public         GitHub Public MCP server
    ref                   Ref Tools MCP server
    sequentialthinking    Sequential Thinking MCP server

Install Options:
    --dry-run            Show what would be installed without making changes
    --force              Re-register servers (remove existing before adding)
    --verbose            Show detailed output

Examples:
    $0 install                         # Install all servers
    $0 install brave github_enterprise # Install specific servers
    $0 install --dry-run               # Preview installation
    $0 install --force brave           # Force reinstall brave server
    $0 list                            # List installed servers
    $0 brave                           # Run brave server directly

EOF
}

# Check if Claude CLI is installed
check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}Error: Claude CLI is not installed${NC}"
        echo "Please install Claude CLI first: https://docs.anthropic.com/claude-cli"
        return 1
    fi
    return 0
}

# Cache for claude mcp list output
CLAUDE_MCP_LIST_CACHE=""

# Get cached claude mcp list output
get_mcp_list() {
    if [[ -z "$CLAUDE_MCP_LIST_CACHE" ]]; then
        CLAUDE_MCP_LIST_CACHE=$(claude mcp list 2>/dev/null)
        export CLAUDE_MCP_LIST_CACHE
    fi
    echo "$CLAUDE_MCP_LIST_CACHE"
}

# Clear the mcp list cache (call after adding/removing servers)
clear_mcp_list_cache() {
    CLAUDE_MCP_LIST_CACHE=""
}

# Check if server is already installed
is_server_installed() {
    local name="$1"
    get_mcp_list | grep -q "^${name}:"
}

# Install a single server
install_server() {
    local name="$1"
    local dry_run="$2"
    local force="$3"
    local verbose="$4"

    # Check if server is defined
    local display_name
    display_name="$(get_server_name "$name")"
    if [[ -z "$display_name" ]]; then
        echo -e "${RED}Error: Unknown server '${name}'${NC}"
        return 1
    fi

    local server_cmd
    server_cmd="$(get_server_command "$name")"
    local env_vars
    env_vars="$(get_server_env_vars "$name")"

    # Check required environment variables
    if [[ -n "$env_vars" ]]; then
        IFS=' ' read -ra ENV_ARRAY <<< "$env_vars"
        for var in "${ENV_ARRAY[@]}"; do
            if [[ -z "${!var}" ]]; then
                echo -e "${YELLOW}Warning: ${display_name} requires ${var} to be set${NC}"
                echo "  Skipping ${name} installation. Set ${var} and try again."
                return 1
            fi
        done
    fi

    # Check if already installed
    if is_server_installed "$name"; then
        if [[ "$force" == "true" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "${BLUE}[DRY RUN] Would remove existing ${display_name} server${NC}"
            else
                [[ "$verbose" == "true" ]] && echo -e "${BLUE}Removing existing ${display_name} server...${NC}"
                claude mcp remove "$name" 2>/dev/null || true
                clear_mcp_list_cache
            fi
        else
            echo -e "${GREEN}Server ${display_name} already installed. Skipping.${NC}"
            return 0
        fi
    fi

    # Build the install command
    local cmd="claude mcp add --scope user \"${name}\" \"${SCRIPT_PATH}\" \"${server_cmd}\""

    # Add environment variables to command
    if [[ -n "$env_vars" ]]; then
        IFS=' ' read -ra ENV_ARRAY <<< "$env_vars"
        for var in "${ENV_ARRAY[@]}"; do
            cmd+=" -e \"${var}=\${${var}}\""
        done
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN] Would install ${display_name} server:${NC}"
        # Show command with redacted env values
        local display_cmd="claude mcp add --scope user \"${name}\" \"${SCRIPT_PATH}\" \"${server_cmd}\""
        if [[ -n "$env_vars" ]]; then
            IFS=' ' read -ra ENV_ARRAY <<< "$env_vars"
            for var in "${ENV_ARRAY[@]}"; do
                display_cmd+=" -e \"${var}=<redacted>\""
            done
        fi
        echo "  $display_cmd"
    else
        [[ "$verbose" == "true" ]] && echo -e "${BLUE}Installing ${display_name} server...${NC}"
        if eval "$cmd" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} ${display_name} server installed successfully"
            clear_mcp_list_cache
        else
            echo -e "${RED}✗${NC} Failed to install ${display_name} server"
            return 1
        fi
    fi

    return 0
}

# List command handler
handle_list() {
    # Check Claude CLI
    if ! check_claude_cli; then
        return 1
    fi

    echo -e "${BLUE}Installed MCP servers:${NC}\n"

    local mcp_output
    mcp_output=$(get_mcp_list)
    if [[ -z "$mcp_output" ]] || ! echo "$mcp_output" | grep -v "^$"; then
        echo -e "${YELLOW}No MCP servers installed.${NC}"
        echo "Use '$0 install' to install servers."
        return 0
    fi
}

# Install command handler
handle_install() {
    shift # Remove 'install' from arguments

    local dry_run="false"
    local force="false"
    local verbose="false"
    local servers=()

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --force)
                force="true"
                shift
                ;;
            --verbose)
                verbose="true"
                shift
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use '$0 install --help' for usage"
                return 1
                ;;
            *)
                servers+=("$1")
                shift
                ;;
        esac
    done

    # Check Claude CLI
    if ! check_claude_cli; then
        return 1
    fi

    # If no servers specified, install all
    if [[ ${#servers[@]} -eq 0 ]]; then
        servers=("brave" "github_enterprise" "github_public" "ref" "sequentialthinking")
        echo -e "${BLUE}Installing all MCP servers...${NC}\n"
    else
        echo -e "${BLUE}Installing selected MCP servers...${NC}\n"
    fi

    local failed=0
    local installed=0
    local skipped=0

    for server in "${servers[@]}"; do
        if is_server_installed "$server" && [[ "$force" != "true" ]]; then
            ((skipped++))
        fi

        if ! install_server "$server" "$dry_run" "$force" "$verbose"; then
            # Only count as failure if it wasn't already installed
            if ! is_server_installed "$server" || [[ "$force" == "true" ]]; then
                ((failed++))
            fi
        else
            if ! is_server_installed "$server" || [[ "$force" == "true" ]]; then
                ((installed++))
            fi
        fi
    done

    echo ""
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${BLUE}Dry run complete. No changes were made.${NC}"
    else
        if [[ $installed -gt 0 ]]; then
            echo -e "${GREEN}Installed $installed server(s) successfully.${NC}"
        fi
        if [[ $skipped -gt 0 ]]; then
            echo -e "${BLUE}Skipped $skipped already installed server(s).${NC}"
        fi
        if [[ $failed -gt 0 ]]; then
            echo -e "${RED}Failed to install $failed server(s).${NC}"
            return 1
        fi
        if [[ $installed -gt 0 ]]; then
            echo "Restart Claude Code to use the new servers."
        fi
    fi

    return 0
}

# Main dispatcher
case "$1" in
    install)
        handle_install "$@"
        ;;

    list)
        handle_list
        ;;

    help|--help|-h)
        show_help
        ;;

    brave)
        exec npx -y @brave/brave-search-mcp-server --transport stdio
        ;;

    github_enterprise)
        export GITHUB_HOST="$GITHUB_ENTERPRISE_HOST"
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_ENTERPRISE_ACCESS_TOKEN"
        exec docker run --rm -i -e GITHUB_PERSONAL_ACCESS_TOKEN -e GITHUB_HOST "$GITHUB_DOCKER_IMAGE"
        ;;

    github_public)
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PUBLIC_ACCESS_TOKEN"
        exec docker run --rm -i -e GITHUB_PERSONAL_ACCESS_TOKEN "$GITHUB_DOCKER_IMAGE"
        ;;

    ref)
        exec npx ref-tools-mcp@latest
        ;;

    sequentialthinking)
        exec docker run --rm -i "$SEQUENTIAL_THINKING_DOCKER_IMAGE"
        ;;

    "")
        show_help
        exit 1
        ;;

    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac
