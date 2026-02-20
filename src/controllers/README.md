# `src/controllers` — контракт каталога

## Что будет размещаться
- Area-tick контроллеры и планировщики выполнения (bucketization, jitter, step-based execution).
- Политики распределения нагрузки между «hot/cold» наборами NPC.
- Контроллеры lifecycle уровня area (`RUNNING/PAUSED/STOPPED`) и их runtime-конфиги.

## Критерий готовности
Каталог считается готовым к первой фазе, когда:
1. Реализован рабочий area-controller с управлением tick budget и очередями.
2. Поддержаны предсказуемые переходы lifecycle и базовая защита от перегрузки (defer/skip/overflow policy).
3. Есть воспроизводимые сценарные проверки fairness и latency (p95) для area orchestration.

## Связанные design-доки
- Архитектурная концепция: `docs/design.md`.
- Runtime-контракт оркестрации: `docs/npc_runtime_orchestration.md`.
- Backlog реализации: `docs/npc_implementation_backlog.md`.
