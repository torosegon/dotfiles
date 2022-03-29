# Shortcuts
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias phpstorm='open -a /Applications/PhpStorm.app "`pwd`"'
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias whatsmyip="dig +short myip.opendns.com @resolver1.opendns.com"
alias whatsmylocalip="ipconfig getifaddr en0"
alias grep="grep --color=auto"
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
alias csv="sed 's/,,/, ,/g;s/,,/, ,/g' "$@" | column -s, -t | less -#2 -N -S"
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1    ;;
            *)           echo "'$1' cannot be extracted via extract" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}


# Directories
alias ~="cd ~"
alias ..="cd ../"
alias dotfiles="cd $DOTFILES"
alias library="cd $HOME/Library"
alias codes="cd $HOME/Codes"
alias downloads="cd $HOME/Downloads"
alias ls="ls -lhaG"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Laravel
alias artisan="php artisan"
alias tinker="php artisan tinker"
alias seed="php artisan db:seed"
alias serve="php artisan serve"

# PHP
alias composer="php -d memory_limit=-1 /opt/homebrew/bin/composer"

# Git
alias gti="git"
alias igt="git"
alias gt="git"
alias gi="git"