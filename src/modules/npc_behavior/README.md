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
  - `npc_tick_interval_idle_sec` → если `< 0.2`, то `6.0`
  - `npc_tick_interval_combat_sec` → если `< 0.2`, то `2.0`
- Init-once:
  - служебные runtime-local (`npc_state`, pending/deferred/last tick counters) нормализуются через `NpcBehaviorInitialize` только один раз по флагу `npc_behavior_init_done`.
- Disable guard:
  - при `npc_flag_disable_object = TRUE` spawn handler выполняет ранний выход после нормализации и инкремента метрики spawn.

Это сохраняет `npc_behavior_spawn.nss` thin-entrypoint: вся бизнес-логика остается в `npc_behavior_core.nss`.

## Что уже покрыто

- централизация логики хуков через единый include;
- state transitions `IDLE/ALERT/COMBAT`;
- tick pacing и лимит `NPC_TICK_PROCESS_LIMIT`;
- минимальная телеметрия (`spawn/perception/damaged/physical_attacked/spell_cast_at/combat_round/death/dialogue` counters);
- связка `OnDeath + decays/lootable` и `OnPerception + hidden AI disable`.

## Observability contract (Phase 1)

Phase 1 использует единый helper записи метрик `NpcBehaviorMetricInc/NpcBehaviorMetricAdd` в `npc_behavior_core.nss`: каждый handler пишет counters через один и тот же API, без прямого `SetLocalInt` в entrypoints.

### Контракт по handlers

- `NpcBehaviorOnPerception` → `npc_metric_perception_count`.
- `NpcBehaviorOnDamaged` → `npc_metric_damaged_count`.
- `NpcBehaviorOnPhysicalAttacked` → `npc_metric_physical_attacked_count`.
- `NpcBehaviorOnSpellCastAt` → `npc_metric_spell_cast_at_count`.
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
- `NpcBehaviorOnDeath` работает без intake: пишет только `npc_metric_death_count` и выполняет terminal side-effects (`lootable/decay`) без постановки в queue.

### Intake/coalesce/degraded mode (Phase 1+)

В `npc_behavior_core.nss` добавлены базовые guardrails из runtime-плана:

- bounded area queue через `npc_area_queue_depth` + priority buckets (`critical/high/normal/low`);
- coalesce окно `NPC_COALESCE_WINDOW_SEC` для шумных non-critical событий (`perception/dialogue/spell/combat_round`);
- при overflow non-critical события уходят в defer, а `CRITICAL` вытесняет последовательно `LOW -> NORMAL -> HIGH`;
- для пикового боевого шторма есть emergency reserve (`NPC_AREA_CRITICAL_RESERVE`) сверх nominal `queueCapacity`;
- auto degraded mode (`npc_area_degraded_mode`) по high/low watermarks и selective skip idle-heartbeat при перегрузке.

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
