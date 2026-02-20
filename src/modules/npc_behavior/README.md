# NPC Behavior Module (Phase 1 MVP)

Стартовая реализация модуля поведения NPC по плану первой итерации из `docs/design.md` и `docs/npc_runtime_orchestration.md`.

## Входные скрипты

- `npc_behavior_tick.nss` — area-tick обработчик с лимитом `nProcessLimit` и базовым pacing по состоянию NPC.
- `npc_behavior_perception.nss` — обработчик perception-событий, переключает NPC между `IDLE/ALERT/COMBAT` и считает deferred-сигналы.
- `npc_behavior_combat.nss` — синхронизатор состояния COMBAT/ALERT на боевых хуках.

## Что покрыто в MVP

- разделение fast-path на `COMBAT` и `IDLE/ALERT`;
- ограничение обработок за тик (`nProcessLimit`) как первый budget cap;
- заготовка метрик через Local Variables на NPC/Area (`npc_processed_in_tick`, `npc_deferred_events`).

## Следующий шаг

1. Добавить bounded queue + coalesce окно на уровне area orchestrator.
2. Подключить write-behind персистентность состояния в SQLite (через NWNX SQL).
3. Вывести runtime-метрики в отдельный модуль наблюдаемости.
