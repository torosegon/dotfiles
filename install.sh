#!/usr/bin/env bash
# Dotfiles installer for Fedora + sway.
#
# Usage: ./install.sh [-n] [step ...]
#   -n      dry run: only print what would be done
#   steps:
#     packages  install the packages from packages/fedora.txt (sudo)
#     link      symlink everything under stow/ into $HOME with GNU Stow
#     apps      generate the .desktop launchers in ~/.local/share/applications
#     system    install the greetd (tuigreet) config and switch the display manager (sudo)
#
# Default steps: packages link apps. "system" only runs when asked for explicitly.
set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STOW_DIR="$DOTFILES/stow"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY=0

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
run() { if [ "$DRY" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }

step_packages() {
    local pkgs
    mapfile -t pkgs < <(grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/packages/fedora.txt")
    log "Installing ${#pkgs[@]} packages"
    run sudo dnf install -y "${pkgs[@]}"
}

# Move existing files that would conflict with a stow link into the backup directory.
backup_conflicts() { # package
    local pkg=$1 f rel target
    while IFS= read -r -d '' f; do
        rel=${f#"$STOW_DIR/$pkg/"}
        target="$HOME/$rel"
        # a link that already points into this repo is fine, stow replaces it
        if [ -L "$target" ] && [[ $(readlink -f "$target") == "$DOTFILES"/* ]]; then continue; fi
        [ -e "$target" ] || [ -L "$target" ] || continue
        log "Backing up $target -> $BACKUP/$rel"
        run mkdir -p "$BACKUP/$(dirname "$rel")"
        run mv "$target" "$BACKUP/$rel"
    done < <(find "$STOW_DIR/$pkg" \( -type f -o -type l \) -print0)
}

step_link() {
    [ "$DRY" = 1 ] || command -v stow >/dev/null || die "stow not found (run: ./install.sh packages)"
    local pkg
    for pkg in $(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort); do
        backup_conflicts "$pkg"
        log "Linking $pkg"
        # --no-folding: link individual files, so runtime-written files never end up in the repo
        run stow --dir "$STOW_DIR" --target "$HOME" --no-folding --restow "$pkg"
    done

    # foot includes theme.ini, which darkmode.sh rewrites; make sure it exists
    local theme="$HOME/.config/foot/theme.ini"
    if [ ! -e "$theme" ]; then
        log "Creating default $theme"
        if [ "$DRY" != 1 ]; then
            mkdir -p "$(dirname "$theme")"
            printf '[main]\ninitial-color-theme=dark\n' > "$theme"
        fi
    fi
}

step_apps() {
    local dst="$HOME/.local/share/applications" f out
    run mkdir -p "$dst"
    for f in "$DOTFILES"/templates/applications/*.desktop.in; do
        out="$dst/$(basename "${f%.in}")"
        log "Generating $out"
        [ "$DRY" = 1 ] || sed "s|@HOME@|$HOME|g" "$f" > "$out"
    done
    if command -v update-desktop-database >/dev/null; then run update-desktop-database "$dst"; fi
}

step_system() {
    log "This installs the greetd config and switches the display manager to greetd + tuigreet."
    if [ "$DRY" != 1 ]; then
        read -r -p "Continue? [y/N] " ans
        [[ $ans == [yY] ]] || { log "Skipped"; return 0; }
    fi
    run sudo install -Dm644 -b "$DOTFILES/system/etc/greetd/config.toml" /etc/greetd/config.toml
    if systemctl is-enabled --quiet gdm.service 2>/dev/null; then
        run sudo systemctl disable gdm.service
    fi
    run sudo systemctl enable --force greetd.service
    log "Done, takes effect on the next boot."
    log "Rollback: sudo systemctl disable greetd.service && sudo systemctl enable --force gdm.service"
}

steps=()
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY=1 ;;
        -h|--help)    sed -n '2,/^set /{/^set /!p}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        packages|link|apps|system) steps+=("$arg") ;;
        *) die "unknown argument: $arg (try --help)" ;;
    esac
done
[ ${#steps[@]} -gt 0 ] || steps=(packages link apps)

for s in "${steps[@]}"; do "step_$s"; done
log "Finished: ${steps[*]}"
