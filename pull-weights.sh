#!/usr/bin/env bash
# Fetch the real, downloadable Fugu-style artifacts into ./.fugu/ (git-ignored).
#
# Official Sakana Fugu has NO public weights (API-only). The genuinely
# downloadable pieces are:
#   1. OpenFugu (open reimpl) + its Qwen3-0.6B backbone & router checkpoints
#   2. (optional) the separate ~6 GB Llama-3.2-3B "Conductor" weights
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUGU_DIR="${HERE}/.fugu"
REPO_DIR="${FUGU_DIR}/OpenFugu"
WEIGHTS_DIR="${FUGU_DIR}/weights/openfugu-conductor-3b"

OPENFUGU_REPO="https://github.com/trotsky1997/OpenFugu"
CONDUCTOR_REPO="di-zhang-fdu/openfugu-conductor-3b"   # ~6 GB, Llama 3.2 Community License

mkdir -p "${FUGU_DIR}"

echo "==> 1/4  Cloning OpenFugu (open reimplementation of Sakana Fugu)"
if [ -d "${REPO_DIR}/.git" ]; then
  git -C "${REPO_DIR}" pull --ff-only || echo "    (pull skipped — using existing clone)"
else
  git clone --depth 1 "${OPENFUGU_REPO}" "${REPO_DIR}"
fi

echo
echo "==> 2/4  Fetching backbone + router checkpoints (Qwen3-0.6B, model_iter_60.npy, fixtures)"
echo "    OpenFugu pulls these via its own script (they are not redistributed here)."
if [ -f "${REPO_DIR}/scripts/fetch_artifacts.py" ]; then
  echo "    Run after setup-fugu.sh (needs the venv):"
  echo "        source ${FUGU_DIR}/venv/bin/activate && python ${REPO_DIR}/scripts/fetch_artifacts.py"
else
  echo "    scripts/fetch_artifacts.py not found — check the repo layout: ${REPO_DIR}"
fi

echo
echo "==> 3/4  TRINITY router"
echo "    Nothing to download: ~19.5K params, trained locally and gradient-free."
echo "    After setup, train with (from inside OpenFugu):"
echo "        python train/train_trinity.py        # no GPU required"

echo
echo "==> 4/4  Conductor weights: ${CONDUCTOR_REPO}  (~6 GB, Llama-3.2-3B fine-tune)"
echo "    Only needed for the heavier Fugu-Ultra / Conductor-DAG path (ultra.py)."
echo "    Gated by the Llama 3.2 Community License — you may need 'huggingface-cli login'."
read -r -p "    Download ~6 GB of Conductor weights now? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  mkdir -p "${WEIGHTS_DIR}"
  if command -v huggingface-cli >/dev/null 2>&1; then
    huggingface-cli download "${CONDUCTOR_REPO}" --local-dir "${WEIGHTS_DIR}"
  elif command -v hf >/dev/null 2>&1; then
    hf download "${CONDUCTOR_REPO}" --local-dir "${WEIGHTS_DIR}"
  else
    echo "    huggingface-cli not found. Install: pip install -U 'huggingface_hub[cli]'"
    echo "    Or clone via git-lfs:"
    echo "        git lfs install && git clone https://huggingface.co/${CONDUCTOR_REPO} '${WEIGHTS_DIR}'"
    exit 1
  fi
  echo "    OK Conductor weights at: ${WEIGHTS_DIR}"
else
  echo "    Skipped. Low on RAM / on Termux? Options:"
  echo "      - Use the router (Qwen3-0.6B) + remote API workers (tiny local footprint), or"
  echo "      - Quantize to GGUF for llama.cpp:"
  echo "          python -m llama_cpp.convert '${WEIGHTS_DIR}' --outtype q4_k_m"
fi

echo
echo "Done. Next: ./setup-fugu.sh"
