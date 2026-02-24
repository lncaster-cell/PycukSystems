# `src/controllers` — контракт каталога

## Что будет размещаться
- Area-tick контроллеры и планировщики выполнения (bucketization, jitter, step-based execution).
- Политики распределения нагрузки между «hot/cold» наборами NPC.
- Экспериментальные/будущие runtime-контроллеры, которые ещё не включены в боевой контур.

## Текущее состояние
- `lifecycle_controller.nss` сохранён как legacy-placeholder без экспортируемого API.
- Единственный источник истины для area lifecycle (`RUNNING/PAUSED/STOPPED`) находится в `src/modules/npc/npc_core.nss`.
- Runtime timer-loop, state-переходы и queue lifecycle не должны дублироваться в `src/controllers/*`.

## Критерий готовности
Каталог считается готовым к первой фазе, когда:
1. Реализован рабочий area-controller с управлением tick budget и очередями.
2. Поддержаны предсказуемые переходы lifecycle и базовая защита от перегрузки (defer/skip/overflow policy).
3. Есть воспроизводимые сценарные проверки fairness и latency (p95) для area orchestration.

## Связанные design-доки
- Архитектурная концепция: `docs/design.md`.
- Runtime-контракт оркестрации: `docs/npc_runtime_orchestration.md`.
- Backlog реализации: `docs/npc_implementation_backlog.md`.
- Perf-сценарии fairness: `docs/perf/npc_area_queue_fairness_scenarios.md`.
- Быстрая статическая проверка контракта: `bash scripts/check_npc_lifecycle_contract.sh`.
