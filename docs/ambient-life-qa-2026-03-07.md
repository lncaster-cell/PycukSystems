# QA-проверка сценариев AL (статический проход)

Дата: 2026-03-07

## Ограничения проверки

Проверка выполнена как **статический аудит скриптов** `scripts/al_prototype` (без запуска игрового рантайма NWN2 в этом окружении).

Важно: стоковые/third-party скрипты не проверялись.

## 1) Сценарии lifecycle

### 1.1 enter / exit / client leave
- `OnEnter` всегда сбрасывает `al_exit_counted`, выставляет `al_last_area`, инкрементит `al_player_count`, а для первого игрока запускает warm-up + unhide/resync.
- `OnExit` и `OnClientLeave` используют единый helper `AL_OnPlayerExitCount`; повторный декремент блокируется через `al_exit_counted`.
- Empty-handler (`AL_HandleAreaBecameEmpty`) вызывается только когда decrement довёл счётчик до нуля.

**Вывод:** сценарии enter/exit/client leave покрыты единым каноном счётчика игроков и защищены от двойного декремента.

### 1.2 empty freeze
- При переходе area в пустое состояние выполняется `AL_HandleAreaBecameEmpty`:
  - инвалидируется тик-эпоха (`al_tick_token++`), очищаются scheduling-локалы;
  - сбрасывается `al_tick_warm_left` и route-cache;
  - вызывается `AL_HideRegisteredNPCs`.
- В `AL_HideRegisteredNPCs` перед hide вызывается `AL_ResetNPCFreezeState` + `ClearAllActions()`.

**Вывод:** freeze-path очищает runtime state и скрывает NPC без оставления подвешенных sleep/route локалов.

### 1.3 wake fast
- На первом игроке `OnEnter` делает `AL_UnhideAndResyncRegisteredNPCs` и запускает warm ticks (`al_tick_warm_left`).
- `AL_UnhideAndResyncRegisteredNPCs` выполняет unhide только если NPC реально скрыт (`GetScriptHidden`) и затем отправляет `AL_EVT_RESYNC`.

**Вывод:** быстрый wake после empty-фазы корректно форсирует единый RESYNC-проход и не дублирует `SetScriptHidden(FALSE)`.

### 1.4 hot-warm-hot / cold-hot
- `OnEnter` первого игрока всегда выставляет `al_tick_warm_left`.
- `AreaTick` потребляет warm budget и затем переключается в обычный период; при неизменном слоте просто планирует следующий тик.
- При смене слота происходит только slot-broadcast (`AL_EVT_SLOT_*`) без дублирующего full-resync.

**Вывод:** цепочка hot-warm-hot/cold-hot соблюдает slot-driven модель и не смешивает slot switch с лишними lifecycle-операциями.

### 1.5 off-detach / attach
- При empty area вызывается hide для текущего registry состава.
- В `AL_SyncAreaNPCRegistry` NPC, сменивший area, удаляется из старого registry и регистрируется в новом (`AL_RegisterNPC`) с обновлением `al_last_area`.
- `AL_HandleRouteAreaTransition` (в `al_npc_routes.nss`) после transition форсирует RESYNC при наличии игроков в целевой area, иначе hide.

**Вывод:** detach/attach сценарий согласован между area-registry и route-transition логикой.

## 2) sleep reset и pair revalidation на wake

### 2.1 sleep reset
- Freeze reset (`AL_ResetNPCFreezeState`) принудительно возвращает collision в `TRUE` и удаляет:
  - `al_sleep_docked`, `al_sleep_approach_tag`;
  - `r_active`, `r_slot`, `r_idx`.
- Дополнительно, при обычном выходе из сна используется `AL_StopSleepAtBed`/`AL_ResetSleepDockState`.

**Вывод:** sleep-state и route-loop state сбрасываются корректно перед hide и при wake не переиспользуются.

### 2.2 pair revalidation на wake
- На `AL_EVT_RESYNC` в `al_npc_onud` сначала вызываются `AL_InitTrainingPartner` и `AL_InitBarPair`, затем `AL_RevalidateAreaPairLinksForWake`.
- `AL_RevalidateAreaPairLinksForWake` удаляет stale ссылки NPC-level и area-level (включая `*_ref`/runtime ключи), если объекты уже не в текущей area или backlink асимметричен.

**Вывод:** wake-путь выполняет реинициализацию и повторную валидацию пар до применения активности/маршрута.

## 3) Подтверждение: нет дублирования hide/unhide lifecycle, slot-driven канон сохранён

- `AL_HideRegisteredNPCs` вызывает `SetScriptHidden(TRUE)` только если NPC ещё не скрыт.
- `AL_UnhideAndResyncRegisteredNPCs` вызывает `SetScriptHidden(FALSE)` только если NPC скрыт.
- `AreaTick` в slot-driven режиме шлёт `AL_EVT_SLOT_*` только при фактической смене `al_slot`.
- В `al_npc_onud` повторный non-resync event для того же слота отсекается через `al_last_slot`, а repeat-event дополнительно проверяет `r_active` и соответствие `al_last_slot`.

**Итог:** дублирования hide/unhide lifecycle не выявлено; slot-driven канон (`slot change -> AL_EVT_SLOT_* -> route/activity`) сохранён.
