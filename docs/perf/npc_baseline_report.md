# NPC Baseline Report (Phase 1)

## 1. Контекст прогона
- Дата:
- Commit SHA:
- Ветка:
- Окружение (локально/CI):
- Версия runtime/NWNX:

## 2. Сценарии и длительность
- scenario_a_nominal:
- scenario_b_combat_spike:
- scenario_c_recovery:

## 3. Результаты (минимум 3 прогона)

| Metric | Run 1 | Run 2 | Run 3 | Median | p95 | Threshold | Status |
|---|---:|---:|---:|---:|---:|---:|---|
| area-tick latency (ms) |  |  |  |  |  | <= 12 |  |
| queue depth p99 |  |  |  |  |  | <= 300 |  |
| dropped/deferred (%) |  |  |  |  |  | <= 0.5 |  |
| db flush p95 (ms) |  |  |  |  |  | baseline +10% max |  |
| budget overrun (%) |  |  |  |  |  | <= 1 |  |

## 4. Сравнение с предыдущим baseline
- Базовый commit/дата:
- Δ p95 area-tick latency:
- Δ p99 queue depth:
- Δ dropped/deferred:
- Δ db flush p95:

## 5. Вывод (go/no-go)
- Решение:
- Обоснование:
- Rollback/mitigation (если нужно):
