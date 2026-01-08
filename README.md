# dazdotdev-devbox

A portable, headless development environment running on Coolify. Connect via SSH/mosh from anywhere on your Tailscale network.

## What's included

| Tool | Purpose |
|------|---------|
| **fnm** | Fast Node Manager (Node 22 LTS) |
| **pnpm** | Package manager |
| **bun** | Fast JS runtime and bundler |
| **Claude Code** | AI coding assistant (native binary) |
| **Neovim + LazyVim** | Editor with sensible defaults |
| **tmux** | Terminal multiplexer with session persistence |
| **Starship** | Minimal prompt with git status |
| **Tailscale** | Mesh VPN for direct access |
| **mosh** | Mobile-friendly SSH replacement |

## Prerequisites

- Coolify instance running on your server
- Tailscale account with auth key
- SSH public key(s) for your devices

## Setup

### 1. Add your SSH keys

Edit `config/authorized_keys` with your public keys:

```bash
# Get your key (run on your Mac/phone)
cat ~/.ssh/id_ed25519.pub
```

Paste into `config/authorized_keys`, one key per line.

### 2. Create Tailscale auth key

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Generate auth key:
   - Reusable: Yes (survives container rebuilds)
   - Expiry: Your preference
   - Tags: Optional
3. Copy the key

### 3. Deploy to Coolify

1. Create new resource → Dockerfile
2. Point to this repo
3. Configure environment variables:

| Variable | Value | Notes |
|----------|-------|-------|
| `TAILSCALE_AUTHKEY` | `tskey-auth-xxx` | From step 2 |
| `TAILSCALE_HOSTNAME` | `dazdotdev` | Your preferred name |
| `GIT_AUTHOR_NAME` | `Your Name` | For git commits |
| `GIT_AUTHOR_EMAIL` | `you@example.com` | For git commits |
| `GIT_COMMITTER_NAME` | `Your Name` | Usually same as author |
| `GIT_COMMITTER_EMAIL` | `you@example.com` | Usually same as author |

4. Configure container capabilities (Advanced → Custom Docker Options):

```json
{
  "CapAdd": ["NET_ADMIN", "SYS_MODULE"],
  "Devices": ["/dev/net/tun:/dev/net/tun"]
}
```

5. Configure volumes:

| Container path | Host path | Purpose |
|----------------|-----------|---------|
| `/home/dev` | `dazdotdev-home` | Projects, configs, shell history |
| `/var/lib/tailscale` | `dazdotdev-tailscale` | Tailscale state |

6. Resource limits (recommended):
   - CPU: 2 cores
   - Memory: 4GB

7. Deploy

### 4. First boot setup

Connect and complete one-time setup:

```bash
# From any device on your tailnet
mosh dev@dazdotdev

# Install tmux plugins (inside container)
~/.tmux/plugins/tpm/bin/install_plugins

# Authenticate Claude Code
claude
# Follow the OAuth URL it provides

# Clone your repos
cd ~/Code
git clone git@github.com:youruser/yourproject.git
```

## Daily usage

### Connecting

```bash
# From Mac/iPhone (via Terminus)
mosh dev@dazdotdev

# Attach to existing tmux session
tmux attach || tmux new -s main
```

### tmux cheatsheet

| Keys | Action |
|------|--------|
| `C-a \|` | Split vertical |
| `C-a -` | Split horizontal |
| `C-a h/j/k/l` | Navigate panes |
| `C-a c` | New window |
| `C-a 1-9` | Switch window |
| `C-a d` | Detach |
| `C-a r` | Reload config |

Sessions auto-save every 15 minutes and restore on tmux start.

### File transfer

**Code** - use git:
```bash
# On container
cd ~/Code/project
git add . && git commit -m "wip" && git push

# On Mac
git pull
```

**Files** - use Tailscale:
```bash
# From Mac to container
tailscale file cp ./file.txt dazdotdev:

# From container to Mac (run on container)
tailscale file cp ~/file.txt macbook:
```

**Bulk sync** - use rsync:
```bash
# Mac → Container
rsync -avz ./local-folder/ dev@dazdotdev:~/Code/project/

# Container → Mac
rsync -avz dev@dazdotdev:~/Code/project/ ./local-folder/
```

## Maintenance

### Adding new system dependencies

1. Commit and push any work in progress
2. Update `Dockerfile`
3. Push to repo
4. Redeploy in Coolify

Your `/home/dev` volume persists - only system-level changes require rebuild.

### What survives a rebuild

| Survives | Lost |
|----------|------|
| `~/Code/*` | Runtime `apt install` |
| `~/.config/nvim` | System packages not in Dockerfile |
| `~/.ssh` | `/tmp`, `/var` state |
| `~/.tmux/plugins` | |
| Tailscale auth | |

### Checking container health

```bash
# From inside container
claude doctor          # Claude Code status
tailscale status       # Network status
nvim --version         # Editor
node --version         # Node via fnm
```

## Troubleshooting

**Can't connect via mosh**
- Check Tailscale: `tailscale status` on both devices
- Ensure UDP ports 60000-60010 aren't blocked
- Fall back to SSH: `ssh dev@dazdotdev`

**Claude Code auth expired**
- Run `claude` and follow the OAuth flow again
- Credentials stored in `~/.claude/` (persisted)

**tmux plugins not working**
- Run `~/.tmux/plugins/tpm/bin/install_plugins`
- Then `tmux source ~/.tmux.conf`

**Node version issues**
- `fnm list` to see installed versions
- `fnm use 22` or `fnm install <version>`

## Philosophy

This container is cattle, not a pet. The Dockerfile is the source of truth. If something breaks badly, nuke it and redeploy - your code is in git, your home directory is on a volume, you lose nothing but a few minutes.
