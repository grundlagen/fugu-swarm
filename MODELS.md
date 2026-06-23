# Model guide — best models, which weights to run, what hardware to put them on

Cloud running is fine here, so the default is **best-of-breed API workers**; local
weights are optional. This doc covers: (1) which model for which role, (2) which
trained weights are actually worth downloading and on what hardware, and (3) the
honest "don't bother locally, use the API" cases.

> One-liner: **Claude has no weights (API only). DeepSeek-V4-Pro has weights but
> they're server-only — use its API. The best models you can realistically *run*
> yourself are Qwen3.6, Gemma 4, and DeepSeek-V4-Flash (with real GPUs).**

---

## 1. Best model per role (the SLOT_MODELS mix)

The coordinator assigns each turn a role. Give it diversity so the Verifier isn't
the same brain as the Worker.

| Role | What it does | Best picks (June 2026) |
|---|---|---|
| **Thinker** | decompose, plan, hard reasoning/math | `deepseek/deepseek-reasoner` (cheap, ~frontier reasoning), `anthropic/claude-opus-4-8` |
| **Worker** | do the task, write code, long-context work | `deepseek/deepseek-chat` (V4, cheap+strong coding), `openai/gpt-5.5`, `anthropic/claude-opus-4-8` |
| **Verifier** | independently check the answer | a *different* family than the Worker: `gemini/gemini-3.1-pro` or `anthropic/claude-opus-4-8` |

Recommended `.env` default (paid, cloud, best quality):
```
SLOT_MODELS=anthropic/claude-opus-4-8,deepseek/deepseek-reasoner,deepseek/deepseek-chat,openai/gpt-5.5,gemini/gemini-3.1-pro
```
DeepSeek does most of the heavy lifting cheaply; Claude/Gemini add judgement +
diversity for verification and contested ("debate") calls.

---

## 2. Trained weights worth downloading — by hardware tier

Rule of thumb: **FP16 ≈ 2 GB / 1B params; INT4 ≈ 0.5 GB / 1B params.** For MoE
models, total params drive the *disk/VRAM* footprint, active params drive *speed*.

| Tier | Hardware | Run these weights | Notes |
|---|---|---|---|
| **Phone / Termux** | 4–12 GB RAM | router backbone **Qwen3-0.6B** (already fetched) + **remote API workers** | Don't run big workers on a phone. The router is tiny; workers live in the cloud. |
| **Laptop** | 16–32 GB RAM, no/weak GPU | **Qwen3-8B** (~5 GB Q4), **Gemma 4** (~14 GB Q4) | Good local Worker/Verifier for cheap tasks. |
| **Single GPU** | 24 GB VRAM (e.g. 4090) | **Qwen3.6-27B** coder (~16 GB Q4), **Gemma 4-27B** | Best self-hosted *coding* worker; Apache-2.0. |
| **Workstation** | 2× 80 GB or 4×48 GB | **DeepSeek-V4-Flash** (284B/13B active, ~140 GB Q4), **GLM-5.1**, **Kimi K2.6** | Frontier-ish open weights you can actually serve. |
| **Server only** | 8× H100-class | **DeepSeek-V4-Pro** (1.6T/49B active) | Technically downloadable (MIT) but impractical to self-host. **Use the DeepSeek API instead.** |

### Conductor weights (for the heavier Fugu-Ultra / DAG path)
- `di-zhang-fdu/openfugu-conductor-3b` — Llama-3.2-3B fine-tune, ~6 GB, runs on a
  24 GB GPU or quantized on a laptop. Pulled (optionally) by `./pull-weights.sh`.

### What NOT to download
- **Claude / GPT / Gemini** — no public weights, ever. API only.
- **DeepSeek-V4-Pro** locally — unless you have an 8×H100 box; the API is cheaper
  and faster than your electricity bill.

---

## 3. Which to actually pick

- **Cloud, best quality (recommended):** the API mix above. Zero downloads.
- **Mostly cloud + a cheap local fallback:** API mix + `ollama/qwen3:8b` for
  offline/cheap calls.
- **Self-hosted serious:** `Qwen3.6-27B` (coding) + `DeepSeek-V4-Flash` (general)
  + `gemini-3.1-pro` API as an independent Verifier.
- **Phone:** router + API workers. Nothing heavy local.

## Sources
- Open-weight landscape: https://huggingface.co/blog/daya-shankar/open-source-llms · https://kilo.ai/open-source-models
- DeepSeek V4 (Pro/Flash, MIT): https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro · https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash · https://simonwillison.net/2026/apr/24/deepseek-v4/
- Comparisons: https://codersera.com/blog/best-open-source-llm-2026-llama-4-qwen-3-5-deepseek-v4-gemma-4-mistral/ · https://onyx.app/self-hosted-llm-leaderboard
