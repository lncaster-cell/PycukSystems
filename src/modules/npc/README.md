# NPC behavior runtime contour

Каталог содержит официальный подготовительный runtime-контур для NPC.

> Примечание по неймингу: префикс `NpcBhvr*` в именах функций и константа `NPC_BHVR_*`
> сохранены как часть уже принятого API-контракта, но сам модуль в документации
> далее именуется просто `NPC`.


## Готовый модуль: что подключать в toolset

Используйте модуль как готовый runtime-пакет из `src/modules/npc/`:

1. Подключите event hooks к thin-entrypoint скриптам (таблица «Карта hook-скриптов» ниже).
2. Убедитесь, что include `npc_core` доступен всем entrypoint-файлам `npc_*.nss`.
3. Для приёмки запустите smoke/contract проверки:
   - `bash scripts/test_npc_smoke.sh`
   - `bash scripts/check_npc_lifecycle_contract.sh`
   - `bash scripts/test_npc_fairness.sh`

После этих шагов модуль считается готовым к интеграции в модуль NWN2 (при корректной привязке hook-скриптов).

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- RUNNING loop рескейджулится только в состоянии `RUNNING`; в `PAUSED` используется отдельный редкий watchdog-тик (`30s`) с отдельной метрикой.
- Тяжёлый deferred full-reconcile вынесен из hot-path `NpcBhvrOnAreaTick` в отдельный maintenance entrypoint `npc_area_maintenance` (редкий watchdog + state transitions pause/resume/stop).
- Реализована bounded queue (`NPC_BHVR_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Coalesce повторных enqueue выполняется напрямую в `NpcBhvrQueueEnqueue`: существующий pending-subject не дублируется, а его приоритет пересчитывается через `NpcBhvrPriorityEscalate` (включая эскалацию `damage -> CRITICAL`).
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.
- `npc_pending_updated_at` хранится как `int`-timestamp с секундной точностью (на базе календарного дня и `HH:MM:SS`) и при частых обновлениях монотонно увеличивается минимум на 1.
- Tick perf-budget runtime API (боевой путь): `NpcBhvrSetTickMaxEvents` и `NpcBhvrSetTickSoftBudgetMs` применяются через `NpcBhvrApplyTickRuntimeConfig` в bootstrap (`NpcBhvrBootstrapModuleAreas`) и при активации area (`NpcBhvrAreaActivate`), с override-цепочкой `area cfg -> module cfg -> defaults` по ключам `npc_cfg_tick_max_events` и `npc_cfg_tick_soft_budget_ms`.

## Базовые include-файлы

- `npc_core.nss` — константы, runtime-internal declarations между include-юнитами и thin entrypoint-обёртки.
- `npc_queue_inc.nss` — queue/pending/deferred internals (`NpcBhvrQueue*`, `NpcBhvrPending*`, overflow/deferred guardrails).
- `npc_queue_pending_compat_inc.nss` — legacy-обёртки `NpcBhvrPending*` без суффикса `At` (оставлены только для внешней совместимости, runtime использует `*At`).
- `npc_tick_inc.nss` — tick orchestration и бюджет/деградация (`NpcBhvrTick*`, runtime budget config, degraded carryover).
- `npc_lifecycle_inc.nss` — area/player lifecycle (`NpcBhvrOnAreaEnter/Exit`, player-count cache, activate/pause/stop, module bootstrap).
- `npc_registry_inc.nss` — registry internals (`NpcBhvrRegistry*`, индекс/слоты, idle broadcast).
- `npc_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `npc_metrics_inc.nss` — единый helper API для метрик (`NpcBhvrMetricInc/Add`).

### Deprecated/compat API

- `npc_legacy_compat_inc.nss` — **external-only** legacy include (не подключается `npc_core` и не участвует в основном runtime).
  Поддерживаемые legacy-обёртки:
  - `NpcBhvrAreaSetState`
  - `NpcBhvrCountPlayersInArea`
  - `NpcBhvrCountPlayersInAreaExcluding`
  - `NpcBhvrGetCachedPlayerCount`
  - `NpcBhvrRegistryBroadcastIdleTick`
  - `NpcBhvrQueuePackLocation`
- `npc_compat_inc.nss` оставлен как runtime-empty заглушка для обратной совместимости по имени include.
- В текущем runtime-контуре (`npc_tick_inc`, `npc_lifecycle_inc`, `npc_registry_inc`, `npc_queue_index_inc`) используются только внутренние версии API:
  - `NpcBhvrAreaSetStateInternal`
  - `NpcBhvrCountPlayersInAreaInternalApi`
  - `NpcBhvrCountPlayersInAreaExcludingInternalApi`
  - `NpcBhvrGetCachedPlayerCountInternal`
  - `NpcBhvrRegistryBroadcastIdleTickBudgeted`

Tick/degraded telemetry в runtime включает:
- `npc_metric_processed_total` (обработанные события за тик без двойного инкремента),
- `npc_metric_tick_budget_exceeded_total`, `npc_metric_degraded_mode_total`,
- `npc_metric_degradation_events_total`,
- `npc_metric_maintenance_self_heal_count` (количество self-heal reconcile в maintenance loop),
- `npc_metric_idle_budget_throttled_total` (сколько тиков idle-budget был снижен adaptive-throttling),
- `npc_tick_last_degradation_reason` всегда отражает последний reason-code деградации (включая `EVENT_BUDGET|SOFT_BUDGET|OVERFLOW|QUEUE_PRESSURE|ROUTE_MISS|DISABLED`);

- Tick budget-параметры (`npc_tick_max_events`, `npc_tick_soft_budget_ms`) нормализуются и фиксируются при `NpcBhvrAreaActivate` через `NpcBhvrSetTickMaxEvents/NpcBhvrSetTickSoftBudgetMs` (с hard-cap), после чего используются в `NpcBhvrOnAreaTick`.

### Perf-budget runtime application

- Runtime-пределы тика (`max events` и `soft budget ms`) применяются через `NpcBhvrApplyTickRuntimeConfig`.
- Источники конфигурации (по приоритету): area-local (`npc_cfg_tick_max_events`, `npc_cfg_tick_soft_budget_ms`) -> module-local (те же ключи на `GetModule()`) -> встроенные defaults (`NPC_BHVR_TICK_MAX_EVENTS_DEFAULT`, `NPC_BHVR_TICK_SOFT_BUDGET_MS_DEFAULT`).
- Точка применения в lifecycle: bootstrap всех областей на module-load и каждое `NpcBhvrAreaActivate`, чтобы настройки оставались консистентными после pause/resume.

- Idle broadcast budget адаптивный: при queue-pressure (`pending_total` выше runtime-порога от `npc_tick_max_events`, `npc_tick_soft_budget_ms` и `npc_tick_carryover_events`) применяется throttling `NPC_BHVR_IDLE_MAX_NPC_PER_TICK_DEFAULT`, при нормализации очереди budget автоматически возвращается к базовому значению.


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
  - `npc_activity_cooldown_until_ts` (deadline cooldown/state gate в timestamp-тиках от `NpcBhvrPendingNow()`),
  - `npc_activity_cooldown` (legacy fallback, read-only для миграции уже созданных NPC),
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
- `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty` отбрасывает невалидные route-id (не входящие в `default_route|priority_patrol|critical_safe`), чтобы fallback-цепочка не блокировалась мусорными значениями, и завершает нормализацию через `NpcBhvrActivityAdapterNormalizeRoute` как канонический adapter-step.
- При отбрасывании невалидного route-id инкрементируется `npc_metric_activity_invalid_route_total`.
- Idle-dispatch (`NpcBhvrActivityOnIdleTick`) работает как адаптерный диспетчер `slot/route`:
  - CRITICAL-safe ветка (приоритет №1): `slot=critical` **или** route-map -> `critical_safe`;
  - priority-ветка (приоритет №2): `slot=priority` **или** route-map -> `priority_patrol`;
  - fallback: `default_route` c состоянием `idle_default`.
- Mapping-слой (`NpcBhvrActivityMapRouteHint`) выполняет трансляцию route-id -> activity hint, чтобы AL-семантика подключалась через адаптер, а не через прямой `al_*` namespace.
- В `npc_activity_inc.nss` перенесён data-layer AmbientLiveV2 активностей (legacy `al_acts_inc.nss`) с полной линейкой activity-id и runtime metadata-резолверами:
  - custom anims, numeric anims, waypoint-tag requirements, training/bar pair flags;
  - route-point activity id читается через `npc_route_activity_<routeId>_<index>` (NPC-local -> area-local) и пробрасывается в locals `npc_activity_id|custom_anims|numeric_anims|waypoint_tag|requires_*`.
- Примитивы `NpcBhvrActivityApplyCriticalSafeRoute/NpcBhvrActivityApplyPriorityRoute/NpcBhvrActivityApplyDefaultRoute` выполняются через единый helper `NpcBhvrActivityApplyRouteState` и теперь дополнительно обновляют waypoint/runtime locals.
- Route-point/waypoint контракт задаётся через `npc_*`-locals (без `al_*` keyspace):
  - `npc_route_count_<routeId>` — количество waypoint-узлов в route (NPC-local приоритетнее area-local);
  - `npc_route_loop_<routeId>` — loop policy (`>0` loop enabled, `<0` loop disabled, `0` = default enabled);
  - `npc_route_tag_<routeId>` — route-tag для генерации состояния формата `<base_state>_<tag>_<index>_of_<count>`;
  - `npc_route_pause_ticks_<routeId>` — добавка к cooldown после dispatch для route-point pacing.

### Контракт входных/выходных состояний activity primitives

- **Вход для `NpcBhvrActivityOnSpawn`:** валидный `oNpc`; любые/пустые значения `npc_activity_slot|route`; опциональные route-profile fallback locals `npc_route_profile_slot_<slot>` и `npc_route_profile_default` на NPC/area; `npc_activity_cooldown_until_ts` может быть отрицательным.
- **Выход `NpcBhvrActivityOnSpawn`:**
  - `slot` нормализован в поддерживаемые значения (`default|priority|critical`),
  - `npc_activity_route` сохраняет только явно заданный route (или очищается, если route не задан),
  - `npc_activity_route_effective` выставляется как effective route-profile (`default_route|priority_patrol|critical_safe`) после fallback-резолва,
  - `state=spawn_ready`,
  - `last=spawn_ready`,
  - `last_ts` обновлён,
  - `cooldown_until_ts >= 0`,
  - waypoint-runtime locals нормализованы и готовы к первому idle-dispatch.
- **Вход для `NpcBhvrActivityOnIdleTick`:** валидный `oNpc`; допускаются пустые/невалидные `slot/route` (slot нормализуется, невалидный route отбрасывается и заменяется fallback-резолвом).
- **Допустимые значения `slot`:** только `default|priority|critical`. Любое другое значение (включая пустую строку) считается невалидным и принудительно нормализуется в `default`.
- **Выход `NpcBhvrActivityOnIdleTick`:**
  - при активном cooldown (`npc_activity_cooldown_until_ts > now`) выполняется early-return без записи;
  - при невалидном `slot` выставляется `npc_activity_slot_fallback=1` и инкрементируется метрика `npc_metric_activity_invalid_slot_total`;
  - при неактивном cooldown выполняется ровно одна ветка диспетчера:
    1) `critical_safe` -> `state/last=idle_critical_safe`, `cooldown_until_ts=now+1`;
    2) `priority_patrol` -> `state/last=idle_priority_patrol`, `cooldown_until_ts=now+2`;
    3) `default` -> `state/last=idle_default`, `cooldown_until_ts=now+1`;
  - если для route есть `npc_route_count_<routeId> > 0` и `npc_route_tag_<routeId>`, то `state/last` получают waypoint-суффикс (`..._<tag>_<i>_of_<N>`), а `npc_activity_wp_index` продвигается с учётом loop-policy;
  - после dispatch `last_ts` всегда отражает момент последнего transition;
  - `npc_activity_action` пересчитывается на каждом dispatch в зависимости от slot/route/waypoint parity и может использоваться внешним runtime для привязки анимаций/поведенческих команд.

## Плановое "повседневное" поведение NPC (schedule-aware slot)

Для подготовки модуля к тестам поведения "NPC живут по расписанию" добавлен schedule-aware выбор slot на `spawn` и `idle tick`:

- Флаг включения: `npc_activity_schedule_enabled` на NPC или area (`1` включает планировщик).
- Окна задаются локалами по слотам:
  - `npc_schedule_start_critical` / `npc_schedule_end_critical`,
  - `npc_schedule_start_priority` / `npc_schedule_end_priority`.
- Правила интерпретации окна:
  - `start == end` -> специальный «пустой» window (в `NpcBhvrActivityIsHourInWindow` возвращается `FALSE`, т.е. слот по этому окну никогда не активируется);
  - `start < end` -> обычное дневное окно `[start, end)`;
  - `start > end` -> ночное окно с переходом через полночь (например, `22 -> 6`).
- Причина для `start == end`: защита от неявного always-on, когда ключи расписания отсутствуют и `GetLocalInt` даёт `0` для `start/end`.
- Приоритет резолва slot по расписанию: `critical` -> `priority` -> `default`.
- Публичная точка резолва для scheduling API: `NpcBhvrActivityResolveScheduledSlotForContext(oNpc, sCurrentSlot, bScheduleEnabled, nResolvedHour)`; вызывающая сторона обязана передать уже вычисленные context-параметры (`bScheduleEnabled`, `nResolvedHour`).
- Если расписание выключено, сохраняется текущий runtime slot после нормализации.

Smoke-композит теперь включает `scripts/test_npc_activity_schedule_contract.sh` для валидации этих инвариантов.

## Identifier constraints

Для route-идентификаторов и route-tag в `npc_activity_inc.nss` действует единая политика нормализации перед построением runtime key/state:

- Допустимые символы: только `a-z`, `0-9`, `_`.
- Пустые значения запрещены (`non-empty`).
- `routeId`:
  - минимальная длина: `1`;
  - максимальная длина: `32`.
- `routeTag`:
  - минимальная длина: `1`;
  - максимальная длина: `24`.
- При нарушении ограничений инкрементируется `npc_metric_activity_invalid_route_total`, а runtime использует детерминированный fallback:
  - `routeId` -> `default_route`;
  - `routeTag` -> `default`.

Примеры:

- Допустимые `routeId`: `default_route`, `priority_patrol`, `critical_safe`.
- Недопустимые `routeId`: `""` (empty), `priority-patrol` (символ `-`), `Priority` (верхний регистр), строка длиннее 32.
- Допустимые `routeTag`: `market_lane`, `north_gate_2`, `default`.
- Недопустимые `routeTag`: `""` (empty), `market lane` (пробел), `tag!` (символ `!`), строка длиннее 24.



### Runtime split (hot-path mapping)

- `npc_queue_inc.nss` — **queue hot-path**: enqueue/dequeue, drop/overflow guardrails, deferred reconcile/trim.
- `npc_tick_inc.nss` — **tick hot-path**: budgeted processing, degradation/carryover, deferred reconcile stage.
- `npc_lifecycle_inc.nss` — **lifecycle hot-path**: area/player enter-exit, player-count cache, area activate/pause/stop, loop orchestration.
- `npc_core.nss` — стабильная фасадная точка include: константы + runtime-internal declarations + тонкие wrappers entrypoint-ов.

## Ограничения длины идентификаторов (NWN2) и safe-лимиты

Перед интеграцией контента разделяйте **формальный engine-лимит** и **операционный safe-limit**:

- **Engine/формальный лимит**: идентификаторы в NWN2 обычно проходят до `63` символов (байтов) без немедленной ошибки компиляции/сохранения.
- **Operational safe-limit (рекомендуется для production-контента)**: держать длину в диапазоне `<= 35`.
- **Риск-зона `36+`**: растёт вероятность проблем с читаемостью, коллизиями усечённых имён в toolset/скриптовых пайплайнах и сложностью отладки на поздних этапах.
- **Roster-tag**: использовать более строгий лимит `<= 24` (в массовом контенте и UI/экспорте это снижает риск конфликтов и «шумных» сокращений).

> Практическое правило: если идентификатор может попасть в roster, журнал, экспорт или составные state-ключи — проектируйте его сразу как short-safe (`<=24` для roster-tag, `<=35` для остальных content-tag).

| Тип идентификатора | Engine / формальный лимит | Рекомендация (safe-limit) | Пример |
| --- | --- | --- | --- |
| NPC tag (`Tag`) | до `63` | `<=35` (риск выше на `36+`) | `npc_bg_blacklake_guard_a01` |
| Route tag (`npc_route_tag_*`) | до `63` | `<=35` (учитывать суффиксы `_i_of_N`) | `market_day_patrol` |
| Activity/slot id (`npc_activity_id`, route activity id) | до `63` | `<=35` | `idle_vendor_day` |
| Roster tag / roster-facing id | до `63` | `<=24` (более строгий лимит) | `bg_guard_a01` |


## Контракт pending-состояний (NPC-local и area-local)

- Источник истины для pending-статуса — `NPC-local` (`npc_pending_*` на объекте NPC); `NpcBhvrQueueEnqueue` и queue-processing используют runtime API `NpcBhvrPendingSetTrackedAtIntReason`/`NpcBhvrPendingSetStatusTrackedAt` (единый `nNow`) для переходов `queued/running/deferred/processed/dropped`.
- `area-local` (`npc_queue_pending_*` на area) — диагностическое/наблюдаемое зеркало последнего состояния, обновляется через `NpcBhvrPendingAreaTouch`.
- Временная модель (`*_updated_at`) едина для обоих хранилищ: используется `NpcBhvrPendingNow()` (секундный timestamp на базе календарного дня + `HH:MM:SS`).
- Для `NPC-local` timestamp дополнительно поддерживает монотонность при частых апдейтах (минимум `+1` при коллизии секунды); `area-local` пишет то же текущее значение времени без отдельного источника часов.
- `deferred` при `GetArea(oSubject) != oArea` фиксируется **в обоих хранилищах** и не очищается неявно в этом же шаге.
- Очистка pending (`NpcBhvrPendingNpcClear` и `NpcBhvrPendingAreaClear`) допустима только на явных terminal-переходах (`processed`, `dropped`, удаление/смерть NPC, очистка очереди/area shutdown).
- Следствие: deferred является краткоживущим состоянием до следующего события/terminal-перехода, но в течение этого окна наблюдается консистентно и в NPC-local, и в area-local.


## Canonical runtime references

- Runtime module: `src/modules/npc/*`
- Runtime backlog: `docs/npc_implementation_backlog.md`
- Runtime checklist: `docs/npc_phase1_test_checklist.md`
- Perf gate: `docs/perf/npc_perf_gate.md`
- Runtime dashboards: `docs/perf/dashboards/README.md`

## Current readiness snapshot

- **Runtime MVP:** `READY` — core lifecycle/queue/activity/metrics и thin-entrypoints подключены в `src/modules/npc/*`.
- **Fairness/lifecycle self-check:** `READY` — автоматические проверки доступны через `scripts/test_npc_fairness.sh` и `scripts/check_npc_lifecycle_contract.sh`.
- **Perf baseline/perf-gate:** `GO (PASS)` — baseline свежий и валидный (>=3 runs, <=14 days), активные guardrails в статусе PASS; см. `docs/perf/npc_baseline_report.md` и `docs/perf/reports/npc_gate_summary_latest.md`.
- **Runtime dashboards:** `READY` — артефакты дашбордов зафиксированы в `docs/perf/dashboards/` (`tick_orchestration`, `db_flush`, `ai_step_cost`).

Правило консистентности: при обновлении baseline в `docs/perf/npc_baseline_report.md` обязательно синхронизируйте status-блоки в `README.md` (раздел "Текущий этап разработки / Phase 1 snapshot") и в этой секции.

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
| Area maintenance loop | `npc_area_maintenance.nss` | `NpcBhvrOnAreaMaintenance` |

Этот документ описывает **модуль поведения NPC** из `src/modules/npc/`: как он устроен, как работает в рантайме, как подключить и настроить его в тулсете (NWN2 Toolset), какие локальные переменные и контракты используются, и как проверять модуль после изменений.

> Область документа: только `src/modules/npc`.
> Папка `third_party/` и компилятор внутри неё не относятся к этому модулю и в рамках этого README не используются.

---

## 1) Что входит в модуль

Каталог `src/modules/npc/` состоит из двух частей:

1. **Thin entrypoint scripts** (тонкие скрипты-хуки событий).
   Они почти ничего не решают сами, а делегируют в core.
2. **Core/include слой** (`npc_core`, `npc_activity_inc`, `npc_metrics_inc`) с основной логикой lifecycle, очереди, активностей и метрик.

### Состав файлов

- `npc_core.nss` — центральная runtime-фасадная логика:
  - lifecycle area-controller (`RUNNING/PAUSED/STOPPED`),
  - bounded queue с приоритетами,
  - tick pipeline и degraded mode,
  - обработка hook-событий,
  - интеграция write-behind flush.
- `npc_activity_inc.nss` — activity adapter/runtime:
  - слот/маршрут/состояние NPC,
  - schedule-aware выбор route,
  - waypoint/activity разрешение.
- `npc_metrics_inc.nss` — helper API для метрик.
- Thin hooks:
  - `npc_spawn.nss`
  - `npc_perception.nss`
  - `npc_damaged.nss`
  - `npc_death.nss`
  - `npc_dialogue.nss`
  - `npc_area_enter.nss`
  - `npc_area_exit.nss`
  - `npc_area_tick.nss`
  - `npc_area_maintenance.nss`
  - `npc_module_load.nss`

---

## 2) Архитектура и модель выполнения

## 2.1 Lifecycle по области

Для каждой area хранится состояние:

- `STOPPED` — loop не активен;
- `RUNNING` — обычный tick processing;
- `PAUSED` — watchdog-режим (редкий тик + обслуживание).

Главные принципы:

- В RUNNING модуль обрабатывает очередь событий и activity.
- В PAUSED основной интенсивный loop выключен, но есть watchdog и maintenance.
- При полном idle и отсутствии игроков area может быть автоматически остановлена.

## 2.2 Очередь событий NPC

Очередь bounded (ограниченная), приоритетная:

- `CRITICAL`
- `HIGH`
- `NORMAL`
- `LOW`

Особенности:

- coalesce/anti-duplicate: повторные события не раздувают очередь бесконтрольно;
- starvation guard: low-priority bucket не должен голодать вечно;
- overflow guardrail: при переполнении применяются правила деградации и trim/drop;
- deferred accounting: часть задач может быть отложена и учитывается отдельными счётчиками.

## 2.3 Tick pipeline (high-level)

Один area tick проходит через стадии:

1. **Подготовка бюджетов** (events/budget/carryover).
2. **Budgeted work** — цикл обработки очереди в пределах budget.
3. **Degradation/carryover** — выставление режима деградации и перенос бюджета.
4. **Deferred reconcile/trim** — защитные операции на deferred backlog.
5. **Backlog telemetry + idle stop policy**.
6. **Flush write-behind** (по условию).
7. **Планирование следующего тика** по state.

Эта стадийность нужна, чтобы разделять hot-path и maintenance-path и держать поведение предсказуемым.

---

## 3) Карта hook-скриптов для тулсета

Ниже — какие entrypoint-скрипты назначать на события в NWN2 Toolset.

> Важно: это thin wrappers. Их нельзя перегружать бизнес-логикой — логика живет в `npc_core`/include.

| Toolset hook | Script |
|---|---|
| Module OnLoad | `npc_module_load` |
| Creature OnSpawn | `npc_spawn` |
| Creature OnPerception | `npc_perception` |
| Creature OnDamaged | `npc_damaged` |
| Creature OnDeath | `npc_death` |
| Creature OnConversation / Dialogue | `npc_dialogue` |
| Area OnEnter | `npc_area_enter` |
| Area OnExit | `npc_area_exit` |
| Area Tick dispatcher (через DelayCommand) | `npc_area_tick` |
| Area maintenance watchdog | `npc_area_maintenance` |

Практика интеграции:

- Назначайте эти скрипты как canonical hooks в шаблонах существ/областей модуля.
- Не создавайте отдельные «альтернативные» копии с теми же обязанностями — это ломает контрактный контур.

---

## 3.1) TL;DR: минимальная настройка NPC за 5 минут

Если коротко, чтобы NPC вообще «ожили», нужно всего 4 вещи:

1. В **Module OnLoad** поставить `npc_module_load`.
2. У NPC-шаблонов (creature blueprints) выставить hooks:
   - `OnSpawn = npc_spawn`
   - `OnPerception = npc_perception`
   - `OnDamaged = npc_damaged`
   - `OnDeath = npc_death`
   - `OnConversation = npc_dialogue`
3. У area привязать `npc_area_enter` и `npc_area_exit` (если в модуле используется area enter/exit pipeline).
4. Скомпилировать скрипты и проверить, что после запуска у NPC появляются locals:
   - `npc_activity_slot`
   - `npc_activity_state`
   - `npc_activity_last_ts`

Если эти locals не появляются, почти всегда проблема в одном из пунктов выше (обычно не назначен hook или не скомпилирован нужный `npc_*.nss`).

## 3.2) Как NPC понимает, куда идти (route -> waypoint)

Короткий принцип движения такой:

1. На idle-тик runtime выбирает **effective route** (например `default_route` / `priority_patrol` / `critical_safe`) через fallback-цепочку.
2. Для выбранного route читаются параметры waypoint-маршрута:
   - `npc_route_count_<routeId>` — сколько точек в маршруте;
   - `npc_route_tag_<routeId>` — tag группы waypoint/состояния;
   - `npc_route_loop_<routeId>` — зацикливать маршрут или нет.
3. Текущая позиция берётся из `npc_activity_wp_index`.
4. После dispatch индекс двигается на следующую точку:
   - при loop=on: после `N` идёт снова `1`;
   - при loop=off: остаётся на последней валидной точке.
5. В `npc_activity_state`/`npc_activity_last` пишется состояние с суффиксом маршрута, например `..._<routeTag>_<i>_of_<N>`, чтобы было видно, какой waypoint сейчас активен.

Важно: если `npc_route_count_<routeId> <= 0` или не задан `npc_route_tag_<routeId>`, runtime не сможет построить waypoint-ветку и уйдёт в безопасный fallback-state без waypoint-суффикса.

Минимум данных, чтобы NPC реально ходил по маршруту:

- валидный `routeId` (`default_route|priority_patrol|critical_safe`),
- `npc_route_count_<routeId> > 0`,
- `npc_route_tag_<routeId>` (не пустой),
- корректные waypoint-объекты/теги в вашем контенте под этот route-tag.

Быстрая диагностика, если «стоит на месте»:

- проверить `npc_activity_route_effective` (какой route реально выбран),
- проверить `npc_activity_wp_index|npc_activity_wp_count|npc_activity_wp_loop`,
- проверить рост `npc_metric_activity_invalid_route_total` (невалидный route -> fallback),
- проверить cooldown (`npc_activity_cooldown_until_ts`): пока активен, idle-dispatch не двигает состояние.

## 4) Настройка в тулсете: пошагово

### Шаг 1. Подключить исходники

Убедитесь, что `npc_*.nss`, `npc_core.nss`, `npc_activity_inc.nss`, `npc_metrics_inc.nss` присутствуют в вашем рабочем наборе скриптов модуля.

### Шаг 2. Назначить event hooks

В NWN2 Toolset:

- на уровне **Module properties** выставить `OnLoad = npc_module_load`;
- на уровне **Area properties** привязать вход/выход (`npc_area_enter`, `npc_area_exit`) в используемом у вас пайплайне;
- на уровне **Creature blueprint/template** назначить:
  - `OnSpawn = npc_spawn`
  - `OnPerception = npc_perception`
  - `OnDamaged = npc_damaged`
  - `OnDeath = npc_death`
  - `OnConversation = npc_dialogue` (или ваш эквивалент поля диалога).

### Шаг 3. Проверить старт lifecycle

После загрузки модуля (`npc_module_load`) runtime должен:

- инициализировать подсистемы,
- применить tick runtime config,
- активировать/восстановить area loops в корректных состояниях.

### Шаг 4. Проверить базовые NPC locals

Для NPC стоит проверить наличие runtime locals после spawn/первых тиков:

- `npc_activity_slot`
- `npc_activity_route_effective`
- `npc_activity_state`
- `npc_activity_last`
- `npc_activity_last_ts`

Для area:

- `npc_area_state`
- `npc_queue_pending_total`
- `npc_tick_max_events`
- `npc_tick_soft_budget_ms`

### Шаг 5. Проверить, что loop «живой»

Косвенные признаки:

- меняются метрики processed/degraded,
- обновляется activity state у NPC,
- при idle очередь не растёт,
- при нагрузке queue budget ограничивает обработку, но не стопорит модуль.

---

## 5) Конфигурация runtime (что можно настраивать)

## 5.1 Tick budget

Поддерживаются ключи конфигурации:

- `npc_cfg_tick_max_events`
- `npc_cfg_tick_soft_budget_ms`

Цепочка применения:

1. area-local override,
2. module-local fallback,
3. встроенные defaults.

Нормализация:

- значения ограничиваются hard-cap внутри runtime,
- итог сохраняется в:
  - `npc_tick_max_events`
  - `npc_tick_soft_budget_ms`

## 5.2 Очередь и деградация

Контур использует:

- bounded queue,
- reason-коды деградации,
- deferred cap,
- carryover events.

Это значит: при пиковых нагрузках модуль «сбрасывает давление» по правилам, а не деградирует в неуправляемую задержку.

## 5.3 Activity slot/route

NPC runtime учитывает:

- slot (`default/priority/critical`),
- route profile,
- route tag,
- schedule windows,
- waypoint loop/count/index.

Некорректные значения нормализуются в допустимые и отмечаются метриками invalid-route/invalid-slot.

---

## 6) Runtime-переменные (сокращенный справочник)

## 6.1 Area locals

- `npc_area_state`
- `npc_area_timer_running`
- `npc_area_maint_timer_running`
- `npc_queue_depth`
- `npc_queue_pending_total`
- `npc_queue_deferred_total`
- `npc_tick_max_events`
- `npc_tick_soft_budget_ms`
- `npc_tick_carryover_events`
- `npc_tick_degraded_mode`
- `npc_tick_last_degradation_reason`
- `npc_player_count`

## 6.2 NPC locals (activity/pending)

- `npc_activity_slot`
- `npc_activity_route`
- `npc_activity_route_effective`
- `npc_activity_state`
- `npc_activity_last`
- `npc_activity_last_ts`
- `npc_activity_cooldown_until_ts`
- `npc_activity_cooldown`
- `npc_activity_wp_index`
- `npc_activity_wp_count`
- `npc_activity_wp_loop`

Pending/queue зеркало:

- `npc_pending_priority`
- `npc_pending_reason_code`
- `npc_pending_reason` (legacy string mirror for diagnostics/transition compatibility)
- `npc_pending_status`
- `npc_pending_updated_at`

---

## 7) Метрики и диагностика

Модуль использует helper API метрик и пишет runtime-счётчики для наблюдаемости.

Полезные направления мониторинга:

- throughput:
  - `processed_total`
- деградация:
  - `tick_budget_exceeded_total`
  - `degraded_mode_total`
  - `degradation_events_total`
  - `tick_last_degradation_reason`
- очередь:
  - dropped/deferred counters
  - pending/deferred totals
- maintenance:
  - self-heal reconcile counters

Если видите устойчивый рост degraded/overflow — увеличивайте budget аккуратно и/или снижайте интенсивность генерации событий у контента.

---

## 8) Рекомендации по тюнингу в тулсете

1. **Начинайте с дефолтов** и меняйте только при фактической нагрузке.
2. **Повышайте budget постепенно**:
   - сначала `npc_cfg_tick_max_events`;
   - затем при необходимости `npc_cfg_tick_soft_budget_ms`.
3. **Не назначайте CRITICAL без необходимости** — это bypass fairness.
4. **Проверяйте schedule/route данные на контенте** (ошибки маршрутов маскируются fallback-механизмами, но стоят метрик и качества поведения).
5. **Сохраняйте thin-hook модель**: любые расширения добавляйте в include/core, а не в entrypoint-файлы.

---

## 9) Процедура валидации после изменений

Минимальный набор:

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/test_npc_fairness.sh
bash scripts/test_npc_activity_contract.sh
```

Дополнительно (по необходимости):

```bash
bash scripts/test_npc_activity_lifecycle_smoke.sh
bash scripts/test_npc_activity_schedule_contract.sh
bash scripts/test_npc_activity_route_contract.sh
```

---

## 10) Типичные проблемы и что проверить

### Проблема: NPC «замирают»

Проверьте:

- правильность hook-скриптов на blueprint,
- `npc_area_state` (не осталась ли area в STOPPED/PAUSED),
- queue pending/deferred totals,
- presence `npc_activity_route_effective` и `npc_activity_state`.

### Проблема: сильная деградация под нагрузкой

Проверьте:

- `tick_budget_exceeded_total` и reason-коды,
- не превышен ли разумный queue pressure,
- настройку `npc_cfg_tick_max_events` / `npc_cfg_tick_soft_budget_ms`.

### Проблема: route/slot ведут себя «не так»

Проверьте:

- валидность route id/tag,
- schedule окна,
- не срабатывает ли fallback (через метрики invalid-route/invalid-slot).

---

## 11) Правила расширения модуля

Чтобы не ломать контракт:

- сохраняйте thin entrypoints тонкими;
- новую behavior-логику добавляйте в include/core;
- не меняйте ключевые local key names без миграционного слоя;
- при любой оптимизации сохраняйте совместимость lifecycle/queue/activity контрактов;
- после изменений всегда гоняйте contract checks.

---

## 12) Краткий интеграционный чеклист

- [ ] Скрипты `src/modules/npc` подключены в проект модуля.
- [ ] Hook-скрипты назначены в NWN2 Toolset согласно таблице.
- [ ] На module load вызывается `npc_module_load`.
- [ ] После запуска подтверждён живой area loop.
- [ ] Проверены базовые area/NPC locals.
- [ ] Прогнаны smoke + lifecycle + fairness + activity контракты.

Если все пункты отмечены — NPC behavior module считается корректно интегрированным и готовым к дальнейшему контентному развитию.
