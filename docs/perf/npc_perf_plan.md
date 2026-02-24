# NPC Bhvr perf plan: gate-метрики baseline

Документ описывает минимальный baseline-gate для NPC Bhvr и формат измерений перед интеграцией в CI.

## Scope

- Контур: area-tick loop NPC Bhvr под нагрузкой (steady, burst, starvation-risk).
- Окно baseline: минимум 3 запуска на каждый сценарий.
- Источник данных: CSV telemetry с tick-уровнем.

## Gate-метрики

### 1) Area-tick latency p95/p99

- Что меряем: `area_tick_latency_ms` по тикам в состоянии `RUNNING`.
- Почему важно: напрямую отражает headroom относительно tick-budget.
- Gate:
  - `p95 <= 20 ms`
  - `p99 <= 25 ms`

### 2) Queue depth p95/p99

- Что меряем: `queue_depth` (pending queue size) по тикам `RUNNING`.
- Почему важно: ранний индикатор деградации fairness и риска starvation.
- Gate:
  - `p95 <= 64`
  - `p99 <= 80`

### 3) Deferred / overflow rate

- Что меряем:
  - `deferred_rate = sum(deferred_events > 0) / running_ticks`
  - `overflow_rate = sum(overflow_events > 0) / running_ticks`
- Почему важно: deferred допустим при burst, overflow должен оставаться редким.
- Gate:
  - `deferred_rate <= 0.35`
  - `overflow_rate <= 0.02`

### 4) Budget overrun rate

- Что меряем: `budget_overrun_rate = sum(budget_overrun > 0) / running_ticks`.
- Почему важно: показывает долю тиков, где loop выходит за целевой budget.
- Gate:
  - `budget_overrun_rate <= 0.10`

## Scenario IDs (single naming convention)

Во всех скриптах/отчётах используется единый набор scenario ID: `steady`, `burst`, `starvation-risk` (как в `scripts/run_npc_bench.sh`).

## Fixture-профили

- `docs/perf/fixtures/npc/steady.csv` — стабильная нагрузка без overflow, с минимальным deferred.
- `docs/perf/fixtures/npc/steady_decimal_latency.csv` — стабильная нагрузка с дробным latency/queue_depth; ожидаемый результат анализатора: `[OK]`.
- `docs/perf/fixtures/npc/burst.csv` — кратковременные всплески очереди и латентности.
- `docs/perf/fixtures/npc/starvation_risk.csv` — стресс-профиль с высоким queue depth и риском budget overrun (scenario ID: `starvation-risk`).

## Локальный запуск

```bash
# One-step baseline run (генерация run_*.csv + пост-анализ + summary.md)
bash scripts/run_npc_bench.sh steady

# Audit-derived one-step profiles из npc_perf_gate.md
bash scripts/run_npc_bench.sh overflow-guardrail
bash scripts/run_npc_bench.sh tick-budget
bash scripts/run_npc_bench.sh fairness-checks
```

`run_npc_bench.sh` теперь автоматически:
- запускает `scripts/analyze_npc_fairness.py` для каждого `run_*.csv`;
- запускает `scripts/analyze_area_queue_fairness.py` там, где fixture содержит `processed_*` колонки, и всегда передаёт обязательные флаги (`--max-starvation-window`, `--enforce-pause-zero`, `--max-post-resume-drain-ticks`, `--min-resume-transitions`);
- формирует `summary.md` с явным PASS/FAIL по guardrail-проверкам.

## Audit-derived guardrails

Детальные сценарии по ограничениям из AL-аудита вынесены в `docs/perf/npc_perf_gate.md` и входят в release-gate NPC Bhvr.
