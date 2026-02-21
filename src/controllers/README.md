# `src/controllers` — контракт каталога

## Что будет размещаться
- Area-tick контроллеры и планировщики выполнения (bucketization, jitter, step-based execution).
- Политики распределения нагрузки между «hot/cold» наборами NPC.
- Контроллеры lifecycle уровня area (`RUNNING/PAUSED/STOPPED`) и их runtime-конфиги.


## Реализовано (Phase 1, Task 3.2/3.3)
- `lifecycle_controller.nss` — state machine для area lifecycle: `RUNNING/PAUSED/STOPPED`.
- Контракт совместимости: при смене lifecycle синхронизируется legacy-флаг `nb_area_active` для существующих проверок.
- Управление timer-loop вынесено в `NpcControllerAreaIsTimerRunning/SetTimerRunning`, чтобы предотвращать duplicate loops.

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
