# NPC area queue fairness: сценарные perf-проверки

Документ фиксирует минимальные сценарии для проверки fairness очереди area-tick где lifecycle остаётся в `src/modules/npc/npc_core.nss` как единственный runtime-источник истины.

## Общие условия

- Контрольный модуль: `src/modules/npc/*`.
- Lifecycle area: `RUNNING/PAUSED/STOPPED` через актуальный API `NpcBhvrAreaActivate/Pause/Stop`.
- Ключевые метрики:
  - `npc_area_metric_processed_count`
  - `npc_area_metric_skipped_count`
  - `npc_area_metric_deferred_count`
  - `npc_area_metric_queue_overflow_count`

## Локальная статическая проверка контракта

Перед сценарными прогонами выполнить:

```bash
bash scripts/check_npc_lifecycle_contract.sh
```

Проверка валидирует, что `src/modules/npc/npc_core.nss` соответствует текущему lifecycle-контракту и не дублирует legacy area lifecycle vars.

## Источник истины

- Core-реализация lifecycle/queue/handlers: `src/modules/npc/npc_core.nss`.
- Контрактные ожидания и паттерны проверки: `scripts/contracts/npc.contract`.

При обновлении сценариев и терминов синхронизируйте названия только с этими двумя файлами, чтобы избежать повторного дрейфа.

## Scenario A — Burst fairness без starvation

1. Поднять area в состоянии `RUNNING` (`NpcBhvrAreaActivate`).
2. Создать burst событий в очередь с mix приоритетов: LOW/NORMAL/HIGH/CRITICAL.
3. Прогнать не менее 120 area-tick итераций.
4. Проверить, что LOW/NORMAL события не голодают: каждый bucket получает обработку в пределах окна 10 tick.

Ожидаемый результат:
- отсутствует бесконечный starvation для LOW/NORMAL;
- `deferred_count` растёт только при реальном budget limit;
- overflow не происходит в номинале.

## Scenario B — Pause/resume без потери очереди

1. Запустить area в `RUNNING` и накопить pending очередь.
2. Перевести area в `PAUSED` через module API (`NpcBhvrAreaPause`).
3. Убедиться, что entrypoint `npc_area_tick.nss` (handler `NpcBhvrOnAreaTick`) не обрабатывает очередь до возврата `RUNNING`.
4. Вернуть `RUNNING` через `NpcBhvrAreaActivate`, продолжить тики и сравнить pending до/после.

Ожидаемый результат:
- во время `PAUSED` нет роста `processed_count`;
- после возврата в `RUNNING` очередь дренируется в штатном порядке;
- `overflow_count` не увеличивается только из-за pause/resume.

## Scenario C — Stop/start с корректным таймером

1. Запустить area в `RUNNING`, убедиться что таймер один (`nb_area_timer_running=TRUE`).
2. Перевести в `STOPPED` (`NpcBhvrAreaStop`) и дождаться остановки loop.
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

Контракт CSV: все используемые числовые поля (`tick` и любые задействованные `processed_*`) должны быть валидными `int`. При нечисловом значении анализатор завершает работу fail-fast с кодом `2` и сообщением вида `[FAIL] invalid numeric value ...`.

Контракт lifecycle-state: входной профиль обязан содержать хотя бы одну строку с `lifecycle_state=RUNNING`; если `RUNNING`-строки отсутствуют, анализатор завершает работу с кодом `2` и сообщением `[FAIL] no RUNNING rows in input`.

### Рекомендованные профили для «следующего шага» Task 3.2

Два минимальных fixture-профиля покрывают длительный burst и fault-injection на pause/resume:

```bash
# Длительный burst: проверка starvation-window при доминирующем HIGH/CRITICAL потоке
python3 scripts/analyze_area_queue_fairness.py \
  --input docs/perf/fixtures/area_queue_fairness_long_burst.csv \
  --max-starvation-window 2 \
  --buckets LOW,NORMAL

# Fault-injection pause/resume: проверка pause-zero + восстановления дренажа после resume
python3 scripts/analyze_area_queue_fairness.py \
  --input docs/perf/fixtures/area_queue_fairness_pause_resume_fault_injection.csv \
  --max-starvation-window 3 \
  --buckets LOW,NORMAL \
  --enforce-pause-zero \
  --min-resume-transitions 3 \
  --max-post-resume-drain-ticks 1
```

Новые CLI-флаги:
- `--min-resume-transitions` — гарантирует, что профиль действительно содержит нужное число циклов pause/resume.
- `--max-post-resume-drain-ticks` — ограничивает число `RUNNING` тиков после resume до первой обработки отслеживаемых bucket.

Для локальной регрессии CLI-проверок используйте `bash scripts/test_area_queue_fairness_analyzer.sh` — он проверяет как pass-профили, так и ожидаемые fail-кейсы (pause-zero, минимальные resume-переходы, post-resume drain latency и отсутствие `RUNNING`-строк).
