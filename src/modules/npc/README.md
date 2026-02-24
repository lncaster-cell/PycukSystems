# NPC behavior runtime contour

Каталог содержит официальный подготовительный runtime-контур для NPC.

> Примечание по неймингу: префикс `NpcBhvr*` в именах функций и константа `NPC_BHVR_*`
> сохранены как часть уже принятого API-контракта, но сам модуль в документации
> далее именуется просто `NPC`.


## Готовый модуль: что подключать в toolset

Используйте модуль как готовый runtime-пакет из `src/modules/npc/`:

1. Подключите event hooks к thin-entrypoint скриптам (таблица «Карта hook-скриптов» ниже).
2. Убедитесь, что include `npc_core` доступен всем entrypoint-файлам `npc_*.nss` / `npc_behavior_*.nss`.
3. Для приёмки запустите smoke/contract проверки:
   - `bash scripts/test_npc_smoke.sh`
   - `bash scripts/check_npc_lifecycle_contract.sh`
   - `bash scripts/test_npc_fairness.sh`

После этих шагов модуль считается готовым к интеграции в модуль NWN2 (при корректной привязке hook-скриптов).

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- RUNNING loop рескейджулится только в состоянии `RUNNING`; в `PAUSED` используется отдельный редкий watchdog-тик (`30s`) с отдельной метрикой.
- Реализована bounded queue (`NPC_BHVR_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.
- `npc_pending_updated_at` хранится как `int`-timestamp с секундной точностью (на базе календарного дня и `HH:MM:SS`) и при частых обновлениях монотонно увеличивается минимум на 1.

## Базовые include-файлы

- `npc_core.nss` — lifecycle area-controller, bounded queue с приоритетами, routing хуков в core.
- `npc_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `npc_metrics_inc.nss` — единый helper API для метрик (`NpcBhvrMetricInc/Add`).

Tick/degraded telemetry в runtime включает:
- `npc_metric_processed_total` (обработанные события за тик без двойного инкремента),
- `npc_metric_tick_budget_exceeded_total`, `npc_metric_degraded_mode_total`,
- `npc_metric_degradation_events_total`,
- reason-specific: `npc_metric_degradation_by_reason_event_budget_total`, `npc_metric_degradation_by_reason_soft_budget_total`, `npc_metric_degradation_by_reason_empty_queue_total`, `npc_metric_degradation_by_reason_overflow_total`, `npc_metric_degradation_by_reason_queue_pressure_total`, `npc_metric_degradation_by_reason_route_miss_total`, `npc_metric_degradation_by_reason_disabled_total`,
- `npc_tick_last_degradation_reason` всегда отражает последний reason-code деградации (включая `OVERFLOW|QUEUE_PRESSURE|ROUTE_MISS|DISABLED`);
- `npc_metric_diagnostic_dropped_total` для нераспознанных reason-code.


## Activity primitives runtime-контракт

`npc_activity_inc.nss` теперь фиксирует минимальный runtime-layer поверх AL-подхода через `npc_*` keyspace (без прямого использования `al_*` locals в core-flow):

- AL-понятия (`slot-group`, `route-profile`, `activity transition`) обязаны проходить через adapter-helpers include-файла:
  - `NpcBhvrActivityAdapterNormalizeSlot`,
  - `NpcBhvrActivityAdapterNormalizeRoute`,
  - `NpcBhvrActivityMapRouteHint`,
  - `NpcBhvrActivityResolveRouteProfile`,
  - `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty`,
  - `NpcBhvrActivityAdapterStampTransition`.

- Spawn-инициализация профиля NPC (`NpcBhvrActivityOnSpawn`) обязана выставлять:
  - `npc_activity_slot` (по умолчанию `default`),
  - `npc_activity_route` (явно сконфигурированный route-profile на NPC; если пусто — используется fallback-цепочка),
  - `npc_activity_route_effective` (диагностическое зеркало effective route-profile после fallback-резолва),
  - `npc_activity_slot_fallback` (`0|1`, признак fallback в `default` при невалидном slot),
  - `npc_activity_state` (начальное состояние `spawn_ready`),
  - `npc_activity_cooldown` (неотрицательный cooldown/state gate),
  - `npc_activity_last` (последняя activity transition),
  - `npc_activity_last_ts` (timestamp последнего transition в секундах игрового времени),
  - `npc_activity_wp_index|npc_activity_wp_count|npc_activity_wp_loop` (текущее состояние маршрута по waypoint-позициям),
  - `npc_activity_route_tag` (идентификатор route-tag для state-композера),
  - `npc_activity_slot_emote` (resolved ambient emote для активного slot, с fallback `NPC-slot -> area-slot -> area-global -> NPC-global`),
  - `npc_activity_action` (resolved action-token для игрового runtime-dispatch: `guard_hold|patrol_move|patrol_scan|patrol_ready|ambient_*`).
- Резолв route-profile (`NpcBhvrActivityResolveRouteProfile`) выполняется по цепочке fallback без `al_*` keyspace:
  1) `npc_activity_route` на NPC (если явно задан);
  2) `npc_route_profile_slot_<slot>` на NPC;
  3) `npc_route_profile_default` на NPC;
  4) area-level cache `npc_route_cache_slot_<slot>` (при первом обращении заполняется из area locals);
  5) area-level cache `npc_route_cache_default`;
  6) `default_route`.
- Lifecycle area cache:
  - `routes_cached` (`0|1`) — признак валидного area-level cache;
  - `routes_cache_version` — монотонная версия cache (увеличивается на invalidate/warmup-cycle);
  - `NpcBhvrAreaRouteCacheWarmup` выполняет первичный prewarm при активации area-loop и идемпотентен при повторных вызовах (без полного re-scan);
  - `NpcBhvrAreaRouteCacheInvalidate` очищает cache и переводит следующий resolve в controlled rescan/warmup.
- Контракт idempotent warmup: повторные `OnEnter/Resolve` в той же area без invalidate должны приводить к cache hit-path, без роста `*_rescan_total`.
- `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty` отбрасывает невалидные route-id (не входящие в `default_route|priority_patrol|critical_safe`), чтобы fallback-цепочка не блокировалась мусорными значениями.
- При отбрасывании невалидного route-id инкрементируются диагностические метрики:
  - `npc_metric_activity_invalid_route_total` — любой невалидный route в activity fallback-цепочке;
  - `npc_metric_activity_invalid_route_npc_local_total` — невалидный route найден в `NPC-local` источнике (`npc_activity_route`, `npc_route_profile_slot_<slot>`, `npc_route_profile_default` на NPC);
  - `npc_metric_activity_invalid_route_area_local_total` — невалидный route найден в `area-local` источнике (`npc_route_profile_slot_<slot>`, `npc_route_profile_default` на area).
  - `npc_metric_route_cache_warmup_total` — количество успешных warmup-cycle;
  - `npc_metric_route_cache_rescan_total` — количество полных area-rescan при пустом/инвалидированном cache;
  - `npc_metric_route_cache_hit_ratio` — отношение hit/miss cache в процентах (`0..100`).
- Idle-dispatch (`NpcBhvrActivityOnIdleTick`) работает как адаптерный диспетчер `slot/route`:
  - CRITICAL-safe ветка (приоритет №1): `slot=critical` **или** route-map -> `critical_safe`;
  - priority-ветка (приоритет №2): `slot=priority` **или** route-map -> `priority_patrol`;
  - fallback: `default_route` c состоянием `idle_default`.
- Mapping-слой (`NpcBhvrActivityMapRouteHint`) выполняет трансляцию route-id -> activity hint, чтобы AL-семантика подключалась через адаптер, а не через прямой `al_*` namespace.
- Примитивы `NpcBhvrActivityApplyCriticalSafeRoute/NpcBhvrActivityApplyPriorityRoute/NpcBhvrActivityApplyDefaultRoute` выполняются через единый helper `NpcBhvrActivityApplyRouteState` и теперь дополнительно обновляют waypoint/runtime locals.
- Route-point/waypoint контракт задаётся через `npc_*`-locals (без `al_*` keyspace):
  - `npc_route_count_<routeId>` — количество waypoint-узлов в route (NPC-local приоритетнее area-local);
  - `npc_route_loop_<routeId>` — loop policy (`>0` loop enabled, `<0` loop disabled, `0` = default enabled);
  - `npc_route_tag_<routeId>` — route-tag для генерации состояния формата `<base_state>_<tag>_<index>_of_<count>`;
  - `npc_route_pause_ticks_<routeId>` — добавка к cooldown после dispatch для route-point pacing.

### Контракт входных/выходных состояний activity primitives

- **Вход для `NpcBhvrActivityOnSpawn`:** валидный `oNpc`; любые/пустые значения `npc_activity_slot|route`; опциональные route-profile fallback locals `npc_route_profile_slot_<slot>` и `npc_route_profile_default` на NPC/area; `npc_activity_cooldown` может быть отрицательным.
- **Выход `NpcBhvrActivityOnSpawn`:**
  - `slot` нормализован в поддерживаемые значения (`default|priority|critical`),
  - `npc_activity_route` сохраняет только явно заданный route (или очищается, если route не задан),
  - `npc_activity_route_effective` выставляется как effective route-profile (`default_route|priority_patrol|critical_safe`) после fallback-резолва,
  - `state=spawn_ready`,
  - `last=spawn_ready`,
  - `last_ts` обновлён,
  - `cooldown >= 0`,
  - waypoint-runtime locals нормализованы и готовы к первому idle-dispatch.
- **Вход для `NpcBhvrActivityOnIdleTick`:** валидный `oNpc`; допускаются пустые/невалидные `slot/route` (slot нормализуется, невалидный route отбрасывается и заменяется fallback-резолвом).
- **Допустимые значения `slot`:** только `default|priority|critical`. Любое другое значение (включая пустую строку) считается невалидным и принудительно нормализуется в `default`.
- **Выход `NpcBhvrActivityOnIdleTick`:**
  - при `cooldown > 0` выполняется только декремент cooldown на 1 и early-return;
  - при невалидном `slot` выставляется `npc_activity_slot_fallback=1` и инкрементируется метрика `npc_metric_activity_invalid_slot_total`;
  - при `cooldown == 0` выполняется ровно одна ветка диспетчера:
    1) `critical_safe` -> `state/last=idle_critical_safe`, `cooldown=1`;
    2) `priority_patrol` -> `state/last=idle_priority_patrol`, `cooldown=2`;
    3) `default` -> `state/last=idle_default`, `cooldown=1`;
  - если для route есть `npc_route_count_<routeId> > 0` и `npc_route_tag_<routeId>`, то `state/last` получают waypoint-суффикс (`..._<tag>_<i>_of_<N>`), а `npc_activity_wp_index` продвигается с учётом loop-policy;
  - после dispatch `last_ts` всегда отражает момент последнего transition;
  - `npc_activity_action` пересчитывается на каждом dispatch в зависимости от slot/route/waypoint parity и может использоваться внешним runtime для привязки анимаций/поведенческих команд.


## Контракт pending-состояний (NPC-local и area-local)

- Источник истины для pending-статуса — `NPC-local` (`npc_pending_*` на объекте NPC).
- `area-local` (`npc_queue_pending_*` на area) — диагностическое/наблюдаемое зеркало последнего состояния, обновляется через `NpcBhvrPendingAreaTouch`.
- `deferred` при `GetArea(oSubject) != oArea` фиксируется **в обоих хранилищах** и не очищается неявно в этом же шаге.
- Очистка pending (`NpcBhvrPendingNpcClear` и `NpcBhvrPendingAreaClear`) допустима только на явных terminal-переходах (`processed`, `dropped`, удаление/смерть NPC, очистка очереди/area shutdown).
- Следствие: deferred является краткоживущим состоянием до следующего события/terminal-перехода, но в течение этого окна наблюдается консистентно и в NPC-local, и в area-local.


## Canonical runtime references

- Runtime module: `src/modules/npc/*`
- Runtime backlog: `docs/npc_implementation_backlog.md`
- Runtime checklist: `docs/npc_phase1_test_checklist.md`
- Perf gate: `docs/perf/npc_perf_gate.md`

## Current readiness snapshot

- **Runtime MVP:** `READY` — core lifecycle/queue/activity/metrics и thin-entrypoints подключены в `src/modules/npc/*`.
- **Fairness/lifecycle self-check:** `READY` — автоматические проверки доступны через `scripts/test_npc_fairness.sh` и `scripts/check_npc_lifecycle_contract.sh`.
- **Perf baseline/perf-gate:** `BLOCKED` — актуальный валидный baseline (>=3 runs, <=14 days) отсутствует; см. `docs/perf/npc_baseline_report.md`.
- **Runtime dashboards:** `BLOCKED` — артефакты конфигураций дашбордов не зафиксированы в репозитории.

## Карта hook-скриптов (thin entrypoints)

| Hook | Script | Core handler |
| --- | --- | --- |
| OnSpawn | `npc_spawn.nss` | `NpcBhvrOnSpawn` |
| OnPerception | `npc_perception.nss` | `NpcBhvrOnPerception` |
| OnDamaged | `npc_damaged.nss` | `NpcBhvrOnDamaged` |
| OnDeath | `npc_death.nss` | `NpcBhvrOnDeath` |
| OnDialogue | `npc_dialogue.nss` | `NpcBhvrOnDialogue` |
| Area OnEnter | `npc_area_enter.nss` | `NpcBhvrOnAreaEnter` |
| Area OnExit | `npc_area_exit.nss` | `NpcBhvrOnAreaExit` |
| OnModuleLoad | `npc_module_load.nss` | `NpcBhvrOnModuleLoad` |
| Area tick loop | `npc_area_tick.nss` | `NpcBhvrOnAreaTick` |

## Норматив

**Правило:** entrypoint-скрипт не содержит бизнес-логики.

Допустимо только:
- подключение `npc_core`;
- получение event-context (`OBJECT_SELF`, `GetEnteringObject()`, `GetExitingObject()`);
- прямой вызов одного core-handler.

Недопустимо:
- прямые `SetLocal*`/`GetLocal*` для доменной логики в entrypoints;
- манипуляции очередью/lifecycle вне `npc_core.nss`;
- запись метрик вне `NpcBhvrMetricInc/Add`.
