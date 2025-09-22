# Bitwarden Integration Setup

## Prerequisites

1. **Install Bitwarden CLI**:
   ```bash
   npm install -g @bitwarden/cli
   # or
   sudo pacman -S bitwarden-cli
   ```

2. **Install jq**:
   ```bash
   sudo pacman -S jq
   ```

## Setup

1. **Login to Bitwarden**:
   ```bash
   bw config server https://vault.bitwarden.com  # or your self-hosted URL
   bw login
   bw unlock
   ```

2. **Create Git credential items in Bitwarden**:

   For each Git provider/context combination, create an item with:
   
   **Item Details:**
   - **Name**: `Git - GitHub - Personal` (or `Git - GitLab - Work`, etc.)
   - **Type**: Login
   - **Username**: Your Git username (e.g., `RemoteRabbit`)
   - **Password**: Your PAT/token
   
   **Custom Fields** (optional, for better organization):
   - `provider`: `github.com` or `gitlab.com`
   - `context`: `personal` or `work`

   **Example items to create:**
   ```
   Git - GitHub - Personal    (username: RemoteRabbit, password: ghp_xxx)
   Git - GitHub - Work        (username: work-user, password: ghp_yyy)
   Git - GitLab - Work        (username: work-user, password: glpat_zzz)
   ```

3. **Enable Bitwarden helper** in your identity configs:
   
   Uncomment the Bitwarden option in the relevant identity files:
   ```gitconfig
   [credential "https://github.com"]
     helper = ~/repos/personal/git/helpers/git-credential-bitwarden
   ```

4. **Test the setup**:
   ```bash
   cd ~/repos/personal/some-repo
   git ls-remote https://github.com/username/repo.git
   ```

## Usage

The helper automatically detects context based on your directory:
- `~/repos/personal/**` → looks for "personal" context items
- `~/repos/work/**` → looks for "work" context items

### Manual context override
Set a context hint for repositories outside standard directories:
```bash
git config credential.bitwarden.context "work"
```

### Unlock vault when needed
If you see "vault is locked" errors:
```bash
bw unlock
```

### Session management
For automated workflows, you can set session variables:
```bash
export BW_SESSION="$(bw unlock --raw)"
```

## Troubleshooting

### Item not found
- Verify item names match the expected pattern: `Git - {Provider} - {Context}`
- Check custom fields if using them
- List items: `bw list items --search git`

### Vault locked
- Run: `bw unlock`
- Check status: `bw status`

### Credentials not working
- Test manually: `bw get item "Git - GitHub - Personal"`
- Verify PAT permissions and expiration
- Check username matches exactly

## Security Benefits

- **No plain text storage**: Credentials encrypted in Bitwarden vault
- **Centralized management**: Update tokens in one place
- **Audit trail**: Bitwarden tracks access
- **Multi-device sync**: Available across all your devices
- **Automatic locking**: Vault locks after inactivity
