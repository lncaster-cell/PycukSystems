# NPC Toolset Post-Cleanup Validation

_Обновлено: 2026-02-24._


Документ фиксирует ручной проверочный сценарий после удаления toolset-derived логики из `npc_behavior_core.nss` и ожидаемое поведение.

## Контекст

В `NpcBehaviorOnSpawn`, `NpcBehaviorOnDeath` и `NpcBehaviorOnDialogue` удалены автоматические sync/side-effects, завязанные на внутренние Toolset-свойства NPC (decay/loot/dialog interruptibility/hidden-ai/plot). Текущий runtime-контракт покрывает только runtime-local параметры и state machine.

## Checklist (manual validation)

### 1) Spawn defaults

**Цель:** убедиться, что NPC после спавна получает корректные runtime-значения без legacy toolset-sync.

- [ ] Для тестового NPC без локалов проверить fallback:
  - `npc_tick_interval_idle_sec = 6`
  - `npc_tick_interval_combat_sec = 2`
  - `npc_alert_decay_sec = 12`
- [ ] Для NPC с template string-local (`npc_tpl_tick_interval_idle_sec`, `npc_tpl_tick_interval_combat_sec`, `npc_tpl_alert_decay_sec`) убедиться, что они приоритетнее runtime-local и корректно нормализуются.
- [ ] Для NPC с `npc_flag_disable_object = TRUE` убедиться, что spawn-метрика увеличивается, но дальнейшая активная обработка не запускается.
- [ ] Для blueprints, которые раньше зависели от toolset-флагов (decays/lootable/dialog/hidden-ai/plot), проверить что поведение определяется только настройками blueprint/toolset, а не runtime-скриптом.

**Ожидаемое поведение:**
- `NpcBehaviorOnSpawn` инициализирует только runtime-интервалы/alert-decay и init state.
- Legacy toolset-флаги не читаются/не записываются из core.

### 2) Death side-effects (decay/loot)

**Цель:** проверить, что death-path не навязывает toolset-derived логику, но сохраняет корректный cleanup core-состояния.

- [ ] Убить NPC с lootable corpse в Toolset: убедиться, что лут доступен согласно настройке blueprint/toolset.
- [ ] Убить NPC с non-lootable corpse: убедиться, что скрипт не меняет это поведение.
- [ ] Проверить decay-поведение трупа на шаблонах с разными Toolset-настройками decay: скрипт не должен вызывать `DestroyObject` по локалам.
- [ ] Подтвердить, что после смерти не остаётся «подвешенных» pending/queue вкладов NPC (по telemetry/debug наблюдениям).

**Ожидаемое поведение:**
- `NpcBehaviorOnDeath` всегда делает queue/pending cleanup и пишет death metric.
- Loot/decay управляются внешними настройками (Toolset/module rules), без script-forced override.

### 3) Dialogue interruption behavior

**Цель:** подтвердить, что dialogue path работает без legacy interruptibility hook.

- [ ] Начать диалог с NPC вне боя и убедиться, что диалог не прерывается скриптом через `ClearAllActions`.
- [ ] Для NPC в `COMBAT` при событии dialogue проверить перевод состояния в `ALERT`.
- [ ] Проверить шаблоны с разными expected interruption rules: итог определяется текущей game/toolset конфигурацией, не runtime-local `npc_flag_dialog_interruptible`.

**Ожидаемое поведение:**
- `NpcBehaviorOnDialogue` выполняет intake/метрику и state transition `COMBAT -> ALERT`.
- Принудительное прерывание действий через legacy-флаг отсутствует.

## Статус

- **Дата обновления:** 2026-02-23
- **Статус валидации:** сценарий подготовлен, runtime-прохождение на стенде в процессе (manual QA).
- **Источник для кросс-ссылок:** этот файл используется как validation-report после cleanup TODO.
