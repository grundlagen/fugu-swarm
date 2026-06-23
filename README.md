# fugu-swarm

A self-contained kit for running a **Sakana Fugu-style multi-agent orchestrator**
locally: a tiny coordinator model that, per query, assigns *Thinker / Worker /
Verifier* roles to a pool of LLMs, picks a topology, verifies, and does bounded
recursive retry — served behind a single OpenAI-compatible endpoint.

This repo holds the *setup kit* (scripts + config + docs). The heavy stuff
(cloned code, multi-GB weights, venv) lands under `.fugu/`, which is git-ignored
and never committed.

> **TL;DR to get running:** `./pull-weights.sh` → `./setup-fugu.sh` →
> drop your keys into `.env` (copy from `.env.example`) → `./serve.sh`.

---

## What's actually real (verified 2026-06-23)

I re-checked every claim against primary sources rather than trusting the earlier
chat. Findings:

| Thing | Status | Weights? |
|---|---|---|
| **Sakana Fugu / Fugu Ultra** (official) | Real. Beta 2026-04-25, GA **2026-06-22** | ❌ Closed. API-only, OpenAI-compatible. Official conductor is **~7B**, not released. |
| **TRINITY** (arXiv 2512.04695, ICLR'26) | Real paper. ~0.6B backbone + ~10K-param head, evolutionary (gradient-free) | Sakana's closed; you train your own in minutes (no GPU). |
| **Conductor** (ICLR'26, trained on ToolScale) | Real. RL/GRPO-trained coordinator | Sakana's closed; **open reimpl weights exist** ↓ |
| **OpenFugu** (`trotsky1997/OpenFugu`, Apache-2.0) | 3rd-party open reimplementation | ✅ Runnable. **Qwen3-0.6B** backbone + ~19.5K trainable params (sep-CMA-ES). read→run→train→serve. |
| **`di-zhang-fdu/openfugu-conductor-3b`** | 3rd-party Conductor weights on HF | ✅ **Downloadable.** Llama-3.2-3B-Instruct fine-tune, ~6 GB, Llama 3.2 Community License. |

So there are **two distinct downloadable artifacts**, and the old notes conflated
them:

1. **The router** (TRINITY-style) — a **Qwen3-0.6B** backbone + a ~19.5K-param
   linear head. Negligible to train and run. This is the default path here.
2. **The Conductor** (`openfugu-conductor-3b`) — a separate **Llama-3.2-3B**
   fine-tune (~6 GB) used for the heavier "Fugu-Ultra" workflow-DAG path.

The **official** Fugu has no weights to hunt — it's a paid endpoint.

## The honest caveats before you spend bandwidth or money

**1. The coordinator is the cheap part; the workers are the value.** Fugu's whole
trick is orchestrating *frontier* workers (Opus, Gemini, GPT). A 19.5K-param
router or a 3B conductor is near-worthless without strong workers behind it. Two
regimes:

- **Real Fugu-quality** = coordinator (local, cheap) + **frontier API workers**
  (paid, per-call). The architecture that actually performs. Not free, not local.
- **Fully local / Termux** = coordinator + small local workers via Ollama
  (Llama/Gemma/DeepSeek). You get the *mechanism* — role assignment, topology,
  verify, retry — at small-model quality. Good for learning + cheap decomposable
  tasks; won't match Fugu Ultra.

**2. Treat Sakana's headline numbers with skepticism.** Sakana's "Fugu Ultra
matches Fable/Mythos without export-control risk" claim is disputed (Stella
Biderman and others), and it is **not independently verified**. Sakana also has a
prior eval-gaming incident (the "AI CUDA Engineer" exploited a sandbox loophole;
they acknowledged it and revised the paper). The *mechanism* is real and useful;
the *frontier-parity marketing* is not established. Build on the architecture, not
the press release.

**Termux note:** a 3B BF16 conductor (~6 GB) won't run comfortably on a phone.
On Termux prefer the **router (Qwen3-0.6B)** + remote API workers, or a quantized
GGUF conductor. See `pull-weights.sh`.

---

## Quick start

```bash
# 1. Fetch the real artifacts: clones OpenFugu + Qwen3-0.6B backbone + checkpoints
#    (prompts before the optional ~6 GB Conductor weights)
./pull-weights.sh

# 2. venv + deps + self-test (expects ~95% agent / 100% role accuracy)
./setup-fugu.sh

# 3. Drop in your API keys — THIS is the only file you edit to add providers
cp .env.example .env
$EDITOR .env

# 4. Serve the OpenAI-compatible endpoint on :8088
./serve.sh

# (optional) train the tiny router for your worker pool — no GPU, minutes
./train.sh router
```

Point any OpenAI-compatible client (incl. Claude Code) at `http://localhost:8088/v1`
and call the single model name `fugu`.

## Dropping in APIs

`.env` is the **one place** you add providers. The flow:

1. Paste keys for whichever providers you want as workers
   (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `NOVITA_API_KEY`, …).
2. List the worker models in `SLOT_MODELS` (litellm-style names, comma-separated),
   e.g. `anthropic/claude-opus-4-8,openai/gpt-5.5,gemini/gemini-3.1-pro`.
3. `./serve.sh` passes them to OpenFugu as `--slot-models`. The coordinator routes
   among exactly those.

`workers.example.yaml` documents the role/topology/verify-retry knobs and the
local-vs-frontier mixing strategy in more detail (it's reference; `.env` is the
runtime drop-in).

## Swarm capabilities, web search & GPU training

This kit is set up for the full thing, not just a single router call:

- **Swarm / topologies.** The coordinator runs multi-turn with Thinker / Worker /
  Verifier roles and picks a topology per query: `single`, `sequential`,
  `parallel` (fan-out), or `debate` (multiple frontier models argue, then
  synthesize). Bounded recursive retry kicks in when the Verifier's confidence is
  below threshold. Tune these in `workers.example.yaml` (`control:` block).
- **Web search.** Drop a `TAVILY_API_KEY` (or SerpAPI/Brave) into `.env` and the
  swarm exposes a `web_search` tool so workers/verifier can ground answers on live
  data instead of stale weights.
- **Best models, picked per role.** See `MODELS.md` (what to run/download) and
  `BENCHMARKS.md` (the scores behind the picks). Default pool is all the strong
  models **bar GPT**, plus out-of-the-way open ones (Nemotron 3, Kimi K2.6,
  GLM-5.1) for diversity.
- **GPU training.** `./train.sh router` trains the tiny TRINITY router gradient-free
  (no GPU, minutes). `./train.sh conductor` trains the 3B Conductor with RL —
  rent an 8×A100/H100 cloud box and run it there (notes in `train.sh`).

Cloud running is the intended default: best API workers + optional cloud GPU for
the conductor. Nothing here requires a local GPU unless you choose the conductor
training path or self-host open weights.

## Alternatives & related projects

| Project | What it is | When to use |
|---|---|---|
| **OpenFugu** (`trotsky1997/OpenFugu`) | Most complete open reimpl; read→run→train→serve, OpenAI-compatible | Default. What this kit wires up. |
| **`di-zhang-fdu/openfugu-conductor-3b`** | The 3B Conductor weights for the Ultra/DAG path | When you want the heavier conductor, not just the router |
| **`BicaMindLabs/open-sakanafugu`** | 9 LLMs as implementers + Codex as independent reviewer + bounded review-fix loop | A coding-workflow take; good if you want a reviewer-in-the-loop pattern |
| **`nshkrdotcom/trinity_coordinator`** | TRINITY reimplemented in Elixir/Axon | If you live in the BEAM/Elixir ecosystem |
| **Official `SakanaAI/fugu`** | Closed, API-only | When you'll pay for the managed endpoint and want their tuned 7B conductor |

## Sources

- Fugu launch: https://sakana.ai/fugu-release/ · Beta: https://sakana.ai/fugu-beta/
- TRINITY: https://arxiv.org/abs/2512.04695 · https://sakana.ai/trinity/
- OpenFugu (open reimpl): https://github.com/trotsky1997/OpenFugu
- Conductor weights: https://huggingface.co/di-zhang-fdu/openfugu-conductor-3b
- Alternatives: https://github.com/BicaMindLabs/open-sakanafugu · https://github.com/nshkrdotcom/trinity_coordinator
- Official (closed): https://github.com/SakanaAI/fugu
- Skepticism: https://the-decoder.com/sakana-ais-fugu-orchestrates-multiple-llms-to-match-anthropics-fable-and-mythos-benchmarks/ · https://digg.com/tech/hm73dcfr
