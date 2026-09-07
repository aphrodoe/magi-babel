# Uptime Kuma monitors

Uptime Kuma has no file-based provisioning — every monitor lives in the SQLite
database inside its volume, which is a GUI setting and therefore breaks R1.
This file is the compromise: the volume is what restores in practice (R3), and
this is what lets you rebuild by hand if it doesn't.

**Probe the public hostname, not the container.** `https://grafana.lab.…`
exercises DNS, the wildcard cert, Caddy's routing and the service itself. The
container name checks only the last of those, and the first three are what
actually break — a cert that failed to renew, a Caddyfile line that never got
reloaded, a DNS delegation that lapsed.

| Monitor | Type | Target | Notes |
|---|---|---|---|
| Grafana | HTTP(s) | `https://grafana.lab.akhildhyani.me` | redirects to `/login`; accept 200 |
| Prometheus | HTTP(s) | `https://prom.lab.akhildhyani.me/-/healthy` | its own liveness endpoint |
| Mosquitto | TCP Port | `mosquitto` : `1883` | container name — reached over `bus` |
| Loki | HTTP(s) | `http://loki:3100/ready` | no public hostname by design; reached over `glass` |
| Authelia | HTTP(s) | `https://auth.lab.akhildhyani.me/api/health` | returns 200; the front door for everything with no auth of its own |
| AdGuard | **DNS** | resolve `example.com` via `100.94.219.53` | **Not an HTTP check.** See below |
| AdGuard blocking | **DNS** | resolve `doubleclick.net` via `100.94.219.53` | Condition: record **equals `0.0.0.0`**. Without the condition it passes on a real answer, which is the state you want to catch |
| Radicale | HTTP(s) | `https://dav.lab.akhildhyani.me/` | redirects to `/.web`; accept 200 |
| Wall port | HTTP(s) | `https://connectivity-check.ubuntu.com` | catches the captive portal expiring. **Not 1.1.1.1** — on campus wifi that address is the DHCP server, not Cloudflare (CLAUDE.md) |

**AdGuard gets a DNS monitor, not an HTTP one, and this is not a preference.**
On 2026-09-07 its web UI served 200 for half an hour while every single query
timed out — the upstream was blocked and the resolver was useless. An HTTP check
would have stayed green through all of it. Kuma's DNS monitor type resolves a
name through the server, which is the only check that tests the thing the
service exists to do.

The same failure also left AdGuard with **no blocklist at all**: it could not
resolve the URL its filter list downloads from. A broken resolver is
self-compounding, and nothing about the UI says so.

**Two monitors, because resolving and blocking fail separately.** The
`example.com` row catches a dead upstream. It cannot catch a missing blocklist —
that name resolves perfectly either way. The `doubleclick.net` row catches the
second failure, but only because of the condition on `0.0.0.0`; a DNS monitor
with no condition passes on *any* answer, including the real ad-server address.

Leave **Domain Name Expiry Notification off** on both. On a DNS monitor it
watches the registration expiry of the name being queried — `example.com`
belongs to IANA, and `doubleclick.net` to Google. Neither is yours to renew.

Interval 60 s, retries 2. Anything tighter just fills Loki with probe noise.

## Not wired up yet

Kuma can publish to MQTT on state change, which is what H-05's SERVICE DOWN
LED state wants. Deferred: `config/mosquitto/TOPICS.md` has no topic for a
prober's opinion yet, and inventing one before the consumer exists is how
topic trees rot. Decide it in H-05, when there is something listening.

## Waiting on hardware

**restic** has no monitor because it has never run — `/mnt/backup` is not
mounted until the 2 TB HDD arrives. When it does, the right shape is a Kuma
**Push** monitor: `magi-backup.sh` curls the push URL on success, and Kuma goes
red if a night passes without one. A backup that fails silently is the failure
mode R3 exists to prevent, and "no news" must not read as good news.
