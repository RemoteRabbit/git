# Modular Git Configuration

Personal git configuration setup with provider-specific settings and identity management.

## Structure

```
git/
├── .gitconfig                 # Main config with includes and conditionals
├── setup.sh                  # Interactive setup script
├── providers/
│   ├── github.gitconfig      # GitHub-specific settings (URLs, credentials)
│   └── gitlab.gitconfig      # GitLab-specific settings (URLs, credentials, proxy)
├── identities/
│   ├── personal-github.gitconfig    # Personal GitHub identity
│   ├── work-github.gitconfig        # Work GitHub identity
│   └── work-gitlab.gitconfig        # Work GitLab identity
└── README.md
```

## How It Works

### Provider Configs

- **GitHub**: URL rewrites, credential helpers
- **GitLab**: URL rewrites, proxy settings, credential helpers

### Identity Switching

Git automatically switches identities based on:

1. **Directory structure**:
   - `~/repos/personal/**` → Personal GitHub identity
   - `~/repos/work/github/**` → Work GitHub identity  
   - `~/repos/work/gitlab/**` → Work GitLab identity

2. **URL-based matching**:
   - `git@gitlab.com:**` → Work GitLab identity (fallback)

## Setup

1. **Initial setup**: `./setup.sh`
2. **Symlink**: `ln -s $(pwd)/.gitconfig ~/.gitconfig`
3. **Create directory structure**:
   ```bash
   mkdir -p ~/repos/{personal,work/{github,gitlab}}
   ```
4. **Authentication setup**:
   - **SSH**: Keys are configured by `setup.sh`
   - **HTTPS/PAT**: Run `./setup-credentials.sh` for token-based auth
     - Auto-detects Bitwarden CLI for secure credential storage
     - Falls back to file-based storage if Bitwarden unavailable

## Usage

### Adding New Repos

```bash
# Personal project
cd ~/repos/personal/
git clone git@github.com:remoterabbit/project.git

# Work GitHub project
cd ~/repos/work/github/
git clone git@github.com:company/project.git

# Work GitLab project  
cd ~/repos/work/gitlab/
git clone git@gitlab.com:company/project.git
```

### Verification

```bash
# Check which config is being used
git config --list --show-origin | grep user.email

# Test in different directories
cd ~/repos/personal/some-project && git config user.email
cd ~/repos/work/github/some-project && git config user.email
cd ~/repos/work/gitlab/some-project && git config user.email
```

## Configuration

### Adding New SSH Keys

Update the appropriate identity file:

```bash
# Edit identity configs
vim identities/work-github.gitconfig
vim identities/work-gitlab.gitconfig
```

### Adding Proxy Settings

Edit `providers/gitlab.gitconfig`:

```gitconfig
[http "https://gitlab.com"]
  proxy = http://proxy.company.com:8080
[https "https://gitlab.com"]  
  proxy = http://proxy.company.com:8080
```

### Adding New Providers

1. Create `providers/newprovider.gitconfig`
2. Add to main `.gitconfig` includes
3. Create identity configs if needed
4. Add conditional includes

## Troubleshooting

### Wrong Identity Used

```bash
# Check current identity
git config user.email

# Check which config files are being loaded
git config --list --show-origin | grep "user\|include"

# Verify directory patterns match
pwd  # Should match includeIf patterns
```

### SSH Issues

```bash
# Test SSH connections
ssh -T git@github.com
ssh -T git@gitlab.com

# Check SSH key loading
ssh-add -l

# Test with specific key
ssh -i ~/.ssh/work_github_key -T git@github.com
```

### Bitwarden Issues
```bash
# Check Bitwarden status
bw status

# Unlock vault
bw unlock

# List Git credentials
bw list items --search "Git -"

# Test credential retrieval
bw get item "Git - GitHub - Personal"

# Set session for automated workflows
export BW_SESSION="$(bw unlock --raw)"
```

### Credential Helper Issues
```bash
# Check which helper is active
git config --get credential.helper

# Test credential helper manually
echo -e "protocol=https\nhost=github.com" | git credential fill

# Clear cached credentials
git credential reject <<EOF
protocol=https
host=github.com
EOF
```

### Config Not Loading

```bash
# Check symlink
ls -la ~/.gitconfig

# Verify file paths exist
git config --list --show-origin | grep "fatal\|error"

# Test includeIf conditions
cd /target/directory
git config --show-origin --get user.email
```

## Aliases Reference

- `git alias` - List all aliases
- `git c` - Clone with submodules
- `git ca` - Add all and commit with editor
- `git cam "msg"` - Add all and commit with message
- `git go branch` - Checkout or create branch
- `git l` - Pretty log (20 entries)
- `git lg` - Detailed pretty log with signatures
- `git s` - Short status
- `git p` - Pull and update submodules
- `git up` - Push current branch upstream
- `git dm` - Delete merged branches

## Authentication Setup

### SSH Keys
```bash
# Personal key (GitHub)
ssh-keygen -t ed25519 -f ~/.ssh/proton -C "trjahnke@protonmail.com"
ssh-add ~/.ssh/proton

# Work keys
ssh-keygen -t ed25519 -f ~/.ssh/work_github_key -C "work-email@company.com"
ssh-keygen -t ed25519 -f ~/.ssh/work_gitlab_key -C "work-email@company.com"
ssh-add ~/.ssh/work_github_key ~/.ssh/work_gitlab_key
```

### PAT/Token Authentication

#### Automated Setup (Recommended)
```bash
# Interactive setup with Bitwarden or file-based storage
./setup-credentials.sh

# The script will:
# 1. Detect if Bitwarden CLI is available
# 2. Prompt for Bitwarden vs file-based storage
# 3. Check for existing credentials
# 4. Create/update credential storage
# 5. Configure the appropriate git credential helper
```

#### Manual Setup Options

**Option 1: Bitwarden (Most Secure)**
```bash
# Install prerequisites
npm install -g @bitwarden/cli
sudo pacman -S jq

# Create items in Bitwarden with names like:
# "Git - GitHub - Personal", "Git - GitHub - Work", etc.

# Enable in identity configs (uncomment Option 4)
vim identities/personal-github.gitconfig
```

**Option 2: File-based Storage**
```bash
# Create credential files:
echo "https://username:token@github.com" > ~/.git-credentials-personal
echo "https://username:token@github.com" > ~/.git-credentials-work-github  
echo "https://username:token@gitlab.com" > ~/.git-credentials-work-gitlab
chmod 600 ~/.git-credentials-*

# Enable in identity configs (uncomment Option 1 or 2)
vim identities/personal-github.gitconfig
```

### Switching Authentication Methods

Each identity config supports multiple authentication options:

1. **SSH** - Uses SSH keys (default)
2. **File-based credentials** - Plain text files (separate per identity) 
3. **Shared credential store** - Single file for all credentials
4. **Memory cache** - Temporary storage, expires after timeout
5. **Bitwarden integration** - Encrypted vault storage

```bash
# Edit identity config to change method
vim identities/personal-github.gitconfig

# Uncomment the desired option:
# [credential "https://github.com"]
#   helper = ~/repos/personal/git/helpers/git-credential-bitwarden  # Bitwarden
#   helper = store --file ~/.git-credentials-personal              # File-based
#   helper = store                                                 # Shared
#   helper = cache --timeout=3600                                  # Memory
```

## Security Considerations

### Credential Storage Options (Most to Least Secure)

1. **SSH Keys** - Private keys encrypted on disk, no network transmission of secrets
2. **Bitwarden** - PATs encrypted in vault, centralized management, audit trail
3. **Memory Cache** - Temporary storage, clears on timeout/reboot
4. **File-based** - Plain text files (chmod 600), separate per context
5. **Shared Store** - Single plain text file for all credentials

### Best Practices

- **Use fine-grained PATs** with minimal required permissions
- **Set expiration dates** on tokens and rotate regularly  
- **Enable 2FA** on provider accounts
- **Monitor access logs** for unauthorized usage
- **Use Bitwarden** for credential storage when possible
- **Keep vault locked** when not actively using git

## Directory Organization

```
~/repos/
├── personal/           # Personal GitHub projects
│   ├── dotfiles/
│   ├── project1/
│   └── project2/
└── work/
    ├── github/         # Work GitHub projects
    │   ├── internal-tool/
    │   └── client-project/
    └── gitlab/         # Work GitLab projects
        ├── enterprise-app/
        └── deployment-scripts/
```

## Files Reference

```
git/
├── .gitconfig                           # Main config with includes
├── setup.sh                           # Initial setup script  
├── setup-credentials.sh                # Credential setup script
├── setup-bitwarden.md                 # Bitwarden setup guide
├── README.md                          # This documentation
├── providers/
│   ├── github.gitconfig               # GitHub URL rewrites & credentials
│   └── gitlab.gitconfig               # GitLab URL rewrites & proxy
├── identities/
│   ├── personal-github.gitconfig      # Personal GitHub identity
│   ├── work-github.gitconfig          # Work GitHub identity
│   └── work-gitlab.gitconfig          # Work GitLab identity
└── helpers/
    └── git-credential-bitwarden       # Bitwarden credential helper
```
