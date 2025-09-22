#!/bin/bash

# Git Configuration Setup Script
# Sets up modular gitconfig with provider-specific and identity-specific configs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"

echo "🚀 Setting up modular Git configuration..."
echo "Config directory: $CONFIG_DIR"
echo

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$CONFIG_DIR/providers"
mkdir -p "$CONFIG_DIR/identities"

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Collect personal information
echo "👤 Personal Information Setup"
prompt_with_default "Personal email" "trjahnke@protonmail.com" PERSONAL_EMAIL
prompt_with_default "Personal name" "Tristan Jahnke" PERSONAL_NAME
prompt_with_default "Personal GitHub username" "RemoteRabbit" PERSONAL_GITHUB_USERNAME
prompt_with_default "Personal SSH key path" "~/.ssh/proton" PERSONAL_SSH_KEY

echo

# Collect work information
echo "💼 Work Information Setup"
prompt_with_default "Work GitHub email" "" WORK_GITHUB_EMAIL
prompt_with_default "Work GitHub username" "" WORK_GITHUB_USERNAME
prompt_with_default "Work GitHub SSH key path" "~/.ssh/work_github_key" WORK_GITHUB_SSH_KEY

echo
read -p "Do you use GitLab for work? (y/N): " use_gitlab
if [[ "$use_gitlab" =~ ^[Yy]$ ]]; then
    prompt_with_default "Work GitLab email" "" WORK_GITLAB_EMAIL
    prompt_with_default "Work GitLab username" "" WORK_GITLAB_USERNAME
    prompt_with_default "Work GitLab SSH key path" "~/.ssh/work_gitlab_key" WORK_GITLAB_SSH_KEY
    
    read -p "Do you need a proxy for GitLab? (y/N): " need_proxy
    if [[ "$need_proxy" =~ ^[Yy]$ ]]; then
        prompt_with_default "GitLab proxy URL" "http://proxy.company.com:8080" GITLAB_PROXY
    fi
fi

echo

# Create identity configs
echo "🔧 Creating identity configurations..."

# Personal GitHub identity
cat > "$CONFIG_DIR/identities/personal-github.gitconfig" << EOF
# Personal identity for GitHub
[user]
  email = $PERSONAL_EMAIL
  name = $PERSONAL_NAME
  username = $PERSONAL_GITHUB_USERNAME

[core]
  sshCommand = "ssh -i $PERSONAL_SSH_KEY"
EOF

# Work GitHub identity
if [ -n "$WORK_GITHUB_EMAIL" ]; then
cat > "$CONFIG_DIR/identities/work-github.gitconfig" << EOF
# Work identity for GitHub
[user]
  email = $WORK_GITHUB_EMAIL
  name = $PERSONAL_NAME
  username = $WORK_GITHUB_USERNAME

[core]
  sshCommand = "ssh -i $WORK_GITHUB_SSH_KEY"
EOF
fi

# Work GitLab identity
if [ -n "$WORK_GITLAB_EMAIL" ]; then
cat > "$CONFIG_DIR/identities/work-gitlab.gitconfig" << EOF
# Work identity for GitLab
[user]
  email = $WORK_GITLAB_EMAIL
  name = $PERSONAL_NAME
  username = $WORK_GITLAB_USERNAME

[core]
  sshCommand = "ssh -i $WORK_GITLAB_SSH_KEY"
EOF
fi

# Create/update provider configs
echo "🌐 Creating provider configurations..."

# GitHub provider config (already exists, just confirm)
if [ -f "$CONFIG_DIR/providers/github.gitconfig" ]; then
    echo "✅ GitHub provider config already exists"
else
    echo "❌ GitHub provider config missing - please ensure it exists"
fi

# GitLab provider config
if [[ "$use_gitlab" =~ ^[Yy]$ ]]; then
    gitlab_config="# GitLab-specific configuration
[url \"git@gitlab.com:\"]
  pushInsteadOf = \"https://gitlab.com/\"
  pushInsteadOf = \"gitlab:\"
  pushInsteadOf = \"git://gitlab.com/\"

[url \"git://gitlab.com/\"]
  insteadOf = \"gitlab:\"

# GitLab credential helper (if using glab CLI)
# [credential \"https://gitlab.com\"]
#   helper = !/usr/bin/glab auth git-credential"

    if [ -n "$GITLAB_PROXY" ]; then
        gitlab_config="$gitlab_config

# Proxy settings for GitLab
[http \"https://gitlab.com\"]
  proxy = $GITLAB_PROXY
[https \"https://gitlab.com\"]  
  proxy = $GITLAB_PROXY"
    else
        gitlab_config="$gitlab_config

# Proxy settings for GitLab (uncomment and configure as needed)
# [http \"https://gitlab.com\"]
#   proxy = http://proxy.company.com:8080
# [https \"https://gitlab.com\"]  
#   proxy = http://proxy.company.com:8080"
    fi
    
    echo "$gitlab_config" > "$CONFIG_DIR/providers/gitlab.gitconfig"
fi

# Create directory structure recommendations
echo
echo "📂 Recommended directory structure:"
echo "~/repos/personal/          - Personal GitHub projects"
echo "~/repos/work/github/       - Work GitHub projects"
if [[ "$use_gitlab" =~ ^[Yy]$ ]]; then
echo "~/repos/work/gitlab/       - Work GitLab projects"
fi

# Setup symlink
echo
read -p "Create symlink from ~/.gitconfig to $CONFIG_DIR/.gitconfig? (Y/n): " create_symlink
if [[ ! "$create_symlink" =~ ^[Nn]$ ]]; then
    if [ -f ~/.gitconfig ] && [ ! -L ~/.gitconfig ]; then
        echo "📋 Backing up existing ~/.gitconfig to ~/.gitconfig.backup"
        mv ~/.gitconfig ~/.gitconfig.backup
    fi
    
    if [ -L ~/.gitconfig ]; then
        rm ~/.gitconfig
    fi
    
    ln -s "$CONFIG_DIR/.gitconfig" ~/.gitconfig
    echo "✅ Created symlink: ~/.gitconfig -> $CONFIG_DIR/.gitconfig"
fi

echo
echo "🎉 Setup complete!"
echo
echo "📝 Next steps:"
echo "1. Organize your repos into the recommended directory structure"
echo "2. Test with: git config --list --show-origin"
echo "3. Verify identity switching: cd into different repo types and run 'git config user.email'"

if [ -n "$WORK_GITHUB_EMAIL" ] || [ -n "$WORK_GITLAB_EMAIL" ]; then
    echo "4. Ensure your SSH keys exist and are added to ssh-agent"
fi

echo
echo "🔍 Config files created:"
find "$CONFIG_DIR" -name "*.gitconfig" -type f | sort
