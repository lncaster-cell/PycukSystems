# NPC Baseline Report (Phase 1)

> Current baseline (reference-point) для всех сравнений perf-gate: этот документ.
> Архив исторических baseline-отчётов: `docs/perf/reports/`.

## 1. Контекст последнего валидного прогона
- Дата: **N/A** (в репозитории отсутствует подтверждённый валидный baseline-run с телеметрией).
- Commit SHA: **N/A**.
- Ветка: **N/A**.
- Окружение (локально/CI): **N/A**.
- Версия runtime/NWNX: **N/A**.

## 2. Сценарии и длительность
- scenario_a_nominal: N/A
- scenario_b_combat_spike: N/A
- scenario_c_recovery: N/A

## 3. Агрегированные метрики (минимум 3 прогона)

| Metric | Run 1 | Run 2 | Run 3 | Median | p95 | Threshold | Status |
|---|---:|---:|---:|---:|---:|---:|---|
| area-tick latency (ms) | N/A | N/A | N/A | N/A | N/A | <= 12 | BLOCKED (нет валидных данных) |
| queue depth p99 | N/A | N/A | N/A | N/A | N/A | <= 300 | BLOCKED (нет валидных данных) |
| dropped/deferred (%) | N/A | N/A | N/A | N/A | N/A | <= 0.5 | BLOCKED (нет валидных данных) |
| db flush p95 (ms) | N/A | N/A | N/A | N/A | N/A | baseline +10% max | BLOCKED (нет валидных данных) |
| budget overrun (%) | N/A | N/A | N/A | N/A | N/A | <= 1 | BLOCKED (нет валидных данных) |

## 4. Сравнение с предыдущим baseline
- Базовый commit/дата: N/A.
- Δ p95 area-tick latency: N/A.
- Δ p99 queue depth: N/A.
- Δ dropped/deferred: N/A.
- Δ db flush p95: N/A.

## 5. Baseline freshness policy
- Для perf-gate сравнений baseline должен быть **не старше 14 дней**.
- Если актуальный baseline старше 14 дней или отсутствует, сравнение считается **невалидным** (статус `BLOCKED`) до повторного baseline-прогона.
- Для публикации нового baseline обязательны:
  - минимум 3 прогона на сценарий;
  - фиксация даты, commit SHA, окружения и агрегированных метрик;
  - архивирование предыдущего current baseline в `docs/perf/reports/YYYY-MM-DD_*`.

## 6. Вывод (go/no-go)
- Решение: **BLOCKED**.
- Обоснование: текущий current baseline не содержит подтверждённых валидных telemetry-данных.
- Rollback/mitigation: выполнить свежий baseline-run по `scripts/run_npc_bench.sh` и обновить current baseline + архив.
