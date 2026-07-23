# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source Powerlevel10k theme
source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ================= Aliases ================= #
# System
alias sn="shutdown now"
alias rb="reboot"
alias ls="eza --color=always --long --git --no-filesize --icons=always"
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."
alias \?="pay-respects"

# Git
alias glg="git log --oneline --graph --all --decorate"
alias gst="git status"
alias gcob="git checkout -b"
alias gco="git checkout"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias gcl="git clone"
alias update-cp='git commit -m "Update $(date '\''+%Y-%m-%d %H:%M:%S'\'')"'
alias commit="cz commit"

# Plugins
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

