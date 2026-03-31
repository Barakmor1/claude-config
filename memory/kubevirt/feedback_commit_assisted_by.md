---
name: Commit assisted-by trailer
description: Always add "Assisted-by: Claude Opus 4.6" before Signed-off-by in commit messages
type: feedback
---

Always include `Assisted-by: Claude Opus 4.6` as a trailer in commit messages, placed before the `Signed-off-by` line.

**Why:** User wants to attribute AI assistance in commits consistently.

**How to apply:** When creating or amending any git commit, add the line `Assisted-by: Claude Opus 4.6` immediately before the `Signed-off-by:` trailer.
