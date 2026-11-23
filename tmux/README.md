<!-- Author: Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE) -->

# tmux: a quiet status line and a modern terminal underneath

A short configuration for [tmux](https://github.com/tmux/tmux): it tells tmux what a modern terminal
can do, and it draws a status line that stays out of the way. tmux keeps a session alive when the
window closes, which the terminal itself does not.

## Design

* **The colours of the terminal.** The status line, the borders of the panes and the copy mode use
  the sixteen colours of the terminal, so tmux wears the colour scheme of the terminal, whichever it
  is, light or dark.
* **One accent.** The name of the session sits in a pill of the blue of the
  [Starship prompt](../starship/README.md) (`#1E3A8A` with `#F8FAFC`), the current window is written
  in blue, and everything else is dim.
* **Nothing lost on the way.** Full colour, links, updates drawn in one piece, the clipboard, modified
  keys, focus and styled underlines pass through tmux to the terminal and back.

## Settings

| Setting | Value | Why |
|---|---|---|
| `default-terminal` | `tmux-256color` | The description that programs inside tmux read. |
| `terminal-features` | `RGB`, `hyperlinks`, `sync`, `clipboard`, `extkeys`, `focus`, `usstyle` | What the description of the outer terminal does not say, for Ghostty (`xterm-ghostty`) and for terminals that say `xterm-256color`. |
| `set-clipboard` | `on` | A copy made in tmux, or by a program inside it, reaches the clipboard of the desktop. |
| `extended-keys`, `extended-keys-format` | `on`, `csi-u` | A program inside tmux tells Shift+Enter from Enter. |
| `focus-events` | `on` | A program learns that its pane got the keyboard, and an editor reloads a changed file. |
| `allow-passthrough` | `on` | Pictures and other sequences that tmux does not know go through to the terminal. |
| `mouse` | `on` | Click a pane, drag a border, scroll the history. |
| `history-limit` | `50000` | Lines kept for each pane. |
| `base-index`, `renumber-windows` | `1`, `on` | Windows are counted from 1, as the keys are laid out, and stay numbered without gaps. |
| `status-left`, `window-status-current-format`, `status-right` | see `tmux.conf` | The session in a pill, the current window in blue, the clock. |
| `pane-border-style`, `pane-active-border-style`, `mode-style` | colours 8, 4, and 0 on 4 | Dim borders, a blue one for the pane with the keyboard, and a blue selection in the copy mode. |

The keys are those of tmux: the prefix stays Ctrl+B.

## Install on a machine

```bash
git clone https://github.com/dutykh/my-cli-config.git ~/workspace/my-cli-config
~/workspace/my-cli-config/install.sh
# or only this component:
~/workspace/my-cli-config/tmux/install.sh
```

The installer:

1. does nothing, and says so, when `tmux` is not installed
2. backs up an existing real `~/.config/tmux/tmux.conf` (not a symlink)
3. symlinks `~/.config/tmux/tmux.conf` to this repo's `tmux.conf`
4. says so when a `~/.tmux.conf` exists, which tmux reads before this file

A second run changes nothing. Update with `git pull`. A server that already runs keeps its settings
until `tmux source-file ~/.config/tmux/tmux.conf`.

Requirements: tmux 3.5 or later (`extended-keys-format` came with 3.5), and a Nerd Font in the
terminal for the two round ends of the pill.

## Files

| file | purpose |
|---|---|
| `tmux.conf` | the shared configuration (tracked) |
| `install.sh` | symlink into `~/.config/tmux/` |

## Uninstall

```bash
rm ~/.config/tmux/tmux.conf                         # the symlink
```

If the installer backed up a configuration you had before, restore it:
`ls ~/.config/tmux/tmux.conf.bak.*`.

---

**Author**: Dr. Denys Dutykh, Mathematics Department, Khalifa University, Abu Dhabi, UAE ·
[Homepage](https://www.denys-dutykh.com/) · [GitHub](https://github.com/dutykh) ·
[ORCID](https://orcid.org/0000-0001-5247-2788)
**License**: [MIT](../LICENSE) · part of [my-cli-config](https://github.com/dutykh/my-cli-config)
