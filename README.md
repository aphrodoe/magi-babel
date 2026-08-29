# MAGI & BABEL-2588

**MAGI** is a homelab — an always-on box on a shelf, judged by uptime.
**BABEL-2588** is a cyberdeck — a portable field computer, judged by self-sufficiency.

Opposite failure modes on purpose. One teaches how computers work *together*; the other,
how they work *with the physical world*. Everything here is built to a single rule:

> **A thing is only cool if it is legible.** Ten seconds, no explanation, a stranger can
> tell something is happening and roughly what.

An LED strip where amber means a container died passes. RGB cycling rainbow does not.
Six Grafana panels you actually read passes. Forty does not.

📖 **[`MASTERPLAN.md`](MASTERPLAN.md)** — the full plan: ground rules, all 23 phases, the
learning path paired to each one, hardware verdicts, and costs in ₹.
Rendered version with a plain-English toggle: [`magi-babel.html`](magi-babel.html).

---

## Progress

**Phase H-01 · the spine.** H-00 is done: MAGI runs Ubuntu Server 26.04.1, boots in 14 s,
reaches the network over campus wired with WPA2-Enterprise wifi behind it as a fallback,
and answers only on the tailnet — port 22 is closed on the LAN. **One H-00 item is
carried forward: the 2 × 8 GB DDR4-3200 upgrade, which blocks H-08 and nothing before it.**
Nothing containerised yet.

### MAGI — the homelab

| | Phase | | Cost |
|:--|:--|:--|--:|
| ✅ | **H-00** | Groundwork — install, network, hardening, `git init` · *RAM upgrade still to buy* | ₹0–4k |
| ⬜ | **H-01** | The Spine — Docker, Tailscale, Caddy, wildcard TLS | ₹800/yr |
| ⬜ | **H-02** | The Nervous System — Mosquitto, the MQTT topic tree | ₹0 |
| ⬜ | **H-03** | The Glass — Prometheus, Grafana, Loki, Uptime Kuma | ₹0 |
| ⬜ | **H-04** | The House — Jellyfin, Immich, Vaultwarden, Paperless | ₹0 |
| ⬜ | **H-05** | Ambient Telemetry — ESP32-S3, LED strip, wall panel | ₹1.5–2.5k |
| ⬜ | **H-06** | The Sky Log — RTL-SDR, ADS-B, weather satellites | ₹4.8–5.5k |
| ⬜ | **H-07** | The Range — Suricata, Juice Shop, the security lab | ₹0 |
| ⬜ | **H-08** | The Oracle — local LLM, RAG over the runbook | ₹0 |
| ⬜ | **H-09** | The Eye — cameras, Frigate detection | ₹0–2.5k |
| ⬜ | **H-10** | The Cluster — k3s, GitOps, the second machine | ₹20–35k |
| ⬜ | **H-11** | Final Form | — |

### BABEL-2588 — the cyberdeck

| | Phase | | Cost |
|:--|:--|:--|--:|
| ⬜ | **CD-00** | The Brain Bench — SBC selection and burn-in | ₹15–19k |
| ⬜ | **CD-01** | The Vault — Kiwix, the offline payload | ₹0 |
| ⬜ | **CD-02** | The Shell — enclosure, power, **ship v1** | ₹12–22k |
| ⬜ | **CD-03** | Physical UI — switches, panel meter, labels | ₹2.5–4.5k |
| ⬜ | **CD-04** | The Module Bay — the cartridge interface | ₹2–3.5k |
| ⬜ | **CD-05** | Cartridge: RF | — |
| ⬜ | **CD-06** | Cartridge: Mesh — Meshtastic, IN865 | ₹5–16k |
| ⬜ | **CD-07** | Cartridge: CAN | ₹1.5–3k |
| ⬜ | **CD-08** | Cartridge: Environment | ₹5.5–8k |
| ⬜ | **CD-09** | Cartridge: Crypto | — |
| ⬜ | **CD-10** | Field Doctrine | — |

<!-- /wrap updates the phase line and ticks these at phase boundaries. -->

## Running

| On | Service | For |
|:--|:--|:--|
| magi | **Tailscale** | The access fabric. `ssh magi` from anywhere, no port-forwarding. |
| magi | **OpenSSH** | Keys only. Password auth off. |
| magi | **ufw** | Default-deny inbound; SSH, `tailscale0`, 41641/udp allowed. |
| magi | **unattended-upgrades** | Automatic security patches. |

Containerised services land here as they come up.

---

## Layout

```
compose/      one directory per stack — compose.yaml + .env.example
config/       per-service config: caddy, prometheus, mosquitto, loki
dashboards/   exported Grafana JSON
ansible/      later, when sshing in by hand stops being charming
runbook/      one log per phase — what I did, what broke, what I'd do differently
secrets/      gitignored; real values here, .env.example in the repo
```

**Config files over GUI settings, everywhere.** A setting that lives only in a web UI's
database is a setting that gets lost in the rebuild — and there *is* a rebuild: the whole
lab moves from Ubuntu + Docker to Proxmox around month six, from this repo, deliberately.

**Naming.** Hosts, MQTT topics, Grafana titles and panel labels all use the callsigns.
MQTT roots are `magi/…` and `babel-2588/…`. One scheme everywhere — the consistency *is*
the aesthetic.

**Working history** is in [`runbook/`](runbook/); conventions and current state in
[`CLAUDE.md`](CLAUDE.md).

---

> Build the infrastructure that runs without you, and the instrument that works without
> anything. Make both of them tell you what they're doing. Write down what you learn.
> Then take the instrument somewhere with no signal and find out if you were right.
