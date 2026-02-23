# NPC Toolset Properties Cleanup Report

## Scope
Удалены переменные и код, связанные с внутренними NPC Toolset-свойствами (Decays/Lootable/DialogInterruptible/Hidden AI disable/Plot) из runtime-модуля поведения NPC.

> Примечание по структуре: `src/modules/npc_behavior/` является redirect/документационным слоем. Production runtime-скрипты находятся в `tools/npc_behavior_system/`.

## Files changed

### 1) `tools/npc_behavior_system/npc_behavior_core.nss`

Удалённые символы/идентификаторы:
- `NPC_DEFAULT_FLAG_DECAYS`
- `NPC_DEFAULT_FLAG_LOOTABLE_CORPSE`
- `NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN`
- `NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE`
- `NPC_DEFAULT_DECAY_TIME_SEC`
- `NPC_VAR_FLAG_DECAYS`
- `NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE`
- `NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN`
- `NPC_VAR_FLAG_PLOT`
- `NPC_VAR_FLAG_LOOTABLE_CORPSE`
- `NPC_VAR_RUNTIME_HIDDEN`
- `NPC_VAR_FLAG_DECAYS_SET`
- `NPC_VAR_FLAG_LOOTABLE_CORPSE_SET`
- `NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN_SET`
- `NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE_SET`
- `NPC_VAR_TEMPLATE_FLAG_DECAYS`
- `NPC_VAR_TEMPLATE_FLAG_LOOTABLE_CORPSE`
- `NPC_VAR_TEMPLATE_FLAG_DISABLE_AI_WHEN_HIDDEN`
- `NPC_VAR_TEMPLATE_FLAG_DIALOG_INTERRUPTIBLE`
- `NPC_VAR_TEMPLATE_DECAY_TIME_SEC`
- `NPC_VAR_DECAY_TIME_SEC`

Удалённые участки кода:
- Ветка disable-check по hidden AI (`npc_flag_disable_ai_when_hidden` + `npc_runtime_hidden`) из `NpcBehaviorIsDisabled`.
- Полная инициализация/валидация toolset-флагов в `NpcBehaviorOnSpawn`:
  - чтение template keys `npc_tpl_flag_*`, `npc_tpl_decay_time_sec`;
  - применение `*_SET` и fallback-логики;
  - запись `npc_flag_plot` через `GetPlotFlag`.
- Death side-effects по toolset-свойствам:
  - `SetLootable(...)`;
  - `DelayCommand(..., DestroyObject(oNpc))` на базе `npc_decay_time_sec`.
- Dialogue side-effect по toolset-свойству:
  - `AssignCommand(oNpc, ClearAllActions())` на основе `npc_flag_dialog_interruptible`.

Добавленные TODO (ручная проверка поведения):
- в `NpcBehaviorOnSpawn` — проверить template defaults после удаления Toolset sync;
- в `NpcBehaviorOnDeath` — проверить decay/loot поведение вручную;
- в `NpcBehaviorOnDialogue` — проверить правила interruption вручную.

### 2) `tools/npc_behavior_system/README.md`

Удалены упоминания и контракты по удалённым toolset-переменным:
- `npc_flag_decays`
- `npc_flag_lootable_corpse`
- `npc_flag_disable_ai_when_hidden`
- `npc_flag_dialog_interruptible`
- `npc_flag_plot`
- `npc_tpl_flag_decays`
- `npc_tpl_flag_lootable_corpse`
- `npc_tpl_flag_disable_ai_when_hidden`
- `npc_tpl_flag_dialog_interruptible`
- `npc_tpl_decay_time_sec`

Документация обновлена под runtime-only параметры (`npc_flag_disable_object`, `npc_tpl_tick_interval_*`, `npc_tpl_alert_decay_sec`).

## Removed symbol volume (approx)
- `tools/npc_behavior_system/npc_behavior_core.nss`: ~5663 удалённых символов (по diff, сумма длины удалённых строк).
- `tools/npc_behavior_system/README.md`: ~2352 удалённых символов (по diff, сумма длины удалённых строк).
