# MQTT topic tree

The schema for the whole lab. Not an inventory — topics come and go with what's
deployed. What is fixed is *where a new publisher goes*, so adding one is never a
naming decision.

Settled 2026-09-02, H-02.

---

## The tree

```
magi/
  status                    online | offline          retained, LWT
  sys/{cpu,mem,temp,load,uptime,disk,batt,power}
  svc/<service>/state       up | down | degraded
  backup/{state,pct}
  sky/
    adsb/{count,nearest,farthest}
    pass/{next,active}
    image                   newest decoded pass, path only
  rf/<protocol>/<device>    rtl_433, acars, ais
  range/alert               IDS severity + signature
  oracle/{status,state,tok_per_s,digest}
  eye/...                   Frigate's shape under our prefix
  light/
    status                  is the strip alive
    state                   what it is showing now
    set                     the write topic

babel-2588/
  status                    online | offline          the Handshake fires on this
  sys/{cpu,mem,batt,temp}
  pos
  <cartridge>/...           mesh, rf, can, env

mesh/<node>/{status,msg,rssi,snr,dist}

homeassistant/...           HA autodiscovery owns this namespace
```

## Rules

**MAGI is a laptop, and the tree says so.** `sys/batt` and `sys/power` (`ac` |
`battery`) exist because a power cut longer than the battery needs a human, and nothing
else on the bus can say the clock is running.

**Roots are callsigns.** `magi/`, `babel-2588/`, and every H-10 cluster node when it
gets one. Two exceptions, both deliberate: `mesh/` is a fabric rather than a host, and
`homeassistant/` is a foreign namespace we don't control.

**Every publisher has a `status` topic** — retained, and registered as its LWT (Last
Will and Testament: the message the broker publishes on your behalf if you drop without
disconnecting cleanly). This is what separates *the sensor reads zero* from *the sensor
died three days ago*. Nothing else on the bus can tell you that.

**`state` is current value, retained. Events are not retained.** A subscriber that
connects at 3 a.m. should immediately know the world as it is, and should not be told
about a Suricata alert from three weeks ago. Retaining an event is how the LED strip
ends up strobing red at nothing after every reconnect.

**`set` is the only writable suffix.** Everything else is read-only by convention and,
once the ACL exists, by enforcement. The ESP32 may publish `magi/light/state` and
subscribe broadly; it may not write anything under `magi/svc/`.

**QoS 0 for telemetry, 1 for events and commands.** A dropped CPU reading is corrected
by the next tick. A dropped alert is gone.

## Payload format

**Bare scalars on leaves. JSON only where the value is genuinely composite** —
`pos`, `range/alert`, `eye/…`.

```
magi/sys/cpu        42.1
magi/svc/caddy/state  up
babel-2588/pos      {"lat":26.47,"lon":73.11,"alt":232}
```

Chosen for the most constrained subscriber on the bus: the H-05 ESP32 parses a scalar
with one `atof()`. The cost is paid at the other end — Home Assistant and Node-RED
prefer JSON and need one entity declared per scalar topic. That is config, and config is
the cheap side to change; firmware is not.

## Namespaces we don't own

Three services publish their own structure and let you set only the prefix. Design
around this rather than against it.

| Service | Knob | Phase |
|---|---|---|
| Frigate | `mqtt.topic_prefix` → `magi/eye` | H-09 |
| Meshtastic | `mqtt.root` → `mesh` (default is `msh/`) | CD-06 |
| Home Assistant | discovery prefix, `homeassistant/` | A-01 |

Re-check each at its phase — this layer moves.

## Consequences

- **H-11 panel labels are these strings.** The engraved labels, the Grafana titles and
  the topic names are one scheme; that is the point of the callsigns.
- **The ACL file is written against this shape**, so restructuring later means
  rewriting permissions, not just renaming topics.
- **Prometheus does not speak MQTT.** Graphing any of this in H-03 needs a bridge
  (`mqtt2prometheus`) pointed at the branches worth keeping as time series.
