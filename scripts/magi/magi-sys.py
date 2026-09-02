#!/usr/bin/env python3
"""Publish MAGI's own vitals onto the bus. See config/mosquitto/TOPICS.md.

One long-lived connection, deliberately: a Last Will and Testament only fires
when the broker notices *this* connection drop. A cron job that connects,
publishes and disconnects every 15 s can never have a meaningful will — the
broker would see a clean disconnect every time and `magi/status` would say
"online" forever, including for the week after the machine died.

Everything published here is state, so everything is retained: a subscriber
that connects at 03:00 learns the whole picture immediately instead of waiting
out an interval.

    magi-sys.py            run forever, publishing
    magi-sys.py --once     print one sample and exit, publishing nothing
"""

import glob
import os
import shutil
import sys
import time

INTERVAL = 15
BROKER = os.environ.get("MQTT_HOST", "100.94.219.53")
BAT = "/sys/class/power_supply/BAT0"


def _read(path):
    with open(path) as f:
        return f.read()


def cpu_sample():
    v = [int(x) for x in _read("/proc/stat").split("\n", 1)[0].split()[1:]]
    return sum(v), v[3] + v[4]          # total, idle+iowait


def mem_pct():
    m = {}
    for line in _read("/proc/meminfo").splitlines():
        k, _, v = line.partition(":")
        m[k] = int(v.split()[0])
    return 100.0 * (1 - m["MemAvailable"] / m["MemTotal"])


def temp_c():
    # Zone numbering is not stable across boots — match on type, not index.
    for z in glob.glob("/sys/class/thermal/thermal_zone*"):
        try:
            if _read(z + "/type").strip() == "x86_pkg_temp":
                return int(_read(z + "/temp")) / 1000.0
        except OSError:
            pass
    return None


def battery():
    """(percent, 'ac'|'battery'). None on a machine without one."""
    try:
        pct = int(_read(BAT + "/capacity"))
        state = "battery" if _read(BAT + "/status").strip() == "Discharging" else "ac"
        return pct, state
    except OSError:
        return None, None


def sample(prev):
    total, idle = cpu_sample()
    pt, pi = prev
    dt, di = total - pt, idle - pi
    cpu = 100.0 * (1 - di / dt) if dt > 0 else 0.0

    du = shutil.disk_usage("/")
    pct, power = battery()

    return (total, idle), {
        "magi/sys/cpu": round(cpu, 1),
        "magi/sys/mem": round(mem_pct(), 1),
        "magi/sys/temp": temp_c(),
        "magi/sys/load": round(os.getloadavg()[0], 2),
        "magi/sys/uptime": int(float(_read("/proc/uptime").split()[0])),
        "magi/sys/disk": round(100.0 * du.used / du.total, 1),
        "magi/sys/batt": pct,
        "magi/sys/power": power,
    }


def main():
    prev = cpu_sample()

    if "--once" in sys.argv:
        time.sleep(1)                    # a CPU delta needs two samples
        _, values = sample(prev)
        for topic, value in values.items():
            print(f"{topic} {value}")
        return

    import paho.mqtt.client as mqtt

    user, password = os.environ["MQTT_USER"], os.environ["MQTT_PASS"]

    def on_connect(client, _u, _f, _rc, _p=None):
        # Fires on every (re)connect, so "online" is republished after an
        # outage without which the will would leave us marked offline forever.
        client.publish("magi/status", "online", qos=1, retain=True)

    c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="magi-sys")
    c.username_pw_set(user, password)
    c.will_set("magi/status", "offline", qos=1, retain=True)
    c.on_connect = on_connect
    c.connect(BROKER, 1883, keepalive=INTERVAL * 2)
    c.loop_start()

    while True:
        time.sleep(INTERVAL)
        prev, values = sample(prev)
        for topic, value in values.items():
            if value is not None:
                c.publish(topic, value, qos=0, retain=True)


if __name__ == "__main__":
    main()
