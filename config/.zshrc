# Terminal fallback for Ghostty etc.
if ! infocmp "$TERM" &>/dev/null; then
    export TERM=xterm-256color
fi

# pnpm
export PNPM_HOME="/home/dev/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# fnm
eval "$(/home/dev/.fnm/fnm env --use-on-cd --shell zsh)"

# Tools PATH
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

# Starship
eval "$(starship init zsh)"

# Git identity from env vars
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-dev}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-dev}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-dev@local}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-dev@local}"
