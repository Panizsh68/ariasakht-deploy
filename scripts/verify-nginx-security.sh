#!/usr/bin/env bash
set -euo pipefail

config=${1:-nginx/nginx.conf}
test -f "$config"

for directive in \
  'Content-Security-Policy' \
  'X-Content-Type-Options "nosniff" always' \
  'Referrer-Policy' \
  'Permissions-Policy' \
  'X-Frame-Options "SAMEORIGIN" always'; do
  grep -F "$directive" "$config" >/dev/null || { echo "missing nginx security directive: $directive" >&2; exit 1; }
done

grep -F "Strict-Transport-Security" "$config" >/dev/null
grep -F "listen 443 ssl" "$config" >/dev/null
awk '
  /listen 443 ssl/ { tls=1 }
  /Strict-Transport-Security/ && !tls { exit 1 }
' "$config"
grep -F "location ^~ /docs/ { return 404; }" "$config" >/dev/null
! grep -F "proxy_pass http://backend:3000/docs" "$config" >/dev/null
! grep -F "unsafe-eval" "$config" >/dev/null
! grep -F "unsafe-inline" "$config" >/dev/null

echo "Nginx security policy checks passed"
