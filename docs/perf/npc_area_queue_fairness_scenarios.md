# NPC area queue fairness: сценарные perf-проверки

Документ фиксирует минимальные сценарии для проверки fairness очереди area-tick после выноса lifecycle-контроля в `src/controllers/lifecycle_controller.nss`.

## Общие условия

- Контрольный модуль: `src/modules/npc_behavior/*`.
- Lifecycle area: `RUNNING/PAUSED/STOPPED` через module API `NpcBehaviorArea*` (backed by `NpcControllerArea*`).
- Ключевые метрики:
  - `npc_area_metric_processed_count`
  - `npc_area_metric_skipped_count`
  - `npc_area_metric_deferred_count`
  - `npc_area_metric_queue_overflow_count`

## Локальная статическая проверка контракта

Перед сценарными прогонами выполнить:

```bash
bash scripts/check_area_lifecycle_contract.sh
```

Проверка валидирует, что `npc_behavior_core.nss` использует `src/controllers/lifecycle_controller.nss` как единую точку lifecycle-контракта и не дублирует legacy area lifecycle vars.

## Scenario A — Burst fairness без starvation

1. Поднять area в состоянии `RUNNING` (`NpcBehaviorAreaActivate`).
2. Создать burst событий в очередь с mix приоритетов: LOW/NORMAL/HIGH/CRITICAL.
3. Прогнать не менее 120 area-tick итераций.
4. Проверить, что LOW/NORMAL события не голодают: каждый bucket получает обработку в пределах окна 10 tick.

Ожидаемый результат:
- отсутствует бесконечный starvation для LOW/NORMAL;
- `deferred_count` растёт только при реальном budget limit;
- overflow не происходит в номинале.

## Scenario B — Pause/resume без потери очереди

1. Запустить area в `RUNNING` и накопить pending очередь.
2. Перевести area в `PAUSED` через module API (`NpcBehaviorAreaPause`, внутри вызывает controller).
3. Убедиться, что `NpcBehaviorAreaTickLoop` не обрабатывает очередь до `RUNNING`.
4. Вернуть `RUNNING` через `NpcBehaviorAreaResume`, продолжить тики и сравнить pending до/после.

Ожидаемый результат:
- во время `PAUSED` нет роста `processed_count`;
- после возврата в `RUNNING` очередь дренируется в штатном порядке;
- `overflow_count` не увеличивается только из-за pause/resume.

## Scenario C — Stop/start с корректным таймером

1. Запустить area в `RUNNING`, убедиться что таймер один (`nb_area_timer_running=TRUE`).
2. Перевести в `STOPPED` (`NpcBehaviorAreaDeactivate`) и дождаться остановки loop.
3. Повторно выполнить старт и убедиться, что не появляется duplicate loop.

Ожидаемый результат:
- после stop loop завершён и `nb_area_timer_running=FALSE`;
- повторный start поднимает ровно один loop;
- метрики queue depth/buckets остаются консистентны.

## Анализ экспортированных метрик fairness

Для быстрого анализа starvation-window по bucket и инварианта pause-zero:

```bash
python3 scripts/analyze_area_queue_fairness.py \
  --input docs/perf/fixtures/area_queue_fairness_sample.csv \
  --max-starvation-window 10 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero
```

Скрипт ожидает CSV с колонками `tick`, `lifecycle_state`, `processed_low`, `processed_normal` (остальные `processed_*` — опционально).


Проверка самого анализатора (smoke):

```bash
bash scripts/test_area_queue_fairness_analyzer.sh
```
