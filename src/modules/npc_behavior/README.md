# NPC Behavior Module (Phase 1 MVP, revised)

Цель: централизовать системную логику NPC в одном `include`, а в event-hook скриптах оставить только thin-entrypoint.

## Центральный слой

- `npc_behavior_core.nss` — общие константы, state machine, heartbeat/area-tick pacing, и минимальная телеметрия.

## Hook-скрипты (entrypoints)

- `npc_behavior_spawn.nss` — OnSpawn (P0)
- `npc_behavior_perception.nss` — OnPerception (P0)
- `npc_behavior_damaged.nss` — OnDamaged (P0)
- `npc_behavior_death.nss` — OnDeath (P0)
- `npc_behavior_dialogue.nss` — OnDialogue (P0)
- `npc_behavior_heartbeat.nss` — OnHeartbeat (P1)
- `npc_behavior_combat.nss` — OnEndCombatRound/боевой sync helper (P1)
- `npc_behavior_tick.nss` — area-local tick dispatcher с budget cap

## Поведенческие свойства (через Local Variables)

`npc_behavior_core.nss` поддерживает набор переменных, которые можно синхронизировать с blueprint/template NPC:

- `npc_flag_decays`
- `npc_flag_resurrectable`
- `npc_flag_selectable_when_dead`
- `npc_flag_spirit_override`
- `npc_flag_immortal`
- `npc_flag_always_seen`
- `npc_flag_dialog_interruptible`
- `npc_flag_can_talk_to_creatures`
- `npc_flag_disable_ai_when_hidden`
- `npc_flag_plot`
- `npc_flag_lootable_corpse`
- `npc_flag_disable_object`
- `npc_decay_time_sec`
- `npc_perception_range`
- `npc_walk_speed`
- `npc_soundset`

## Что уже покрыто

- централизация логики хуков через единый include;
- state transitions `IDLE/ALERT/COMBAT`;
- tick pacing и лимит `NPC_TICK_PROCESS_LIMIT`;
- минимальная телеметрия (`spawn/perception/damaged/death/dialogue` counters);
- связка `OnDeath + decays/lootable` и `OnPerception + hidden AI disable`.

## Следующие шаги

1. Подключить реальную инициализацию флагов из template-параметров NPC на OnSpawn.
2. Добавить bounded queue + coalesce окно на area-orchestrator уровне.
3. Подключить write-behind persistence (NWNX SQLite) и вынести метрики в отдельный sink.
