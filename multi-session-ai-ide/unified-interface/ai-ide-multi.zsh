#!/bin/bash

# Multi-Session AI IDE Unified Interface

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION_MANAGER="$PROJECT_ROOT/session-manager/session-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logo
function print_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ____             __  __            _     
   / __ \___  __  __/ /_/ /_  ___    (_)___ 
  / /_/ / _ \/ / / / __/ __ \/ _ \  / / __ \
 / ____/  __/ /_/ / /_/ / / /  __/ / / / / /
/_/    \___/\__, /\__/_/ /_/\___/_/_/_/ /_/ 
           /____/                           
EOF
    echo -e "${NC}Multi-Session AI IDE v1.0${NC}"
    echo ""
}

# Help
function show_help() {
    print_logo
    cat << 'EOF'
Usage: ai-ide <command> [options]

🚀 Quick Start:
  ai-ide                          - Auto-detect project and suggest AI
  ai-ide --new <provider>         - Create new session (gemini|claude|glm)
  ai-ide --list                   - List all active sessions
  ai-ide --switch <session-id>     - Switch to session
  ai-ide --status                 - Show system status

🎯 Examples:
  ai-ide --new glm                # Create new GLM-4.6 session
  ai-ide --create claude my-session # Create named Claude session
  ai-ide --list                   # List all sessions
EOF
}

# Project detection
function detect_project_type() {
    local project_dir="${1:-$(pwd)}"
    
    if [[ -f "$project_dir/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$project_dir/requirements.txt" || -f "$project_dir/pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "$project_dir/Dockerfile" ]]; then
        echo "docker"
    else
        echo "general"
    fi
}

# AI recommendation
function recommend_ai() {
    local project_type="$1"
    
    case "$project_type" in
        "docker")
            echo -e "${YELLOW}💡 Use ${GREEN}gemini${YELLOW} for DevOps & Infrastructure${NC}"
            echo -e "${BLUE}Quick start: ${CYAN}ai-ide --new gemini${NC}"
            ;;
        "nodejs"|"python")
            echo -e "${YELLOW}💡 Use ${GREEN}claude${YELLOW} for Software Engineering${NC}"
            echo -e "${BLUE}Quick start: ${CYAN}ai-ide --new claude${NC}"
            ;;
        *)
            echo -e "${YELLOW}💡 Use ${GREEN}glm${YELLOW} for General Purpose${NC}"
            echo -e "${BLUE}Quick start: ${CYAN}ai-ide --new glm${NC}"
            ;;
    esac
}

# Main logic
function main() {
    local command="$1"
    
    case "$command" in
        ""|"--new"|"-n")
            if [[ -z "$2" ]]; then
                print_logo
                echo -e "${BLUE}🔍 Analyzing project...${NC}"
                local project_type=$(detect_project_type)
                recommend_ai "$project_type"
            else
                echo "Creating $2 session..."
            fi
            ;;
        "--list"|"-l")
            echo "Listing sessions..."
            ;;
        "--status"|"-st")
            print_logo
            echo -e "${BLUE}📊 System Status${NC}"
            echo -e "${GREEN}📁 Current Project: ${CYAN}$(pwd)${NC}"
            echo -e "${GREEN}🏷️  Project Type: ${CYAN}$(detect_project_type)${NC}"
            ;;
        "--help"|"--"|"-?"|"help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            echo -e "${YELLOW}💡 Use 'ai-ide --help' for available commands${NC}"
            return 1
            ;;
    esac
}

# Запуск
main "$@"
