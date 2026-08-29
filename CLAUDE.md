# MAGI & BABEL-2588

Two linked projects, one repo. **MAGI** is the homelab: an always-on box on a shelf.
**BABEL-2588** is the cyberdeck: a portable, self-contained field computer.

`MASTERPLAN.md` is the full plan — thesis, ground rules, every build phase (H-00…H-11,
CD-00…CD-10), learning path, hardware dossier, costs. **Read the relevant phase from it
rather than assuming; don't restate it back into this file.**

## Where I am right now

- **Phase: H-00 (groundwork), nearly complete.** Nothing containerised yet.
- **MAGI is up:** HP 15s-fq5xxx, i5-1235U (10c/12t, Iris Xe), 2 × 4 GB DDR4-3200 with
  **both slots full** (32 GB ceiling), 512 GB NVMe, **no Ethernet port**, battery 100%.
  Ubuntu Server 26.04.1 LTS, LVM no LUKS, root expanded to 466 G. Keys-only SSH, ufw
  default-deny, unattended-upgrades, lid-close ignored (`scripts/h00-harden.sh`).
- **Reach it with `ssh magi`** — Tailscale (H-01, pulled forward) bridges cipher and
  magi across different networks. On cipher, Tailscale and Cloudflare WARP coexist only
  because `*.tailscale.com` is in WARP's split-tunnel exclude list; don't reset that.
- Outstanding H-00: RAM pair and USB-Ethernet not bought, no DHCP reservation,
  `apt upgrade` pending non-mobile data, MAGI's permanent network undecided (campus
  wifi is WPA2-Enterprise; wired is captive-portal or 802.1X, not yet determined).

<!-- Keep this block current. It is the one thing a fresh session can't infer. -->

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
6. **Never edit configs directly on MAGI.** Edit here on `cipher`, commit, push, then
   `git pull` on MAGI and bring the stack up. A file changed over SSH exists only on a
   disk R3 assumes can die, and it silently breaks R2 — the Proxmox rebuild's whole
   premise is that the lab regenerates *from this repo*. Run commands on MAGI over SSH
   freely; just don't let it become the only place a config lives.

## The two machines

- **`cipher`** — this laptop. The workstation: where the repo lives, where edits happen,
  where Claude Code runs. Dual-boots Windows; `/` is ext4 and runs tight on space.
- **`magi`** — the HP 15s, Ubuntu Server, headless. A deployment target driven over SSH.
  Its RAM belongs to services, not to tooling.

The loop: `edit on cipher → commit → push → git pull on magi → docker compose up -d`.
GitOps by hand until H-10 automates it with Flux.

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

## Commit and push cadence

- **Commit whenever something works.** A container comes up healthy, a config finally
  does what it should, a script runs clean — that's a commit. Typically a few per
  session, not one at the end. Sessions die and machines reboot; a checkpoint you can
  return to beats a tidy history.
- **A broken checkpoint is fine to commit** — just say so in the message
  (`WIP: caddy not issuing certs yet`). Untracked work is the only real failure mode.
- **Push at the end of every session, minimum.** `/wrap` does it. This matters more
  here than in a normal project: R2 rebuilds the entire lab on Proxmox *from this repo*,
  and R3's whole premise is that the machine can die. A commit sitting unpushed on the
  laptop protects you from nothing.
- **Work on `main`.** Solo repo, no review, branches are ceremony. The exception is the
  Proxmox rebuild — branch that one, since it's the change that can leave you with
  neither the old lab nor the new one.
- **Never `git add -A` blind after touching configs.** Check `git status` first; new
  services write credentials into places you didn't expect.

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

Run **`/wrap`** at the end of a session and it drafts the entry, commits and pushes.
