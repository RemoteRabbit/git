#!/bin/bash

# Git Credentials Setup Script
# Sets up PAT-based authentication for different providers and contexts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔐 Setting up Git credentials for PAT authentication..."
echo

# Check for Bitwarden CLI
USE_BITWARDEN=false
if command -v bw >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    read -p "Use Bitwarden for credential storage? (Y/n): " use_bw
    if [[ ! "$use_bw" =~ ^[Nn]$ ]]; then
        USE_BITWARDEN=true
        echo "📱 Bitwarden integration enabled"
        
        # Check if vault is unlocked
        if ! bw status | grep -q "unlocked"; then
            echo "🔓 Unlocking Bitwarden vault..."
            if ! bw unlock; then
                echo "❌ Failed to unlock Bitwarden vault"
                USE_BITWARDEN=false
            fi
        fi
    fi
else
    echo "ℹ️  Bitwarden CLI not found - using file-based storage"
fi

echo

# Function to setup credential file
setup_credential_file() {
    local provider="$1"
    local username="$2"
    local token="$3"
    local file="$4"
    local url="$5"
    
    # Create credential entry
    echo "https://$username:$token@$url" > "$file"
    chmod 600 "$file"
    echo "✅ Created credential file: $file"
}

# Function to check/create Bitwarden item
setup_bitwarden_item() {
    local provider="$1"
    local context="$2"
    local username="$3"
    local token="$4"
    local url="$5"
    
    local item_name="Git - ${provider^} - ${context^}"
    
    # Check if item already exists
    if bw get item "$item_name" >/dev/null 2>&1; then
        read -p "Item '$item_name' already exists. Update? (y/N): " update_item
        if [[ "$update_item" =~ ^[Yy]$ ]]; then
            local item_id=$(bw get item "$item_name" | jq -r '.id')
            local item_json=$(bw get item "$item_name")
            
            # Update the item
            local updated_item=$(echo "$item_json" | jq \
                --arg username "$username" \
                --arg password "$token" \
                '.login.username = $username | .login.password = $password')
            
            echo "$updated_item" | bw encode | bw edit item "$item_id"
            echo "✅ Updated Bitwarden item: $item_name"
        else
            echo "⏭️  Skipping update of: $item_name"
        fi
    else
        # Create new item
        local item_json=$(cat <<EOF
{
  "type": 1,
  "name": "$item_name",
  "login": {
    "username": "$username",
    "password": "$token"
  },
  "fields": [
    {
      "name": "provider",
      "value": "$url",
      "type": 0
    },
    {
      "name": "context", 
      "value": "$context",
      "type": 0
    }
  ]
}
EOF
)
        
        echo "$item_json" | bw encode | bw create item
        echo "✅ Created Bitwarden item: $item_name"
    fi
}

# Function to prompt for credentials
prompt_for_credentials() {
    local context="$1"
    local provider="$2"
    local default_username="$3"
    
    echo "🔑 $context $provider credentials:"
    
    # Check Bitwarden first if enabled
    if [ "$USE_BITWARDEN" = true ]; then
        local item_name="Git - ${provider^} - ${context^}"
        if bw get item "$item_name" >/dev/null 2>&1; then
            local existing_username=$(bw get item "$item_name" | jq -r '.login.username // empty')
            if [ -n "$existing_username" ]; then
                echo "Found existing credentials in Bitwarden for $item_name"
                read -p "Use existing username ($existing_username)? (Y/n): " use_existing
                if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
                    echo "$existing_username|BITWARDEN_EXISTING"
                    return 0
                fi
            fi
        fi
    fi
    
    read -p "Username [$default_username]: " username
    username="${username:-$default_username}"
    
    echo "Enter PAT/token (input hidden):"
    read -s token
    echo
    
    if [ -z "$token" ]; then
        echo "❌ Token cannot be empty"
        return 1
    fi
    
    echo "$username|$token"
}

# Setup personal GitHub
read -p "Setup personal GitHub PAT? (y/N): " setup_personal
if [[ "$setup_personal" =~ ^[Yy]$ ]]; then
    creds=$(prompt_for_credentials "personal" "github" "RemoteRabbit")
    username=$(echo "$creds" | cut -d'|' -f1)
    token=$(echo "$creds" | cut -d'|' -f2)
    
    if [ "$USE_BITWARDEN" = true ]; then
        if [ "$token" != "BITWARDEN_EXISTING" ]; then
            setup_bitwarden_item "github" "personal" "$username" "$token" "github.com"
        fi
        
        # Update identity config for Bitwarden
        sed -i 's/^# \(# Option 4: Bitwarden integration\)/\1/' \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
        sed -i 's/^# \(\[credential "https:\/\/github\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
        sed -i 's/^# \(  helper = ~\/repos\/personal\/git\/helpers\/git-credential-bitwarden\)$/\1/' \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
    else
        setup_credential_file "github.com" "$username" "$token" \
            "$HOME/.git-credentials-personal" "github.com"
        
        # Update identity config for file storage
        sed -i 's/^# \(\[credential "https:\/\/github\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
        sed -i "s/^# \(  username = \).*/\1$username/" \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
        sed -i 's/^# \(  helper = store --file ~\/.git-credentials-personal\)$/\1/' \
            "$SCRIPT_DIR/identities/personal-github.gitconfig"
    fi
    
    # Comment out SSH
    sed -i 's/^\[core\]/# [core]/' "$SCRIPT_DIR/identities/personal-github.gitconfig"
    sed -i 's/^  sshCommand/#  sshCommand/' "$SCRIPT_DIR/identities/personal-github.gitconfig"
fi

echo

# Setup work GitHub
read -p "Setup work GitHub PAT? (y/N): " setup_work_github
if [[ "$setup_work_github" =~ ^[Yy]$ ]]; then
    creds=$(prompt_for_credentials "work" "github" "your-work-github-username")
    username=$(echo "$creds" | cut -d'|' -f1)
    token=$(echo "$creds" | cut -d'|' -f2)
    
    if [ "$USE_BITWARDEN" = true ]; then
        if [ "$token" != "BITWARDEN_EXISTING" ]; then
            setup_bitwarden_item "github" "work" "$username" "$token" "github.com"
        fi
        
        # Update identity config for Bitwarden
        sed -i 's/^# \(\[credential "https:\/\/github\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/work-github.gitconfig"
        sed -i 's/^# \(  helper = ~\/repos\/personal\/git\/helpers\/git-credential-bitwarden\)$/\1/' \
            "$SCRIPT_DIR/identities/work-github.gitconfig"
    else
        setup_credential_file "github.com" "$username" "$token" \
            "$HOME/.git-credentials-work-github" "github.com"
        
        # Update identity config for file storage
        sed -i 's/^# \(\[credential "https:\/\/github\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/work-github.gitconfig"
        sed -i "s/^# \(  username = \).*/\1$username/" \
            "$SCRIPT_DIR/identities/work-github.gitconfig"
        sed -i 's/^# \(  helper = store --file ~\/.git-credentials-work-github\)$/\1/' \
            "$SCRIPT_DIR/identities/work-github.gitconfig"
    fi
    
    # Comment out SSH
    sed -i 's/^\[core\]/# [core]/' "$SCRIPT_DIR/identities/work-github.gitconfig"
    sed -i 's/^  sshCommand/#  sshCommand/' "$SCRIPT_DIR/identities/work-github.gitconfig"
fi

echo

# Setup work GitLab
read -p "Setup work GitLab PAT? (y/N): " setup_work_gitlab
if [[ "$setup_work_gitlab" =~ ^[Yy]$ ]]; then
    creds=$(prompt_for_credentials "work" "gitlab" "your-work-gitlab-username")
    username=$(echo "$creds" | cut -d'|' -f1)
    token=$(echo "$creds" | cut -d'|' -f2)
    
    if [ "$USE_BITWARDEN" = true ]; then
        if [ "$token" != "BITWARDEN_EXISTING" ]; then
            setup_bitwarden_item "gitlab" "work" "$username" "$token" "gitlab.com"
        fi
        
        # Update identity config for Bitwarden
        sed -i 's/^# \(\[credential "https:\/\/gitlab\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
        sed -i 's/^# \(  helper = ~\/repos\/personal\/git\/helpers\/git-credential-bitwarden\)$/\1/' \
            "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
    else
        setup_credential_file "gitlab.com" "$username" "$token" \
            "$HOME/.git-credentials-work-gitlab" "gitlab.com"
        
        # Update identity config for file storage
        sed -i 's/^# \(\[credential "https:\/\/gitlab\.com"\]\)$/\1/' \
            "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
        sed -i "s/^# \(  username = \).*/\1$username/" \
            "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
        sed -i 's/^# \(  helper = store --file ~\/.git-credentials-work-gitlab\)$/\1/' \
            "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
    fi
    
    # Comment out SSH
    sed -i 's/^\[core\]/# [core]/' "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
    sed -i 's/^  sshCommand/#  sshCommand/' "$SCRIPT_DIR/identities/work-gitlab.gitconfig"
fi

echo
echo "🎉 Credential setup complete!"
echo

if [ "$USE_BITWARDEN" = true ]; then
    echo "🔐 Using Bitwarden for secure credential storage"
    echo "📝 Next steps:"
    echo "1. Ensure Bitwarden vault stays unlocked during git operations"
    echo "2. Test authentication:"
    echo "   git ls-remote https://github.com/username/repo.git"
    echo "   git ls-remote https://gitlab.com/username/repo.git"
    echo
    echo "🔓 To unlock vault when needed:"
    echo "   bw unlock"
    echo
    echo "📱 Bitwarden items created/updated:"
    bw list items --search "Git -" | jq -r '.[].name' | sort || echo "None found"
else
    echo "📁 Using file-based credential storage"
    echo "📝 Next steps:"
    echo "1. Test authentication:"
    echo "   git ls-remote https://github.com/username/repo.git"
    echo "   git ls-remote https://gitlab.com/username/repo.git"
    echo
    echo "🔐 Credential files created:"
    ls -la ~/.git-credentials-* 2>/dev/null || echo "None created"
    echo
    echo "⚠️  Security reminder:"
    echo "- Keep credential files secure (chmod 600)"
fi

echo
echo "2. Use HTTPS URLs for cloning:"
echo "   git clone https://github.com/username/repo.git"
echo "   git clone https://gitlab.com/username/repo.git"
echo
echo "⚠️  Security reminder:"
echo "- Use fine-grained PATs with minimal permissions"
echo "- Rotate tokens regularly"
