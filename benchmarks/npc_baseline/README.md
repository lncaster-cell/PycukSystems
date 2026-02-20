# NPC Baseline Benchmark Scenarios (Phase 1)

Набор воспроизводимых baseline-сценариев для первой фазы NPC runtime.

## Цели
- Зафиксировать контрольные метрики перед perf-чувствительными изменениями.
- Поддерживать сравнимость результатов между локальным прогоном и CI.

## Сценарии

### scenario_a_nominal
- **Описание:** штатная целевая нагрузка.
- **Профиль:** 200 NPC в 4 area, стандартный event mix (spawn/perception/damaged/dialogue/death).
- **Длительность:** 10 минут.
- **SLO-ориентиры:** p95 area-tick latency <= 12 ms, dropped/deferred <= 0.5%.

### scenario_b_combat_spike
- **Описание:** пиковая боевая нагрузка.
- **Профиль:** burst боевых событий (damaged/combat round) с повышенной интенсивностью в 2 area.
- **Длительность:** 5 минут + 2 минуты warmup.
- **Цель:** выявление очередей и budget overrun на горячем пути.

### scenario_c_recovery
- **Описание:** восстановление после пика.
- **Профиль:** после combat spike снизить входной event rate до nominal.
- **Длительность:** 5 минут.
- **Цель:** убедиться, что queue depth и deferred-rate возвращаются к baseline.

## Обязательные метрики
- Tick orchestration: p50/p95/p99 area-tick latency, budget overruns.
- Queue: p95/p99 queue depth, dropped/deferred rate.
- DB flush: batch size, p95/p99 flush duration, flush error rate.
- AI step cost: p95 step duration, top-N expensive handlers.

## Формат артефактов
Скрипт `scripts/run_npc_bench.sh` пишет summary и raw-артефакты в:
- `benchmarks/npc_baseline/results/<timestamp>/summary.md`
- `benchmarks/npc_baseline/results/<timestamp>/raw/`

Шаблон итогового отчёта: `docs/perf/npc_baseline_report.md`.
