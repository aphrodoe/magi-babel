# Reading the dashboards

What the Grafana dashboards in this directory mean, and which question each one
answers. Written 2026-09-07, during H-03, from MAGI's own readings — the baseline
numbers below are a **snapshot, not a spec**. Their value is comparison: a reading
is only meaningful against what this box normally does.

Two dashboards, provisioned from `config/grafana/provisioning/dashboards/`:

| File | Title | uid | Source |
|---|---|---|---|
| `node-exporter-full.json` | Node Exporter Full | `magi-node` | grafana.com 1860 |
| `cadvisor.json` | Cadvisor exporter | `magi-cadvisor` | grafana.com 14282 |

## The three questions

1. **Is it healthy right now?** — the gauges. Glanceable, no thinking.
2. **What changed, and when?** — the time series. The one that earns its keep; a
   number is meaningless without its own history.
3. **When do I need to buy something?** — trends over weeks. The question with
   money riding on it (§01 RAM, R3's backup HDD).

Most observability gets built for #1 and only ever pays off on #2 and #3.

## Baseline — MAGI idle, full stack up, 2026-09-07

| Reading | Value | Notes |
|---|---|---|
| CPU busy (5m) | 2.15% | across 12 threads (i5-1235U, 10c/12t) |
| Load 1 / 5 / 15 | 0.46 / 0.19 / 0.19 | ~3.8% of capacity |
| CPU pressure (PSI) | 0.25% | nothing meaningfully stalls |
| RAM total | 6.93 GiB | **not 8** — see trap 1 |
| RAM available | 5.28 GiB | the honest number |
| Cache + buffers | 4.85 GiB | looks used, is free on demand |
| Swap used | 0 of 4 GiB | anything sustained here is a problem |
| Root FS | 424 GiB free of 465 (8.9% used) | |
| Disk utilisation | 0.2% | `rate(node_disk_io_time_seconds_total[5m])` |
| All containers, CPU | ~0.145 cores (1.2%) | |
| All containers, RAM | ~800 MiB | |
| Prometheus | 6,245 series, 383 samples/s | ~50 MB/day, ~1.5 GB at 30d retention |

## Node Exporter Full

16 rows, 14 collapsed by default. That's deliberate: the two open rows are the
daily driver, the rest is for when something is already wrong. No obligation to
expand them.

### Load average is not a percentage

`0.46` means *0.46 processes were runnable on average over the last minute*.
**Divide by thread count** — 12 here. Load 12 is "fully committed", load 24 is
"everything waiting its turn".

Linux-specific: unlike other Unixes, Linux load counts processes in
**uninterruptible sleep** (`D` state, usually blocked on disk), not just ones
wanting CPU. **A load spike can mean the disk is struggling, not the CPU.** High
load with low CPU Busy → look at disk.

### Pressure is the panel to trust

`Pressure` is **PSI (Pressure Stall Information)**, kernel ≥4.20. Plain English:
*what fraction of the time was some task stalled waiting for this resource?*

Better than load average because it measures **harm** rather than a proxy for it.
Load 12 on 12 threads with everything finishing on time is fine; load 3 with
constant stalling is not. If you learn one panel, make it this one.

Thresholds worth carrying: CPU busy sustained >70%, real RAM >85%, root FS >80%,
PSI >10%, **any** sustained swap.

## Four traps

Each of these has cost someone an evening. They are all cases where the obvious
reading of a panel is wrong.

### 1. 6.93 GiB of RAM, not 8

2 × 4 GB installed; ~1.07 GiB is reserved by the **Iris Xe iGPU** as shared video
memory, carved out by firmware before Linux sees it. Nothing is broken. But the
box is tighter than the spec sheet implies, and that is real input to §01.

### 2. "RAM Used" counts cache as used

Linux deliberately fills spare RAM with disk cache and evicts it instantly when a
process wants memory. Idle RAM is wasted RAM. Here, 4.85 GiB of 6.93 is cache —
a naive "used" reading shows ~76% and looks alarming; the real figure is ~24%.

**`MemAvailable` is the kernel's own estimate of what is genuinely obtainable
without swapping. It is the only memory number worth alerting on.** The Memory
Basic timeseries breaks this into bands; read the cache band as spare.

### 3. The dashboard says Tailscale is down while you are using it

```
tailscale0   carrier=1   operstate=unknown   ->  node_network_up = 0
```

`node_network_up` derives from `operstate`. TUN devices are userspace constructs
with no physical link, so the kernel reports `unknown` and node_exporter maps
anything not `up` to `0` — while that interface carries every SSH session to this
box. (`docker0` also reads down; that one is honest, nothing is attached to it.)

Same class of bug as the H-01 carryover about route metrics trusting link state
over reachability. **Link state is a claim about a cable. Reachability is a claim
about whether packets arrive.** Every layer of this stack offers the cheap one by
default.

### 4. `br-glass` shows zero traffic, and that is correct

Loki, Grafana and Prometheus talk over `glass` constantly, yet the bridge reads
0 B/s both directions. **A Linux bridge's interface counters only count frames
entering or leaving the host through the bridge, not frames forwarded port-to-port
between containers.** Container-to-container traffic is invisible there.

The `veth` pairs do carry it, but they are named `veth9ad30b1` and are renamed on
every recreate. Which is the gap cAdvisor exists to fill.

## cAdvisor

Four panels, answering *"which of the nine containers is responsible?"*

Two things in the baseline are worth knowing:

- **cAdvisor is the most expensive container on the box** (0.061 cores — more than
  anything it observes). It walks every cgroup on a timer. Observability is not
  free: ~1.2% CPU and ~800 MiB buys the ability to see anything at all. A fine
  trade at this scale, but a trade.
- **Mosquitto uses 4 MiB.** The broker carrying the whole `magi/sys/*` bus costs
  less than a browser tab.

Memory here is **working set**, not RSS — roughly "memory that would not be
reclaimable under pressure". It is the number that predicts an OOM kill, which is
why cgroups use it.

## What this says about the open purchases

- **RAM (§01).** 1.65 GiB in use of 6.93 with the entire stack running. Nothing
  currently justifies 2 × 8 GB. **H-08's local model is the trigger** — now
  provable from the baseline rather than assumed.
- **R3's backup HDD.** Metrics will never be the disk problem (~1.5 GB steady
  state against 424 GiB free). **Loki will be.** Log volume scales with how chatty
  services are, not with how many run, and it does not compress at a fixed rate
  per series the way numeric samples do. That is the line to watch when sizing.

## Actually using them

- **Daily:** don't. That is what Uptime Kuma is for. Dashboards are for questions,
  not vigils.
- **After deploying anything:** cAdvisor memory, before and after. Catches a leak
  in week one instead of month three.
- **When something feels slow:** Pressure first; then load vs CPU Busy to decide
  CPU or disk; then cAdvisor to find the container.
- **Monthly:** disk trend. The only metric here that fails slowly enough to be
  preventable.

## For the wall panel

Best guess at the six numbers: **CPU busy · MemAvailable · root FS free · load1 ·
uptime · Kuma monitors up**. Deliberately not committed to — the cheap 2.4" TFT
exists to test that guess before anything is spent on e-paper.
