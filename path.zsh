# Load dotfiles binaries
export PATH="$DOTFILES/bin:$DOTFILES/exports:$PATH"

# Load pkgx binaries
export PATH="$HOME/.local/bin:$PATH"

# Load Composer tools
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Load Node global installed binaries
export PATH="$HOME/.node/bin:$PATH"

# Use project specific binaries before global ones
export PATH="node_modules/.bin:vendor/bin:$PATH"
