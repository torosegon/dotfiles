# Path to your dotfiles.
export DOTFILES=$HOME/.dotfiles

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

[[ -f "$DOTFILES/path.zsh" ]] && . $DOTFILES/path.zsh
[[ -f "$DOTFILES/aliases.zsh" ]] && . $DOTFILES/aliases.zsh

export PROMPT="%B %1~ %(!.#.>) %b"
