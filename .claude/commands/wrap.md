---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(ls:*), Bash(cat:*)
argument-hint: [optional note — anything I should know that isn't in the diff]
description: Draft the runbook entry for this session, then commit and push
---

Close out this working session.

## State

- Current phase (from CLAUDE.md): !`grep -m1 -i "Phase:" CLAUDE.md`
- Existing logs: !`ls runbook/`
- Working tree: !`git status --short`
- Changes since last commit: !`git diff --stat HEAD`
- Recent commits: !`git log --oneline -5`

The user's note for this session: $ARGUMENTS

## What to do

1. **Pick the log file.** One log per phase, in `runbook/`, matching the current phase
   above. If the phase moved on and its log doesn't exist yet, create it with a heading
   for the phase.

2. **Draft the entry** and append it under today's date:

   ```
   ## YYYY-MM-DD
   - **Did:**
   - **Broke:**
   - **Differently:**
   ```

   Base it on what actually happened in this session — the conversation, the diff, and
   the user's note. Not the git diff alone; the diff shows what changed, not what was
   confusing, what took three tries, or what turned out to be a dead end.

   **The "Broke" line is the valuable one.** A log of only successes is worthless in
   month eight, and this file is what the local model reads in H-08 — so failures are
   the part with retrieval value. If genuinely nothing broke, say so plainly rather
   than inventing something. If something is still unresolved, say that too, and add a
   `### Next` checklist so the next session has a starting point.

   Keep it to three honest lines. This is a log, not a transcript.

3. **Show the drafted entry and stop.** Let the user confirm or correct it — they know
   what felt wrong, which nothing in the diff can tell you.

4. **After they confirm**, write it, then:
   - Update the `Phase:` line in CLAUDE.md **only if the phase actually changed.**
     Not every session. That file is auto-loaded into every context and should stay
     small and stable.
   - `git add -A`, commit with a message saying what was done and *why* where it isn't
     obvious, and `git push`.
   - Before committing, confirm nothing sensitive is staged:
     `git diff --cached --name-only` should show no `.env`, key, or `secrets/` file
     other than `secrets/README.md`.

5. **Report** the log file written, the commit hash, and confirm the push succeeded.
