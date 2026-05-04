# Zsh Configuration
# Minimal, fast, and clean setup

# ============================================================================
# History Configuration
# ============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# ============================================================================
# Zsh Options
# ============================================================================
setopt AUTO_CD              # cd into directory by typing its name
setopt EXTENDED_GLOB        # extended globbing
setopt NOMATCH              # error on non-matching patterns
setopt NOTIFY               # report background job status immediately
setopt PROMPT_SUBST         # enable prompt variable substitution

# ============================================================================
# Completion System
# ============================================================================
autoload -Uz compinit
compinit

# Completion styles
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %d --%f'

# ============================================================================
# Plugins
# ============================================================================

# zsh-autosuggestions
source ~/.dotfiles/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^n' autosuggest-accept

# zsh-syntax-highlighting (must be sourced last)
source ~/.dotfiles/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================================================
# Prompt
# ============================================================================
PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{blue}%~%f %F{yellow}❯%f '
RPROMPT='$(git rev-parse --abbrev-ref HEAD 2>/dev/null | sed "s/^/%F{magenta}(/" | sed "s/$/)%f/")'

# ============================================================================
# Aliases
# ============================================================================
alias ls='ls -G'
alias la='ls -Ga'
alias ll='ls -lG'
alias lla='ls -laG'
alias cd..='cd ..'
alias grep='grep --color=auto'

# ============================================================================
# Environment Variables
# ============================================================================
export CLICOLOR=1
export CLICOLOR_FORCE=1
export LSCOLORS='ExGxBxDxCxEgEdxbxgxcxd'

# ============================================================================
# Key Bindings
# ============================================================================
bindkey -v  # vi key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ============================================================================
# Android SDK
# ============================================================================
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# ============================================================================
# Java Development Kit
# ============================================================================
if java_home=$(/usr/libexec/java_home -v 17 2>/dev/null); then
  export JAVA_HOME="$java_home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# ============================================================================
# Tmux
# ============================================================================
if command -v tmux >/dev/null 2>&1; then
  if [ -z "$TMUX" ]; then
    tmux new-session -A -s main
  fi
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
