# ╔══════════════════════════════════════════════════════════════════╗
# ║   ~/.zshrc — Vaporwave shell for HP Stream 7                     ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── History ────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY INC_APPEND_HISTORY
setopt AUTO_CD PROMPT_SUBST

# ── Completion ─────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ── Plugins ────────────────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# vaporwave autosuggest color (soft magenta)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#b683d4,underline'

# ── Aliases ────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias fetch='fastfetch'
alias neofetch='fastfetch'   # muscle memory
alias vibe='cmatrix -ab -C magenta'
alias rice='fastfetch | lolcat -F 0.3'

# ── Starship prompt ────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Welcome banner (only for interactive non-SSH sessions) ─────────
if [[ -o interactive ]] && [[ -z "$SSH_CONNECTION" ]] && [[ -z "$ZSH_BANNER_SHOWN" ]]; then
    export ZSH_BANNER_SHOWN=1
    if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
        figlet -f slant "Stream 7" | lolcat -F 0.2 -p 2.0
        echo "        ｖａｐｏｒｗａｖｅ ｔｅｒｍｉｎａｌ" | lolcat
        echo ""
    fi
    fastfetch 2>/dev/null | lolcat -F 0.1 2>/dev/null || fastfetch 2>/dev/null
fi
