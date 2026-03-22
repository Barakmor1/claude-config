# Claude Config Repo — File Mapping

Repository: ~/Work/claude-config (remote: github.com/Barakmor1/claude-config)

## File Mapping (repo path → filesystem path)

| Repo Path          | Filesystem Path        | Description                      |
|--------------------|------------------------|----------------------------------|
| `global/CLAUDE.md` | `~/.claude/CLAUDE.md`  | Global Claude Code instructions  |
| `preferences.md`   | Applied to auto-memory | User preferences and conventions |

## Commands

- **sync config / pull config**: `git -C ~/Work/claude-config pull`, then read files and apply the mapping above
- **push config**: Read the filesystem files, update the repo files, commit and `git -C ~/Work/claude-config push`
- **update config**: Edit the repo files as requested, then apply mapping and push
