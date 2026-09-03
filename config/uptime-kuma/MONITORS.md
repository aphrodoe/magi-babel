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
| Loki | HTTP(s) | `http://loki:3100/ready` | no public hostname by design |
| MAGI wall port | HTTP(s) | `https://1.1.1.1` (or any external) | catches the captive portal expiring |

Interval 60 s, retries 2. Anything tighter just fills Loki with probe noise.

## Not wired up yet

Kuma can publish to MQTT on state change, which is what H-05's SERVICE DOWN
LED state wants. Deferred: `config/mosquitto/TOPICS.md` has no topic for a
prober's opinion yet, and inventing one before the consumer exists is how
topic trees rot. Decide it in H-05, when there is something listening.
