#!/usr/bin/env bash
# betl-container/build.sh — build the betl container image.
#
# Overrides:
#   BETL_IMAGE        image tag to apply (default: betl:dev)
#   BETL_RUNTIME      podman | docker (default: auto-detect)
#   BETL_NATIVE_REF   git ref (branch / tag / SHA) of betl-native to clone.
#                     Default: resolve betl-native master HEAD to a SHA via
#                     `git ls-remote`, so docker's build cache auto-busts
#                     whenever upstream master moves.
#
# Forwards extra args to the runtime, e.g.:
#   ./build.sh --no-cache
#   ./build.sh --build-arg HTTP_PROXY=...

set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"

image=${BETL_IMAGE:-betl:dev}

runtime=${BETL_RUNTIME:-}
if [[ -z "$runtime" ]]; then
    if   command -v podman >/dev/null 2>&1; then runtime=podman
    elif command -v docker >/dev/null 2>&1; then runtime=docker
    else
        echo "build.sh: no container runtime (podman/docker) found" >&2
        exit 127
    fi
fi

# Resolve to a concrete SHA when no explicit ref is given so docker's
# build cache busts whenever upstream master moves. Falls back to the
# literal "master" if git isn't installed or the remote is unreachable
# (in which case the user can pass --no-cache to force a fresh clone).
if [[ -z "${BETL_NATIVE_REF:-}" ]]; then
    if command -v git >/dev/null 2>&1; then
        resolved=$(git ls-remote \
            https://github.com/jasonuithol/betl-native.git master \
            2>/dev/null | awk '{print $1}' | head -n1 || true)
        BETL_NATIVE_REF=${resolved:-master}
    else
        BETL_NATIVE_REF=master
    fi
fi

echo "[build] $runtime build -t $image -f Containerfile (BETL_NATIVE_REF=$BETL_NATIVE_REF)" >&2
exec "$runtime" build -t "$image" -f "$repo/Containerfile" \
     --build-arg "BETL_NATIVE_REF=$BETL_NATIVE_REF" \
     "$@" "$repo"
