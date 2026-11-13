[[ $- != *i* ]] && return

export DOTFILES="$HOME/.dotfiles"

alias ~="cd ~"
alias ..="cd ../"
alias dotfiles='cd "$DOTFILES"'
alias codes="cd $HOME/Codes"
alias downloads="cd $HOME/Downloads"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Common typos for git
alias gti="git"
alias igt="git"
alias gt="git"
alias gi="git"

PS1='\[\e[1m\]\w\[\e[0m\]$(if [[ $EUID -eq 0 ]]; then echo " #"; else echo " >"; fi) '

# npm global packages (user prefix, see ~/.npmrc)
export PATH="$HOME/.npm-global/bin:$PATH"

# Lerd
export PATH="$HOME/.local/share/lerd/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# fzf key bindings and completion
command -v fzf >/dev/null && eval "$(fzf --bash)"
