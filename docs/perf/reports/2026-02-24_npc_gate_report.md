# NPC Gate Report — 2026-02-24

- Commit SHA: **ee2da52 (`ee2da52f718134afa2e6fa4a4d23953e49f1f949`)**.
## Sources
- Perf plan: `docs/perf/npc_perf_plan.md`
- Perf gate criteria: `docs/perf/npc_perf_gate.md`
- Current baseline reference-point: `docs/perf/npc_baseline_report.md`

## Run matrix (>=3 runs each)
- `steady` → `benchmarks/npc_baseline/results/20260224_092127`
- `burst` → `benchmarks/npc_baseline/results/20260224_092134`
- `starvation-risk` → `benchmarks/npc_baseline/results/20260224_092142`
- `overflow-guardrail` → `benchmarks/npc_baseline/results/20260224_092150`
- `tick-budget` → `benchmarks/npc_baseline/results/20260224_092158`
- `tick-budget-degraded` → `benchmarks/npc_baseline/results/20260224_092206`
- `fairness-checks` → `benchmarks/npc_baseline/results/20260224_092214`

## Guardrail execution summary

| Guardrail | Profiles | Result |
|---|---|---|
| Registry overflow guardrail | starvation-risk, overflow-guardrail | PASS (3/3 + 3/3) |
| Tick budget / degraded-mode guardrail | burst, starvation-risk, tick-budget, tick-budget-degraded | PASS (3/3 в каждом профиле) |
| Automated fairness guardrail | fairness-checks | PASS (3/3) |

## Raw artifacts
Сырые CSV/логи/summary сохранены в `benchmarks/npc_baseline/results/<timestamp>/` для каждого профиля из run matrix.

## Gate decision
**GO (PASS)**: baseline свежий, все обязательные guardrails выполнены.
