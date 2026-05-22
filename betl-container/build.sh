#!/usr/bin/env bash
# betl-container/build.sh — build the betl container image.
#
# Overrides:
#   BETL_IMAGE        image tag to apply (default: betl:dev)
#   BETL_RUNTIME      podman | docker (default: auto-detect)
#   BETL_NATIVE_REF   git ref of betl-native to clone (default: master)
#
# Forwards extra args to the runtime, e.g.:
#   ./build.sh --no-cache
#   ./build.sh --build-arg BETL_NATIVE_REF=v0.2.1

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

build_args=()
if [[ -n "${BETL_NATIVE_REF:-}" ]]; then
    build_args+=(--build-arg "BETL_NATIVE_REF=$BETL_NATIVE_REF")
fi

echo "[build] $runtime build -t $image -f Containerfile $repo" >&2
exec "$runtime" build -t "$image" -f "$repo/Containerfile" \
     "${build_args[@]}" "$@" "$repo"
