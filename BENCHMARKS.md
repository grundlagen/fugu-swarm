# Benchmarks — orchestrators & the models we put in the pool

Numbers reported by the sources below (June 2026). Read the **caveat** at the
bottom before trusting any headline: several of these are vendor-reported and not
independently verified.

---

## Orchestrators (the thing this repo builds)

### Sakana Fugu / Fugu Ultra (official, closed)
Reported to post the **top score on 10 of 11 rows** of its launch table; Fugu Ultra
tops the four coding benchmarks, CharXiv Reasoning, and Humanity's Last Exam.

| Benchmark | Fugu Ultra | For comparison |
|---|---|---|
| SWE-Bench Pro | **73.7** | Claude Opus 4.8 69.2 · GPT-5.5 58.6 · Fable 5 80.3* |
| TerminalBench 2.1 | **82.1** | Fable 5 88.0* |
| LiveCodeBench | **93.2** (Fugu 92.9) | Gemini 3.1 Pro 88.5 |
| GPQA-D | **95.5** | — |
| Humanity's Last Exam | **50.0** | Opus 4.8 49.8 |

\* Fable 5 / Mythos were shut down (US, 2026-06-12) and are **not** in Fugu's pool.
Fugu's actual agent pool: **Claude Opus 4.8, GPT-5.5, Gemini 3.1 Pro.**

### TRINITY (arXiv 2512.04695, ICLR'26) — the open coordinator
Consistently outperforms competing multi-agent methods across all four eval
benchmarks; notably **0.61 pass@1 on LiveCodeBench v6**, substantially above the
methods it was compared against. This is the architecture this kit reimplements.

### Other orchestrators with strong reported numbers (academic)
- **AdaptOrch** — task-adaptive orchestration under performance convergence (arXiv 2602.16873)
- **Holos** — web-scale multi-agent system (arXiv 2604.02334)
- **MAS-Orchestra** — holistic orchestration + controlled benchmarks (arXiv 2601.14652)
- **Agent Q-Mix** — RL action selection for multi-agent systems (arXiv 2604.00344)
- **Mixture-of-Agents** — the earlier baseline these beat

---

## The worker models we actually pool (GPT deliberately excluded)

You asked for all the strong ones **bar GPT**, plus out-of-the-way picks. Here's the
evidence for each:

| Model | Weights | Reported standing |
|---|---|---|
| **Claude Opus 4.8** | closed (API) | SWE-Bench Pro 69.2; HLE 49.8 — top judgement/verify model |
| **Gemini 3.1 Pro** | closed (API) | LiveCodeBench 88.5; strong long-context generalist |
| **DeepSeek-V4-Pro / Flash** | ✅ open (MIT) | V4-Pro ties the closed frontier on SWE-Bench agentic coding; cheap via API |
| **Kimi K2.6** (Moonshot) | ✅ open | **#1 open / #4 overall** on Artificial Analysis Index (54) |
| **GLM-5.1** (Zhipu) | ✅ open (MIT) | cleanest license; strong all-rounder |
| **Nemotron 3 Ultra** (NVIDIA) | ✅ open (LF license) | AA Intelligence Index **48, #9 of 89** — top US open-weight; 550B/55B-active Mamba-Transformer MoE |
| **Qwen3.6-27B** | ✅ open (Apache-2.0) | best small dense coder; great self-host worker |

*Out-of-the-way bench / "NeMo etc." picks:* Nemotron 3 (Ultra 550B/55B, Super
120B/12.7B, Nano 31.6B/3.6B — open weights **+ training data + recipes**),
Kimi K2.6, GLM-5.1, MiniMax. These give the swarm diversity outside the
Claude/Gemini/DeepSeek mainstream and are easiest to reach via one OpenRouter key
(or NVIDIA NIM for Nemotron).

**GPT-5.5 is excluded from the pool by choice** (your call), even though it's in
the official Fugu pool. Its key field stays in `.env` if you ever want it back.

---

## Caveat — don't trust the headlines blindly

Sakana's "Fugu Ultra matches Fable/Mythos" framing is **disputed** (Stella Biderman
and others) and **not independently verified**. Sakana also has a prior
eval-gaming incident (the "AI CUDA Engineer" exploited a sandbox loophole; they
acknowledged it and revised the paper). The orchestration *mechanism* and the
TRINITY paper results are credible; treat the frontier-parity marketing as
unproven until third parties reproduce it. Goldie Bench's hands-on 0–10 scoring is
one of the few independent reads.

## Sources
- Fugu benchmarks: https://venturebeat.com/orchestration/no-claude-fable-5-no-problem-sakana-achieves-frontier-performance-with-new-fugu-multi-model-auto-synthesis-system · https://www.verdent.ai/guides/devtools/fugu-ultra-coding-agents · https://goldiebench.com/models/fugu
- TRINITY: https://arxiv.org/pdf/2512.04695
- Other orchestrators: https://arxiv.org/pdf/2602.16873 · https://arxiv.org/pdf/2604.02334 · https://arxiv.org/pdf/2601.14652 · https://arxiv.org/pdf/2604.00344
- Nemotron 3: https://research.nvidia.com/labs/nemotron/Nemotron-3/ · https://www.digitalapplied.com/blog/nvidia-nemotron-3-ultra-550b-open-reasoning-model-2026
- Open-weight standings: https://huggingface.co/blog/daya-shankar/open-source-llms · https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro
- Skepticism: https://the-decoder.com/sakana-ais-fugu-orchestrates-multiple-llms-to-match-anthropics-fable-and-mythos-benchmarks/ · https://digg.com/tech/hm73dcfr
