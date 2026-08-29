# MAGI & BABEL-2588

Two linked projects, one repo. **MAGI** is the homelab: an always-on box on a shelf.
**BABEL-2588** is the cyberdeck: a portable, self-contained field computer.

`MASTERPLAN.md` is the full plan — thesis, ground rules, every build phase (H-00…H-11,
CD-00…CD-10), learning path, hardware dossier, costs. **Read the relevant phase from it
rather than assuming; don't restate it back into this file.**

## Where I am right now

- **Phase: H-00 (groundwork).** Nothing deployed yet.
- Next concrete step: `sudo dmidecode -t memory` to find out whether the laptop has a
  free SO-DIMM slot. That answer changes the plan (see §01, "The very first command").

<!-- Keep the two lines above current. It is the one thing a fresh session can't infer. -->

## Rules that matter more than convenience

1. **Never print, echo, `cat`, or commit anything from `secrets/`, `.env`, or a keyfile.**
   Not into chat, not into a log, not into a runbook entry. `.env.example` with dummy
   values is the committed artifact.
2. **SeedSigner stays airgapped.** It never touches this network, this repo, or any
   machine that does. If a suggestion would connect it, the suggestion is wrong.
3. **Suricata stays scoped to the Docker bridge** until a real mirror/SPAN port exists.
   It cannot see traffic that doesn't cross the interface it's watching.
4. **The club Mac Studio is a burst tier, never a foundation.** Nothing structural may
   depend on it, and no private data (Vaultwarden, Immich, personal documents) goes onto
   borrowed hardware. It buys artifacts, not architecture.
5. **Buy the thing that unblocks the next phase, nothing else** (R6) — except long-lead
   AliExpress parts, ordered one phase early.

## Conventions

- **Layout:** `compose/` one dir per stack (`compose.yaml` + `.env.example`) ·
  `config/` per-service config · `dashboards/` exported Grafana JSON ·
  `ansible/` later · `runbook/` how to restore, what broke, why · `secrets/` gitignored.
- **Config files over GUI settings** (R1). A setting that lives only in a web UI's
  database is a setting that gets lost in the rebuild.
- **Naming:** hosts, MQTT topics, Grafana titles and panel labels all use the callsigns.
  MQTT roots are `magi/…` and `babel-2588/…`. One scheme, everywhere — the consistency
  is the aesthetic.
- **Commits:** present tense, say *why* when it isn't obvious. Git covers what changed;
  the runbook covers what broke.

## How to work with me

- **I'm learning this, not maintaining it.** Explain the reasoning, don't just hand me
  a working command. If there's a real choice being made, say what the alternatives were.
- **Keep the jargon, add a plain-English line next to it.** Don't dumb things down and
  don't strip technical terms — I want them for later. Just translate when it gets dense.
- **Don't run destructive or outward-facing things without asking** — `docker compose down -v`,
  anything that deletes volumes, anything that opens a port to the internet.
- **At the end of a working session, offer to draft the runbook entry** (see below).

## The runbook (R5)

One log file per phase: `runbook/000-log.md` for H-00, `001-log.md` for H-01, and so on.
Every session gets **three lines**:

```
## YYYY-MM-DD
- Did:
- Broke:
- Differently:
```

Three honest lines, not a transcript. This file is also what the local model reads in
H-08, so it compounds — signal is worth more here than volume.
