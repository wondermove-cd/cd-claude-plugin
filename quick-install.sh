#!/bin/bash

# Claude Code UX Plugin Quick Install Script
# Repository: https://github.com/wondermove-cd/cd-claude-plugin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Claude Code UX Plugin - Quick Installer${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Warning: Current directory is not a git repository${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 1
    fi
fi

# Check if .claude already exists
if [ -e ".claude" ]; then
    echo -e "${YELLOW}⚠️  .claude already exists in current directory${NC}"

    if [ -L ".claude" ]; then
        EXISTING_TARGET=$(readlink .claude)
        echo -e "   Current symlink points to: ${YELLOW}$EXISTING_TARGET${NC}"
    fi

    read -p "Replace existing .claude? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 1
    fi

    # Backup existing .claude
    if [ -d ".claude" ] && [ ! -L ".claude" ]; then
        BACKUP_NAME=".claude.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Backing up existing .claude to $BACKUP_NAME${NC}"
        mv .claude "$BACKUP_NAME"
    else
        rm -f .claude
    fi
fi

# Define the plugin directory
PLUGIN_DIR="$HOME/Documents/Claude/cd-claude-plugin"

echo -e "${BLUE}🔍 Checking for existing plugin installation...${NC}"

# Check if plugin is already installed locally
if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${GREEN}✅ Found existing plugin at: $PLUGIN_DIR${NC}"

    # Update the existing plugin
    echo -e "${BLUE}📦 Updating plugin to latest version...${NC}"
    cd "$PLUGIN_DIR"

    # Check if it's a git repo and update
    if [ -d ".git" ]; then
        # Save current branch
        CURRENT_BRANCH=$(git branch --show-current)

        # Stash any local changes
        if [[ -n $(git status -s) ]]; then
            echo -e "${YELLOW}Stashing local changes...${NC}"
            git stash push -m "Auto-stash before plugin update $(date)"
        fi

        # Pull latest changes
        echo -e "${BLUE}Pulling latest changes from GitHub...${NC}"
        git pull origin main || {
            echo -e "${YELLOW}⚠️  Could not pull from GitHub (might be offline or permission issue)${NC}"
            echo -e "${GREEN}Continuing with local version...${NC}"
        }
    fi

    cd - > /dev/null
else
    echo -e "${BLUE}📦 Installing plugin for the first time...${NC}"

    # Create Claude directory if it doesn't exist
    mkdir -p "$HOME/Documents/Claude"

    # Clone the repository
    echo -e "${BLUE}Cloning plugin repository...${NC}"
    git clone https://github.com/wondermove-cd/cd-claude-plugin.git "$PLUGIN_DIR" || {
        echo -e "${RED}❌ Failed to clone repository${NC}"
        echo -e "${YELLOW}Please check your internet connection and GitHub access${NC}"
        exit 1
    }
fi

# Create symlink to the plugin
echo -e "${BLUE}🔗 Creating symlink to plugin...${NC}"
ln -sf "$PLUGIN_DIR/.claude" .claude

# Verify installation
if [ -L ".claude" ] && [ -d ".claude" ]; then
    echo -e "${GREEN}✅ Plugin successfully installed!${NC}"
    echo ""

    # Count available resources
    COMMANDS_COUNT=$(ls -1 .claude/commands/*.md 2>/dev/null | wc -l | xargs)
    SKILLS_COUNT=$(ls -1 .claude/skills/*.md 2>/dev/null | wc -l | xargs)

    echo -e "${BLUE}📊 Installation Summary:${NC}"
    echo -e "   • Location: ${GREEN}$(pwd)/.claude${NC}"
    echo -e "   • Commands: ${GREEN}${COMMANDS_COUNT} available${NC}"
    echo -e "   • Skills: ${GREEN}${SKILLS_COUNT} available${NC}"
    echo ""

    # Show some available commands
    echo -e "${BLUE}📝 Key Commands:${NC}"
    echo -e "   ${YELLOW}/ux-init${NC} - Initialize new UX project"
    echo -e "   ${YELLOW}/ux-onboard${NC} - Analyze existing project"
    echo -e "   ${YELLOW}/context-restore${NC} - Restore previous session"
    echo -e "   ${YELLOW}/plugin-update${NC} - Update plugin to latest"
    echo ""

    # Check for JIRA environment variables
    echo -e "${BLUE}🔧 Configuration Check:${NC}"
    if [ -n "$JIRA_HOST" ] && [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
        echo -e "   ${GREEN}✅ JIRA environment variables configured${NC}"
    else
        echo -e "   ${YELLOW}⚠️  JIRA not configured (optional)${NC}"
        echo -e "      To enable JIRA integration, set:"
        echo -e "      • JIRA_HOST"
        echo -e "      • JIRA_EMAIL"
        echo -e "      • JIRA_API_TOKEN"
    fi

    echo ""
    echo -e "${GREEN}🎉 Installation complete! The plugin is ready to use.${NC}"
    echo -e "${BLUE}================================================${NC}"

    # Show next steps
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Open this project in Claude Code"
    echo -e "2. Try ${YELLOW}/ux-onboard${NC} to analyze your project"
    echo -e "3. Use ${YELLOW}/help${NC} to see all available commands"

else
    echo -e "${RED}❌ Installation failed!${NC}"
    echo -e "Please check permissions and try again"
    exit 1
fi