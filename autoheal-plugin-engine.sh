#!/usr/bin/env bash
set -euo pipefail

# AutoHeal Plugin Telemetry Engine

find_autoheal() {
  local candidate
  candidate=$(command -v autoheal 2>/dev/null || true)
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
  elif [[ -x "$HOME/.local/bin/autoheal" ]]; then
    printf '%s\n' "$HOME/.local/bin/autoheal"
  elif [[ -x "$HOME/Work/autoheal/autoheal" ]]; then
    printf '%s\n' "$HOME/Work/autoheal/autoheal"
  fi
  return 0
}

get_status() {
  local memory_count=0
  local memory_file="$HOME/.local/share/autoheal/memory.json"
  local recent_heals='[]'
  if [[ -f "$memory_file" && ! -L "$memory_file" ]]; then
    memory_count=$(jq 'if type == "object" then keys | length else 0 end' "$memory_file" 2>/dev/null || echo 0)
    recent_heals=$(jq -c '
      if type == "object" then
        [to_entries[] | {error: .key, fix: (.value | tostring), time: "learned"}] | .[:5]
      else [] end
    ' "$memory_file" 2>/dev/null || echo '[]')
  fi

  local python_v uv_v node_v docker_v git_v status
  python_v=$(python3 --version 2>/dev/null || echo "Not Found")
  uv_v=$(uv --version 2>/dev/null | awk '{print $2}' || echo "Not Found")
  node_v=$(node --version 2>/dev/null || echo "Not Found")
  docker_v=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "Offline")
  git_v=$(git --version 2>/dev/null | awk '{print $3}' || echo "Not Found")
  if [[ -n "$(find_autoheal)" ]]; then
    status="READY"
  else
    status="UNAVAILABLE"
  fi

  jq -n \
    --arg status "$status" \
    --argjson memory_rules "$memory_count" \
    --arg python "$python_v" \
    --arg uv "$uv_v" \
    --arg node "$node_v" \
    --arg docker "$docker_v" \
    --arg git "$git_v" \
    --argjson recent_heals "$recent_heals" \
    '{
      status: $status,
      reflex_latency_ms: null,
      memory_rules: $memory_rules,
      toolchains: {python: $python, uv: $uv, node: $node, docker: $docker, git: $git},
      recent_heals: $recent_heals
    }'
}

cmd="${1:-get}"
case "$cmd" in
  get|status)
    get_status
    ;;
  test)
    bin=$(find_autoheal)
    test_status="UNAVAILABLE"
    if [[ -n "$bin" ]]; then
      if timeout 15 "$bin" test >/dev/null 2>&1; then
        test_status="PASSED"
      else
        test_status="FAILED"
      fi
    fi
    if [[ "$test_status" == "PASSED" ]]; then
      omarchy-notification-send -g ⚡ "AutoHeal" "Reflex engine self-test passed." >/dev/null 2>&1 || true
    else
      omarchy-notification-send -g ⚠ "AutoHeal" "Reflex engine self-test: $test_status." >/dev/null 2>&1 || true
    fi
    printf '{"result":"%s"}\n' "$test_status"
    ;;
  *)
    get_status
    ;;
esac
