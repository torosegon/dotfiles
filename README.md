# dotfiles

Fedora + [sway](https://swaywm.org) setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Every directory under `stow/` is a Stow package that mirrors `$HOME`; `install.sh` symlinks the
files one by one (`--no-folding`), so files written at runtime never end up in this repo.

## Fresh install

```sh
sudo dnf install -y git
git clone https://torosegon/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh            # packages, link, apps
./install.sh system     # optional: greetd + tuigreet instead of GDM (asks for confirmation)
```

`./install.sh -n` does a dry run. Existing files that would conflict with a link are moved to
`~/.dotfiles-backup/<timestamp>/`.

## Layout

| Path | Purpose |
| --- | --- |
| `stow/sway` | sway config and helper scripts (bar status, OSD, calculator, Wi-Fi/Bluetooth menus, screenshots, dark mode) |
| `stow/fuzzel` | fuzzel style (`sway.ini`) |
| `stow/swappy` | swappy (screenshot annotator) settings |
| `stow/foot` | foot terminal (the dark/light theme is switched by `darkmode.sh`) |
| `stow/shell` | `.bashrc`, `.bash_profile`, `.gitconfig`, `.npmrc` |
| `templates/` | `.desktop` launchers, rendered with the real `$HOME` by the `apps` step |
| `system/` | system-wide files (`/etc/greetd/config.toml`), installed by the `system` step |
| `packages/fedora.txt` | packages installed by the `packages` step |

## Adding a config

Put the file under `stow/<package>/` at the same relative path it has in `$HOME`, then run
`./install.sh link` (it is safe to re-run).
