# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Initialize zoxide
eval "$(zoxide init zsh)"

# Source Powerlevel10k theme
source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ================= History ================= #
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# History options
setopt HIST_IGNORE_DUPS       # Do not record duplicate commands right after each other
setopt HIST_IGNORE_ALL_DUPS   # Remove old duplicate entries if a new one is saved
setopt HIST_IGNORE_SPACE      # Do not record commands that start with a space
setopt SHARE_HISTORY          # Share history across all active zsh sessions

# ================= Aliases ================= #
# System
alias sn="shutdown now"
alias rb="reboot"
alias sys-update="sudo dnf upgrade --refresh -y && flatpak update -y"
alias sys-clean="sudo dnf autoremove -y && sudo dnf clean all && flatpak remove --unused -y && journalctl --vacuum-size=100M"
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

