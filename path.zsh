# Load dotfiles binaries
export PATH="$DOTFILES/bin:$DOTFILES/exports:$PATH"

# Load Composer tools
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Load Node global installed binaries
export PATH="$HOME/.node/bin:$PATH"

# Use project specific binaries before global ones
export PATH="node_modules/.bin:vendor/bin:$PATH"

# Load StarShip config file
export STARSHIP_CONFIG=$DOTFILES/starship.toml