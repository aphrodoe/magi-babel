# Caddy's official image ships no DNS provider modules — they're compiled in,
# not loaded at runtime. So we build one containing exactly the module we need.
FROM caddy:2-builder AS builder
RUN xcaddy build --with github.com/caddy-dns/desec

FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
