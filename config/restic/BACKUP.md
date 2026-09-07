# Backups (R3)

What gets backed up, what deliberately does not, and how to get it back.
Written 2026-09-07, H-04. The job is `scripts/magi/magi-backup.sh`, installed
by `scripts/magi/70-backup.sh`, run nightly at 02:00 by `magi-backup.timer`.

## The password

`/etc/magi/backup.env` holds `RESTIC_PASSWORD`. **There is no recovery path** —
restic cannot decrypt a repository without it, by design. It is the sixth file
R2 cannot regenerate, and unlike the other five, losing it destroys data that
already exists rather than costing an afternoon of re-setup.

Keep a copy outside this machine. On paper until Vaultwarden exists; in
Vaultwarden after — noting the obvious circularity, so keep the paper too.

## What is in a snapshot

| Path | Why |
|---|---|
| `/etc/magi` | `mqtt.env`, `netaccess.env`, `backup.env` — R2 cannot regenerate these |
| `/etc/netplan` | the wifi credentials, likewise |
| `<repo>/secrets` | `caddy.env` (deSEC token), `authelia.env`, `authelia/users.yml`, mosquitto `passwd` |
| `/var/lib/docker/volumes` | every service's state |
| `/var/lib/magi-backup` | SQLite dumps, staged fresh each run then deleted |

**Not the repo itself.** It is in git, pushed to a remote; that is already two
copies on two machines. Backing it up would be backing up a backup.

## What is excluded, and why

`observability_prometheus_data`, `observability_loki_data`,
`observability_alloy_data`.

These are regenerable telemetry — losing them costs *history*, not function,
and Loki is the one store here that grows without bound. Metrics run ~50 MB/day
at 30-day retention; logs do not compress at a predictable rate per stream.
Backing them up would make the nightly job largely a copy of data that exists
to be thrown away on a schedule anyway.

Change this the day the metrics are the thing you would miss.

## Databases are dumped, not copied

A live SQLite file copied byte-for-byte can land mid-write and restore corrupt.
The job runs `sqlite3 … ".backup"`, which uses SQLite's own backup API and is
safe against a running writer, WAL included. It globs for `*.db` / `*.sqlite3`
inside the included volumes, so a service added later is picked up without
editing the script.

**Immich and Paperless bring Postgres.** That needs a `docker exec … pg_dump`
added to step 1 of the job, before the restic call — not beside it. A Postgres
data directory copied live is not a backup.

## Retention

`--keep-daily 7 --keep-weekly 4 --keep-monthly 6`.

`forget` runs nightly and is metadata-only. `--prune` runs **Sundays only**: it
rewrites pack files, which is a lot of small random I/O, and the 2 TB portable
target is SMR — the one workload that class of drive is genuinely bad at.

## Restoring

```bash
sudo -i
set -a; . /etc/magi/backup.env; set +a

restic snapshots --tag magi                      # what exists
restic ls latest                                 # what is in the newest one
restic restore latest --target /tmp/restore      # everything, somewhere safe
restic restore latest --target /tmp/restore \
  --include /etc/magi/mqtt.env                   # or just one file
```

Restore to `/tmp/restore` and copy into place deliberately. `--target /` works
and is how you overwrite a running system by accident.

## The part that is not done yet

**This is one copy, not 3-2-1.** R3 asks for three copies, two kinds of
storage, one offsite. As of writing there is the live NVMe and — once the HDD
arrives — one local snapshot. The offsite bucket (~₹100/month, MASTERPLAN §09)
is still unbought, and until it exists a fire or a theft takes both copies.

**Test the restore before trusting any of this.** R3: *"an untested backup is a
rumour."* The proof named in the plan is restoring Vaultwarden into a fresh
container and logging in. Put a recurring event in a real calendar.
