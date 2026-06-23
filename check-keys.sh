#!/usr/bin/env bash
# Show which expected API keys are visible (from .env and/or the environment),
# masked. Run this before ./serve.sh to confirm your keys are wired up.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pull in .env if present, without clobbering keys already in the environment.
if [ -f "${HERE}/.env" ]; then
  set -a; # shellcheck disable=SC1091
  source "${HERE}/.env"; set +a
  echo "Source: .env + environment"
else
  echo "Source: environment only (no .env file)"
fi
echo

mask() {  # print first 4 + last 4 chars, hide the middle
  local v="$1"
  if [ -z "${v}" ]; then echo "—"; return; fi
  local n=${#v}
  if [ "${n}" -le 8 ]; then echo "set (${n} chars)"; else
    echo "${v:0:4}…${v: -4}  (${n} chars)"
  fi
}

check() {  # check VAR_NAME "what it's for"
  local name="$1" desc="$2" val="${!1:-}"
  if [ -n "${val}" ]; then
    printf "  ✓ %-22s %s\n" "${name}" "$(mask "${val}")"
  else
    printf "  ✗ %-22s MISSING — %s\n" "${name}" "${desc}"
  fi
}

echo "Provider keys:"
check ANTHROPIC_API_KEY  "Claude Opus 4.8"
check GEMINI_API_KEY     "Gemini 3.1 Pro"
check DEEPSEEK_API_KEY   "DeepSeek-V4 reasoner/chat/flash"
check OPENROUTER_API_KEY "Kimi K2.6 / GLM-5.1 / MiniMax / Qwen"
check NVIDIA_NIM_API_KEY "Nemotron 3 Ultra"
echo
echo "Search keys (any one enables the web_search tool):"
check TAVILY_API_KEY     "Tavily search"
check SERPAPI_API_KEY    "SerpAPI search"
check BRAVE_API_KEY      "Brave search"
echo
echo "Worker pool (SLOT_MODELS):"
echo "  ${SLOT_MODELS:-<not set — defaults will be used or set it in .env>}"
echo
echo "If a model in SLOT_MODELS shows its key as MISSING above, that worker will"
echo "fail at call time. Fill it in .env (or your platform secrets) and re-run."
