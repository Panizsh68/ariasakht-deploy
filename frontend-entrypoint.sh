#!/bin/sh
set -eu

# Some versions of Nitro leave legacy entities v4 deep imports in the server
# bundle while tracing entities v6 into the production image. entities v6 only
# exports these modules through its public subpaths, so Node rejects /lib/*.js.
bundle_dir=/app/.output/server

if [ ! -d "$bundle_dir" ]; then
  echo "Frontend server bundle not found at $bundle_dir" >&2
  exit 1
fi

find "$bundle_dir" -type f -name '*.mjs' -exec \
  sed -i \
    -e 's#entities/lib/decode\.js#entities/decode#g' \
    -e 's#entities/lib/escape\.js#entities/escape#g' {} +

if find "$bundle_dir" -type f -name '*.mjs' -exec \
  grep -l 'entities/lib/\(decode\|escape\)\.js' {} + | grep -q .; then
  echo 'Unsupported entities deep imports remain in the frontend bundle' >&2
  exit 1
fi

exec node /app/.output/server/index.mjs
