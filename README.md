# Claude Code Configuration Backup

Backs up all Claude Code configuration from `~/.claude/` and project-level `.claude/` directories.

## Structure

```
├── backup.sh                # Run to sync live config → this repo
├── user-level/              # ~/.claude/
│   ├── CLAUDE.md
│   ├── settings.json
│   ├── commands/            # Slash commands
│   ├── agents/              # Custom agents
│   ├── rules/               # Always-loaded rules
│   └── hooks/               # Event-triggered scripts
├── project-level/           # Per-repo .claude/ configs
│   └── <repo-name>/
└── memory/                  # Auto-memory per project
    └── <repo-name>/
```

## Usage

```bash
./backup.sh          # Audit + backup
./backup.sh --check  # Audit only (no backup)
./backup.sh --force  # Skip audit, backup directly
```

Review changes with `git diff`, then commit.
