# NPC Behavior Module (Phase 1 MVP, revised)

Цель: централизовать системную логику NPC в одном `include`, а в event-hook скриптах оставить только thin-entrypoint.

## Центральный слой

- `npc_behavior_core.nss` — общие константы, state machine, heartbeat/area-tick pacing, и минимальная телеметрия.

## Hook-скрипты (entrypoints)

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

`npc_behavior_core.nss` использует минимальный runtime-набор переменных для логики,
которая реально работает в обработчиках:

- `npc_flag_decays`
- `npc_flag_dialog_interruptible`
- `npc_flag_disable_ai_when_hidden`
- `npc_flag_plot`
- `npc_flag_lootable_corpse`
- `npc_flag_disable_object`
- `npc_decay_time_sec`


## Spawn defaults and validation

В `NpcBehaviorOnSpawn` добавлена явная инициализация контрактных переменных с fallback-валидацией:

- Флаги (допускаются только `TRUE/FALSE`, иначе применяется дефолт):
  - `npc_flag_decays` → `TRUE`
  - `npc_flag_lootable_corpse` → `TRUE`
  - `npc_flag_disable_ai_when_hidden` → `FALSE`
  - `npc_flag_dialog_interruptible` → `TRUE`
- Параметры (защита от невалидных значений):
  - `npc_decay_time_sec` → если `<= 0`, то `5` (секунд)
  - `npc_tick_interval_idle_sec` → если `< 1`, то `6`
  - `npc_tick_interval_combat_sec` → если `< 1`, то `2`
- Init-once:
  - служебные runtime-local (`npc_state`, pending/deferred/last tick counters) нормализуются через `NpcBehaviorInitialize` только один раз по флагу `npc_behavior_init_done`.
- Disable guard:
  - при `npc_flag_disable_object = TRUE` spawn handler выполняет ранний выход после нормализации и инкремента метрики spawn.

Это сохраняет `npc_behavior_spawn.nss` thin-entrypoint: вся бизнес-логика остается в `npc_behavior_core.nss`.

## Что уже покрыто

- централизация логики хуков через единый include;
- state transitions `IDLE/ALERT/COMBAT`;
- переход в `NPC_STATE_COMBAT` в `OnPerception/OnPhysicalAttacked/OnSpellCastAt` выполняется через единый контракт `GetIsReactionTypeHostile(source, target)`: в handlers `source` всегда инициатор события (`seen/attacker/caster`), `target` — NPC; для совместимости используется helper с явной двусторонней проверкой (`source -> npc` **или** `npc -> source`) при faction/charm асимметрии;
- tick pacing и лимит `NPC_TICK_PROCESS_LIMIT`;
- минимальная телеметрия (`spawn/perception/damaged/physical_attacked/spell_cast_at/combat_round/death/dialogue` counters);
- связка `OnDeath + decays/lootable` и `OnPerception + hidden AI disable`.

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
- `NpcBehaviorOnDeath` работает без intake: перед terminal side-effects (`lootable/decay`) вызывает flush pending/queue-состояния (`npc_pending_*`, `npc_pending_total`, `npc_pending_priority`) и снимает соответствующие area queue buckets, затем пишет `npc_metric_death_count`.

### Intake/coalesce/degraded mode (Phase 1+)

В `npc_behavior_core.nss` добавлены базовые guardrails из runtime-плана:

- bounded area queue через `npc_area_queue_depth` + priority buckets (`critical/high/normal/low`);
- coalesce окно `NPC_COALESCE_WINDOW_SEC` для шумных non-critical событий (`perception/dialogue/spell/combat_round`);
- при overflow non-critical события уходят в defer (без bucket-only вытеснения), а `CRITICAL` owner-aware вытесняет конкретный pending-элемент из очереди последовательно `LOW -> NORMAL -> HIGH`;
- для пикового боевого шторма есть emergency reserve (`NPC_AREA_CRITICAL_RESERVE`) сверх nominal `queueCapacity`; при вытеснении синхронно обновляются и area buckets/depth, и `npc_pending_*`/`npc_pending_total` владельца;
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
  - Area OnEnter handler is resilient to area-list update timing: it activates when there is at least one PC already counted in area **or** the entering object is a PC, but only if `NpcBehaviorAreaIsActive(oArea) == FALSE`.
  - Area OnExit handler is resilient to delayed removal from area list: it counts `nPlayers = NpcBehaviorCountPlayersInArea(oArea)` and deactivates when no PCs remain after exit (`GetIsPC(oExiting) && nPlayers <= 1`, or `!GetIsPC(oExiting) && nPlayers == 0`), with an additional guard that area must be active.
  - `NpcBehaviorAreaActivate(oArea)` sets `nb_area_active=TRUE` and starts one timer loop (`nb_area_timer_running`) without duplicates.
  - `NpcBehaviorAreaDeactivate(oArea)` sets `nb_area_active=FALSE`; loop stops on next iteration.
- Timer loop: `NpcBehaviorAreaTickLoop(oArea)` self-schedules with 1.0 sec interval and does not use Area OnHeartbeat.
- Dispatcher: `NpcBehaviorOnAreaTick(oArea)` processes only creatures in current area with budget (`NPC_AREA_BUDGET_PER_TICK`) and stagger offset (`nb_area_tick_seq`).
- Filtering in dispatcher:
  - only creatures, non-PC, `npc_behavior_init_done==TRUE`, `npc_flag_disable_object!=TRUE`.
  - per selected NPC: `NpcBehaviorShouldProcess(oNpc)` then `NpcBehaviorOnHeartbeat(oNpc)`.

## Disable flags behavior for dialogue hook

`NpcBehaviorOnDialogue` использует тот же ранний disable-check, что и другие event handlers: `NpcBehaviorIsDisabled(oNpc)`.

Ожидаемое поведение:

- `npc_flag_disable_object = TRUE`
  - dialogue hook завершает обработку сразу;
  - не выполняется intake/coalesce для `dialogue`;
  - не инкрементируется `npc_metric_dialog_count`;
  - не применяются `dialog_interruptible`-действия и state transition `COMBAT -> ALERT`.
- `npc_flag_disable_ai_when_hidden = TRUE`
  - при `npc_runtime_hidden = TRUE` поведение идентично полному disable: dialogue hook выходит сразу;
  - при `npc_runtime_hidden = FALSE` dialogue hook работает штатно.

## Следующие шаги

1. Подключить реальную инициализацию флагов из template-параметров NPC на OnSpawn.
2. Подключить write-behind persistence (NWNX SQLite) и вынести метрики в отдельный sink.
3. Формализовать area lifecycle состояния (RUNNING/PAUSED/STOPPED) в отдельном controller script.
