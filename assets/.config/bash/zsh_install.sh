mkdir -p ~/.config/zsh/plugins
mkdir -p ~/.config/zsh/themes

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.config/zsh/plugins/zsh-autosuggestions
mkdir -p ~/.config/zsh/plugins/sudo
curl -o ~/.config/zsh/plugins/sudo/sudo.plugin.zsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/refs/heads/master/plugins/sudo/sudo.plugin.zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.config/zsh/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.config/zsh/plugins/fzf
XDG_CONFIG_HOME="$HOME/.config/zsh/plugins" ~/.config/zsh/plugins/fzf/install --all --no-bash --no-fish --xdg --no-update-rc
git clone https://github.com/romkatv/powerlevel10k ~/.config/zsh/themes/powerlevel10k
git clone https://github.com/0TrashPanda/zsh-plugins ~/.config/zsh/plugins/0TrashPanda
