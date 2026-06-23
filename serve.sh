#!/usr/bin/env bash
# Serve the Fugu-style orchestrator as an OpenAI-compatible endpoint.
# Reads your providers/keys from ./.env (copy from .env.example first).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUGU_DIR="${HERE}/.fugu"
REPO_DIR="${FUGU_DIR}/OpenFugu"
VENV_DIR="${FUGU_DIR}/venv"

if [ ! -f "${HERE}/.env" ]; then
  echo "No .env found. Run: cp .env.example .env  and add your keys." >&2
  exit 1
fi
if [ ! -d "${REPO_DIR}" ] || [ ! -d "${VENV_DIR}" ]; then
  echo "Not set up yet. Run ./pull-weights.sh then ./setup-fugu.sh first." >&2
  exit 1
fi

# Load .env (export every var) so keys reach litellm / OpenFugu subprocesses.
set -a
# shellcheck disable=SC1091
source "${HERE}/.env"
set +a

: "${SLOT_MODELS:?Set SLOT_MODELS in .env (comma-separated litellm model names)}"
PORT="${PORT:-8088}"

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
cd "${REPO_DIR}"

echo "==> Serving '${SERVED_MODEL_NAME:-fugu}' on :${PORT}"
echo "    Workers: ${SLOT_MODELS}"
echo "    Endpoint: http://localhost:${PORT}/v1   (call model name '${SERVED_MODEL_NAME:-fugu}')"
echo

# Router path (default). For the heavier 3B Conductor DAG, use ultra.py instead:
#   python openfugu/ultra.py --query "..." \
#       --local-conductor "${FUGU_DIR}/weights/openfugu-conductor-3b" \
#       --slot-models "${SLOT_MODELS}"
exec python openfugu/serve.py --slot-models "${SLOT_MODELS}" --port "${PORT}"
