#!/usr/bin/env bash
# Which DNS transports does this network actually permit?
#
# Answers a question no config file can: the campus filters encrypted DNS by
# *provider*, not by protocol, and the policy is someone else's. Run this when
# AdGuard stops resolving, then put whatever passes into
# config/adguard/AdGuardHome.yaml and re-run 75-adguard.sh.
#
# Changes nothing. diag-*, so it sorts after the numbered setup scripts.
set -uo pipefail

ok()   { printf '  \033[32m%-6s\033[0m %s\n' PASS "$1"; }
bad()  { printf '  \033[31m%-6s\033[0m %s\n' FAIL "$1"; }

echo "== plain UDP/53 =="
for r in 9.9.9.9 8.8.8.8; do
  dig +short +time=3 +tries=1 "@$r" example.com >/dev/null 2>&1 \
    && ok "udp  $r" || bad "udp  $r"
done

echo "== DoT (853) =="
# +tls, not a port check: TCP/853 to a blocked provider is ACCEPTED by a
# middlebox and then hangs, so `nc -z` reports it open. Resolve or fail.
for h in dns.google dns.quad9.net one.one.one.one; do
  timeout 8 dig +tls +short +time=5 +tries=1 "@$h" example.com >/dev/null 2>&1 \
    && ok "dot  $h" || bad "dot  $h"
done

echo "== DoH (443) =="
for h in dns.adguard-dns.com dns.google cloudflare-dns.com dns.quad9.net; do
  timeout 10 curl -s --max-time 8 -H 'accept: application/dns-json' \
    "https://$h/resolve?name=example.com&type=A" 2>/dev/null | grep -q '"Answer"' \
    && ok "doh  $h" || bad "doh  $h"
done

echo "== what DHCP handed us =="
resolvectl status 2>/dev/null | grep -m2 'DNS Servers' | sed 's/^/  /'

echo "== is a block DNS-level or deeper? =="
# If a name resolves identically through campus and an external resolver but
# the site still will not load, the filtering is at IP or SNI and no resolver
# change will help. Only a tunnel will.
for d in reddit.com; do
  c=$(dig +short +time=3 +tries=1 "$d" | head -1)
  e=$(dig +short +time=3 +tries=1 @9.9.9.9 "$d" | head -1)
  printf '  %-14s campus=%-16s external=%-16s ' "$d" "${c:-none}" "${e:-none}"
  code=$(timeout 10 curl -sI --max-time 8 "https://$d" -o /dev/null -w '%{http_code}' 2>/dev/null)
  [ "$code" = 000 ] && echo "reachable=NO  -> IP/SNI block, a resolver cannot fix it" \
                    || echo "reachable=$code"
done
