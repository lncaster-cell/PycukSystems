# Module 3 behavior runtime contour (skeleton)

Каталог содержит официальный подготовительный runtime-контур для Module 3.

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- Реализована bounded queue (`MODULE3_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.

## Базовые include-файлы

- `module3_core.nss` — lifecycle area-controller, bounded queue с приоритетами, routing хуков в core.
- `module3_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `module3_metrics_inc.nss` — единый helper API для метрик (`Module3MetricInc/Add`).

## Карта hook-скриптов (thin entrypoints)

| Hook | Script | Core handler |
| --- | --- | --- |
| OnSpawn | `module3_behavior_spawn.nss` | `Module3OnSpawn` |
| OnPerception | `module3_behavior_perception.nss` | `Module3OnPerception` |
| OnDamaged | `module3_behavior_damaged.nss` | `Module3OnDamaged` |
| OnDeath | `module3_behavior_death.nss` | `Module3OnDeath` |
| OnDialogue | `module3_behavior_dialogue.nss` | `Module3OnDialogue` |
| Area OnEnter | `module3_behavior_area_enter.nss` | `Module3OnAreaEnter` |
| Area OnExit | `module3_behavior_area_exit.nss` | `Module3OnAreaExit` |
| OnModuleLoad | `module3_behavior_module_load.nss` | `Module3OnModuleLoad` |
| Area tick loop | `module3_behavior_area_tick.nss` | `Module3OnAreaTick` |

## Норматив

**Правило:** entrypoint-скрипт не содержит бизнес-логики.

Допустимо только:
- подключение `module3_core`;
- получение event-context (`OBJECT_SELF`, `GetEnteringObject()`, `GetExitingObject()`);
- прямой вызов одного core-handler.

Недопустимо:
- прямые `SetLocal*`/`GetLocal*` для доменной логики в entrypoints;
- манипуляции очередью/lifecycle вне `module3_core.nss`;
- запись метрик вне `Module3MetricInc/Add`.
