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

## SSH Key Setup

### Personal Key (GitHub)

```bash
# Generate if needed
ssh-keygen -t ed25519 -f ~/.ssh/proton -C "trjahnke@protonmail.com"

# Add to SSH agent
ssh-add ~/.ssh/proton

# Add public key to GitHub
cat ~/.ssh/proton.pub
```

### Work Keys

```bash
# GitHub work key
ssh-keygen -t ed25519 -f ~/.ssh/work_github_key -C "work-email@company.com"
ssh-add ~/.ssh/work_github_key

# GitLab work key  
ssh-keygen -t ed25519 -f ~/.ssh/work_gitlab_key -C "work-email@company.com"
ssh-add ~/.ssh/work_gitlab_key
```

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
