# NPC Bhvr perf gate: audit-derived guardrails

Документ фиксирует perf/fault-injection проверки, критерии PASS/FAIL/BLOCKED и формат итогового gate-summary для NPC Bhvr.

## Baseline reference-point (обязательная привязка)

Единственный current baseline для perf-gate — `docs/perf/npc_baseline_report.md`.

- Если baseline отсутствует, содержит `N/A` дату или старше 14 дней: итог по guardrail помечается `BLOCKED` даже при локальном PASS.
- `docs/perf/reports/*` — архив исторических отчётов и не используется как reference-point для текущего gate.
- `scripts/run_npc_bench.sh` автоматически проверяет freshness baseline и добавляет статус в `gate_summary.json/csv`.

## Scenario IDs

Базовые scenario ID: `steady`, `burst`, `starvation-risk`.

Fault profiles (отдельные прогоны guardrails):
- `overflow-guardrail`
- `tick-budget`
- `tick-budget-degraded`
- `fairness-checks`
- `warmup-rescan`

## Guardrail criteria (machine-readable contract)

### G1 — Registry overflow guardrail

**Сценарии:** `starvation-risk`, `overflow-guardrail`.

**PASS:**
- есть RUNNING-тики;
- `overflow_events > 0` встречается в каждом run;
- `gate_summary` фиксирует `registry_overflow=PASS`.

**FAIL:**
- отсутствуют `overflow_events`/RUNNING-данные;
- или overflow ни разу не зафиксирован в run.

**BLOCKED:**
- baseline stale/absent по политике freshness.

### G2 — Tick budget / degraded-mode guardrail

**Сценарии:** `burst`, `starvation-risk`, `tick-budget`, `tick-budget-degraded`.

**PASS:**
- есть RUNNING-тики;
- в run наблюдаются оба сигнала: `budget_overrun > 0` и `deferred_events > 0`;
- `analyze_npc_fairness.py` проходит для валидных fixture.

**FAIL:**
- нет budget/deferred сигналов;
- либо gate-analyzer падает на невалидных числах/контракте.

**BLOCKED:**
- baseline stale/absent.

### G3 — Automated fairness guardrail

**Сценарии:** `steady`, `burst`, `starvation-risk`, `fairness-checks` + fault fixtures.

**PASS:**
- `analyze_area_queue_fairness.py` проходит с флагами:
  `--max-starvation-window 3 --enforce-pause-zero --max-post-resume-drain-ticks 1 --min-resume-transitions 2`;
- fault fixtures детерминированно падают на нужном инварианте (starvation/pause-zero/post-resume).

**FAIL:**
- любой обязательный fairness-инвариант не соблюдён;
- или expected-fail fixture не даёт отказ.

**BLOCKED:**
- baseline stale/absent.

### G4 — Route cache warmup/rescan guardrail

**Сценарии:** `warmup-rescan`.

**PASS:**
- fixture содержит поля `route_cache_warmup_ok`, `route_cache_rescan_ok`, `route_cache_guardrail_status`;
- во всех RUNNING-записях `route_cache_warmup_ok=1`, `route_cache_rescan_ok=1`;
- `route_cache_guardrail_status=PASS` на каждом run;
- `gate_summary` фиксирует `route_cache_warmup_rescan=PASS`.

**FAIL:**
- отсутствует любой из `route_cache_*` сигналов;
- либо warmup/rescan signal не PASS хотя бы в одном run.

**BLOCKED:**
- baseline stale/absent.

## Release gate integration checklist

- [x] Overflow сценарий добавлен в perf-прогон NPC Bhvr.
- [x] Warmup/rescan сценарий добавлен в perf-прогон и связан с route-cache guardrail status.
- [x] Fault-injection silent degradation сценарий добавлен в perf-прогон для активных guardrails (overflow/tick-budget/fairness).
- [x] Automated fairness checks добавлены в perf-прогон NPC Bhvr.
- [x] Tick budget/degraded-mode сценарий добавлен в perf-прогон NPC Bhvr.
- [x] Итоговый отчёт содержит явный pass/fail/blocked по каждому guardrail.

## Как запускать

```bash
# Базовые сценарии
RUNS=3 bash scripts/run_npc_bench.sh steady
RUNS=3 bash scripts/run_npc_bench.sh burst
RUNS=3 bash scripts/run_npc_bench.sh starvation-risk

# Отдельные fault profiles по guardrails
RUNS=3 bash scripts/run_npc_bench.sh overflow-guardrail
RUNS=3 bash scripts/run_npc_bench.sh tick-budget
RUNS=3 bash scripts/run_npc_bench.sh tick-budget-degraded
RUNS=3 bash scripts/run_npc_bench.sh fairness-checks
RUNS=3 bash scripts/run_npc_bench.sh warmup-rescan

# Self-check analyzers
bash scripts/test_npc_fairness.sh
bash scripts/test_area_queue_fairness_analyzer.sh
```

## Артефакты результата

Каждый запуск `run_npc_bench.sh` создаёт:
- `benchmarks/npc_baseline/results/<timestamp>/summary.md`
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.csv`
- `benchmarks/npc_baseline/results/<timestamp>/gate_summary.json`

Единый репозиторный snapshot gate-summary ведётся в `docs/perf/reports/npc_gate_summary_latest.md`.
