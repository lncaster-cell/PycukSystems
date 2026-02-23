# NPC Behavior Module (Phase 1 MVP, revised)

Цель: централизовать системную логику NPC в одном `include`, а в event-hook скриптах оставить только thin-entrypoint.

## Центральный слой

- `npc_behavior_core.nss` — общие константы, state machine, heartbeat/area-tick pacing, и минимальная телеметрия.

## Source of truth for runtime scripts

- Production runtime-скрипты NPC behavior system поддерживаются в каталоге `tools/npc_behavior_system/`.
- Каталог `src/modules/npc_behavior/` является redirect/документационным слоем и не должен рассматриваться как источник runtime-кода.
- При обновлении документации и ссылок используйте `tools/npc_behavior_system/*` как canonical path, чтобы избежать дрейфа путей.

## Hook-скрипты (entrypoints)

Runtime entrypoints (production) не зависят от временных debug-хелперов: в модуле отсутствуют `al_dbg` и debug-варианты `*_debug.nss`, чтобы исключить случайные назначения неканоничных hook-скриптов.

| Hook | Core handler | Приоритет |
| --- | --- | --- |
| OnSpawn | `NpcBehaviorOnSpawn` | P0 |
| OnPerception | `NpcBehaviorOnPerception` | P0 |
| OnDamaged | `NpcBehaviorOnDamaged` | P0 |
| OnPhysicalAttacked | `NpcBehaviorOnPhysicalAttacked` | P0 |
| OnSpellCastAt | `NpcBehaviorOnSpellCastAt` | P0 |
| OnDeath | `NpcBehaviorOnDeath` | P0 |
| OnDialogue | `NpcBehaviorOnDialogue` | P0 |
| Area OnEnter | `NpcBehaviorAreaActivate` via `npc_behavior_area_enter` | P1 |
| Area OnExit | `NpcBehaviorAreaDeactivate` via `npc_behavior_area_exit` | P1 |
| OnEndCombatRound | `NpcBehaviorOnEndCombatRound` (canonical), `NpcBehaviorOnCombatRound` (compat wrapper) | P1 |
| area-local tick dispatcher | `NpcBehaviorOnAreaTick` | P2 |

## Поведенческие свойства (через Local Variables)

`npc_behavior_core.nss` после cleanup использует только runtime-переменные,
не привязанные к внутренним NPC Toolset-свойствам:

- `npc_flag_disable_object`
- `npc_tick_interval_idle_sec`
- `npc_tick_interval_combat_sec`
- `npc_alert_decay_sec`

## Spawn defaults and validation

В `NpcBehaviorOnSpawn` выполняется инициализация runtime-параметров:

- template-значения из string-local:
  - `npc_tpl_tick_interval_idle_sec`
  - `npc_tpl_tick_interval_combat_sec`
  - `npc_tpl_alert_decay_sec`
- fallback-валидация:
  - `npc_tick_interval_idle_sec` → если `< 1`, то `6`
  - `npc_tick_interval_combat_sec` → если `< 1`, то `2`
  - `npc_alert_decay_sec` → если `<= 0`, то `12`
- init-once:
  - `NpcBehaviorInitialize` выполняется один раз по `npc_behavior_init_done`.
- disable guard:
  - при `npc_flag_disable_object = TRUE` spawn handler делает ранний выход после инкремента метрики spawn.

> Ручная пост-cleanup валидация (spawn defaults / death side-effects / dialogue interruption) зафиксирована в `docs/npc_toolset_post_cleanup_validation.md`.

## Что уже покрыто

- централизация логики хуков через единый include;
- state transitions `IDLE/ALERT/COMBAT` + time-based decay `ALERT -> IDLE`;
- переход в `NPC_STATE_COMBAT` в `OnPerception/OnPhysicalAttacked/OnSpellCastAt` выполняется через единый контракт `GetIsReactionTypeHostile(source, target)`: в handlers `source` всегда инициатор события (`seen/attacker/caster`), `target` — NPC; для совместимости используется helper с явной двусторонней проверкой (`source -> npc` **или** `npc -> source`) при faction/charm асимметрии;
- tick pacing и лимит `NPC_TICK_PROCESS_LIMIT`;
- минимальная телеметрия (`spawn/perception/damaged/physical_attacked/spell_cast_at/combat_round/death/dialogue` counters);
- связка боевых переходов состояния (`OnPerception/OnDamaged/OnPhysicalAttacked/OnSpellCastAt`) и area tick pacing.

## Observability contract (Phase 1)

Phase 1 использует единый helper записи метрик `NpcBehaviorMetricInc/NpcBehaviorMetricAdd` в `npc_behavior_core.nss`: каждый handler пишет counters через один и тот же API, без прямого `SetLocalInt` в entrypoints.

### Контракт по handlers

- `NpcBehaviorOnPerception` → `npc_metric_perception_count`; если `seen` hostile к NPC по контракту `source -> target` (с compat fallback на обратное направление через helper), переводит NPC в `NPC_STATE_COMBAT`, иначе при `IDLE` переводит в `ALERT`.
- `NpcBehaviorOnDamaged` → `npc_metric_damaged_count`.
- `NpcBehaviorOnPhysicalAttacked` → `npc_metric_physical_attacked_count`; если `attacker` hostile к NPC по контракту `source -> target` (с compat fallback на обратное направление через helper), переводит NPC в `NPC_STATE_COMBAT`.
- `NpcBehaviorOnSpellCastAt` → `npc_metric_spell_cast_at_count`; если `caster` hostile к NPC по контракту `source -> target` (с compat fallback на обратное направление через helper), переводит NPC в `NPC_STATE_COMBAT`.
- `NpcBehaviorOnDeath` → `npc_metric_death_count`.
- `NpcBehaviorOnDialogue` → `npc_metric_dialog_count`.
- `NpcBehaviorOnHeartbeat` (P1) → `npc_metric_heartbeat_count`, при раннем выходе/skip также `npc_metric_heartbeat_skipped_count`.
- `NpcBehaviorOnEndCombatRound` (P1, canonical) выполняет intake/coalesce, переход `COMBAT -> ALERT` при выходе из боя, пишет `npc_metric_combat_round_count`, затем heartbeat sync через `NpcBehaviorOnHeartbeat`.
- `NpcBehaviorOnCombatRound` сохранен как compatibility-wrapper и делегирует в `NpcBehaviorOnEndCombatRound`, чтобы исключить конкурирующие пути.
- `NpcBehaviorOnAreaTick` (P1, area-level) аккумулирует на area:
  - processed (`npc_area_metric_processed_count`) — heartbeat действительно выполнен (`NpcBehaviorOnHeartbeat == TRUE`),
  - skipped (`npc_area_metric_skipped_count`) — heartbeat был запущен в рамках прохода, но завершился `FALSE` (invalid/dead/disabled/degraded/interval),
  - deferred (`npc_area_metric_deferred_count`) — eligible NPC не дошли до попытки heartbeat в этом area-tick только из-за лимита budget/очереди,
  - queue overflow (`npc_area_metric_queue_overflow_count`).

### Intake policy after `NpcBehaviorTryIntakeEvent(...)`

- **Strict policy**: `NpcBehaviorOnPerception`, `NpcBehaviorOnEndCombatRound`, `NpcBehaviorOnDialogue`, `NpcBehaviorOnSpellCastAt` делают ранний `return`, если intake/coalesce вернул `FALSE`.
- **Explicit CRITICAL bypass policy**: `NpcBehaviorOnDamaged`, `NpcBehaviorOnPhysicalAttacked` продолжают обработку даже при отказе queue/coalesce, чтобы не потерять критические side-effects (state flow).
- Для CRITICAL bypass добавлена отдельная метрика `npc_metric_intake_bypass_critical`: инкрементируется только когда intake для CRITICAL вернул `FALSE` в `NpcBehaviorOnDamaged/OnPhysicalAttacked`, и тем самым отделяет bypass от обычного queued/deferred пути.
- `NpcBehaviorOnDeath` работает без intake: выполняет flush pending/queue-состояния (`npc_pending_*`, `npc_pending_total`, `npc_pending_priority`) и снимает соответствующие area queue buckets, затем пишет `npc_metric_death_count`.

### Intake/coalesce/degraded mode (Phase 1+)

В `npc_behavior_core.nss` добавлены базовые guardrails из runtime-плана:

- bounded area queue через `npc_area_queue_depth` + priority buckets (`critical/high/normal/low`);
- coalesce окно `NPC_COALESCE_WINDOW_SEC` для шумных non-critical событий (`perception/dialogue/spell/combat_round`);
- при overflow non-critical события уходят в defer (без bucket-only вытеснения), а `CRITICAL` owner-aware вытесняет конкретный pending-элемент из очереди последовательно `LOW -> NORMAL -> HIGH`;
- для пикового боевого шторма есть emergency reserve (`NPC_AREA_CRITICAL_RESERVE`): CRITICAL после overflow может занять слот сверх nominal `NPC_AREA_QUEUE_CAPACITY` (в пределах `NPC_AREA_QUEUE_CAPACITY + NPC_AREA_CRITICAL_RESERVE`, при этом storage-буфер задан literal `NPC_AREA_QUEUE_STORAGE_CAPACITY` из-за ограничения NSC); при вытеснении синхронно обновляются и area buckets/depth, и `npc_pending_*`/`npc_pending_total` владельца;
- auto degraded mode (`npc_area_degraded_mode`) по high/low watermarks и selective skip idle-heartbeat при перегрузке; coalesce применяется только к non-critical событиям в окне `NPC_COALESCE_WINDOW_SEC`.

## Invariants

- `sum(area buckets) == npc_area_queue_depth` (`critical + high + normal + low` всегда равны текущей глубине area queue).
- Сумма `npc_pending_total` по всем NPC в area согласована с area queue: enqueue/dequeue/coalesce/defer/evict обновляют owner pending и area buckets/depth синхронно.
- Death-path полностью очищает вклад NPC в pending/queue: перед terminal side-effects `NpcBehaviorOnDeath` снимает pending-state NPC и соответствующие записи из area queue, чтобы после смерти не оставалось orphaned вкладов.

Ключевые точки кода для проверки инвариантов:

- `NpcBehaviorTryIntakeEvent` (intake/coalesce/owner pending синхронизация);
- `NpcBehaviorAreaTryQueueEvent` (queue admission, overflow/defer, bucket/depth accounting);
- `NpcBehaviorOnDeath` (death cleanup pending/queue);
- `NpcBehaviorConsumePending` (dequeue/consume и поддержание pending/queue консистентности).

## Code review checklist

- Intake/coalesce:
  - Проверить, что `NpcBehaviorTryIntakeEvent` корректно применяет coalesce окно только для non-critical событий и не ломает CRITICAL path.
  - Проверить, что `NpcBehaviorConsumePending` и intake-путь не расходятся по счетчикам `npc_pending_*`/`npc_pending_total`.
- Overflow/deferred:
  - Проверить, что `NpcBehaviorAreaTryQueueEvent` при overflow корректно различает deferred для non-critical и owner-aware eviction для CRITICAL.
  - Проверить, что при deferred/evict синхронно обновляются area buckets, `npc_area_queue_depth` и pending владельца.
- Death cleanup:
  - Проверить, что `NpcBehaviorOnDeath` всегда выполняет очистку pending/queue до `lootable/decay` side-effects и метрик смерти.
  - Проверить, что после death cleanup инварианты queue depth/buckets/pending сохраняются.
- Hostility-trigger в COMBAT:
  - Проверить, что hostile-trigger переход в `NPC_STATE_COMBAT` в `OnPerception/OnPhysicalAttacked/OnSpellCastAt` остается на контракте `GetIsReactionTypeHostile(source, target)` с compat fallback.
  - Проверить, что strict vs CRITICAL bypass intake-policy не пропускает обязательные COMBAT state transitions.

### Metric keys для write-behind слоя (планируемый whitelist)

- `npc_metric_spawn_count`
- `npc_metric_perception_count`
- `npc_metric_damaged_count`
- `npc_metric_death_count`
- `npc_metric_dialog_count`
- `npc_metric_heartbeat_count`
- `npc_metric_heartbeat_skipped_count`
- `npc_metric_combat_round_count` (единый ключ для OnEndCombatRound/compat-wrapper)
- `npc_metric_intake_bypass_critical`
- `npc_area_metric_processed_count`
- `npc_area_metric_skipped_count`
- `npc_area_metric_deferred_count`
- `npc_area_metric_queue_overflow_count`



## Area controller runtime (performance skeleton)

- Area activity lifecycle:
  - Module startup bootstrap:
    - `npc_behavior_module_load` calls `NpcBehaviorBootstrapModuleAreas()` to recover area controllers right after restart/reload.
    - Area auto-start policy is centralized in `NpcBehaviorAreaShouldAutoStart(oArea)`: starts when area has at least one PC or has local flag `npc_area_always_on = TRUE`.
  - Area OnEnter handler is resilient to area-list update timing: it activates when there is at least one PC already counted in area **or** the entering object is a PC, but only if `NpcBehaviorAreaIsActive(oArea) == FALSE`.
  - Area OnExit handler is resilient to delayed removal from area list: it counts `nPlayers = NpcBehaviorCountPlayersInArea(oArea)` and moves area to `PAUSED` when no PCs remain after exit (`GetIsPC(oExiting) && nPlayers <= 1`, or `!GetIsPC(oExiting) && nPlayers == 0`), with an additional guard that area must be active.
  - `NpcBehaviorAreaActivate(oArea)` переводит lifecycle в `RUNNING` через controller, синхронизирует `nb_area_active=TRUE` (compat) и стартует ровно один timer loop (`nb_area_timer_running`).
  - `NpcBehaviorAreaDeactivate(oArea)` переводит lifecycle в `STOPPED`; loop останавливается на следующей итерации.
  - `NpcBehaviorAreaPause(oArea)` переводит lifecycle в `PAUSED` без принудительного drain очереди; `NpcBehaviorAreaResume(oArea)` возвращает `RUNNING` через activate-path.
  - `NpcBehaviorAreaTickLoop(oArea)` в `PAUSED` продолжает легковесный polling и переводит area в `STOPPED` после idle-window (`npc_area_idle_stop_after_sec`, default 180s), либо обратно в `RUNNING` при появлении PC/always-on.
- Timer loop: `NpcBehaviorAreaTickLoop(oArea)` self-schedules with 1.0 sec interval and does not use Area OnHeartbeat.
- Dispatcher: `NpcBehaviorOnAreaTick(oArea)` processes only creatures in current area with budget (`NPC_AREA_BUDGET_PER_TICK`) and stagger offset (`nb_area_tick_seq`).
- Filtering in dispatcher:
  - only creatures, non-PC, `npc_behavior_init_done==TRUE`, `npc_flag_disable_object!=TRUE`.
  - per selected NPC: `NpcBehaviorOnHeartbeat(oNpc)`; internal throttle gate uses `NpcBehaviorShouldProcess(oNpc)`.

## Disable flags behavior for dialogue hook

`NpcBehaviorOnDialogue` использует тот же ранний disable-check, что и другие event handlers: `NpcBehaviorIsDisabled(oNpc)`.

Ожидаемое поведение:

- `npc_flag_disable_object = TRUE`
  - dialogue hook завершает обработку сразу;
  - не выполняется intake/coalesce для `dialogue`;
  - не инкрементируется `npc_metric_dialog_count`;
  - state transition `COMBAT -> ALERT` не выполняется, т.к. handler завершается ранним return.

## Следующие шаги

1. Подключить write-behind persistence (NWNX SQLite) и вынести метрики в отдельный sink.
2. Расширить scenario/perf-проверки fairness для PAUSED/RESUME/STOPPED и добавить длительные burst-профили со starvation guard.
