# Enable history
HISTFILE=~/.zsh_history
HISTSIZE=10000        # Number of lines kept in memory
SAVEHIST=10000        # Number of lines saved to HISTFILE
# Recommended history options
setopt inc_append_history         # Append commands as they are typed
setopt share_history              # Share history across all terminals
setopt hist_ignore_dups           # Ignore duplicate entries
setopt hist_reduce_blanks         # Remove superfluous blanks

FZF_DIR="$HOME/.config/zsh/plugins/fzf"
if [[ -d "$FZF_DIR/bin" ]]; then
  PATH="$FZF_DIR/bin:$PATH"
fi

source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/sudo/sudo.plugin.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.config/zsh/plugins/fzf/fzf.zsh
# source ~/.config/zsh/plugins/fzf/shell/key-bindings.zsh
# source ~/.config/zsh/plugins/fzf/shell/completion.zsh
source ~/.config/zsh/plugins/0TrashPanda/lsp.zsh
source ~/.config/zsh/plugins/0TrashPanda/toggle-ls-cat.zsh
source ~/.config/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme

# bindkey "${terminfo[kcuu1]}" fzf-history-widget

alias ls="eza -l -F --header --icons -s type"
alias cl="clear"
alias ..="cd .."
alias vim="nvim"
alias svim="sudo nvim"
alias df="df -h"
