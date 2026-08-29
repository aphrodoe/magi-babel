# MAGI & BABEL-2588

Two laboratories with opposite failure modes, and the tension between them is the point.

**MAGI** is the homelab — an always-on box on a shelf, judged by **uptime**. Its virtue
is that it is boring, documented, and still running in March. It teaches how computers
work *together*.

**BABEL-2588** is the cyberdeck — a portable, self-contained field computer, judged by
**self-sufficiency**. Its virtue is that you can open it on a hill with no signal and it
is still the most interesting object in the bag. It teaches how computers work *with the
physical world*.

> **A thing is only cool if it is legible.**
> Ten seconds, no explanation, a stranger can tell something is happening and roughly
> what. An LED strip where amber means a container died is cool. RGB cycling rainbow is
> not. Six Grafana panels you actually read is cool. Forty panels is not.

## Start here

**[`MASTERPLAN.md`](MASTERPLAN.md)** — the whole thing. Thesis, six ground rules, every
build phase (H-00…H-11 for MAGI, CD-00…CD-10 for BABEL-2588), the learning path paired to
each phase, hardware dossier with verdicts, expansions, timeline, and costs in ₹.

[`magi-babel.html`](magi-babel.html) is the same document as a rendered page, with a
plain-English toggle for the dense sections.

**Current phase** lives in [`CLAUDE.md`](CLAUDE.md), and the working history is in
[`runbook/`](runbook/) — one log per phase, three lines per session: what I did, what
broke, what I'd do differently.

## Layout

```
compose/      one directory per stack — compose.yaml + .env.example
config/       per-service config: caddy, prometheus, mosquitto, loki
dashboards/   exported Grafana JSON
ansible/      later, when sshing in by hand stops being charming
runbook/      how to restore, how to rotate, what broke and why
secrets/      gitignored — real values here, .env.example in the repo
```

Config files over GUI settings, everywhere. A setting that lives only in a web UI's
database is a setting that gets lost in the rebuild — and there *is* a rebuild: the whole
lab moves from Ubuntu + Docker to Proxmox around month six, from this repo, on purpose.

## Naming

Hosts, MQTT topics, Grafana titles and panel labels all use the callsigns. MQTT roots are
`magi/…` and `babel-2588/…`. One scheme everywhere — the consistency *is* the aesthetic.

---

> Build the infrastructure that runs without you, and the instrument that works without
> anything. Make both of them tell you what they're doing. Write down what you learn.
> Then take the instrument somewhere with no signal and find out if you were right.
