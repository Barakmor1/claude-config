---
name: claude-config-backup-repo
description: User's Claude Code configuration backup repo at Barakmor1/claude-config - source of truth for all Claude config
type: reference
---

Claude config backup repo: https://github.com/Barakmor1/claude-config

This is the source of truth for all Claude Code configuration.
Always sync changes to this repo when modifying Claude config (skills, settings, commands, hooks, rules, etc.).

The repo has a `backup.sh` script that audits coverage and copies config from `~/.claude/` (user-level) and `~/Work/<repo>/.claude/` (project-level) into the backup repo.

**How to apply:** When the user says "sync" the config repo, run `backup.sh` in the cloned repo, then commit and push to GitHub. Always complete the full cycle — sync means push, not just local backup.
