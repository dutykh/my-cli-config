# my-cli-config

Personal, machine-independent CLI configuration. Each top-level folder is one component with its own
`install.sh`; the root `install.sh` runs them all. Everything is installed by **symlink**, so updating a
machine is `git pull`.

```bash
git clone <your-remote> ~/workspace/my-cli-config
~/workspace/my-cli-config/install.sh
```

| component | what it configures |
|---|---|
| [`claude/`](claude/README.md) | Claude Code status line (3 lines, Nerd Font / emoji icons, light-dark aware, colour-blind-safe) |
| [`starship/`](starship/README.md) | Starship blue powerline prompt (Nerd Font icons, light-dark readable) |

Per-machine settings (e.g. `~/.claude/statusline.conf`) are seeded once and never overwritten, so each
machine can keep its own tweaks while the code stays shared.
