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
| OnHeartbeat | `NpcBehaviorOnHeartbeat` | P1 |
| OnEndCombatRound | `NpcBehaviorOnEndCombatRound` | P1 |
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
  - `npc_decay_time_sec` → если `<= 0`, то `5000`

Это сохраняет `npc_behavior_spawn.nss` thin-entrypoint: вся бизнес-логика остается в `npc_behavior_core.nss`.

## Что уже покрыто

- централизация логики хуков через единый include;
- state transitions `IDLE/ALERT/COMBAT`;
- tick pacing и лимит `NPC_TICK_PROCESS_LIMIT`;
- минимальная телеметрия (`spawn/perception/damaged/physical_attacked/spell_cast_at/end_combat_round/death/dialogue` counters);
- связка `OnDeath + decays/lootable` и `OnPerception + hidden AI disable`.

## Observability contract (Phase 1)

Phase 1 использует единый helper записи метрик `NpcBehaviorMetricInc/NpcBehaviorMetricAdd` в `npc_behavior_core.nss`: каждый handler пишет counters через один и тот же API, без прямого `SetLocalInt` в entrypoints.

### Контракт по handlers

- `NpcBehaviorOnPerception` → `npc_metric_perception_count`.
- `NpcBehaviorOnDamaged` → `npc_metric_damaged_count`.
- `NpcBehaviorOnDeath` → `npc_metric_death_count`.
- `NpcBehaviorOnDialogue` → `npc_metric_dialog_count`.
- `NpcBehaviorOnHeartbeat` (P1) → `npc_metric_heartbeat_count`, при раннем выходе/skip также `npc_metric_heartbeat_skipped_count`.
- `NpcBehaviorOnCombatRound` (P1) → `npc_metric_combat_round_count`, затем heartbeat sync.
- `NpcBehaviorOnAreaTick` (P1, area-level) аккумулирует на area:
  - processed (`npc_area_metric_processed_count`),
  - skipped (`npc_area_metric_skipped_count`),
  - deferred (`npc_area_metric_deferred_count`),
  - queue overflow (`npc_area_metric_queue_overflow_count`).

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
- `npc_metric_combat_round_count`
- `npc_area_metric_processed_count`
- `npc_area_metric_skipped_count`
- `npc_area_metric_deferred_count`
- `npc_area_metric_queue_overflow_count`


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
