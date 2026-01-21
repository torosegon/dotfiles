[[ $- != *i* ]] && return

export PATH="$PATH:$HOME/.local/bin:$HOME/.config/composer/vendor/bin"

alias ~="cd ~"
alias ..="cd ../"
alias dotfiles="cd $DOTFILES"
alias codes="cd $HOME/Codes"
alias downloads="cd $HOME/Downloads"
alias ls="ls -lhaG"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias gti="git"
alias igt="git"
alias gt="git"
alias gi="git"

alias php="pls php"
alias composer="pls composer"

alias artisan="php artisan"

PS1='\[\e[1m\]\w\[\e[0m\]$(if [[ $EUID -eq 0 ]]; then echo " #"; else echo " >"; fi) '

eval $(fzf --bash)
