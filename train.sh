#!/usr/bin/env bash
# Train the coordinator. Two paths:
#   router    — TRINITY-style, ~19.5K params, gradient-free (sep-CMA-ES). NO GPU.
#               Minutes on a CPU. This is the default and what you want first.
#   conductor — the 3B Llama Conductor, RL-trained on ToolScale. NEEDS GPUs
#               (~8× A100-class). Cloud GPU is fine; see notes at bottom.
#
# Usage:
#   ./train.sh router       # default
#   ./train.sh conductor
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUGU_DIR="${HERE}/.fugu"
REPO_DIR="${FUGU_DIR}/OpenFugu"
VENV_DIR="${FUGU_DIR}/venv"
MODE="${1:-router}"

if [ ! -d "${REPO_DIR}" ] || [ ! -d "${VENV_DIR}" ]; then
  echo "Not set up. Run ./pull-weights.sh then ./setup-fugu.sh first." >&2
  exit 1
fi

# Load keys (training calls real workers to score routing decisions).
if [ -f "${HERE}/.env" ]; then set -a; source "${HERE}/.env"; set +a; fi
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
cd "${REPO_DIR}"

case "${MODE}" in
  router)
    echo "==> Training TRINITY router (gradient-free, no GPU)."
    echo "    Scores routing against your worker pool: ${SLOT_MODELS:-<set SLOT_MODELS in .env>}"
    python train/train_trinity.py
    echo "    Done. Output head (e.g. trinity_perstep.npy) is in: ${REPO_DIR}"
    ;;
  conductor)
    echo "==> Training the 3B Conductor (RL on ToolScale). Requires GPUs."
    if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi -L || true; else
      echo "    WARNING: no nvidia-smi found — this will be unusably slow without GPUs."
    fi
    python train/train_conductor.py
    ;;
  adaptive)
    echo "==> Training adaptive pool / per-step routing."
    python train/train_adaptive_pool.py && python train/train_adaptive_pool_perstep.py
    ;;
  *)
    echo "Unknown mode '${MODE}'. Use: router | conductor | adaptive" >&2
    exit 1
    ;;
esac

# ── Cloud GPU notes ─────────────────────────────────────────────────────────
# The conductor path is the only part that wants real GPUs. Rent a box
# (RunPod / Lambda / Vast / Clore — 8× A100/H100), then on that box:
#   git clone <this repo> && cd fugu-swarm
#   ./pull-weights.sh && ./setup-fugu.sh
#   cp .env.example .env && edit keys
#   ./train.sh conductor
# The router (./train.sh router) does NOT need any of that — run it anywhere.
