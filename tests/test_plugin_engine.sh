#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT

output=$(HOME="$TEST_HOME" PATH="/usr/bin:/bin" bash "$ROOT_DIR/autoheal-plugin-engine.sh" get)
jq -e '
  .status == "UNAVAILABLE" and
  .reflex_latency_ms == null and
  .memory_rules == 0 and
  (.recent_heals | length == 0)
' >/dev/null <<<"$output"

echo "AutoHeal plugin telemetry smoke test passed"
